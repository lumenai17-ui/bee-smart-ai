/**
 * BEE Smart AI — Audit Logger
 * Records all provider management events for security and debugging.
 * 
 * Events are written to logs/security.log as one JSON object per line (JSONL format).
 */

import * as fs from 'fs';
import * as path from 'path';
import { AuditEvent, AuditAction } from './types';
import { VaultManager } from './vault';

export class AuditLogger {
    private logPath: string;
    private maxEntries: number;

    constructor(logDir: string, maxEntries: number = 10000) {
        this.logPath = path.join(logDir, 'security.log');
        this.maxEntries = maxEntries;

        // Ensure log directory exists
        if (!fs.existsSync(logDir)) {
            fs.mkdirSync(logDir, { recursive: true });
        }
    }

    /**
     * Log an audit event
     */
    log(action: AuditAction, provider: string, details: Record<string, any>, source: AuditEvent['source'] = 'auto'): void {
        const event: AuditEvent = {
            id: this.generateId(),
            action,
            provider,
            details: this.sanitizeDetails(details),
            timestamp: new Date().toISOString(),
            source
        };

        const line = JSON.stringify(event) + '\n';

        try {
            fs.appendFileSync(this.logPath, line, 'utf-8');
        } catch (err: any) {
            console.error(`[AuditLogger] Failed to write: ${err.message}`);
        }
    }

    /**
     * Read recent audit events
     */
    getRecent(count: number = 50, filterAction?: AuditAction, filterProvider?: string): AuditEvent[] {
        if (!fs.existsSync(this.logPath)) return [];

        try {
            const content = fs.readFileSync(this.logPath, 'utf-8');
            const lines = content.trim().split('\n').filter(Boolean);

            let events: AuditEvent[] = lines.map(line => {
                try { return JSON.parse(line); }
                catch { return null; }
            }).filter(Boolean) as AuditEvent[];

            if (filterAction) {
                events = events.filter(e => e.action === filterAction);
            }
            if (filterProvider) {
                events = events.filter(e => e.provider === filterProvider);
            }

            // Return most recent first
            return events.slice(-count).reverse();
        } catch {
            return [];
        }
    }

    /**
     * Rotate log file if it exceeds max entries
     */
    rotateIfNeeded(): void {
        if (!fs.existsSync(this.logPath)) return;

        try {
            const content = fs.readFileSync(this.logPath, 'utf-8');
            const lines = content.trim().split('\n');

            if (lines.length > this.maxEntries) {
                // Keep the last half
                const kept = lines.slice(-Math.floor(this.maxEntries / 2));
                fs.writeFileSync(this.logPath, kept.join('\n') + '\n', 'utf-8');

                this.log('health_check', 'system', {
                    message: 'Audit log rotated',
                    removedEntries: lines.length - kept.length
                });
            }
        } catch {
            // Silently skip rotation errors
        }
    }

    // ═══════════════════════════════════════
    // Helpers
    // ═══════════════════════════════════════

    private generateId(): string {
        const ts = Date.now().toString(36);
        const rand = Math.random().toString(36).slice(2, 8);
        return `evt_${ts}_${rand}`;
    }

    /**
     * Remove sensitive data (API keys) before logging
     */
    private sanitizeDetails(details: Record<string, any>): Record<string, any> {
        const sanitized = { ...details };

        for (const key of Object.keys(sanitized)) {
            if (/key|token|secret|password/i.test(key) && typeof sanitized[key] === 'string') {
                sanitized[key] = VaultManager.maskKey(sanitized[key]);
            }
        }

        return sanitized;
    }
}
