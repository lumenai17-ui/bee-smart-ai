/**
 * BEE Smart AI — Tier Enforcement Middleware
 * Gates features, providers, automations, and channels by pricing tier.
 * Reads from bee-overlay/tiers/tier-config.json.
 */

import * as fs from 'fs';
import * as path from 'path';

export type TierLevel = 'basic' | 'pro' | 'max';

interface TierDefinition {
    name: string;
    price: number;
    currency: string;
    skills: { mode: string; total: number };
    llm: { provider: string; tier: string };
    multimedia: { enabled: boolean; providers?: string[] };
    google_apis: { enabled: boolean; scopes?: string[] };
    automations: { max: number };
    infrastructure: string;
    support: string;
    rateLimits: string;
}

interface TierConfig {
    tiers: Record<TierLevel, TierDefinition>;
    costEstimates: Record<TierLevel, { monthly: number; breakdown: Record<string, number> }>;
}

export class TierEnforcer {
    private config: TierConfig;
    private currentTier: TierLevel;

    constructor(rootDir: string, tier?: TierLevel) {
        this.config = this.loadConfig(rootDir);
        this.currentTier = tier || 'basic';
    }

    private loadConfig(rootDir: string): TierConfig {
        const configPath = path.join(rootDir, 'bee-overlay', 'tiers', 'tier-config.json');
        try {
            return JSON.parse(fs.readFileSync(configPath, 'utf-8'));
        } catch {
            return { tiers: {} as any, costEstimates: {} as any };
        }
    }

    // ═══════════════════════════════════════
    // Feature Gates
    // ═══════════════════════════════════════

    /** Check if multimedia features are available */
    isMultimediaEnabled(): boolean {
        return this.getTierDef()?.multimedia?.enabled || false;
    }

    /** Check if Google APIs are available */
    isGoogleEnabled(): boolean {
        return this.getTierDef()?.google_apis?.enabled || false;
    }

    /** Get allowed Google scopes */
    getGoogleScopes(): string[] {
        return this.getTierDef()?.google_apis?.scopes || [];
    }

    /** Get allowed multimedia providers */
    getMultimediaProviders(): string[] {
        return this.getTierDef()?.multimedia?.providers || [];
    }

    /** Get max automations for current tier */
    getMaxAutomations(): number {
        return this.getTierDef()?.automations?.max || 3;
    }

    /** Check if a specific provider is gated by tier */
    isProviderAllowed(providerTier: TierLevel): boolean {
        const order: TierLevel[] = ['basic', 'pro', 'max'];
        return order.indexOf(this.currentTier) >= order.indexOf(providerTier);
    }

    // ═══════════════════════════════════════
    // Middleware
    // ═══════════════════════════════════════

    /** Gate a skill execution by checking its provider requirements */
    canExecuteSkill(skillCategory: string, requiredProviders: string[]): { allowed: boolean; reason?: string } {
        // Multimedia skills require Pro+
        if (['multimedia'].includes(skillCategory) && !this.isMultimediaEnabled()) {
            return { allowed: false, reason: `Multimedia skills require plan Pro ($40/mes) or Max ($100/mes). Current plan: ${this.currentTier}.` };
        }

        // Google skills require Pro+
        if (requiredProviders.some(p => p.startsWith('google')) && !this.isGoogleEnabled()) {
            return { allowed: false, reason: `Google APIs require plan Pro ($40/mes) or Max ($100/mes). Current plan: ${this.currentTier}.` };
        }

        return { allowed: true };
    }

    /** Gate an automation by checking max count */
    canAddAutomation(currentActive: number): { allowed: boolean; reason?: string } {
        const max = this.getMaxAutomations();
        if (currentActive >= max) {
            return { allowed: false, reason: `Plan ${this.currentTier} allows max ${max} automations. Upgrade to enable more.` };
        }
        return { allowed: true };
    }

    /** Get rate limit config based on tier */
    getRateLimitConfig(): { maxPerMinute: number; maxPerHour: number } {
        const limits: Record<string, { maxPerMinute: number; maxPerHour: number }> = {
            'moderate': { maxPerMinute: 20, maxPerHour: 300 },
            'generous': { maxPerMinute: 50, maxPerHour: 1000 },
            'unlimited': { maxPerMinute: 999, maxPerHour: 99999 }
        };
        const level = this.getTierDef()?.rateLimits || 'moderate';
        return limits[level] || limits['moderate'];
    }

    // ═══════════════════════════════════════
    // Tier Info
    // ═══════════════════════════════════════

    /** Get current tier */
    getCurrentTier(): TierLevel { return this.currentTier; }

    /** Set current tier */
    setTier(tier: TierLevel): void { this.currentTier = tier; }

    /** Get tier details for display */
    getTierDetails(): TierDefinition | undefined {
        return this.getTierDef();
    }

    /** Get upgrade suggestions */
    getUpgradeSuggestion(feature: string): string {
        const prices: Record<TierLevel, number> = { basic: 25, pro: 40, max: 100 };
        const next = this.currentTier === 'basic' ? 'pro' : 'max';
        return `Para ${feature}, necesitas el plan ${next.toUpperCase()} ($${prices[next]}/mes). Contacta a tu administrador para upgrade.`;
    }

    /** Get cost estimate for current tier */
    getCostEstimate(): { monthly: number; breakdown: Record<string, number> } {
        return this.config.costEstimates?.[this.currentTier] || { monthly: 0, breakdown: {} };
    }

    /** Compare tiers for display */
    getTierComparison(): { tier: TierLevel; price: number; multimedia: boolean; google: boolean; maxAuto: number; infra: string }[] {
        return (['basic', 'pro', 'max'] as TierLevel[]).map(t => {
            const def = this.config.tiers[t];
            return {
                tier: t,
                price: def?.price || 0,
                multimedia: def?.multimedia?.enabled || false,
                google: def?.google_apis?.enabled || false,
                maxAuto: def?.automations?.max || 3,
                infra: def?.infrastructure || 'shared'
            };
        });
    }

    private getTierDef(): TierDefinition | undefined {
        return this.config.tiers[this.currentTier];
    }
}
