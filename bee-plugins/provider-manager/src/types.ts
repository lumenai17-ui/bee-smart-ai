/**
 * BEE Smart AI — Provider Manager Types
 * Shared type definitions for the provider management system.
 */

// ═══════════════════════════════════════
// Provider Types
// ═══════════════════════════════════════

export type ProviderType = 'llm' | 'voice' | 'image' | 'video' | 'search';
export type TierLevel = 'basic' | 'pro' | 'max';
export const TIER_ORDER: TierLevel[] = ['basic', 'pro', 'max'];

export interface ProviderConfig {
    /** Unique provider identifier (e.g., "deepgram", "stable-diffusion") */
    name: string;
    /** Provider category */
    type: ProviderType;
    /** Display name for UI/CLI */
    displayName: string;
    /** Base URL for the provider API */
    baseUrl: string;
    /** API type compatibility */
    apiType: string;
    /** Pool of API keys for rotation */
    keys: ProviderKey[];
    /** Index of the currently active key */
    activeKeyIndex: number;
    /** Name of the fallback provider */
    fallback?: string;
    /** Auto-rotate key on rate-limit errors */
    rotateOnError: boolean;
    /** Whether this provider is enabled */
    enabled: boolean;
    /** Minimum tier required to use this provider */
    tierRequired: TierLevel;
    /** Provider health status */
    health: ProviderHealth;
    /** Usage statistics */
    usage: ProviderUsage;
}

export interface ProviderKey {
    /** The actual API key value (stored encrypted in vault) */
    value: string;
    /** Human-readable label (e.g., "production-1", "backup") */
    label: string;
    /** Whether this key is currently valid */
    valid: boolean;
    /** When this key was last used */
    lastUsed: string | null;
    /** Number of requests made with this key */
    requestCount: number;
    /** Number of errors encountered */
    errorCount: number;
    /** When this key was added */
    addedAt: string;
}

export interface ProviderHealth {
    /** Current status */
    status: 'healthy' | 'degraded' | 'down' | 'unknown';
    /** Last health check timestamp */
    lastCheck: string | null;
    /** Consecutive failures */
    consecutiveFailures: number;
    /** Average response time in ms */
    avgResponseTimeMs: number;
}

export interface ProviderUsage {
    /** Total requests made */
    totalRequests: number;
    /** Total errors */
    totalErrors: number;
    /** Requests today */
    requestsToday: number;
    /** Estimated cost this month (USD) */
    estimatedCostUsd: number;
    /** Last reset date */
    lastResetDate: string;
}

// ═══════════════════════════════════════
// Event Types
// ═══════════════════════════════════════

export type AuditAction =
    | 'key_rotated'
    | 'key_added'
    | 'key_removed'
    | 'provider_enabled'
    | 'provider_disabled'
    | 'provider_swapped'
    | 'provider_added'
    | 'provider_removed'
    | 'fallback_triggered'
    | 'health_check'
    | 'tier_changed';

export interface AuditEvent {
    id: string;
    action: AuditAction;
    provider: string;
    details: Record<string, any>;
    timestamp: string;
    source: 'auto' | 'cli' | 'rpc' | 'api';
}

// ═══════════════════════════════════════
// Vault Types
// ═══════════════════════════════════════

export interface VaultData {
    version: string;
    encryptedAt: string;
    providers: ProviderConfig[];
}

// ═══════════════════════════════════════
// API Types
// ═══════════════════════════════════════

export interface ProviderListResponse {
    providers: ProviderSummary[];
    currentTier: TierLevel;
    totalProviders: number;
    healthyProviders: number;
}

export interface ProviderSummary {
    name: string;
    displayName: string;
    type: ProviderType;
    enabled: boolean;
    healthy: boolean;
    keysCount: number;
    activeKeyIndex: number;
    activeKeyLabel: string;
    fallback: string | null;
    tierRequired: TierLevel;
    availableForTier: boolean;
    usage: ProviderUsage;
}

export interface RotateKeyRequest {
    provider: string;
    reason?: string;
    targetKeyIndex?: number;
}

export interface RotateKeyResponse {
    success: boolean;
    provider: string;
    previousKeyIndex: number;
    newKeyIndex: number;
    newKeyLabel: string;
}

export interface SwapProviderRequest {
    type: ProviderType;
    currentProvider: string;
    newProvider: string;
}

export interface AddKeyRequest {
    provider: string;
    key: string;
    label?: string;
}

export interface AddProviderRequest {
    name: string;
    displayName: string;
    type: ProviderType;
    baseUrl: string;
    apiType: string;
    keys: { value: string; label: string }[];
    fallback?: string;
    tierRequired: TierLevel;
}
