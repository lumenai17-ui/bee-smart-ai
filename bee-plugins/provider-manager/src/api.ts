/**
 * BEE Smart AI — Provider Manager HTTP API
 * REST endpoints for provider management.
 * 
 * These routes are registered with the OpenClaw Gateway
 * and exposed under /api/providers/*
 */

import type ProviderManagerPlugin from './index';

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

/**
 * Creates the HTTP route handler map for the Provider Manager
 */
export function createApiRoutes(plugin: ProviderManagerPlugin): Map<string, (req: HttpRequest) => HttpResponse> {
    const routes = new Map<string, (req: HttpRequest) => HttpResponse>();

    // ── GET /api/providers ──────────────────
    // List all providers with status
    routes.set('GET /api/providers', (_req) => {
        return {
            status: 200,
            body: plugin.handleProviderList()
        };
    });

    // ── GET /api/providers/:name ────────────
    // Get details of a specific provider
    routes.set('GET /api/providers/:name', (req) => {
        const detail = plugin.handleProviderDetail({ name: req.params.name });
        if (!detail) {
            return { status: 404, body: { error: `Provider '${req.params.name}' not found` } };
        }
        return { status: 200, body: detail };
    });

    // ── POST /api/providers ─────────────────
    // Add a new provider
    routes.set('POST /api/providers', (req) => {
        try {
            const result = plugin.handleProviderAdd(req.body);
            return { status: 201, body: result };
        } catch (err: any) {
            return { status: 400, body: { error: err.message } };
        }
    });

    // ── DELETE /api/providers/:name ─────────
    // Remove a provider
    routes.set('DELETE /api/providers/:name', (req) => {
        const result = plugin.handleProviderRemove({ name: req.params.name });
        if (!result.success) {
            return { status: 404, body: result };
        }
        return { status: 200, body: result };
    });

    // ── PUT /api/providers/:name/enable ─────
    // Enable a provider
    routes.set('PUT /api/providers/:name/enable', (req) => {
        return {
            status: 200,
            body: plugin.handleProviderToggle({ name: req.params.name, enabled: true })
        };
    });

    // ── PUT /api/providers/:name/disable ────
    // Disable a provider
    routes.set('PUT /api/providers/:name/disable', (req) => {
        return {
            status: 200,
            body: plugin.handleProviderToggle({ name: req.params.name, enabled: false })
        };
    });

    // ── POST /api/providers/:name/rotate ────
    // Rotate the active API key
    routes.set('POST /api/providers/:name/rotate', (req) => {
        const result = plugin.handleKeyRotate({
            provider: req.params.name,
            reason: req.body?.reason || 'api_request',
            targetKeyIndex: req.body?.targetKeyIndex
        });
        return { status: result.success ? 200 : 400, body: result };
    });

    // ── POST /api/providers/:name/keys ──────
    // Add a new key to a provider
    routes.set('POST /api/providers/:name/keys', (req) => {
        const result = plugin.handleKeyAdd({
            provider: req.params.name,
            key: req.body.key,
            label: req.body.label
        });
        return { status: result.success ? 201 : 400, body: result };
    });

    // ── DELETE /api/providers/:name/keys/:index
    // Remove a key from a provider
    routes.set('DELETE /api/providers/:name/keys/:index', (req) => {
        const result = plugin.handleKeyRemove({
            provider: req.params.name,
            keyIndex: parseInt(req.params.index, 10)
        });
        return { status: result.success ? 200 : 400, body: result };
    });

    // ── POST /api/providers/swap ────────────
    // Swap provider for a type
    routes.set('POST /api/providers/swap', (req) => {
        const result = plugin.handleProviderSwap(req.body);
        return { status: result.success ? 200 : 400, body: result };
    });

    // ── GET /api/providers/health ───────────
    // Get health summary for all providers
    routes.set('GET /api/providers/health', (_req) => {
        return {
            status: 200,
            body: plugin.handleHealthSummary()
        };
    });

    // ── GET /api/providers/audit ────────────
    // Get recent audit events
    routes.set('GET /api/providers/audit', (req) => {
        const count = parseInt(req.query.count || '50', 10);
        const action = req.query.action;
        const provider = req.query.provider;
        return {
            status: 200,
            body: plugin.handleAuditList({ count, action, provider })
        };
    });

    return routes;
}
