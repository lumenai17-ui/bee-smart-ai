/**
 * BEE Smart AI — System Prompt Builder
 * Assembles the full system prompt from all sources:
 * - Base system-prompt.md template
 * - Branding tone instructions
 * - Active skills manifest
 * - Active automations list
 * - Tier capabilities
 * - Contact context (injected per-request)
 */

import * as fs from 'fs';
import * as path from 'path';
import { BrandingEngine } from './branding';
import { TierEnforcer } from './tier-enforcer';

export class PromptBuilder {
    private rootDir: string;
    private branding: BrandingEngine;
    private tierEnforcer: TierEnforcer;

    constructor(rootDir: string, branding: BrandingEngine, tierEnforcer: TierEnforcer) {
        this.rootDir = rootDir;
        this.branding = branding;
        this.tierEnforcer = tierEnforcer;
    }

    /**
     * Build the full system prompt (static part, loaded at boot).
     * The contact context is appended per-request by the Unified Context plugin.
     */
    buildSystemPrompt(): string {
        const sections: string[] = [];

        // 1. Base template
        sections.push(this.loadBaseTemplate());

        // 2. Tone instruction
        sections.push(`\n## Instrucciones de Tono\n\n${this.branding.getToneInstruction()}`);

        // 3. Skills manifest
        sections.push(this.buildSkillsManifest());

        // 4. Active automations
        sections.push(this.buildAutomationsSection());

        // 5. Tier capabilities
        sections.push(this.buildTierSection());

        // 6. Channel-specific rules
        sections.push(this.buildChannelRules());

        return sections.filter(s => s.trim()).join('\n\n');
    }

    // ═══════════════════════════════════════
    // Section Builders
    // ═══════════════════════════════════════

    private loadBaseTemplate(): string {
        const promptPath = path.join(this.rootDir, 'config', 'system-prompt.md');
        try {
            return fs.readFileSync(promptPath, 'utf-8');
        } catch {
            return '# Agente BEE Smart AI\n\nSoy un asistente digital inteligente.';
        }
    }

    private buildSkillsManifest(): string {
        const skillsDir = path.join(this.rootDir, 'bee-skills');
        if (!fs.existsSync(skillsDir)) return '';

        const lines: string[] = ['## Habilidades Disponibles', ''];
        let totalSkills = 0;

        try {
            const categories = fs.readdirSync(skillsDir).filter(f =>
                fs.statSync(path.join(skillsDir, f)).isDirectory()
            );

            for (const category of categories) {
                const catDir = path.join(skillsDir, category);
                const skills = fs.readdirSync(catDir).filter(f =>
                    fs.statSync(path.join(catDir, f)).isDirectory()
                );

                if (skills.length === 0) continue;

                const formattedCat = category.replace(/-/g, ' ').replace(/\b\w/g, l => l.toUpperCase());
                lines.push(`### ${formattedCat}`);

                for (const skill of skills) {
                    const skillMdPath = path.join(catDir, skill, 'SKILL.md');
                    if (fs.existsSync(skillMdPath)) {
                        const contents = fs.readFileSync(skillMdPath, 'utf-8');
                        // Extract description from frontmatter
                        const descMatch = contents.match(/description:\s*(.+)/);
                        const desc = descMatch ? descMatch[1].trim() : skill;
                        lines.push(`- **${skill}**: ${desc}`);
                        totalSkills++;
                    }
                }
                lines.push('');
            }
        } catch { /* skip on error */ }

        if (totalSkills === 0) return '';

        lines.unshift(`_${totalSkills} habilidades cargadas._\n`);
        return lines.join('\n');
    }

    private buildAutomationsSection(): string {
        const autoDir = path.join(this.rootDir, 'bee-automations');
        if (!fs.existsSync(autoDir)) return '';

        const enabled: string[] = [];

        try {
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
                            const config = JSON.parse(fs.readFileSync(configPath, 'utf-8'));
                            if (config.enabled) {
                                enabled.push(`- **${config.name}** (${config.schedule?.expression || 'manual'}): ${config.description || entry}`);
                            }
                        } catch { /* skip invalid */ }
                    }
                }
            }
        } catch { /* skip */ }

        if (enabled.length === 0) return '';

        return `## Automatizaciones Activas\n\n${enabled.join('\n')}`;
    }

    private buildTierSection(): string {
        const tier = this.tierEnforcer.getCurrentTier();
        const details = this.tierEnforcer.getTierDetails();
        if (!details) return '';

        const lines = [
            `## Plan Actual: ${tier.toUpperCase()} ($${details.price}/mes)`,
            '',
            `- Multimedia: ${details.multimedia?.enabled ? '✅ Habilitado' : '❌ No disponible'}`,
            `- Google APIs: ${details.google_apis?.enabled ? '✅ Habilitado' : '❌ No disponible'}`,
            `- Automaciones máximas: ${details.automations?.max}`,
            `- Rate limit: ${details.rateLimits}`,
        ];

        if (tier !== 'max') {
            lines.push('');
            lines.push(`> Nota: Si el cliente solicita funciones no disponibles en tu plan, sugiere amablemente un upgrade.`);
        }

        return lines.join('\n');
    }

    private buildChannelRules(): string {
        return `## Reglas por Canal

- **WhatsApp**: Mensajes cortos (max ~1500 chars). Usa *negritas* para títulos. Listas con •.
- **Telegram**: Soporta Markdown completo. Puedes usar enlaces, negritas, itálicas.
- **Discord**: Usa Markdown. Puedes enviar embeds y formateo rico.
- **Email**: Formato largo permitido. Usa saludo formal y firma.
- **Dashboard**: Formato completo con Markdown.`;
    }
}
