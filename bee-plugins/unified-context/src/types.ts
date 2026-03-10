/**
 * BEE Smart AI — Unified Context Types
 * Shared type definitions for the cross-channel context system.
 */

// ═══════════════════════════════════════
// Contact Types
// ═══════════════════════════════════════

export type MessageRole = 'customer' | 'agent' | 'operator';
export type HandoffStatus = 'agent' | 'operator' | 'hybrid';

export interface Contact {
    contactId: string;
    phone: string | null;
    email: string | null;
    username: string | null;
    displayName: string;
    firstSeen: string;
    lastInteraction: string;
    channelsUsed: string[];
    preferredChannel: string;
    language: string;
}

export interface Message {
    id: number;
    contactId: string;
    role: MessageRole;
    channel: string;
    text: string;
    timestamp: string;
    metadata: Record<string, any>;
}

export interface ContactContext {
    currentTopic: string;
    summary: string;
    intentHistory: string[];
    lastMessages: Message[];
    handoffStatus: HandoffStatus;
    handoffOperator: string | null;
}

export interface ContactMetadata {
    totalInteractions: number;
    satisfactionScore: number;
    tags: string[];
    customFields: Record<string, any>;
}

export interface FullContactRecord {
    contact: Contact;
    context: ContactContext;
    metadata: ContactMetadata;
}

// ═══════════════════════════════════════
// Identifier Resolution
// ═══════════════════════════════════════

export interface ContactIdentifier {
    phone?: string;
    email?: string;
    username?: string;
    channel: string;
    displayName?: string;
}

// ═══════════════════════════════════════
// Context Injection
// ═══════════════════════════════════════

export interface ContextInjection {
    /** The formatted context string to inject into the LLM prompt */
    contextBlock: string;
    /** Contact ID for tracking */
    contactId: string;
    /** Whether the contact is in operator handoff mode */
    isHandoff: boolean;
    /** Number of messages used for context */
    messagesUsed: number;
}

// ═══════════════════════════════════════
// Summarization
// ═══════════════════════════════════════

export interface SummarizationRequest {
    contactId: string;
    messages: Message[];
    existingSummary: string;
}

export interface SummarizationResult {
    contactId: string;
    newSummary: string;
    messagesCompressed: number;
    detectedTopic: string;
    detectedIntents: string[];
}

// ═══════════════════════════════════════
// API Types
// ═══════════════════════════════════════

export interface ContactListResponse {
    contacts: ContactSummary[];
    total: number;
    page: number;
    pageSize: number;
}

export interface ContactSummary {
    contactId: string;
    displayName: string;
    phone: string | null;
    lastInteraction: string;
    currentTopic: string;
    handoffStatus: HandoffStatus;
    totalInteractions: number;
    tags: string[];
}

export interface SearchResult {
    contact: ContactSummary;
    matchedMessages: Message[];
    relevanceScore: number;
}
