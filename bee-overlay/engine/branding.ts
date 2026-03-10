/**
 * BEE Smart AI — Branding Engine
 * Applies client-specific branding to the Gateway UI and message templates.
 * Reads from bee-overlay/branding/theme.json.
 */

import * as fs from 'fs';
import * as path from 'path';

export interface BrandingTheme {
    product: { name: string; version: string };
    client: {
        businessName: string;
        colors: {
            primary: string;
            secondary: string;
            accent: string;
            background: string;
            text: string;
        };
        tone: string;
    };
    gateway_ui: {
        title: string;
        welcomeMessage: string;
        showBranding: boolean;
    };
}

export class BrandingEngine {
    private theme: BrandingTheme;
    private rootDir: string;

    constructor(rootDir: string) {
        this.rootDir = rootDir;
        this.theme = this.loadTheme();
    }

    private loadTheme(): BrandingTheme {
        const themePath = path.join(this.rootDir, 'bee-overlay', 'branding', 'theme.json');
        try {
            return JSON.parse(fs.readFileSync(themePath, 'utf-8'));
        } catch {
            return {
                product: { name: 'BEE Smart AI', version: '2.0.0' },
                client: {
                    businessName: 'Business',
                    colors: { primary: '#FFD700', secondary: '#1a1a2e', accent: '#00d4ff', background: '#0f0f23', text: '#ffffff' },
                    tone: 'Profesional'
                },
                gateway_ui: { title: 'BEE Smart AI', welcomeMessage: '🐝 Bienvenido', showBranding: true }
            };
        }
    }

    /** Get the CSS variables for gateway UI injection */
    getCssVariables(): string {
        const { colors } = this.theme.client;
        return `:root {
  --bee-primary: ${colors.primary};
  --bee-secondary: ${colors.secondary};
  --bee-accent: ${colors.accent};
  --bee-bg: ${colors.background};
  --bee-text: ${colors.text};
  --bee-font: 'Inter', 'Segoe UI', sans-serif;
}`;
    }

    /** Get gateway UI configuration for OpenClaw */
    getGatewayConfig(): Record<string, any> {
        return {
            title: this.theme.gateway_ui.title,
            welcomeMessage: this.theme.gateway_ui.welcomeMessage,
            showBranding: this.theme.gateway_ui.showBranding,
            customCss: this.getCssVariables(),
            logoUrl: `/assets/logo.svg`,
            faviconUrl: `/assets/favicon.ico`
        };
    }

    /** Format a message with branding (for channel responses) */
    brandMessage(text: string, channel: string): string {
        switch (channel) {
            case 'whatsapp':
            case 'telegram':
                // Add subtle footer on messaging channels
                return this.theme.gateway_ui.showBranding
                    ? `${text}\n\n_${this.theme.client.businessName} • Powered by BEE Smart AI_`
                    : text;
            case 'email':
                return `${text}\n\n---\n${this.theme.client.businessName}\nPowered by BEE Smart AI`;
            default:
                return text;
        }
    }

    /** Get the welcome message for a channel */
    getWelcomeMessage(channel: string, contactName?: string): string {
        const name = contactName ? `, ${contactName}` : '';
        const biz = this.theme.client.businessName;

        switch (channel) {
            case 'whatsapp':
                return `🐝 ¡Hola${name}! Bienvenido a *${biz}*. ¿En qué puedo ayudarte?`;
            case 'telegram':
                return `🐝 ¡Hola${name}! Soy el asistente de *${biz}*. ¿En qué te puedo apoyar?`;
            case 'discord':
                return `🐝 ¡Hola${name}! Soy el asistente de **${biz}**. ¿Cómo te ayudo?`;
            case 'email':
                return `Estimado${name},\n\nGracias por contactar a ${biz}. ¿En qué podemos asistirle?`;
            default:
                return this.theme.gateway_ui.welcomeMessage;
        }
    }

    /** Get tone instruction for the system prompt */
    getToneInstruction(): string {
        const toneMap: Record<string, string> = {
            'Formal': 'Usa un tono formal y respetuoso. Utiliza "usted" en lugar de "tú". Evita emojis excesivos.',
            'Amigable': 'Sé amigable y cercano. Usa "tú" y emojis moderados. Mantén un tono cálido.',
            'Profesional': 'Mantén un tono profesional pero accesible. Sé claro y directo. Usa emojis ocasionalmente.',
            'Casual': 'Sé casual y relajado. Usa lenguaje coloquial y emojis libremente.',
            'Entusiasta': 'Sé entusiasta y positivo. Usa emojis frecuentemente. Muestra emoción genuina.'
        };
        return toneMap[this.theme.client.tone] || toneMap['Profesional'];
    }

    /** Get the current theme */
    getTheme(): BrandingTheme {
        return this.theme;
    }

    /** Reload theme from disk */
    reload(): void {
        this.theme = this.loadTheme();
    }
}
