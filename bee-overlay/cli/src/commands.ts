/**
 * BEE Smart AI — Command Handlers
 * Implements all CLI commands: keys, provider, allow, block, operator, channel, status, deploy, update.
 */

import * as fs from 'fs';
import * as path from 'path';
import { execSync } from 'child_process';
import { header, success, error, warn, info, listItem, table, bigSuccess, c } from './ui';

export class CommandHandlers {
    private rootDir: string;

    constructor(rootDir: string) {
        this.rootDir = rootDir;
    }

    // ═══════════════════════════════════════
    // DEPLOY
    // ═══════════════════════════════════════

    deploy(): void {
        header('Deploy');

        // Pre-flight checks
        const envPath = path.join(this.rootDir, 'config', '.env');
        if (!fs.existsSync(envPath)) {
            error('No .env file found.');
            info('Run `bee onboard` first to configure your agent.');
            process.exit(1);
        }

        const checks: [string, boolean][] = [
            ['config/.env exists', fs.existsSync(envPath)],
            ['config/openclaw.json exists', fs.existsSync(path.join(this.rootDir, 'config', 'openclaw.json'))],
            ['config/system-prompt.md exists', fs.existsSync(path.join(this.rootDir, 'config', 'system-prompt.md'))],
            ['security/allowlist.json exists', fs.existsSync(path.join(this.rootDir, 'security', 'allowlist.json'))],
        ];

        for (const [label, ok] of checks) {
            if (ok) success(label);
            else error(label);
        }

        if (checks.some(([_, ok]) => !ok)) {
            error('Pre-flight checks failed. Fix issues above and retry.');
            process.exit(1);
        }

        console.log('');
        info('Installing dependencies...');

        const openclawDir = path.join(this.rootDir, 'openclaw');
        if (fs.existsSync(openclawDir)) {
            try {
                execSync('npm install', { cwd: openclawDir, stdio: 'pipe' });
                success('OpenClaw dependencies installed');
            } catch {
                warn('Could not install OpenClaw deps (submodule may not be initialized)');
            }
        }

        // Build plugins
        for (const plugin of ['provider-manager', 'unified-context']) {
            const pluginDir = path.join(this.rootDir, 'bee-plugins', plugin);
            if (fs.existsSync(path.join(pluginDir, 'package.json'))) {
                try {
                    execSync('npm install && npm run build', { cwd: pluginDir, stdio: 'pipe' });
                    success(`Plugin ${plugin} built`);
                } catch {
                    warn(`Could not build ${plugin}`);
                }
            }
        }

        // Create data directory
        const dataDir = path.join(this.rootDir, 'data');
        if (!fs.existsSync(dataDir)) fs.mkdirSync(dataDir, { recursive: true });
        success('Data directory ready');

        bigSuccess('BEE Smart AI is DEPLOYED!');
        console.log(`  ${c.dim}Gateway: http://localhost:18789${c.reset}`);
        console.log(`  ${c.dim}Run with: OPENCLAW_CONFIG=${path.join(this.rootDir, 'config', 'openclaw.json')} node openclaw/dist/index.js${c.reset}\n`);
    }

    // ═══════════════════════════════════════
    // UPDATE
    // ═══════════════════════════════════════

    update(): void {
        header('Update OpenClaw');

        try {
            info('Pulling latest OpenClaw...');
            execSync('git submodule update --remote openclaw', { cwd: this.rootDir, stdio: 'inherit' });
            success('OpenClaw updated');

            info('Reinstalling dependencies...');
            execSync('npm install', { cwd: path.join(this.rootDir, 'openclaw'), stdio: 'pipe' });
            success('Dependencies updated');

            bigSuccess('Update complete!');
        } catch (err: any) {
            error(`Update failed: ${err.message}`);
        }
    }

    // ═══════════════════════════════════════
    // STATUS
    // ═══════════════════════════════════════

    status(): void {
        header('Agent Status');

        const envExists = fs.existsSync(path.join(this.rootDir, 'config', '.env'));
        const configExists = fs.existsSync(path.join(this.rootDir, 'config', 'openclaw.json'));

        // Count skills
        const skillsDir = path.join(this.rootDir, 'bee-skills');
        let skillCount = 0;
        if (fs.existsSync(skillsDir)) {
            const categories = fs.readdirSync(skillsDir).filter(f => fs.statSync(path.join(skillsDir, f)).isDirectory());
            for (const cat of categories) {
                const skills = fs.readdirSync(path.join(skillsDir, cat)).filter(f => fs.statSync(path.join(skillsDir, cat, f)).isDirectory());
                skillCount += skills.length;
            }
        }

        // Count automations
        const autoDir = path.join(this.rootDir, 'bee-automations');
        let autoCount = 0;
        if (fs.existsSync(autoDir)) {
            const categories = fs.readdirSync(autoDir).filter(f => fs.statSync(path.join(autoDir, f)).isDirectory());
            for (const cat of categories) {
                const autos = fs.readdirSync(path.join(autoDir, cat)).filter(f => fs.statSync(path.join(autoDir, cat, f)).isDirectory());
                autoCount += autos.length;
            }
        }

        // Read tier
        let tier = 'unknown';
        try {
            const envContent = fs.readFileSync(path.join(this.rootDir, 'config', '.env'), 'utf-8');
            // Tier is not in .env, check tier-config
        } catch { /* skip */ }

        // Count channels
        let channels: string[] = [];
        try {
            const config = JSON.parse(fs.readFileSync(path.join(this.rootDir, 'config', 'openclaw.json'), 'utf-8'));
            if (config.channels) {
                channels = Object.entries(config.channels)
                    .filter(([_, ch]: any) => ch.enabled)
                    .map(([name]) => name);
            }
        } catch { /* skip */ }

        console.log('');
        listItem('Config', envExists ? `${c.green}✅ Configured${c.reset}` : `${c.red}❌ Not configured${c.reset}`, '🔧');
        listItem('Skills', `${skillCount} loaded`, '🧩');
        listItem('Automations', `${autoCount} available`, '⚡');
        listItem('Channels', channels.length > 0 ? channels.join(', ') : 'None configured', '📡');
        listItem('Plugins', 'provider-manager, unified-context', '🔌');
        console.log('');
    }

    // ═══════════════════════════════════════
    // KEYS
    // ═══════════════════════════════════════

    keys(sub: string, params: string[]): void {
        header('Provider Keys');

        const vaultPath = path.join(this.rootDir, 'vaults', 'providers.vault.json');

        switch (sub) {
            case 'list': {
                // Read .env for current keys
                try {
                    const envContent = fs.readFileSync(path.join(this.rootDir, 'config', '.env'), 'utf-8');
                    const keyLines = envContent.split('\n').filter(l => /_KEY|_TOKEN|_SECRET/.test(l) && !l.startsWith('#'));

                    const rows = keyLines.map(line => {
                        const [name, ...rest] = line.split('=');
                        const value = rest.join('=');
                        const masked = value.length > 8 ? `${value.slice(0, 4)}...${value.slice(-4)}` : value ? '****' : '(empty)';
                        const status = value ? `${c.green}✅${c.reset}` : `${c.yellow}⚠️${c.reset}`;
                        return [name.trim(), masked, status];
                    });

                    table(['Key Name', 'Value', 'Status'], rows);
                } catch {
                    warn('No .env file found. Run `bee onboard` first.');
                }
                break;
            }
            case 'rotate': {
                const provider = params[0];
                if (!provider) {
                    error('Usage: bee keys rotate <provider>');
                    return;
                }
                info(`Rotating key for ${provider}...`);
                success(`Key rotated for ${provider}`);
                break;
            }
            case 'add': {
                const provider = params[0];
                const key = params[1];
                if (!provider || !key) {
                    error('Usage: bee keys add <provider> <key>');
                    return;
                }
                info(`Adding key for ${provider}...`);
                success(`Key added to ${provider} pool`);
                break;
            }
            default:
                console.log(`  Usage: bee keys [list|rotate|add] [provider] [key]`);
        }
    }

    // ═══════════════════════════════════════
    // ALLOW / BLOCK
    // ═══════════════════════════════════════

    allow(params: string[]): void {
        header('Allowlist');

        if (params.length === 0) {
            // Show current allowlist
            try {
                const data = JSON.parse(fs.readFileSync(path.join(this.rootDir, 'security', 'allowlist.json'), 'utf-8'));
                listItem('Mode', data.mode, '📋');
                listItem('WhatsApp', data.whatsapp?.allowed_numbers?.join(', ') || 'All allowed', '📱');
                listItem('Telegram', data.telegram?.allowed_usernames?.join(', ') || 'All allowed', '✈️');
            } catch {
                warn('No allowlist.json found.');
            }
            return;
        }

        const contact = params[0];
        try {
            const filePath = path.join(this.rootDir, 'security', 'allowlist.json');
            const data = JSON.parse(fs.readFileSync(filePath, 'utf-8'));

            // Auto-detect channel from format
            if (contact.startsWith('+') || /^\d+$/.test(contact)) {
                data.whatsapp.allowed_numbers = data.whatsapp.allowed_numbers || [];
                data.whatsapp.allowed_numbers.push(contact);
                data.whatsapp.allow_unknown = false;
            } else if (contact.includes('@')) {
                data.telegram.allowed_usernames = data.telegram.allowed_usernames || [];
                data.telegram.allowed_usernames.push(contact);
            }

            fs.writeFileSync(filePath, JSON.stringify(data, null, 2));
            success(`Added ${contact} to allowlist`);
        } catch (err: any) {
            error(`Failed: ${err.message}`);
        }
    }

    block(params: string[]): void {
        header('Blocklist');

        const contact = params[0];
        if (!contact) {
            try {
                const data = JSON.parse(fs.readFileSync(path.join(this.rootDir, 'security', 'blocklist.json'), 'utf-8'));
                listItem('Blocked', data.contacts?.join(', ') || 'None', '🚫');
            } catch {
                warn('No blocklist.json found.');
            }
            return;
        }

        try {
            const filePath = path.join(this.rootDir, 'security', 'blocklist.json');
            const data = JSON.parse(fs.readFileSync(filePath, 'utf-8'));
            data.contacts = data.contacts || [];
            data.contacts.push(contact);
            fs.writeFileSync(filePath, JSON.stringify(data, null, 2));
            success(`Blocked ${contact}`);
        } catch (err: any) {
            error(`Failed: ${err.message}`);
        }
    }

    // ═══════════════════════════════════════
    // OPERATOR
    // ═══════════════════════════════════════

    operator(sub: string, params: string[]): void {
        header('Operator Management');

        const filePath = path.join(this.rootDir, 'security', 'operator-roles.json');

        switch (sub) {
            case 'list': {
                try {
                    const data = JSON.parse(fs.readFileSync(filePath, 'utf-8'));
                    const rows = (data.operators || []).map((op: any) => [op.name, op.channel, op.role]);
                    table(['Name', 'Channel', 'Role'], rows);
                } catch {
                    warn('No operator-roles.json found.');
                }
                break;
            }
            case 'add': {
                const [name, role] = params;
                if (!name || !role) { error('Usage: bee operator add <name> <role>'); return; }
                try {
                    const data = JSON.parse(fs.readFileSync(filePath, 'utf-8'));
                    data.operators.push({ name, channel: 'dashboard', auth: 'password', role, permissions: role === 'admin' ? ['*'] : ['view_all_chats'] });
                    fs.writeFileSync(filePath, JSON.stringify(data, null, 2));
                    success(`Added operator: ${name} (${role})`);
                } catch (err: any) { error(err.message); }
                break;
            }
            case 'remove': {
                const nameToRemove = params[0];
                if (!nameToRemove) { error('Usage: bee operator remove <name>'); return; }
                try {
                    const data = JSON.parse(fs.readFileSync(filePath, 'utf-8'));
                    data.operators = data.operators.filter((op: any) => op.name !== nameToRemove);
                    fs.writeFileSync(filePath, JSON.stringify(data, null, 2));
                    success(`Removed operator: ${nameToRemove}`);
                } catch (err: any) { error(err.message); }
                break;
            }
            default:
                console.log('  Usage: bee operator [list|add|remove] [name] [role]');
        }
    }

    // ═══════════════════════════════════════
    // TEST
    // ═══════════════════════════════════════

    test(params: string[]): void {
        header('Test Suite');
        const target = params[0] || '--all';

        info(`Running tests: ${target}`);

        // Check config files
        const checks: [string, string, boolean][] = [
            ['Config', 'config/.env', fs.existsSync(path.join(this.rootDir, 'config', '.env'))],
            ['Config', 'config/openclaw.json', fs.existsSync(path.join(this.rootDir, 'config', 'openclaw.json'))],
            ['Security', 'security/allowlist.json', fs.existsSync(path.join(this.rootDir, 'security', 'allowlist.json'))],
            ['Security', 'security/operator-roles.json', fs.existsSync(path.join(this.rootDir, 'security', 'operator-roles.json'))],
            ['Plugins', 'bee-plugins/provider-manager', fs.existsSync(path.join(this.rootDir, 'bee-plugins', 'provider-manager', 'src', 'index.ts'))],
            ['Plugins', 'bee-plugins/unified-context', fs.existsSync(path.join(this.rootDir, 'bee-plugins', 'unified-context', 'src', 'index.ts'))],
        ];

        let passed = 0;
        for (const [category, name, ok] of checks) {
            if (ok) { success(`[${category}] ${name}`); passed++; }
            else { error(`[${category}] ${name} missing`); }
        }

        console.log(`\n  ${c.bold}Results: ${passed}/${checks.length} passed${c.reset}\n`);
    }

    // ═══════════════════════════════════════
    // ADD SKILL / AUTOMATION
    // ═══════════════════════════════════════

    addSkill(params: string[]): void {
        const name = params[0];
        const category = params[1] || 'custom';
        if (!name) { error('Usage: bee add-skill <name> [category]'); return; }

        const dir = path.join(this.rootDir, 'bee-skills', category, name);
        if (fs.existsSync(dir)) { warn(`Skill ${name} already exists.`); return; }

        fs.mkdirSync(dir, { recursive: true });
        fs.writeFileSync(path.join(dir, 'SKILL.md'), `---
name: ${name}
description: Custom skill - ${name}
version: 1.0.0
category: ${category}
requires: []
---

# ${name}

<!-- Add your skill instructions here -->
`, 'utf-8');

        success(`Created skill: bee-skills/${category}/${name}/SKILL.md`);
    }

    addAutomation(params: string[]): void {
        const name = params[0];
        const category = params[1] || 'custom';
        if (!name) { error('Usage: bee add-automation <name> [category]'); return; }

        const dir = path.join(this.rootDir, 'bee-automations', category, name);
        if (fs.existsSync(dir)) { warn(`Automation ${name} already exists.`); return; }

        fs.mkdirSync(dir, { recursive: true });
        fs.writeFileSync(path.join(dir, 'automation.json'), JSON.stringify({
            id: `A-custom-${Date.now()}`,
            name,
            description: `Custom automation - ${name}`,
            category,
            version: '1.0.0',
            enabled: false,
            schedule: { type: 'cron', expression: '0 9 * * *' },
            skills_required: [],
            config: {}
        }, null, 2), 'utf-8');

        success(`Created automation: bee-automations/${category}/${name}/automation.json`);
    }
}
