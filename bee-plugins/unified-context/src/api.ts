/**
 * BEE Smart AI — Unified Context HTTP API
 * REST endpoints for contact management and context operations.
 * Registered with the OpenClaw Gateway under /api/contacts/*
 */

import type UnifiedContextPlugin from './index';

export interface HttpRequest {
    method: string;
    path: string;
    params: Record<string, string>;
    query: Record<string, string>;
    body: any;
}

export interface HttpResponse {
    status: number;
    body: any;
}

export function createContextApiRoutes(plugin: UnifiedContextPlugin): Map<string, (req: HttpRequest) => HttpResponse> {
    const routes = new Map<string, (req: HttpRequest) => HttpResponse>();

    // ── GET /api/contacts ────────────────────
    // List all contacts with pagination
    routes.set('GET /api/contacts', (req) => {
        const page = parseInt(req.query.page || '1', 10);
        const pageSize = parseInt(req.query.pageSize || '50', 10);
        return { status: 200, body: plugin.listContacts(page, pageSize) };
    });

    // ── GET /api/contacts/search ─────────────
    // Search contacts by name, phone, email
    routes.set('GET /api/contacts/search', (req) => {
        return { status: 200, body: plugin.searchContacts(req.query.q || '') };
    });

    // ── GET /api/contacts/:id ────────────────
    // Get full context for a contact
    routes.set('GET /api/contacts/:id', (req) => {
        const result = plugin.getFullRecord(req.params.id);
        if (!result) return { status: 404, body: { error: 'Contact not found' } };
        return { status: 200, body: result };
    });

    // ── GET /api/contacts/:id/context ────────
    // Get the context injection string
    routes.set('GET /api/contacts/:id/context', (req) => {
        const injection = plugin.getContextInjection(req.params.id);
        if (!injection) return { status: 404, body: { error: 'Contact not found' } };
        return { status: 200, body: injection };
    });

    // ── GET /api/contacts/:id/messages ───────
    // Get messages for a contact
    routes.set('GET /api/contacts/:id/messages', (req) => {
        const limit = parseInt(req.query.limit || '50', 10);
        const before = req.query.before;
        return { status: 200, body: plugin.getMessages(req.params.id, limit, before) };
    });

    // ── POST /api/contacts/:id/messages ──────
    // Add a message (used by channels to record messages)
    routes.set('POST /api/contacts/:id/messages', (req) => {
        try {
            plugin.recordMessage(req.params.id, req.body);
            return { status: 201, body: { success: true } };
        } catch (err: any) {
            return { status: 400, body: { error: err.message } };
        }
    });

    // ── POST /api/contacts/resolve ───────────
    // Resolve an identifier to a contact_id
    routes.set('POST /api/contacts/resolve', (req) => {
        const contactId = plugin.resolveContact(req.body);
        return { status: 200, body: { contactId } };
    });

    // ── POST /api/contacts/:id/handoff ───────
    // Start handoff to operator
    routes.set('POST /api/contacts/:id/handoff', (req) => {
        const result = plugin.startHandoff(req.params.id, req.body.operatorId, req.body.reason);
        if (!result) return { status: 404, body: { error: 'Contact not found' } };
        return { status: 200, body: result };
    });

    // ── DELETE /api/contacts/:id/handoff ─────
    // End handoff, return to agent
    routes.set('DELETE /api/contacts/:id/handoff', (req) => {
        const success = plugin.endHandoff(req.params.id, req.body?.operatorId || 'system');
        return { status: success ? 200 : 404, body: { success } };
    });

    // ── GET /api/contacts/:id/handoff ────────
    // Get handoff status
    routes.set('GET /api/contacts/:id/handoff', (req) => {
        const status = plugin.getHandoffStatus(req.params.id);
        if (!status) return { status: 404, body: { error: 'Contact not found' } };
        return { status: 200, body: status };
    });

    // ── PUT /api/contacts/:id/tags ───────────
    // Update contact tags
    routes.set('PUT /api/contacts/:id/tags', (req) => {
        plugin.updateTags(req.params.id, req.body.tags || []);
        return { status: 200, body: { success: true } };
    });

    // ── PUT /api/contacts/:id/topic ──────────
    // Update current topic
    routes.set('PUT /api/contacts/:id/topic', (req) => {
        plugin.updateTopic(req.params.id, req.body.topic || '');
        return { status: 200, body: { success: true } };
    });

    // ── POST /api/contacts/summarize ─────────
    // Trigger summarization for all contacts
    routes.set('POST /api/contacts/summarize', async (_req) => {
        // Note: async route — caller should handle promise
        const results = await plugin.runSummarization();
        return { status: 200, body: { processed: results.length, results } };
    });

    // ── GET /api/contacts/search/messages ────
    // Search across all message history
    routes.set('GET /api/contacts/search/messages', (req) => {
        return { status: 200, body: plugin.searchMessages(req.query.q || '', req.query.contactId) };
    });

    return routes;
}
