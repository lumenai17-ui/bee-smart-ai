/**
 * BEE Smart AI — Unified Context Plugin
 * ═══════════════════════════════════════════
 * 
 * Central orchestrator for the cross-channel context system.
 * 
 * Responsibilities:
 * - Resolve contact identities across channels (phone/email/username → contact_id)
 * - Store and retrieve conversation history in SQLite
 * - Inject rich context into every LLM prompt
 * - Manage operator handoff (agent ↔ operator ↔ hybrid)
 * - Background summarization of old conversations
 * - HTTP API + Gateway RPC for external access
 * 
 * Modules:
 * - types.ts       → Type definitions
 * - database.ts    → SQLite persistence layer
 * - resolver.ts    → Contact identity resolver
 * - injector.ts    → Context injection for LLM prompts
 * - handoff.ts     → Operator handoff manager
 * - summarizer.ts  → Background context compression
 * - api.ts         → HTTP REST API routes
 */

import * as path from 'path';
import { ContactDatabase } from './database';
import { ContactResolver } from './resolver';
import { ContextInjector } from './injector';
import { HandoffManager, HandoffSummary } from './handoff';
import { ContextSummarizer, LlmSummarizeCallback } from './summarizer';
import { createContextApiRoutes } from './api';
import {
    Contact,
    ContactIdentifier,
    ContextInjection,
    Message,
    MessageRole,
    HandoffStatus,
    FullContactRecord,
    ContactListResponse,
    ContactSummary,
    SummarizationResult,
    SearchResult
} from './types';

// ═══════════════════════════════════════
// Plugin Entry Point
// ═══════════════════════════════════════

export default class UnifiedContextPlugin {
    private db: ContactDatabase;
    private resolver: ContactResolver;
    private injector: ContextInjector;
    private handoff: HandoffManager;
    private summarizer: ContextSummarizer;

    constructor(config: {
        rootDir?: string;
        database?: { path?: string };
        contextWindow?: { maxMessages?: number; summaryAfter?: number };
        summarization?: { cronIntervalMs?: number; threshold?: number; keepRecent?: number };
    }) {
        const rootDir = config.rootDir || process.cwd();
        const dbPath = config.database?.path || path.join(rootDir, 'data', 'contacts.db');
        const maxMessages = config.contextWindow?.maxMessages || 15;
        const summaryThreshold = config.summarization?.threshold || config.contextWindow?.summaryAfter || 100;
        const keepRecent = config.summarization?.keepRecent || 30;

        // Initialize sub-systems
        this.db = new ContactDatabase(dbPath);
        this.resolver = new ContactResolver(this.db);
        this.injector = new ContextInjector(this.db, maxMessages);
        this.handoff = new HandoffManager(this.db);
        this.summarizer = new ContextSummarizer(this.db, { threshold: summaryThreshold, keepRecent });

        // Start background summarization cron
        const cronInterval = config.summarization?.cronIntervalMs || 3600000; // 1 hour
        this.summarizer.startCron(cronInterval);
    }

    // ═══════════════════════════════════════
    // Contact Resolution
    // ═══════════════════════════════════════

    /**
     * Resolve an identifier to a contact_id.
     * Creates the contact if it doesn't exist.
     * This is the main entry point for incoming messages.
     */
    resolveContact(identifier: ContactIdentifier): string {
        return this.resolver.resolve(identifier);
    }

    // ═══════════════════════════════════════
    // Message Recording
    // ═══════════════════════════════════════

    /**
     * Record a message from any channel.
     * Automatically resolves the contact and updates context.
     */
    recordIncoming(identifier: ContactIdentifier, text: string, metadata?: Record<string, any>): { contactId: string; contextInjection: ContextInjection | null } {
        const contactId = this.resolveContact(identifier);

        this.db.addMessage({
            contactId,
            role: 'customer',
            channel: identifier.channel,
            text,
            timestamp: new Date().toISOString(),
            metadata: metadata || {}
        });

        // Add channel if new
        this.db.addChannelToContact(contactId, identifier.channel);

        // Build context injection for the LLM response
        const contextInjection = this.injector.buildInjection(contactId);

        return { contactId, contextInjection };
    }

    /**
     * Record an agent response
     */
    recordAgentResponse(contactId: string, text: string, channel: string, metadata?: Record<string, any>): void {
        this.db.addMessage({
            contactId,
            role: 'agent',
            channel,
            text,
            timestamp: new Date().toISOString(),
            metadata: metadata || {}
        });
    }

    /**
     * Record an operator message
     */
    recordOperatorMessage(contactId: string, text: string, channel: string, operatorId: string): void {
        this.db.addMessage({
            contactId,
            role: 'operator',
            channel,
            text,
            timestamp: new Date().toISOString(),
            metadata: { operatorId }
        });
    }

    /**
     * Record a message (generic, used by API)
     */
    recordMessage(contactId: string, msg: { role: MessageRole; channel: string; text: string; metadata?: Record<string, any> }): void {
        this.db.addMessage({
            contactId,
            role: msg.role,
            channel: msg.channel,
            text: msg.text,
            timestamp: new Date().toISOString(),
            metadata: msg.metadata || {}
        });
    }

    // ═══════════════════════════════════════
    // Context Injection
    // ═══════════════════════════════════════

    /**
     * Get the context injection for a contact.
     * Used as middleware before every LLM call.
     */
    getContextInjection(contactId: string): ContextInjection | null {
        return this.injector.buildInjection(contactId);
    }

    /**
     * Get compact context (for smaller context windows)
     */
    getCompactContext(contactId: string): string {
        return this.injector.buildCompactInjection(contactId);
    }

    // ═══════════════════════════════════════
    // Contact Management
    // ═══════════════════════════════════════

    getFullRecord(contactId: string): FullContactRecord | null {
        const contact = this.db.findById(contactId);
        if (!contact) return null;

        const fields = this.db.getContextFields(contactId);
        if (!fields) return null;

        const messages = this.db.getMessages(contactId, 50);

        return {
            contact,
            context: {
                currentTopic: fields.topic,
                summary: fields.summary,
                intentHistory: fields.intents,
                lastMessages: messages,
                handoffStatus: fields.handoffStatus as HandoffStatus,
                handoffOperator: fields.handoffOperator
            },
            metadata: {
                totalInteractions: messages.length,
                satisfactionScore: fields.satisfaction,
                tags: fields.tags,
                customFields: fields.customFields
            }
        };
    }

    listContacts(page: number = 1, pageSize: number = 50): ContactListResponse {
        const { contacts, total } = this.db.listContacts(page, pageSize);

        const summaries: ContactSummary[] = contacts.map(c => {
            const fields = this.db.getContextFields(c.contactId);
            return {
                contactId: c.contactId,
                displayName: c.displayName,
                phone: c.phone,
                lastInteraction: c.lastInteraction,
                currentTopic: fields?.topic || '',
                handoffStatus: (fields?.handoffStatus || 'agent') as HandoffStatus,
                totalInteractions: 0,
                tags: fields?.tags || []
            };
        });

        return { contacts: summaries, total, page, pageSize };
    }

    searchContacts(query: string): ContactSummary[] {
        const contacts = this.db.searchContacts(query);
        return contacts.map(c => ({
            contactId: c.contactId,
            displayName: c.displayName,
            phone: c.phone,
            lastInteraction: c.lastInteraction,
            currentTopic: '',
            handoffStatus: 'agent' as HandoffStatus,
            totalInteractions: 0,
            tags: []
        }));
    }

    getMessages(contactId: string, limit: number = 50, before?: string): Message[] {
        return this.db.getMessages(contactId, limit, before);
    }

    searchMessages(query: string, contactId?: string): Message[] {
        return this.db.searchMessages(query, contactId);
    }

    // ═══════════════════════════════════════
    // Context Updates
    // ═══════════════════════════════════════

    updateTags(contactId: string, tags: string[]): void {
        this.db.updateContextFields(contactId, { tags });
    }

    updateTopic(contactId: string, topic: string): void {
        this.db.updateContextFields(contactId, { topic });
    }

    updateSatisfaction(contactId: string, score: number): void {
        this.db.updateContextFields(contactId, { satisfaction: Math.max(0, Math.min(5, score)) });
    }

    // ═══════════════════════════════════════
    // Operator Handoff
    // ═══════════════════════════════════════

    startHandoff(contactId: string, operatorId: string, reason?: string): HandoffSummary | null {
        return this.handoff.startHandoff(contactId, operatorId, reason);
    }

    endHandoff(contactId: string, operatorId: string): boolean {
        return this.handoff.endHandoff(contactId, operatorId);
    }

    setHybridMode(contactId: string, operatorId: string): boolean {
        return this.handoff.setHybridMode(contactId, operatorId);
    }

    getHandoffStatus(contactId: string): { status: HandoffStatus; operator: string | null } | null {
        return this.handoff.getHandoffStatus(contactId);
    }

    getHandoffSummaryText(contactId: string, reason?: string): string {
        const summary = this.handoff.generateSummary(contactId, reason);
        if (!summary) return 'Contact not found.';
        return this.handoff.formatSummaryText(summary);
    }

    // ═══════════════════════════════════════
    // Summarization
    // ═══════════════════════════════════════

    /**
     * Register the LLM callback for AI-powered summarization
     */
    setLlmCallback(callback: LlmSummarizeCallback): void {
        this.summarizer.setLlmCallback(callback);
    }

    /**
     * Manually trigger summarization
     */
    async runSummarization(): Promise<SummarizationResult[]> {
        return this.summarizer.runAll();
    }

    /**
     * Summarize a single contact
     */
    async summarizeContact(contactId: string): Promise<SummarizationResult | null> {
        return this.summarizer.summarizeContact(contactId);
    }

    // ═══════════════════════════════════════
    // Gateway RPC Handlers
    // ═══════════════════════════════════════

    handleContextGet(params: { contactId: string }): FullContactRecord | null {
        return this.getFullRecord(params.contactId);
    }

    handleContextInject(params: { contactId: string; compact?: boolean }): any {
        if (params.compact) {
            return { context: this.getCompactContext(params.contactId) };
        }
        return this.getContextInjection(params.contactId);
    }

    handleContextSearch(params: { query: string; contactId?: string }): any {
        if (params.contactId) {
            return { messages: this.searchMessages(params.query, params.contactId) };
        }
        return { contacts: this.searchContacts(params.query) };
    }

    handleContextSummarize(params: { contactId: string }): any {
        return { summary: this.getHandoffSummaryText(params.contactId) };
    }

    handleHandoffStart(params: { contactId: string; operatorId: string; reason?: string }): any {
        return this.startHandoff(params.contactId, params.operatorId, params.reason);
    }

    handleHandoffEnd(params: { contactId: string; operatorId: string }): any {
        return { success: this.endHandoff(params.contactId, params.operatorId) };
    }

    // ═══════════════════════════════════════
    // HTTP API Registration
    // ═══════════════════════════════════════

    getApiRoutes() {
        return createContextApiRoutes(this);
    }

    // ═══════════════════════════════════════
    // Lifecycle
    // ═══════════════════════════════════════

    shutdown(): void {
        this.summarizer.stopCron();
        this.db.close();
    }
}
