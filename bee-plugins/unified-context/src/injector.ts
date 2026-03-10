/**
 * BEE Smart AI — Context Injector
 * Middleware that builds the context block injected into every LLM prompt.
 * Ensures the agent always knows who it's talking to and their history.
 */

import { ContactDatabase } from './database';
import { ContextInjection, FullContactRecord, Message, ContactContext, ContactMetadata } from './types';

export class ContextInjector {
    private db: ContactDatabase;
    private maxRecentMessages: number;

    constructor(db: ContactDatabase, maxRecentMessages: number = 15) {
        this.db = db;
        this.maxRecentMessages = maxRecentMessages;
    }

    /**
     * Build the full context injection for a contact.
     * This string gets appended to the system prompt before every LLM call.
     */
    buildInjection(contactId: string): ContextInjection | null {
        const contact = this.db.findById(contactId);
        if (!contact) return null;

        const fields = this.db.getContextFields(contactId);
        if (!fields) return null;

        const messages = this.db.getMessages(contactId, this.maxRecentMessages);

        const contextBlock = this.formatContextBlock(contact, fields, messages);

        return {
            contextBlock,
            contactId,
            isHandoff: fields.handoffStatus !== 'agent',
            messagesUsed: messages.length
        };
    }

    /**
     * Format the context block as a markdown string for the LLM
     */
    private formatContextBlock(
        contact: any,
        fields: any,
        messages: Message[]
    ): string {
        const lines: string[] = [];

        // Header
        lines.push(`## 👤 Contexto del Contacto: ${contact.displayName}`);
        lines.push('');

        // Contact info
        if (contact.phone) lines.push(`- **Teléfono**: ${contact.phone}`);
        if (contact.email) lines.push(`- **Email**: ${contact.email}`);
        lines.push(`- **Canales usados**: ${contact.channelsUsed.join(', ')}`);
        lines.push(`- **Interacciones totales**: ${fields.satisfaction > 0 ? `${Math.round(fields.satisfaction * 10) / 10}` : 'N/A'}`);
        lines.push(`- **Primera vez**: ${this.formatDate(contact.firstSeen)}`);
        lines.push(`- **Última interacción**: ${this.formatDate(contact.lastInteraction)}`);

        // Tags
        if (fields.tags.length > 0) {
            lines.push(`- **Tags**: ${fields.tags.map((t: string) => `\`${t}\``).join(', ')}`);
        }

        // Topic and summary
        if (fields.topic) {
            lines.push('');
            lines.push(`### 📌 Tema actual: ${fields.topic}`);
        }

        if (fields.summary) {
            lines.push('');
            lines.push(`### 📝 Resumen`);
            lines.push(fields.summary);
        }

        // Handoff status
        if (fields.handoffStatus !== 'agent') {
            lines.push('');
            lines.push(`> ⚠️ **Modo**: ${fields.handoffStatus === 'operator' ? 'Operador humano atendiendo' : 'Modo híbrido (agente + operador)'}`);
            if (fields.handoffOperator) {
                lines.push(`> **Operador**: ${fields.handoffOperator}`);
            }
        }

        // Recent messages
        if (messages.length > 0) {
            lines.push('');
            lines.push('### 💬 Mensajes recientes');
            lines.push('');
            for (const msg of messages) {
                const icon = msg.role === 'customer' ? '👤' : msg.role === 'agent' ? '🤖' : '👨‍💼';
                const time = this.formatTime(msg.timestamp);
                lines.push(`${icon} **[${msg.role}/${msg.channel}]** (${time}): ${msg.text}`);
            }
        }

        // Intent history
        if (fields.intents.length > 0) {
            lines.push('');
            lines.push(`### 🎯 Historial de intenciones: ${fields.intents.slice(-5).join(' → ')}`);
        }

        return lines.join('\n');
    }

    /**
     * Build a compact context (for shorter context windows)
     */
    buildCompactInjection(contactId: string): string {
        const contact = this.db.findById(contactId);
        if (!contact) return '';

        const fields = this.db.getContextFields(contactId);
        if (!fields) return '';

        const messages = this.db.getMessages(contactId, 5);

        const lines = [
            `[Contact: ${contact.displayName}${contact.phone ? ` (${contact.phone})` : ''}]`,
            fields.topic ? `[Topic: ${fields.topic}]` : '',
            fields.summary ? `[Summary: ${fields.summary}]` : '',
            ...messages.map(m => `[${m.role}] ${m.text}`)
        ].filter(Boolean);

        return lines.join('\n');
    }

    // ═══════════════════════════════════════
    // Helpers
    // ═══════════════════════════════════════

    private formatDate(iso: string): string {
        try {
            return new Date(iso).toLocaleDateString('es-MX', {
                year: 'numeric', month: 'short', day: 'numeric'
            });
        } catch { return iso; }
    }

    private formatTime(iso: string): string {
        try {
            return new Date(iso).toLocaleTimeString('es-MX', {
                hour: '2-digit', minute: '2-digit'
            });
        } catch { return iso; }
    }
}
