/**
 * BEE Smart AI — End-to-End Validation Test
 * Verifies that the scheduler can load all automations and find their workflows.
 */

import * as fs from 'fs';
import * as path from 'path';

const ROOT = path.resolve(__dirname, '..');

// ─── Test 1: All 20 automation.json files are valid
console.log('=== Test 1: Automation Configs ===');
const autoDir = path.join(ROOT, 'bee-automations');
const categories = fs.readdirSync(autoDir).filter(f =>
    fs.statSync(path.join(autoDir, f)).isDirectory()
);

let totalAutomations = 0;
let validAutomations = 0;
const errors: string[] = [];

for (const category of categories) {
    const catDir = path.join(autoDir, category);
    const entries = fs.readdirSync(catDir).filter(f =>
        fs.statSync(path.join(catDir, f)).isDirectory()
    );

    for (const entry of entries) {
        totalAutomations++;
        const configPath = path.join(catDir, entry, 'automation.json');
        const workflowPath = path.join(catDir, entry, 'AUTOMATION.md');

        // Check config
        if (!fs.existsSync(configPath)) {
            errors.push(`❌ Missing automation.json: ${entry}`);
            continue;
        }

        const config = JSON.parse(fs.readFileSync(configPath, 'utf-8'));

        if (!config.skills_required || config.skills_required.length === 0) {
            errors.push(`❌ Empty skills_required: ${entry}`);
            continue;
        }

        // Check workflow
        if (!fs.existsSync(workflowPath)) {
            errors.push(`❌ Missing AUTOMATION.md: ${entry}`);
            continue;
        }

        const workflowContent = fs.readFileSync(workflowPath, 'utf-8');
        if (workflowContent.length < 100) {
            errors.push(`⚠️ AUTOMATION.md too short: ${entry} (${workflowContent.length} chars)`);
            continue;
        }

        // Verify skill references exist
        for (const skill of config.skills_required) {
            const skillDirs = fs.readdirSync(path.join(ROOT, 'bee-skills'));
            let found = false;
            for (const sDir of skillDirs) {
                const skillPath = path.join(ROOT, 'bee-skills', sDir, skill, 'SKILL.md');
                if (fs.existsSync(skillPath)) {
                    found = true;
                    break;
                }
            }
            if (!found) {
                errors.push(`⚠️ ${entry}: skill "${skill}" not found in bee-skills`);
            }
        }

        validAutomations++;
        console.log(`  ✅ ${config.id} ${config.name} — ${config.skills_required.length} skills, tier: ${config.tier_minimum}`);
    }
}

console.log(`\nResult: ${validAutomations}/${totalAutomations} valid automations`);

// ─── Test 2: All 58 SKILL.md files are complete
console.log('\n=== Test 2: Skills ===');
const skillsDir = path.join(ROOT, 'bee-skills');
const skillCategories = fs.readdirSync(skillsDir).filter(f =>
    fs.statSync(path.join(skillsDir, f)).isDirectory()
);

let totalSkills = 0;
let validSkills = 0;

for (const category of skillCategories) {
    const catDir = path.join(skillsDir, category);
    const entries = fs.readdirSync(catDir).filter(f =>
        fs.statSync(path.join(catDir, f)).isDirectory()
    );

    for (const entry of entries) {
        totalSkills++;
        const skillPath = path.join(catDir, entry, 'SKILL.md');
        if (!fs.existsSync(skillPath)) {
            errors.push(`❌ Missing SKILL.md: ${category}/${entry}`);
            continue;
        }

        const content = fs.readFileSync(skillPath, 'utf-8');
        if (content.includes('<!-- TODO')) {
            errors.push(`❌ TODO placeholder: ${category}/${entry}`);
            continue;
        }

        const lines = content.split('\n').length;
        if (lines < 40) {
            errors.push(`⚠️ ${category}/${entry}: only ${lines} lines`);
            continue;
        }

        validSkills++;
    }
}

console.log(`Result: ${validSkills}/${totalSkills} valid skills`);

// ─── Test 3: System prompt and env template
console.log('\n=== Test 3: Config Files ===');
const systemPrompt = fs.readFileSync(path.join(ROOT, 'config', 'system-prompt.md'), 'utf-8');
const envTemplate = fs.readFileSync(path.join(ROOT, 'config', '.env.template'), 'utf-8');

console.log(`  system-prompt.md: ${systemPrompt.split('\n').length} lines`);
console.log(`  .env.template: ${envTemplate.split('\n').length} lines`);

// Check system prompt references skills
const skillsInPrompt = systemPrompt.match(/`[\w-]+`/g)?.length || 0;
console.log(`  Skills referenced in system prompt: ${skillsInPrompt}`);

// ─── Summary
console.log('\n=== SUMMARY ===');
console.log(`Skills: ${validSkills}/${totalSkills}`);
console.log(`Automations: ${validAutomations}/${totalAutomations}`);

if (errors.length > 0) {
    console.log(`\n⚠️ ${errors.length} issues:`);
    errors.forEach(e => console.log(`  ${e}`));
} else {
    console.log('\n✅ All checks passed!');
}

process.exit(errors.length > 0 ? 1 : 0);
