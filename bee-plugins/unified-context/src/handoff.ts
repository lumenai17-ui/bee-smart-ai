/**
 * BEE Smart AI — Operator Handoff Manager
 * Manages transitions between AI agent and human operator.
 * Provides summaries, tracks handoff state, and supports hybrid mode.
 */

import { ContactDatabase } from './database';
import { HandoffStatus, Message } from './types';

export interface HandoffSummary {
    contactId: string;
    contactName: string;
    phone: string | null;
    channels: string[];
    currentTopic: string;
    contextSummary: string;
    satisfaction: number;
    tags: string[];
    recentMessages: { role: string; text: string; time: string }[];
    handoffReason: string;
}

export class HandoffManager {
    private db: ContactDatabase;

    constructor(db: ContactDatabase) {
        this.db = db;
    }

    /**
     * Start a handoff from agent to operator
     */
    startHandoff(contactId: string, operatorId: string, reason: string = 'manual'): HandoffSummary | null {
        const contact = this.db.findById(contactId);
        if (!contact) return null;

        const fields = this.db.getContextFields(contactId);
        if (!fields) return null;

        // Update handoff status
        this.db.updateContextFields(contactId, {
            handoffStatus: 'operator',
            handoffOperator: operatorId
        });

        // Record the handoff as a system message
        this.db.addMessage({
            contactId,
            role: 'agent',
            channel: 'system',
            text: `🔄 Conversación transferida al operador ${operatorId}. Motivo: ${reason}`,
            timestamp: new Date().toISOString(),
            metadata: { type: 'handoff', operatorId, reason }
        });

        // Generate summary for the operator
        return this.generateSummary(contactId, reason);
    }

    /**
     * End handoff — return control to agent
     */
    endHandoff(contactId: string, operatorId: string): boolean {
        const contact = this.db.findById(contactId);
        if (!contact) return false;

        this.db.updateContextFields(contactId, {
            handoffStatus: 'agent',
            handoffOperator: null
        });

        this.db.addMessage({
            contactId,
            role: 'operator',
            channel: 'system',
            text: `✅ ${operatorId} devolvió el control al agente.`,
            timestamp: new Date().toISOString(),
            metadata: { type: 'handoff_end', operatorId }
        });

        return true;
    }

    /**
     * Switch to hybrid mode (agent + operator both active)
     */
    setHybridMode(contactId: string, operatorId: string): boolean {
        const contact = this.db.findById(contactId);
        if (!contact) return false;

        this.db.updateContextFields(contactId, {
            handoffStatus: 'hybrid',
            handoffOperator: operatorId
        });

        return true;
    }

    /**
     * Get current handoff status for a contact
     */
    getHandoffStatus(contactId: string): { status: HandoffStatus; operator: string | null } | null {
        const fields = this.db.getContextFields(contactId);
        if (!fields) return null;

        return {
            status: fields.handoffStatus as HandoffStatus,
            operator: fields.handoffOperator
        };
    }

    /**
     * Generate a detailed handoff summary for the operator
     */
    generateSummary(contactId: string, reason: string = ''): HandoffSummary | null {
        const contact = this.db.findById(contactId);
        if (!contact) return null;

        const fields = this.db.getContextFields(contactId);
        if (!fields) return null;

        const messages = this.db.getMessages(contactId, 10);

        return {
            contactId,
            contactName: contact.displayName,
            phone: contact.phone,
            channels: contact.channelsUsed,
            currentTopic: fields.topic,
            contextSummary: fields.summary,
            satisfaction: fields.satisfaction,
            tags: fields.tags,
            recentMessages: messages.map(m => ({
                role: m.role,
                text: m.text,
                time: m.timestamp
            })),
            handoffReason: reason
        };
    }

    /**
     * Format handoff summary as readable text (for sending to operator)
     */
    formatSummaryText(summary: HandoffSummary): string {
        const lines: string[] = [
            `📋 **Resumen de Traspaso**`,
            `━━━━━━━━━━━━━━━━━━━━━━━━━━━━`,
            `👤 **${summary.contactName}**`,
            summary.phone ? `📱 ${summary.phone}` : '',
            `📡 Canales: ${summary.channels.join(', ')}`,
            '',
            `📌 **Tema actual**: ${summary.currentTopic || 'No definido'}`,
            `⭐ **Satisfacción**: ${summary.satisfaction > 0 ? `${summary.satisfaction}/5` : 'Sin calificar'}`,
            summary.tags.length > 0 ? `🏷️ **Tags**: ${summary.tags.join(', ')}` : '',
            '',
            summary.contextSummary ? `📝 **Contexto**: ${summary.contextSummary}` : '',
            summary.handoffReason ? `💡 **Motivo**: ${summary.handoffReason}` : '',
            '',
            `💬 **Últimos mensajes**:`,
            ...summary.recentMessages.map(m => {
                const icon = m.role === 'customer' ? '👤' : m.role === 'agent' ? '🤖' : '👨‍💼';
                return `  ${icon} ${m.text}`;
            })
        ].filter(Boolean);

        return lines.join('\n');
    }
}
