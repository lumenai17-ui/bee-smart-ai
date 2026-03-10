/**
 * BEE Smart AI — Context Summarizer
 * Background service that compresses old message history into summaries.
 * Uses the LLM to generate intelligent summaries and detect topics/intents.
 */

import { ContactDatabase } from './database';
import { Message, SummarizationResult } from './types';

/** Callback to invoke the LLM for summarization */
export type LlmSummarizeCallback = (prompt: string) => Promise<string>;

export class ContextSummarizer {
    private db: ContactDatabase;
    private threshold: number;
    private keepRecent: number;
    private cronInterval: ReturnType<typeof setInterval> | null = null;
    private llmCallback: LlmSummarizeCallback | null = null;

    constructor(db: ContactDatabase, options?: {
        threshold?: number;
        keepRecent?: number;
    }) {
        this.db = db;
        this.threshold = options?.threshold || 100;
        this.keepRecent = options?.keepRecent || 30;
    }

    /**
     * Register the LLM callback for AI-powered summarization
     */
    setLlmCallback(callback: LlmSummarizeCallback): void {
        this.llmCallback = callback;
    }

    /**
     * Start periodic summarization checks
     */
    startCron(intervalMs: number = 3600000): void { // Default: every hour
        this.stopCron();
        this.cronInterval = setInterval(() => this.runAll(), intervalMs);
    }

    stopCron(): void {
        if (this.cronInterval) {
            clearInterval(this.cronInterval);
            this.cronInterval = null;
        }
    }

    /**
     * Run summarization for all contacts that need it
     */
    async runAll(): Promise<SummarizationResult[]> {
        const contactIds = this.db.getContactsNeedingSummarization(this.threshold);
        const results: SummarizationResult[] = [];

        for (const contactId of contactIds) {
            try {
                const result = await this.summarizeContact(contactId);
                if (result) results.push(result);
            } catch (err) {
                console.error(`[Summarizer] Error for ${contactId}:`, err);
            }
        }

        return results;
    }

    /**
     * Summarize a single contact's history
     */
    async summarizeContact(contactId: string): Promise<SummarizationResult | null> {
        const fields = this.db.getContextFields(contactId);
        if (!fields) return null;

        const totalMessages = this.db.getMessageCount(contactId);
        if (totalMessages <= this.threshold) return null;

        // Get all messages
        const allMessages = this.db.getMessages(contactId, totalMessages);
        const toSummarize = allMessages.slice(0, -this.keepRecent);

        if (toSummarize.length === 0) return null;

        // Generate summary
        const summary = await this.generateSummary(toSummarize, fields.summary);

        // Update contact with new summary
        this.db.updateContextFields(contactId, {
            summary: summary.newSummary,
            topic: summary.detectedTopic || fields.topic,
            intents: [...new Set([...fields.intents, ...summary.detectedIntents])]
        });

        // Delete old messages (keep only recent)
        this.db.deleteOldMessages(contactId, this.keepRecent);

        return summary;
    }

    /**
     * Generate a summary from messages
     */
    private async generateSummary(messages: Message[], existingSummary: string): Promise<SummarizationResult> {
        if (this.llmCallback) {
            return this.llmSummarize(messages, existingSummary);
        }
        return this.ruleSummarize(messages, existingSummary);
    }

    /**
     * AI-powered summarization using the LLM
     */
    private async llmSummarize(messages: Message[], existingSummary: string): Promise<SummarizationResult> {
        const messagesText = messages.map(m =>
            `[${m.role}/${m.channel} ${m.timestamp}] ${m.text}`
        ).join('\n');

        const prompt = `Eres un asistente que resume conversaciones de negocio.

${existingSummary ? `Resumen previo:\n${existingSummary}\n\n` : ''}Mensajes a resumir (${messages.length} mensajes):
${messagesText}

Genera un JSON con exactamente esta estructura:
{
  "summary": "Resumen conciso de toda la conversación incluyendo el contexto previo",
  "topic": "Tema principal actual de la conversación",
  "intents": ["lista", "de", "intenciones", "detectadas"]
}

Responde SOLO con el JSON, sin texto adicional.`;

        try {
            const response = await this.llmCallback!(prompt);
            const parsed = JSON.parse(response.trim());

            return {
                contactId: messages[0]?.contactId || '',
                newSummary: parsed.summary || '',
                messagesCompressed: messages.length,
                detectedTopic: parsed.topic || '',
                detectedIntents: parsed.intents || []
            };
        } catch {
            // Fallback to rule-based if LLM fails
            return this.ruleSummarize(messages, existingSummary);
        }
    }

    /**
     * Rule-based summarization (fallback when LLM is unavailable)
     */
    private ruleSummarize(messages: Message[], existingSummary: string): SummarizationResult {
        const customerMessages = messages.filter(m => m.role === 'customer');
        const agentMessages = messages.filter(m => m.role === 'agent');
        const operatorMessages = messages.filter(m => m.role === 'operator');

        // Extract key phrases (simple approach)
        const allText = customerMessages.map(m => m.text).join(' ');
        const words = allText.toLowerCase().split(/\s+/);
        const wordFreq: Record<string, number> = {};
        for (const w of words) {
            if (w.length > 4) wordFreq[w] = (wordFreq[w] || 0) + 1;
        }
        const topWords = Object.entries(wordFreq)
            .sort((a, b) => b[1] - a[1])
            .slice(0, 5)
            .map(([word]) => word);

        const summary = [
            existingSummary ? `${existingSummary} ` : '',
            `${messages.length} mensajes procesados (${customerMessages.length} del cliente, `,
            `${agentMessages.length} del agente, ${operatorMessages.length} del operador). `,
            `Temas frecuentes: ${topWords.join(', ')}.`
        ].join('');

        // Detect simple intents
        const intents: string[] = [];
        const intentPatterns: [RegExp, string][] = [
            [/reserv/i, 'reservación'],
            [/preci|cost|cuar/i, 'consulta_precio'],
            [/hora|abie|cier/i, 'consulta_horario'],
            [/quej|proble|mal/i, 'queja'],
            [/graci|exce|bien/i, 'satisfacción'],
            [/compr|ped|orden/i, 'compra'],
            [/cancel/i, 'cancelación'],
            [/factur/i, 'facturación'],
        ];

        for (const [pattern, intent] of intentPatterns) {
            if (pattern.test(allText)) intents.push(intent);
        }

        return {
            contactId: messages[0]?.contactId || '',
            newSummary: summary.trim(),
            messagesCompressed: messages.length,
            detectedTopic: topWords[0] || '',
            detectedIntents: intents
        };
    }
}
