/**
 * BEE Smart AI — CLI UI Utilities
 * Terminal formatting, colors, prompts, and visual helpers.
 * Uses only Node.js built-in modules (no external dependencies).
 */

import * as readline from 'readline';

// ═══════════════════════════════════════
// ANSI Colors
// ═══════════════════════════════════════

export const c = {
    reset: '\x1b[0m',
    bold: '\x1b[1m',
    dim: '\x1b[2m',
    yellow: '\x1b[33m',
    green: '\x1b[32m',
    red: '\x1b[31m',
    cyan: '\x1b[36m',
    magenta: '\x1b[35m',
    blue: '\x1b[34m',
    white: '\x1b[37m',
    bgYellow: '\x1b[43m',
    bgGreen: '\x1b[42m',
    bgRed: '\x1b[41m',
    bgCyan: '\x1b[46m',
};

// ═══════════════════════════════════════
// Display Helpers
// ═══════════════════════════════════════

export function banner(): void {
    console.log(`
${c.yellow}${c.bold}
    ██████╗ ███████╗███████╗
    ██╔══██╗██╔════╝██╔════╝
    ██████╔╝█████╗  █████╗
    ██╔══██╗██╔══╝  ██╔══╝
    ██████╔╝███████╗███████╗
    ╚═════╝ ╚══════╝╚══════╝
    ${c.cyan}Smart AI${c.reset} ${c.dim}v2.0.0${c.reset}
  `);
}

export function header(title: string): void {
    const line = '━'.repeat(Math.max(40, title.length + 4));
    console.log(`\n${c.yellow}${c.bold}🐝 ${title}${c.reset}`);
    console.log(`${c.dim}${line}${c.reset}`);
}

export function stepHeader(current: number, total: number, title: string): void {
    const progress = '█'.repeat(current) + '░'.repeat(total - current);
    console.log(`\n${c.cyan}${c.bold}[${current}/${total}]${c.reset} ${c.bold}${title}${c.reset}`);
    console.log(`${c.dim}  ${progress}${c.reset}\n`);
}

export function success(msg: string): void {
    console.log(`${c.green}  ✅ ${msg}${c.reset}`);
}

export function error(msg: string): void {
    console.log(`${c.red}  ❌ ${msg}${c.reset}`);
}

export function warn(msg: string): void {
    console.log(`${c.yellow}  ⚠️  ${msg}${c.reset}`);
}

export function info(msg: string): void {
    console.log(`${c.cyan}  ℹ  ${msg}${c.reset}`);
}

export function listItem(label: string, value: string, icon: string = '•'): void {
    console.log(`  ${icon} ${c.bold}${label}${c.reset}: ${value}`);
}

export function table(headers: string[], rows: string[][]): void {
    const colWidths = headers.map((h, i) =>
        Math.max(h.length, ...rows.map(r => (r[i] || '').length)) + 2
    );

    const headerLine = headers.map((h, i) => h.padEnd(colWidths[i])).join('');
    const separator = colWidths.map(w => '─'.repeat(w)).join('');

    console.log(`  ${c.bold}${headerLine}${c.reset}`);
    console.log(`  ${c.dim}${separator}${c.reset}`);
    for (const row of rows) {
        console.log(`  ${row.map((cell, i) => cell.padEnd(colWidths[i])).join('')}`);
    }
}

export function bigSuccess(msg: string): void {
    const border = '★━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━★';
    console.log(`\n${c.green}${c.bold}`);
    console.log(border);
    console.log(`│  🐝 ${msg.padEnd(35)}│`);
    console.log(border);
    console.log(c.reset);
}

// ═══════════════════════════════════════
// Interactive Prompts
// ═══════════════════════════════════════

function createRl(): readline.Interface {
    return readline.createInterface({ input: process.stdin, output: process.stdout });
}

export async function ask(question: string, defaultValue?: string): Promise<string> {
    const rl = createRl();
    const suffix = defaultValue ? ` ${c.dim}(${defaultValue})${c.reset}` : '';
    return new Promise((resolve) => {
        rl.question(`  ${c.cyan}?${c.reset} ${question}${suffix}: `, (answer) => {
            rl.close();
            resolve(answer.trim() || defaultValue || '');
        });
    });
}

export async function askPassword(question: string): Promise<string> {
    const rl = createRl();
    return new Promise((resolve) => {
        rl.question(`  ${c.cyan}🔒${c.reset} ${question}: `, (answer) => {
            rl.close();
            resolve(answer.trim());
        });
    });
}

export async function askSelect(question: string, options: string[]): Promise<string> {
    console.log(`\n  ${c.cyan}?${c.reset} ${question}`);
    options.forEach((opt, i) => {
        console.log(`    ${c.dim}${i + 1}.${c.reset} ${opt}`);
    });

    const rl = createRl();
    return new Promise((resolve) => {
        rl.question(`  ${c.dim}Selecciona (1-${options.length}):${c.reset} `, (answer) => {
            rl.close();
            const idx = parseInt(answer.trim(), 10) - 1;
            resolve(options[Math.max(0, Math.min(idx, options.length - 1))]);
        });
    });
}

export async function askToggle(question: string, defaultValue: boolean = false): Promise<boolean> {
    const hint = defaultValue ? 'S/n' : 's/N';
    const rl = createRl();
    return new Promise((resolve) => {
        rl.question(`  ${c.cyan}?${c.reset} ${question} (${hint}): `, (answer) => {
            rl.close();
            const trimmed = answer.trim().toLowerCase();
            if (trimmed === '') resolve(defaultValue);
            else resolve(trimmed === 's' || trimmed === 'si' || trimmed === 'y' || trimmed === 'yes');
        });
    });
}

export async function askMultiSelect(question: string, options: { label: string; id: string; selected?: boolean }[]): Promise<string[]> {
    console.log(`\n  ${c.cyan}?${c.reset} ${question} ${c.dim}(números separados por coma)${c.reset}`);
    options.forEach((opt, i) => {
        const check = opt.selected ? `${c.green}✔${c.reset}` : ' ';
        console.log(`    [${check}] ${c.dim}${i + 1}.${c.reset} ${opt.label}`);
    });

    const rl = createRl();
    return new Promise((resolve) => {
        rl.question(`  ${c.dim}Selecciona:${c.reset} `, (answer) => {
            rl.close();
            const indices = answer.split(',').map(s => parseInt(s.trim(), 10) - 1).filter(n => !isNaN(n));
            const selected = indices.map(i => options[i]?.id).filter(Boolean);
            // Also include pre-selected
            const preSelected = options.filter(o => o.selected).map(o => o.id);
            resolve([...new Set([...preSelected, ...selected])]);
        });
    });
}

export async function askTextarea(question: string): Promise<string> {
    console.log(`  ${c.cyan}?${c.reset} ${question} ${c.dim}(escribe líneas, termina con línea vacía)${c.reset}`);
    const rl = createRl();
    const lines: string[] = [];

    return new Promise((resolve) => {
        rl.on('line', (line) => {
            if (line.trim() === '') {
                rl.close();
                resolve(lines.join('\n'));
            } else {
                lines.push(line);
            }
        });
    });
}

export function spinner(msg: string): { stop: (finalMsg?: string) => void } {
    const frames = ['⠋', '⠙', '⠹', '⠸', '⠼', '⠴', '⠦', '⠧', '⠇', '⠏'];
    let i = 0;
    const interval = setInterval(() => {
        process.stdout.write(`\r  ${c.cyan}${frames[i % frames.length]}${c.reset} ${msg}`);
        i++;
    }, 80);

    return {
        stop: (finalMsg?: string) => {
            clearInterval(interval);
            process.stdout.write(`\r  ${c.green}✅${c.reset} ${finalMsg || msg}\n`);
        }
    };
}
