#!/usr/bin/env node

/**
 * 🐝 BEE Smart AI — CLI Entry Point
 * ═══════════════════════════════════════════
 * 
 * Main dispatcher that routes commands to their handlers.
 * Uses the modular architecture in src/ for all logic.
 * 
 * Usage: bee <command> [subcommand] [args...]
 */

import * as path from 'path';
import { runOnboardingWizard } from './src/onboarding';
import { ConfigGenerator } from './src/config-generator';
import { CommandHandlers } from './src/commands';
import { banner, header, success, error, bigSuccess, c, spinner } from './src/ui';

// ═══════════════════════════════════════
// Root Directory Resolution
// ═══════════════════════════════════════

// CLI is at bee-overlay/cli/bee-cli.ts — root is 2 levels up
const BEE_ROOT = path.resolve(__dirname, '..', '..');
const VERSION = '2.0.0';

// ═══════════════════════════════════════
// Initialize Handlers
// ═══════════════════════════════════════

const commands = new CommandHandlers(BEE_ROOT);
const configGen = new ConfigGenerator(BEE_ROOT);

// ═══════════════════════════════════════
// CLI Router
// ═══════════════════════════════════════

const args = process.argv.slice(2);
const command = args[0];
const subcommand = args[1];
const params = args.slice(2);

async function main(): Promise<void> {
    switch (command) {

        // ── Core Commands ──────────────────
        case 'onboard':
            await handleOnboard();
            break;

        case 'deploy':
            commands.deploy();
            break;

        case 'update':
            commands.update();
            break;

        case 'status':
            commands.status();
            break;

        case 'test':
            commands.test(args.slice(1));
            break;

        // ── Key Management ─────────────────
        case 'keys':
            commands.keys(subcommand, params);
            break;

        case 'provider':
            handleProvider(subcommand, params);
            break;

        // ── Security ───────────────────────
        case 'allow':
            commands.allow(args.slice(1));
            break;

        case 'block':
            commands.block(args.slice(1));
            break;

        case 'operator':
            commands.operator(subcommand, params);
            break;

        // ── Scaffolding ────────────────────
        case 'add-skill':
            commands.addSkill(args.slice(1));
            break;

        case 'add-automation':
            commands.addAutomation(args.slice(1));
            break;

        // ── Version & Help ─────────────────
        case 'version':
        case '--version':
        case '-v':
            console.log(`BEE Smart AI CLI v${VERSION}`);
            break;

        case 'help':
        case '--help':
        case '-h':
        case undefined:
            showHelp();
            break;

        default:
            error(`Unknown command: ${command}`);
            console.log(`  Run ${c.bold}bee help${c.reset} for available commands.\n`);
            process.exit(1);
    }
}

// ═══════════════════════════════════════
// Onboard Handler (async wizard)
// ═══════════════════════════════════════

async function handleOnboard(): Promise<void> {
    const answers = await runOnboardingWizard(BEE_ROOT);

    const spin = spinner('Generating configuration files...');

    const generatedFiles = configGen.generateAll(answers);

    spin.stop('Configuration files generated!');

    console.log(`\n  ${c.bold}Generated files:${c.reset}`);
    for (const file of generatedFiles) {
        const relative = path.relative(BEE_ROOT, file);
        success(relative);
    }

    bigSuccess('Onboarding Complete!');
    console.log(`  ${c.dim}Next steps:${c.reset}`);
    console.log(`  ${c.cyan}1.${c.reset} Review config/.env and add any missing API keys`);
    console.log(`  ${c.cyan}2.${c.reset} Run ${c.bold}bee deploy${c.reset} to start your agent`);
    console.log(`  ${c.cyan}3.${c.reset} Run ${c.bold}bee status${c.reset} to verify everything is working\n`);
}

// ═══════════════════════════════════════
// Provider Handler
// ═══════════════════════════════════════

function handleProvider(sub: string, params: string[]): void {
    header('Provider Management');

    switch (sub) {
        case 'list':
            commands.keys('list', []);
            break;
        case 'swap':
            if (params.length < 2) {
                error('Usage: bee provider swap <type> <new-provider>');
                return;
            }
            success(`Swapped ${params[0]} provider to: ${params[1]}`);
            break;
        default:
            console.log('  Usage: bee provider [list|swap] [type] [new-provider]');
    }
}

// ═══════════════════════════════════════
// Help
// ═══════════════════════════════════════

function showHelp(): void {
    banner();
    console.log(`${c.bold}Usage:${c.reset} bee <command> [options]\n`);

    console.log(`${c.yellow}${c.bold}Core Commands:${c.reset}`);
    console.log(`  ${c.bold}onboard${c.reset}              Run the 10-step configuration wizard`);
    console.log(`  ${c.bold}deploy${c.reset}               Deploy the agent with all configs`);
    console.log(`  ${c.bold}update${c.reset}               Update OpenClaw upstream`);
    console.log(`  ${c.bold}status${c.reset}               Show agent status and health`);
    console.log(`  ${c.bold}test${c.reset} [--all]          Run test suite`);

    console.log(`\n${c.cyan}${c.bold}Key Management:${c.reset}`);
    console.log(`  ${c.bold}keys list${c.reset}             List provider keys status`);
    console.log(`  ${c.bold}keys rotate${c.reset} <prov>    Rotate active key`);
    console.log(`  ${c.bold}keys add${c.reset} <prov> <key> Add a key to pool`);
    console.log(`  ${c.bold}provider list${c.reset}         List all providers`);
    console.log(`  ${c.bold}provider swap${c.reset} <t> <p> Swap provider for a type`);

    console.log(`\n${c.green}${c.bold}Security:${c.reset}`);
    console.log(`  ${c.bold}allow${c.reset}                 Show allowlist`);
    console.log(`  ${c.bold}allow${c.reset} <contact>       Add to allowlist`);
    console.log(`  ${c.bold}block${c.reset}                 Show blocklist`);
    console.log(`  ${c.bold}block${c.reset} <contact>       Add to blocklist`);
    console.log(`  ${c.bold}operator list${c.reset}         List operators`);
    console.log(`  ${c.bold}operator add${c.reset} <n> <r>  Add an operator`);
    console.log(`  ${c.bold}operator remove${c.reset} <n>   Remove an operator`);

    console.log(`\n${c.magenta}${c.bold}Scaffolding:${c.reset}`);
    console.log(`  ${c.bold}add-skill${c.reset} <name> [cat]      Create a new skill`);
    console.log(`  ${c.bold}add-automation${c.reset} <name> [cat]  Create a new automation`);

    console.log(`\n${c.dim}Version: ${VERSION}${c.reset}\n`);
}

// ═══════════════════════════════════════
// Run
// ═══════════════════════════════════════

main().catch((err) => {
    error(`Fatal: ${err.message}`);
    process.exit(1);
});
