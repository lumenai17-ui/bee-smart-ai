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
    headers?: Record<string, string>;
}

export interface HttpResponse {
    status: number;
    body: any;
}

/**
 * Auth middleware — validates Bearer token against OPENCLAW_GATEWAY_TOKEN
 */
function authenticateRequest(req: HttpRequest): HttpResponse | null {
    const token = process.env.OPENCLAW_GATEWAY_TOKEN;
    if (!token) return null; // No token configured = skip auth (dev mode)

    const authHeader = req.headers?.['authorization'] || req.headers?.['Authorization'] || '';
    const providedToken = authHeader.replace(/^Bearer\s+/i, '').trim();

    if (!providedToken || providedToken !== token) {
        return { status: 401, body: { error: 'Unauthorized — provide valid Bearer token' } };
    }
    return null; // Auth passed
}

/**
 * Creates the HTTP route handler map for the Provider Manager
 */
export function createApiRoutes(plugin: ProviderManagerPlugin): Map<string, (req: HttpRequest) => HttpResponse> {
    const routes = new Map<string, (req: HttpRequest) => HttpResponse>();

    // Wrap each handler with auth middleware
    const withAuth = (handler: (req: HttpRequest) => HttpResponse) => (req: HttpRequest): HttpResponse => {
        const authError = authenticateRequest(req);
        if (authError) return authError;
        return handler(req);
    };

    routes.set('GET /api/providers', withAuth((_req) => {
        return {
            status: 200,
            body: plugin.handleProviderList()
        };
    }));

    routes.set('GET /api/providers/:name', withAuth((req) => {
        const detail = plugin.handleProviderDetail({ name: req.params.name });
        if (!detail) {
            return { status: 404, body: { error: `Provider '${req.params.name}' not found` } };
        }
        return { status: 200, body: detail };
    }));

    routes.set('POST /api/providers', withAuth((req) => {
        try {
            const result = plugin.handleProviderAdd(req.body);
            return { status: 201, body: result };
        } catch (err: any) {
            return { status: 400, body: { error: err.message } };
        }
    }));

    routes.set('DELETE /api/providers/:name', withAuth((req) => {
        const result = plugin.handleProviderRemove({ name: req.params.name });
        if (!result.success) {
            return { status: 404, body: result };
        }
        return { status: 200, body: result };
    }));

    routes.set('PUT /api/providers/:name/enable', withAuth((req) => {
        return {
            status: 200,
            body: plugin.handleProviderToggle({ name: req.params.name, enabled: true })
        };
    }));

    routes.set('PUT /api/providers/:name/disable', withAuth((req) => {
        return {
            status: 200,
            body: plugin.handleProviderToggle({ name: req.params.name, enabled: false })
        };
    }));

    routes.set('POST /api/providers/:name/rotate', withAuth((req) => {
        const result = plugin.handleKeyRotate({
            provider: req.params.name,
            reason: req.body?.reason || 'api_request',
            targetKeyIndex: req.body?.targetKeyIndex
        });
        return { status: result.success ? 200 : 400, body: result };
    }));

    routes.set('POST /api/providers/:name/keys', withAuth((req) => {
        const result = plugin.handleKeyAdd({
            provider: req.params.name,
            key: req.body.key,
            label: req.body.label
        });
        return { status: result.success ? 201 : 400, body: result };
    }));

    routes.set('DELETE /api/providers/:name/keys/:index', withAuth((req) => {
        const result = plugin.handleKeyRemove({
            provider: req.params.name,
            keyIndex: parseInt(req.params.index, 10)
        });
        return { status: result.success ? 200 : 400, body: result };
    }));

    routes.set('POST /api/providers/swap', withAuth((req) => {
        const result = plugin.handleProviderSwap(req.body);
        return { status: result.success ? 200 : 400, body: result };
    }));

    routes.set('GET /api/providers/health', withAuth((_req) => {
        return {
            status: 200,
            body: plugin.handleHealthSummary()
        };
    }));

    routes.set('GET /api/providers/audit', withAuth((req) => {
        const count = parseInt(req.query.count || '50', 10);
        const action = req.query.action;
        const provider = req.query.provider;
        return {
            status: 200,
            body: plugin.handleAuditList({ count, action, provider })
        };
    }));

    return routes;
}
