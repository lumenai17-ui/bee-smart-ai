/**
 * BEE Smart AI — Provider Manager Plugin
 * ═══════════════════════════════════════════
 * 
 * Central orchestrator for the provider management system.
 * 
 * Responsibilities:
 * - Load/save provider configs from encrypted vault
 * - Key rotation (automatic on 429, manual via CLI/API)
 * - Fallback chains (provider A → B → C)
 * - Provider hot-swap (change provider without restart)
 * - Tier enforcement (gate features by $25/$40/$100 plan)
 * - Health monitoring (periodic checks, auto-fallback)
 * - Audit logging (every mutation logged with sanitized keys)
 * - HTTP API + Gateway RPC for external access
 * 
 * Modules:
 * - types.ts   → Type definitions
 * - vault.ts   → AES-256-GCM encrypted key storage
 * - audit.ts   → JSONL audit logger
 * - health.ts  → Provider health monitoring
 * - api.ts     → HTTP REST API routes
 */

import * as path from 'path';
import {
  ProviderConfig,
  ProviderKey,
  ProviderType,
  TierLevel,
  TIER_ORDER,
  ProviderSummary,
  ProviderListResponse,
  RotateKeyResponse,
  AuditAction
} from './types';
import { VaultManager } from './vault';
import { AuditLogger } from './audit';
import { HealthChecker } from './health';
import { createApiRoutes } from './api';

// ═══════════════════════════════════════
// Default Provider Templates
// ═══════════════════════════════════════

const DEFAULT_PROVIDERS: Partial<ProviderConfig>[] = [
  {
    name: 'ollama-cloud',
    displayName: 'Ollama Cloud',
    type: 'llm',
    baseUrl: 'https://api.ollama.cloud/v1',
    apiType: 'openai-completions',
    tierRequired: 'basic',
    fallback: 'openai'
  },
  {
    name: 'openai',
    displayName: 'OpenAI',
    type: 'llm',
    baseUrl: 'https://api.openai.com/v1',
    apiType: 'openai-completions',
    tierRequired: 'basic',
    enabled: false
  },
  {
    name: 'deepgram',
    displayName: 'Deepgram',
    type: 'voice',
    baseUrl: 'https://api.deepgram.com/v1',
    apiType: 'deepgram',
    tierRequired: 'pro',
    fallback: 'whisper-local'
  },
  {
    name: 'stable-diffusion',
    displayName: 'Stable Diffusion',
    type: 'image',
    baseUrl: 'https://api.stability.ai/v1',
    apiType: 'stability',
    tierRequired: 'pro'
  },
  {
    name: 'kling',
    displayName: 'Kling 2.1 (fal.ai)',
    type: 'video',
    baseUrl: 'https://fal.run/fal-ai/kling-video',
    apiType: 'fal',
    tierRequired: 'pro'
  },
  {
    name: 'brave-search',
    displayName: 'Brave Search',
    type: 'search',
    baseUrl: 'https://api.search.brave.com/res/v1',
    apiType: 'brave',
    tierRequired: 'basic'
  }
];

// ═══════════════════════════════════════
// Plugin Entry Point
// ═══════════════════════════════════════

export default class ProviderManagerPlugin {
  private providers: ProviderConfig[];
  private currentTier: TierLevel;
  private vault: VaultManager;
  private audit: AuditLogger;
  private health: HealthChecker;
  private rootDir: string;

  constructor(config: {
    rootDir?: string;
    tier?: TierLevel;
    vaultPassphrase?: string;
    healthCheckIntervalMs?: number;
  }) {
    this.rootDir = config.rootDir || process.cwd();
    this.currentTier = config.tier || 'basic';

    // Initialize sub-systems
    this.vault = new VaultManager(
      path.join(this.rootDir, 'vaults', 'providers.vault.json'),
      config.vaultPassphrase || process.env.OPENCLAW_GATEWAY_TOKEN || 'bee-default-passphrase'
    );

    this.audit = new AuditLogger(
      path.join(this.rootDir, 'logs')
    );

    this.health = new HealthChecker();

    // Load providers from vault or initialize defaults
    this.providers = this.loadProviders();

    // Start health monitoring
    this.health.startPeriodicChecks(
      this.providers,
      config.healthCheckIntervalMs || 60000,
      (provider) => this.onProviderUnhealthy(provider)
    );

    this.audit.log('health_check', 'system', {
      message: 'Provider Manager initialized',
      tier: this.currentTier,
      providerCount: this.providers.length
    });
  }

  // ═══════════════════════════════════════
  // Initialization
  // ═══════════════════════════════════════

  private loadProviders(): ProviderConfig[] {
    // Try loading from vault first
    const vaultProviders = this.vault.load();
    if (vaultProviders.length > 0) {
      return vaultProviders;
    }

    // Initialize with defaults
    const providers = this.initializeDefaults();
    this.vault.save(providers);
    return providers;
  }

  private initializeDefaults(): ProviderConfig[] {
    return DEFAULT_PROVIDERS.map(template => this.createProvider(template));
  }

  private createProvider(partial: Partial<ProviderConfig>): ProviderConfig {
    return {
      name: partial.name || 'unknown',
      displayName: partial.displayName || partial.name || 'Unknown',
      type: partial.type || 'llm',
      baseUrl: partial.baseUrl || '',
      apiType: partial.apiType || 'openai-completions',
      keys: partial.keys || [],
      activeKeyIndex: 0,
      fallback: partial.fallback,
      rotateOnError: partial.rotateOnError ?? true,
      enabled: partial.enabled ?? true,
      tierRequired: partial.tierRequired || 'basic',
      health: {
        status: 'unknown',
        lastCheck: null,
        consecutiveFailures: 0,
        avgResponseTimeMs: 0
      },
      usage: {
        totalRequests: 0,
        totalErrors: 0,
        requestsToday: 0,
        estimatedCostUsd: 0,
        lastResetDate: new Date().toISOString().split('T')[0]
      }
    };
  }

  private persist(): void {
    this.vault.save(this.providers);
  }

  // ═══════════════════════════════════════
  // Core Operations
  // ═══════════════════════════════════════

  /**
   * Get the active API key for a provider.
   * Returns null if provider is disabled or unavailable for current tier.
   */
  getActiveKey(providerName: string): string | null {
    const provider = this.findProvider(providerName);
    if (!provider || !provider.enabled) return null;
    if (!this.isAvailableForTier(providerName)) return null;
    if (provider.keys.length === 0) return null;

    return provider.keys[provider.activeKeyIndex]?.value || null;
  }

  /**
   * Record a request to a provider (for usage tracking)
   */
  recordRequest(providerName: string, success: boolean, errorCode?: number): void {
    const provider = this.findProvider(providerName);
    if (!provider) return;

    const key = provider.keys[provider.activeKeyIndex];
    if (key) {
      key.requestCount++;
      key.lastUsed = new Date().toISOString();
      if (!success) key.errorCount++;
    }

    provider.usage.totalRequests++;
    provider.usage.requestsToday++;

    if (!success) {
      provider.usage.totalErrors++;

      // Auto-rotate on rate limit
      if (errorCode === 429 && provider.rotateOnError) {
        this.rotateKey(providerName, 'rate_limit_429');
      }
    }

    // Persist periodically (every 100 requests)
    if (provider.usage.totalRequests % 100 === 0) {
      this.persist();
    }
  }

  /**
   * Rotate to the next available key for a provider
   */
  rotateKey(providerName: string, reason: string = 'manual'): RotateKeyResponse {
    const provider = this.findProvider(providerName);
    if (!provider) {
      return { success: false, provider: providerName, previousKeyIndex: -1, newKeyIndex: -1, newKeyLabel: '' };
    }
    if (provider.keys.length <= 1) {
      return { success: false, provider: providerName, previousKeyIndex: provider.activeKeyIndex, newKeyIndex: provider.activeKeyIndex, newKeyLabel: provider.keys[0]?.label || '' };
    }

    const previousIndex = provider.activeKeyIndex;

    // Find next valid key
    let nextIndex = (previousIndex + 1) % provider.keys.length;
    let attempts = 0;
    while (!provider.keys[nextIndex].valid && attempts < provider.keys.length) {
      nextIndex = (nextIndex + 1) % provider.keys.length;
      attempts++;
    }

    provider.activeKeyIndex = nextIndex;
    this.persist();

    this.audit.log('key_rotated', providerName, {
      from: previousIndex,
      to: nextIndex,
      fromLabel: provider.keys[previousIndex]?.label,
      toLabel: provider.keys[nextIndex]?.label,
      reason
    }, reason === 'manual' ? 'cli' : 'auto');

    return {
      success: true,
      provider: providerName,
      previousKeyIndex: previousIndex,
      newKeyIndex: nextIndex,
      newKeyLabel: provider.keys[nextIndex]?.label || `key-${nextIndex}`
    };
  }

  /**
   * Add a new key to a provider's pool
   */
  addKey(providerName: string, keyValue: string, label?: string): boolean {
    const provider = this.findProvider(providerName);
    if (!provider) return false;

    const newKey: ProviderKey = {
      value: keyValue,
      label: label || `key-${provider.keys.length + 1}`,
      valid: true,
      lastUsed: null,
      requestCount: 0,
      errorCount: 0,
      addedAt: new Date().toISOString()
    };

    provider.keys.push(newKey);
    this.persist();

    this.audit.log('key_added', providerName, {
      label: newKey.label,
      keyPreview: VaultManager.maskKey(keyValue),
      totalKeys: provider.keys.length
    }, 'cli');

    return true;
  }

  /**
   * Remove a key from a provider's pool
   */
  removeKey(providerName: string, keyIndex: number): boolean {
    const provider = this.findProvider(providerName);
    if (!provider || keyIndex < 0 || keyIndex >= provider.keys.length) return false;
    if (provider.keys.length <= 1) return false; // Can't remove the last key

    const removed = provider.keys.splice(keyIndex, 1)[0];

    // Adjust active index if needed
    if (provider.activeKeyIndex >= provider.keys.length) {
      provider.activeKeyIndex = 0;
    }

    this.persist();

    this.audit.log('key_removed', providerName, {
      label: removed.label,
      remainingKeys: provider.keys.length
    }, 'cli');

    return true;
  }

  /**
   * Swap the active provider for a given type
   */
  swapProvider(type: ProviderType, fromName: string, toName: string): boolean {
    const from = this.findProvider(fromName);
    const to = this.findProvider(toName);

    if (!from || !to) return false;
    if (from.type !== type || to.type !== type) return false;

    from.enabled = false;
    to.enabled = true;
    this.persist();

    this.audit.log('provider_swapped', fromName, {
      type,
      from: fromName,
      to: toName
    }, 'cli');

    return true;
  }

  /**
   * Add a new provider
   */
  addProvider(config: Partial<ProviderConfig>): ProviderConfig {
    const provider = this.createProvider(config);
    this.providers.push(provider);
    this.persist();

    this.audit.log('provider_added', provider.name, {
      type: provider.type,
      displayName: provider.displayName
    }, 'cli');

    return provider;
  }

  /**
   * Remove a provider
   */
  removeProvider(name: string): boolean {
    const index = this.providers.findIndex(p => p.name === name);
    if (index === -1) return false;

    this.providers.splice(index, 1);
    this.persist();

    this.audit.log('provider_removed', name, {}, 'cli');
    return true;
  }

  /**
   * Enable or disable a provider
   */
  toggleProvider(name: string, enabled: boolean): boolean {
    const provider = this.findProvider(name);
    if (!provider) return false;

    provider.enabled = enabled;
    this.persist();

    this.audit.log(enabled ? 'provider_enabled' : 'provider_disabled', name, {}, 'cli');
    return true;
  }

  /**
   * Change the current tier
   */
  setTier(tier: TierLevel): void {
    const oldTier = this.currentTier;
    this.currentTier = tier;

    this.audit.log('tier_changed', 'system', {
      from: oldTier,
      to: tier
    }, 'cli');
  }

  // ═══════════════════════════════════════
  // Fallback Chain
  // ═══════════════════════════════════════

  /**
   * Resolve the provider to use, following fallback chain if primary is down
   */
  resolveProvider(type: ProviderType): ProviderConfig | null {
    const candidates = this.providers.filter(p =>
      p.type === type && p.enabled && this.isAvailableForTier(p.name)
    );

    // Try primary (first enabled of this type)
    for (const candidate of candidates) {
      if (candidate.health.status !== 'down' && candidate.keys.length > 0) {
        return candidate;
      }
    }

    // Try fallback chain
    for (const candidate of candidates) {
      if (candidate.fallback) {
        const fallback = this.findProvider(candidate.fallback);
        if (fallback && fallback.enabled && fallback.health.status !== 'down') {
          this.audit.log('fallback_triggered', candidate.name, {
            fallbackTo: fallback.name,
            reason: 'primary_down'
          });
          return fallback;
        }
      }
    }

    return null;
  }

  // ═══════════════════════════════════════
  // Tier Enforcement
  // ═══════════════════════════════════════

  /**
   * Check if a provider is available for the current tier
   */
  isAvailableForTier(providerName: string): boolean {
    const provider = this.findProvider(providerName);
    if (!provider) return false;

    const requiredIndex = TIER_ORDER.indexOf(provider.tierRequired);
    const currentIndex = TIER_ORDER.indexOf(this.currentTier);
    return currentIndex >= requiredIndex;
  }

  /**
   * Get all providers unavailable due to tier
   */
  getUnavailableForTier(): ProviderConfig[] {
    return this.providers.filter(p => !this.isAvailableForTier(p.name));
  }

  // ═══════════════════════════════════════
  // Auto-Fallback on Unhealthy
  // ═══════════════════════════════════════

  private onProviderUnhealthy(provider: ProviderConfig): void {
    if (this.health.shouldFallback(provider) && provider.fallback) {
      const fallback = this.findProvider(provider.fallback);
      if (fallback && fallback.enabled) {
        this.audit.log('fallback_triggered', provider.name, {
          fallbackTo: fallback.name,
          reason: 'health_check_failed',
          consecutiveFailures: provider.health.consecutiveFailures
        });
      }
    }
  }

  // ═══════════════════════════════════════
  // Gateway RPC Handlers
  // ═══════════════════════════════════════

  handleProviderList(): ProviderListResponse {
    const summaries: ProviderSummary[] = this.providers.map(p => ({
      name: p.name,
      displayName: p.displayName,
      type: p.type,
      enabled: p.enabled,
      healthy: p.health.status === 'healthy',
      keysCount: p.keys.length,
      activeKeyIndex: p.activeKeyIndex,
      activeKeyLabel: p.keys[p.activeKeyIndex]?.label || 'none',
      fallback: p.fallback || null,
      tierRequired: p.tierRequired,
      availableForTier: this.isAvailableForTier(p.name),
      usage: p.usage
    }));

    return {
      providers: summaries,
      currentTier: this.currentTier,
      totalProviders: this.providers.length,
      healthyProviders: this.providers.filter(p => p.health.status === 'healthy').length
    };
  }

  handleProviderDetail(params: { name: string }): ProviderConfig | null {
    return this.findProvider(params.name) || null;
  }

  handleProviderAdd(params: any): { success: boolean; provider: string } {
    const provider = this.addProvider(params);
    return { success: true, provider: provider.name };
  }

  handleProviderRemove(params: { name: string }): { success: boolean } {
    return { success: this.removeProvider(params.name) };
  }

  handleProviderToggle(params: { name: string; enabled: boolean }): { success: boolean } {
    return { success: this.toggleProvider(params.name, params.enabled) };
  }

  handleKeyRotate(params: { provider: string; reason?: string; targetKeyIndex?: number }): RotateKeyResponse {
    return this.rotateKey(params.provider, params.reason || 'rpc_request');
  }

  handleKeyAdd(params: { provider: string; key: string; label?: string }): { success: boolean } {
    return { success: this.addKey(params.provider, params.key, params.label) };
  }

  handleKeyRemove(params: { provider: string; keyIndex: number }): { success: boolean } {
    return { success: this.removeKey(params.provider, params.keyIndex) };
  }

  handleProviderSwap(params: { type: ProviderType; currentProvider: string; newProvider: string }): { success: boolean } {
    return { success: this.swapProvider(params.type, params.currentProvider, params.newProvider) };
  }

  handleHealthSummary(): Record<string, any> {
    return this.health.getHealthSummary(this.providers);
  }

  handleAuditList(params: { count?: number; action?: string; provider?: string }): any {
    return {
      events: this.audit.getRecent(
        params.count || 50,
        params.action as AuditAction | undefined,
        params.provider
      )
    };
  }

  // ═══════════════════════════════════════
  // HTTP API Registration
  // ═══════════════════════════════════════

  getApiRoutes() {
    return createApiRoutes(this);
  }

  // ═══════════════════════════════════════
  // Utilities
  // ═══════════════════════════════════════

  private findProvider(name: string): ProviderConfig | undefined {
    return this.providers.find(p => p.name === name);
  }

  /**
   * Cleanup: stop health checks, persist state
   */
  shutdown(): void {
    this.health.stopPeriodicChecks();
    this.persist();
    this.audit.rotateIfNeeded();
  }
}
