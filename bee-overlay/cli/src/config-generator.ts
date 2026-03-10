/**
 * BEE Smart AI — Config Generator
 * Takes onboarding wizard answers and produces all config files:
 * - config/.env
 * - config/openclaw.json
 * - config/system-prompt.md
 * - security/allowlist.json
 * - security/operator-roles.json
 * - bee-overlay/branding/theme.json
 */

import * as fs from 'fs';
import * as path from 'path';
import * as crypto from 'crypto';

export interface OnboardingAnswers {
    // Step 2: Identity
    businessName: string;
    businessType: string;
    businessAddress: string;
    businessHours: string;
    businessPhone: string;
    businessEmail: string;

    // Step 3: Branding
    colorPrimary: string;
    colorSecondary: string;
    colorAccent: string;
    tone: string;
    phrasesToUse: string;
    phrasesToAvoid: string;

    // Step 4: Channels
    whatsappEnabled: boolean;
    whatsappPhoneId: string;
    whatsappAccessToken: string;
    whatsappAllowlist: string[];
    telegramEnabled: boolean;
    telegramBotToken: string;
    discordEnabled: boolean;
    discordBotToken: string;
    emailEnabled: boolean;
    smtpHost: string;
    smtpUser: string;
    smtpPass: string;
    operatorContacts: { name: string; channel: string; role: string }[];

    // Step 5: Google
    googleEnabled: boolean;
    googleClientId: string;
    googleClientSecret: string;

    // Step 6: Integrations
    wordpressEnabled: boolean;
    wordpressUrl: string;
    wordpressAppPassword: string;
    metaAdsEnabled: boolean;
    metaAdsToken: string;
    stripeEnabled: boolean;
    stripeSecretKey: string;

    // Step 7: Automations
    automationsSelected: string[];

    // Step 8: Knowledge Base
    scrapeUrls: string[];
    specialInstructions: string;

    // Step 9: Billing
    fiscalName: string;
    taxId: string;
    currency: string;
    taxRate: number;

    // Tier
    tier: 'basic' | 'pro' | 'max';
}

export class ConfigGenerator {
    private rootDir: string;

    constructor(rootDir: string) {
        this.rootDir = rootDir;
    }

    /**
     * Generate all config files from onboarding answers
     */
    generateAll(answers: OnboardingAnswers): string[] {
        const generated: string[] = [];

        generated.push(this.generateEnv(answers));
        generated.push(this.generateSystemPrompt(answers));
        generated.push(this.generateAllowlist(answers));
        generated.push(this.generateOperatorRoles(answers));
        generated.push(this.generateTheme(answers));
        generated.push(this.updateOpenclawJson(answers));

        return generated;
    }

    // ── .env ──────────────────────────────

    private generateEnv(a: OnboardingAnswers): string {
        const filePath = path.join(this.rootDir, 'config', '.env');

        const lines: string[] = [
            '# ╔═══════════════════════════════════════╗',
            '# ║  BEE Smart AI — Environment Variables ║',
            `# ║  Generated: ${new Date().toISOString().split('T')[0].padEnd(25)}║`,
            '# ╚═══════════════════════════════════════╝',
            '',
            '# ── LLM Provider ──',
            'LLM_PROVIDER=ollama-cloud',
            'OLLAMA_API_KEY=',
            'OPENAI_API_KEY=',
            '',
            '# ── OpenClaw Gateway ──',
            `OPENCLAW_GATEWAY_TOKEN=${this.generateToken()}`,
            `OPENCLAW_ADMIN_PASSWORD=${this.generateToken(12)}`,
            '',
        ];

        if (a.whatsappEnabled) {
            lines.push('# ── WhatsApp ──');
            lines.push(`WHATSAPP_PHONE_ID=${a.whatsappPhoneId}`);
            lines.push(`WHATSAPP_ACCESS_TOKEN=${a.whatsappAccessToken}`);
            lines.push(`WHATSAPP_WEBHOOK_SECRET=${this.generateToken()}`);
            lines.push('');
        }

        if (a.telegramEnabled) {
            lines.push('# ── Telegram ──');
            lines.push(`TELEGRAM_BOT_TOKEN=${a.telegramBotToken}`);
            lines.push('');
        }

        if (a.discordEnabled) {
            lines.push('# ── Discord ──');
            lines.push(`DISCORD_BOT_TOKEN=${a.discordBotToken}`);
            lines.push('');
        }

        if (a.emailEnabled) {
            lines.push('# ── Email / SMTP ──');
            lines.push(`SMTP_HOST=${a.smtpHost}`);
            lines.push(`SMTP_USER=${a.smtpUser}`);
            lines.push(`SMTP_PASS=${a.smtpPass}`);
            lines.push('');
        }

        if (a.googleEnabled) {
            lines.push('# ── Google APIs ──');
            lines.push(`GOOGLE_CLIENT_ID=${a.googleClientId}`);
            lines.push(`GOOGLE_CLIENT_SECRET=${a.googleClientSecret}`);
            lines.push('GOOGLE_REFRESH_TOKEN=');
            lines.push('');
        }

        if (a.wordpressEnabled) {
            lines.push('# ── WordPress ──');
            lines.push(`WORDPRESS_URL=${a.wordpressUrl}`);
            lines.push(`WORDPRESS_APP_PASSWORD=${a.wordpressAppPassword}`);
            lines.push('');
        }

        if (a.metaAdsEnabled) {
            lines.push('# ── Meta Ads ──');
            lines.push(`META_ADS_ACCESS_TOKEN=${a.metaAdsToken}`);
            lines.push('');
        }

        if (a.stripeEnabled) {
            lines.push('# ── Stripe ──');
            lines.push(`STRIPE_SECRET_KEY=${a.stripeSecretKey}`);
            lines.push('');
        }

        lines.push('# ── Multimedia (Pro/Max) ──');
        lines.push('DEEPGRAM_API_KEY=');
        lines.push('STABLE_DIFFUSION_API_KEY=');
        lines.push('FAL_API_KEY=');
        lines.push('BRAVE_SEARCH_API_KEY=');

        this.writeFile(filePath, lines.join('\n'));
        try { fs.chmodSync(filePath, 0o600); } catch { /* Windows */ }
        return filePath;
    }

    // ── system-prompt.md ──────────────────

    private generateSystemPrompt(a: OnboardingAnswers): string {
        const filePath = path.join(this.rootDir, 'config', 'system-prompt.md');

        const content = `# Identidad del Agente

Eres el asistente digital de **${a.businessName}**, un negocio de tipo **${a.businessType}**.

## Información del Negocio

- **Nombre**: ${a.businessName}
- **Tipo**: ${a.businessType}
- **Dirección**: ${a.businessAddress}
- **Horario**: ${a.businessHours}
- **Teléfono**: ${a.businessPhone}
- **Email**: ${a.businessEmail}

## Personalidad

- **Tono**: ${a.tone}
${a.phrasesToUse ? `- **Frases que DEBES usar**: ${a.phrasesToUse}` : ''}
${a.phrasesToAvoid ? `- **Frases que NUNCA debes usar**: ${a.phrasesToAvoid}` : ''}

## Capacidades

Tienes acceso a 58 habilidades organizadas en 10 categorías:
comunicación, multimedia, documentos, web, inteligencia, negocio, email marketing, código, productividad, y localización.

${a.automationsSelected.length > 0 ? `## Automatizaciones Activas\n\n${a.automationsSelected.map(id => `- ${id}`).join('\n')}` : ''}

${a.specialInstructions ? `## Instrucciones Especiales\n\n${a.specialInstructions}` : ''}

## Reglas Generales

1. Siempre responde en el idioma del cliente.
2. Sé conciso pero completo.
3. Si no tienes información, dilo honestamente y sugiere alternativas.
4. Mantén el tono ${a.tone.toLowerCase()} en todas las interacciones.
5. Protege la información sensible del negocio y los clientes.
`;

        this.writeFile(filePath, content);
        return filePath;
    }

    // ── allowlist.json ────────────────────

    private generateAllowlist(a: OnboardingAnswers): string {
        const filePath = path.join(this.rootDir, 'security', 'allowlist.json');

        const data: any = {
            mode: a.whatsappAllowlist.length > 0 ? 'allowlist' : 'open',
            whatsapp: {
                allowed_numbers: a.whatsappAllowlist,
                allow_unknown: a.whatsappAllowlist.length === 0,
                unknown_response: '¡Hola! Bienvenido. ¿En qué puedo ayudarte?'
            },
            telegram: {
                allowed_usernames: [],
                allowed_group_ids: [],
                allow_unknown: true
            },
            discord: {
                allowed_channel_ids: [],
                allowed_role_ids: [],
                allow_unknown: true
            },
            email: {
                allowed_domains: [],
                blocked_addresses: []
            }
        };

        this.writeFile(filePath, JSON.stringify(data, null, 2));
        return filePath;
    }

    // ── operator-roles.json ───────────────

    private generateOperatorRoles(a: OnboardingAnswers): string {
        const filePath = path.join(this.rootDir, 'security', 'operator-roles.json');

        const operators = a.operatorContacts.map(op => ({
            name: op.name,
            channel: op.channel,
            auth: 'password',
            role: op.role,
            permissions: op.role === 'admin'
                ? ['*']
                : op.role === 'manager'
                    ? ['view_all_chats', 'override_agent', 'manage_allowlist']
                    : ['view_all_chats', 'override_agent']
        }));

        const data = {
            operators,
            roles: {
                admin: { description: 'Acceso total', permissions: ['*'] },
                manager: { description: 'Gestión de chats y listas', permissions: ['view_all_chats', 'override_agent', 'manage_allowlist'] },
                operator: { description: 'Ver y responder chats', permissions: ['view_all_chats', 'override_agent'] },
                viewer: { description: 'Solo lectura', permissions: ['view_all_chats'] }
            }
        };

        this.writeFile(filePath, JSON.stringify(data, null, 2));
        return filePath;
    }

    // ── theme.json ────────────────────────

    private generateTheme(a: OnboardingAnswers): string {
        const filePath = path.join(this.rootDir, 'bee-overlay', 'branding', 'theme.json');

        const data = {
            product: { name: 'BEE Smart AI', version: '2.0.0' },
            client: {
                businessName: a.businessName,
                colors: {
                    primary: a.colorPrimary || '#FFD700',
                    secondary: a.colorSecondary || '#1a1a2e',
                    accent: a.colorAccent || '#00d4ff',
                    background: '#0f0f23',
                    text: '#ffffff'
                },
                tone: a.tone
            },
            gateway_ui: {
                title: `${a.businessName} — AI Assistant`,
                welcomeMessage: `🐝 Bienvenido al panel de ${a.businessName}`,
                showBranding: true
            }
        };

        this.writeFile(filePath, JSON.stringify(data, null, 2));
        return filePath;
    }

    // ── openclaw.json (update channels) ───

    private updateOpenclawJson(a: OnboardingAnswers): string {
        const filePath = path.join(this.rootDir, 'config', 'openclaw.json');

        try {
            const raw = fs.readFileSync(filePath, 'utf-8');
            const config = JSON.parse(raw);

            // Update channel enablement
            if (config.channels) {
                if (config.channels.whatsapp) config.channels.whatsapp.enabled = a.whatsappEnabled;
                if (config.channels.telegram) config.channels.telegram.enabled = a.telegramEnabled;
                if (config.channels.discord) config.channels.discord.enabled = a.discordEnabled;
                if (config.channels.email) config.channels.email.enabled = a.emailEnabled;
            }

            this.writeFile(filePath, JSON.stringify(config, null, 2));
        } catch {
            // If the file doesn't parse, skip
        }

        return filePath;
    }

    // ═══════════════════════════════════════
    // Helpers
    // ═══════════════════════════════════════

    private writeFile(filePath: string, content: string): void {
        const dir = path.dirname(filePath);
        if (!fs.existsSync(dir)) fs.mkdirSync(dir, { recursive: true });
        fs.writeFileSync(filePath, content, 'utf-8');
    }

    private generateToken(length: number = 32): string {
        return crypto.randomBytes(length).toString('base64url').slice(0, length);
    }
}
