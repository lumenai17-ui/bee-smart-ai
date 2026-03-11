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
            // 1. Load the AUTOMATION.md workflow from the automation's directory
            const workflowMd = this.loadAutomationWorkflow(task.automation);
            if (!workflowMd) {
                throw new Error(`No AUTOMATION.md found for ${autoId}`);
            }

            // 2. Compose structured prompt for the agent
            const prompt = this.composeAutomationPrompt(task.automation, workflowMd);

            // 3. Dispatch as an internal agent task
            const result = await this.dispatchAgentTask(task.automation, prompt);

            // 4. Log result
            this.logExecution(task.automation, result);

            task.status = 'scheduled';
            task.nextRun = new Date(Date.now() + this.cronToMs(task.automation.schedule.expression));
        } catch (err: any) {
            task.status = 'error';
            task.lastError = err.message;
            this.logExecution(task.automation, { success: false, error: err.message });
        }
    }

    /** Load the AUTOMATION.md workflow file for an automation */
    private loadAutomationWorkflow(auto: AutomationConfig): string | null {
        const autoDir = path.join(this.rootDir, 'bee-automations');
        if (!fs.existsSync(autoDir)) return null;

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
                const workflowPath = path.join(catDir, entry, 'AUTOMATION.md');
                if (fs.existsSync(configPath) && fs.existsSync(workflowPath)) {
                    try {
                        const config = JSON.parse(fs.readFileSync(configPath, 'utf-8'));
                        if (config.id === auto.id) {
                            return fs.readFileSync(workflowPath, 'utf-8');
                        }
                    } catch { /* skip */ }
                }
            }
        }

        return null;
    }

    /** Compose a structured prompt from automation config + workflow */
    private composeAutomationPrompt(auto: AutomationConfig, workflowMd: string): string {
        const skillsList = auto.skills_required.length > 0
            ? `Use the following skills: ${auto.skills_required.join(', ')}`
            : 'Use the appropriate skills from your available set';

        const configSection = Object.keys(auto.config).length > 0
            ? `\n## Configuration\n${JSON.stringify(auto.config, null, 2)}`
            : '';

        return [
            `# Automation Task: ${auto.name}`,
            ``,
            `You are executing the scheduled automation "${auto.name}" (${auto.id}).`,
            `${auto.description}`,
            ``,
            `## Skills to Use`,
            skillsList,
            configSection,
            ``,
            `## Workflow`,
            workflowMd,
            ``,
            `## Execution Rules`,
            `- Execute each step in order`,
            `- If a step fails, log the error and continue to the next step if possible`,
            `- Report the final status: which steps succeeded, which failed`,
            `- Do NOT ask for user confirmation — this is an automated task`,
        ].join('\n');
    }

    /** Dispatch the composed prompt as an internal agent task */
    private async dispatchAgentTask(
        auto: AutomationConfig,
        prompt: string
    ): Promise<{ success: boolean; output?: string; error?: string }> {
        // The agent task queue processes this prompt using the LLM + tools
        // In production, this sends to the OpenClaw agent's internal task queue
        const taskFile = path.join(this.rootDir, '.bee-tasks', `${auto.id}-${Date.now()}.md`);
        const taskDir = path.dirname(taskFile);

        if (!fs.existsSync(taskDir)) {
            fs.mkdirSync(taskDir, { recursive: true });
        }

        fs.writeFileSync(taskFile, prompt, 'utf-8');

        return { success: true, output: `Task queued: ${taskFile}` };
    }

    /** Log automation execution */
    private logExecution(
        auto: AutomationConfig,
        result: { success: boolean; output?: string; error?: string }
    ): void {
        const logDir = path.join(this.rootDir, '.bee-logs', 'automations');
        if (!fs.existsSync(logDir)) {
            fs.mkdirSync(logDir, { recursive: true });
        }

        const logEntry = {
            timestamp: new Date().toISOString(),
            automationId: auto.id,
            automationName: auto.name,
            success: result.success,
            output: result.output,
            error: result.error,
        };

        const logFile = path.join(logDir, `${auto.id}.log`);
        fs.appendFileSync(logFile, JSON.stringify(logEntry) + '\n', 'utf-8');
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
