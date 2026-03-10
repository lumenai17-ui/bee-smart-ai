/**
 * BEE Smart AI — Automation Scheduler
 * Manages cron-based automations: loads configs, enforces tier limits,
 * and provides the scheduling infrastructure.
 */

import * as fs from 'fs';
import * as path from 'path';
import { TierEnforcer } from './tier-enforcer';

interface AutomationConfig {
    id: string;
    name: string;
    description: string;
    category: string;
    version: string;
    enabled: boolean;
    schedule: { type: string; expression: string };
    skills_required: string[];
    providers_required: string[];
    tier_minimum: string;
    config: Record<string, any>;
}

interface ScheduledTask {
    automation: AutomationConfig;
    nextRun: Date;
    lastRun: Date | null;
    runCount: number;
    status: 'scheduled' | 'running' | 'paused' | 'error';
    lastError?: string;
}

export class AutomationScheduler {
    private rootDir: string;
    private tierEnforcer: TierEnforcer;
    private automations: AutomationConfig[] = [];
    private scheduledTasks: Map<string, ScheduledTask> = new Map();
    private timers: Map<string, ReturnType<typeof setInterval>> = new Map();

    constructor(rootDir: string, tierEnforcer: TierEnforcer) {
        this.rootDir = rootDir;
        this.tierEnforcer = tierEnforcer;
        this.loadAutomations();
    }

    // ═══════════════════════════════════════
    // Loading
    // ═══════════════════════════════════════

    /** Scan and load all automation configs from bee-automations/ */
    loadAutomations(): void {
        this.automations = [];
        const autoDir = path.join(this.rootDir, 'bee-automations');
        if (!fs.existsSync(autoDir)) return;

        const categories = fs.readdirSync(autoDir).filter(f =>
            fs.statSync(path.join(autoDir, f)).isDirectory()
        );

        for (const category of categories) {
            const catDir = path.join(autoDir, category);
            const entries = fs.readdirSync(catDir).filter(f =>
                fs.statSync(path.join(catDir, f)).isDirectory()
            );

            for (const entry of entries) {
                const configPath = path.join(catDir, entry, 'automation.json');
                if (fs.existsSync(configPath)) {
                    try {
                        const config: AutomationConfig = JSON.parse(fs.readFileSync(configPath, 'utf-8'));
                        this.automations.push(config);
                    } catch { /* skip invalid configs */ }
                }
            }
        }
    }

    // ═══════════════════════════════════════
    // Scheduling
    // ═══════════════════════════════════════

    /** Start all enabled automations that pass tier checks */
    startAll(): { started: string[]; skipped: string[]; blocked: string[] } {
        const started: string[] = [];
        const skipped: string[] = [];
        const blocked: string[] = [];

        const activeCount = this.automations.filter(a => a.enabled).length;
        const maxAllowed = this.tierEnforcer.getMaxAutomations();

        let activatedCount = 0;

        for (const auto of this.automations) {
            if (!auto.enabled) {
                skipped.push(`${auto.id} (${auto.name}) — disabled`);
                continue;
            }

            if (activatedCount >= maxAllowed) {
                blocked.push(`${auto.id} (${auto.name}) — tier limit (${maxAllowed} max)`);
                continue;
            }

            this.scheduleAutomation(auto);
            started.push(`${auto.id} (${auto.name})`);
            activatedCount++;
        }

        return { started, skipped, blocked };
    }

    /** Schedule a single automation */
    private scheduleAutomation(auto: AutomationConfig): void {
        const intervalMs = this.cronToMs(auto.schedule.expression);

        const task: ScheduledTask = {
            automation: auto,
            nextRun: new Date(Date.now() + intervalMs),
            lastRun: null,
            runCount: 0,
            status: 'scheduled'
        };

        this.scheduledTasks.set(auto.id, task);

        const timer = setInterval(() => {
            this.executeAutomation(auto.id);
        }, intervalMs);

        this.timers.set(auto.id, timer);
    }

    /** Execute an automation */
    private async executeAutomation(autoId: string): Promise<void> {
        const task = this.scheduledTasks.get(autoId);
        if (!task) return;

        task.status = 'running';
        task.lastRun = new Date();
        task.runCount++;

        try {
            // TODO: Execute the automation's skill chain
            // This would call the skills specified in skills_required
            task.status = 'scheduled';
            task.nextRun = new Date(Date.now() + this.cronToMs(task.automation.schedule.expression));
        } catch (err: any) {
            task.status = 'error';
            task.lastError = err.message;
        }
    }

    /** Stop all automations */
    stopAll(): void {
        for (const [id, timer] of this.timers) {
            clearInterval(timer);
        }
        this.timers.clear();
        this.scheduledTasks.clear();
    }

    // ═══════════════════════════════════════
    // Management
    // ═══════════════════════════════════════

    /** Enable an automation */
    enableAutomation(autoId: string): boolean {
        const auto = this.automations.find(a => a.id === autoId);
        if (!auto) return false;

        const activeCount = [...this.scheduledTasks.values()].filter(t => t.status !== 'paused').length;
        const check = this.tierEnforcer.canAddAutomation(activeCount);
        if (!check.allowed) return false;

        auto.enabled = true;
        this.saveAutomation(auto);
        this.scheduleAutomation(auto);
        return true;
    }

    /** Disable an automation */
    disableAutomation(autoId: string): boolean {
        const auto = this.automations.find(a => a.id === autoId);
        if (!auto) return false;

        auto.enabled = false;
        this.saveAutomation(auto);

        const timer = this.timers.get(autoId);
        if (timer) {
            clearInterval(timer);
            this.timers.delete(autoId);
        }
        this.scheduledTasks.delete(autoId);
        return true;
    }

    /** Get status of all automations */
    getStatus(): { id: string; name: string; enabled: boolean; status: string; lastRun: string | null; nextRun: string | null; runCount: number }[] {
        return this.automations.map(auto => {
            const task = this.scheduledTasks.get(auto.id);
            return {
                id: auto.id,
                name: auto.name,
                enabled: auto.enabled,
                status: task?.status || 'inactive',
                lastRun: task?.lastRun?.toISOString() || null,
                nextRun: task?.nextRun?.toISOString() || null,
                runCount: task?.runCount || 0
            };
        });
    }

    /** Get list of automation IDs */
    getAutomationIds(): string[] {
        return this.automations.map(a => a.id);
    }

    // ═══════════════════════════════════════
    // Helpers
    // ═══════════════════════════════════════

    /** Convert a cron expression to milliseconds (simplified) */
    private cronToMs(cron: string): number {
        // Simplified parser for common patterns
        const parts = cron.split(' ');
        if (parts.length < 5) return 3600000; // Default 1h

        const [min, hour, dayOfMonth, month, dayOfWeek] = parts;

        if (min === '*/5') return 5 * 60 * 1000;
        if (min === '*/15') return 15 * 60 * 1000;
        if (min === '*/30') return 30 * 60 * 1000;
        if (hour === '*') return 60 * 60 * 1000; // Every hour
        if (dayOfMonth === '*' && month === '*') return 24 * 60 * 60 * 1000; // Daily
        if (dayOfWeek !== '*') return 7 * 24 * 60 * 60 * 1000; // Weekly

        return 24 * 60 * 60 * 1000; // Default daily
    }

    /** Save an automation config back to disk */
    private saveAutomation(auto: AutomationConfig): void {
        const autoDir = path.join(this.rootDir, 'bee-automations');
        if (!fs.existsSync(autoDir)) return;

        // Find the config file
        const categories = fs.readdirSync(autoDir).filter(f =>
            fs.statSync(path.join(autoDir, f)).isDirectory()
        );

        for (const category of categories) {
            const catDir = path.join(autoDir, category);
            const entries = fs.readdirSync(catDir).filter(f =>
                fs.statSync(path.join(catDir, f)).isDirectory()
            );

            for (const entry of entries) {
                const configPath = path.join(catDir, entry, 'automation.json');
                if (fs.existsSync(configPath)) {
                    try {
                        const existing = JSON.parse(fs.readFileSync(configPath, 'utf-8'));
                        if (existing.id === auto.id) {
                            fs.writeFileSync(configPath, JSON.stringify(auto, null, 2), 'utf-8');
                            return;
                        }
                    } catch { /* skip */ }
                }
            }
        }
    }
}
