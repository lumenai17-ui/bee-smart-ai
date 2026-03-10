/**
 * BEE Smart AI — Provider Health Checker
 * Periodically pings providers and tracks health status.
 * Automatically triggers fallback when a provider goes down.
 */

import { ProviderConfig, ProviderHealth } from './types';

const HEALTH_CHECK_TIMEOUT_MS = 5000;
const MAX_CONSECUTIVE_FAILURES = 3;

export class HealthChecker {
    private checkInterval: ReturnType<typeof setInterval> | null = null;

    /**
     * Start periodic health checks
     */
    startPeriodicChecks(
        providers: ProviderConfig[],
        intervalMs: number = 60000,
        onUnhealthy?: (provider: ProviderConfig) => void
    ): void {
        this.stopPeriodicChecks();

        this.checkInterval = setInterval(async () => {
            for (const provider of providers) {
                if (!provider.enabled) continue;

                const healthy = await this.checkProvider(provider);
                if (!healthy && onUnhealthy) {
                    onUnhealthy(provider);
                }
            }
        }, intervalMs);
    }

    /**
     * Stop periodic health checks
     */
    stopPeriodicChecks(): void {
        if (this.checkInterval) {
            clearInterval(this.checkInterval);
            this.checkInterval = null;
        }
    }

    /**
     * Check a single provider's health
     */
    async checkProvider(provider: ProviderConfig): Promise<boolean> {
        const startTime = Date.now();

        try {
            // Simple connectivity test — HEAD request to base URL
            const controller = new AbortController();
            const timeout = setTimeout(() => controller.abort(), HEALTH_CHECK_TIMEOUT_MS);

            const response = await fetch(provider.baseUrl, {
                method: 'HEAD',
                signal: controller.signal
            }).catch(() => null);

            clearTimeout(timeout);

            const elapsed = Date.now() - startTime;

            if (response && response.ok) {
                this.updateHealth(provider, 'healthy', elapsed);
                return true;
            } else if (response) {
                // Got a response but not OK — degraded (might be auth-related, which is expected)
                const status = response.status;
                if (status === 401 || status === 403) {
                    // Auth error is normal for a health check — consider it healthy
                    this.updateHealth(provider, 'healthy', elapsed);
                    return true;
                }
                this.updateHealth(provider, 'degraded', elapsed);
                return false;
            } else {
                this.updateHealth(provider, 'down', elapsed);
                return false;
            }
        } catch {
            const elapsed = Date.now() - startTime;
            this.updateHealth(provider, 'down', elapsed);
            return false;
        }
    }

    /**
     * Update provider health status
     */
    private updateHealth(provider: ProviderConfig, status: ProviderHealth['status'], responseTimeMs: number): void {
        const prev = provider.health;

        if (status === 'healthy' || status === 'degraded') {
            provider.health = {
                status,
                lastCheck: new Date().toISOString(),
                consecutiveFailures: 0,
                avgResponseTimeMs: prev.avgResponseTimeMs
                    ? Math.round((prev.avgResponseTimeMs * 0.7) + (responseTimeMs * 0.3))
                    : responseTimeMs
            };
        } else {
            provider.health = {
                status,
                lastCheck: new Date().toISOString(),
                consecutiveFailures: (prev.consecutiveFailures || 0) + 1,
                avgResponseTimeMs: prev.avgResponseTimeMs || 0
            };
        }
    }

    /**
     * Check if a provider should trigger fallback
     */
    shouldFallback(provider: ProviderConfig): boolean {
        return provider.health.consecutiveFailures >= MAX_CONSECUTIVE_FAILURES;
    }

    /**
     * Get a health summary for all providers
     */
    getHealthSummary(providers: ProviderConfig[]): Record<string, any> {
        const summary: Record<string, any> = {};

        for (const p of providers) {
            summary[p.name] = {
                status: p.health.status,
                consecutiveFailures: p.health.consecutiveFailures,
                avgResponseTimeMs: p.health.avgResponseTimeMs,
                lastCheck: p.health.lastCheck
            };
        }

        return summary;
    }
}
