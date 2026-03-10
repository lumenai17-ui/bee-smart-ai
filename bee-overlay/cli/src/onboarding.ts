/**
 * BEE Smart AI — Interactive Onboarding Wizard
 * Walks the operator through 10 steps to fully configure the agent.
 * Produces OnboardingAnswers that feed into ConfigGenerator.
 */

import * as fs from 'fs';
import * as path from 'path';
import { OnboardingAnswers } from './config-generator';
import {
    banner, header, stepHeader, success, warn, info,
    ask, askPassword, askSelect, askToggle, askMultiSelect, askTextarea,
    c
} from './ui';

export async function runOnboardingWizard(rootDir: string): Promise<OnboardingAnswers> {
    banner();
    header('Onboarding Wizard — Configuración Completa');
    console.log(`  ${c.dim}Este asistente te guiará para configurar tu agente BEE Smart AI.${c.reset}\n`);

    const answers: Partial<OnboardingAnswers> = {};

    // ── Step 1: Welcome ─────────────────────
    stepHeader(1, 10, 'Bienvenido a BEE Smart AI');
    console.log(`  BEE Smart AI convierte tu negocio en un ${c.bold}empleado digital${c.reset}`);
    console.log(`  con 58 habilidades y 20 automatizaciones integradas.\n`);

    answers.tier = await askSelect('¿Qué plan deseas?', ['basic ($25/mes)', 'pro ($40/mes)', 'max ($100/mes)']) as any;
    answers.tier = answers.tier!.split(' ')[0] as 'basic' | 'pro' | 'max';
    success(`Plan seleccionado: ${answers.tier}`);

    // ── Step 2: Business Identity ───────────
    stepHeader(2, 10, 'Identidad del Negocio');

    answers.businessName = await ask('Nombre del negocio');
    answers.businessType = await askSelect('Tipo de negocio', [
        'Restaurante', 'Hotel', 'Tienda', 'Servicios',
        'Salud/Fitness', 'Educación', 'Inmobiliaria', 'E-commerce', 'Otro'
    ]);
    answers.businessAddress = await ask('Dirección');
    answers.businessHours = await ask('Horario de operación', 'Lun-Vie 9am-6pm');
    answers.businessPhone = await ask('Teléfono de contacto');
    answers.businessEmail = await ask('Email de contacto');

    success(`Negocio: ${answers.businessName} (${answers.businessType})`);

    // ── Step 3: Branding ────────────────────
    stepHeader(3, 10, 'Marca y Personalidad');

    answers.tone = await askSelect('Tono de comunicación', [
        'Formal', 'Amigable', 'Profesional', 'Casual', 'Entusiasta'
    ]);
    answers.colorPrimary = await ask('Color primario (hex)', '#FFD700');
    answers.colorSecondary = await ask('Color secundario (hex)', '#1a1a2e');
    answers.colorAccent = await ask('Color acento (hex)', '#00d4ff');
    answers.phrasesToUse = await ask('Frases que el agente DEBE usar (separadas por ;)', '');
    answers.phrasesToAvoid = await ask('Frases que el agente NUNCA debe usar (separadas por ;)', '');

    success(`Tono: ${answers.tone}`);

    // ── Step 4: Channels ────────────────────
    stepHeader(4, 10, 'Canales de Comunicación');

    answers.whatsappEnabled = await askToggle('¿Habilitar WhatsApp?', true);
    if (answers.whatsappEnabled) {
        answers.whatsappPhoneId = await ask('WhatsApp Phone ID');
        answers.whatsappAccessToken = await askPassword('WhatsApp Access Token');
        const allowStr = await ask('Números permitidos (separados por coma, o vacío para todos)', '');
        answers.whatsappAllowlist = allowStr ? allowStr.split(',').map(s => s.trim()) : [];
    } else {
        answers.whatsappPhoneId = '';
        answers.whatsappAccessToken = '';
        answers.whatsappAllowlist = [];
    }

    answers.telegramEnabled = await askToggle('¿Habilitar Telegram?', false);
    if (answers.telegramEnabled) {
        answers.telegramBotToken = await askPassword('Telegram Bot Token');
    } else {
        answers.telegramBotToken = '';
    }

    answers.discordEnabled = await askToggle('¿Habilitar Discord?', false);
    if (answers.discordEnabled) {
        answers.discordBotToken = await askPassword('Discord Bot Token');
    } else {
        answers.discordBotToken = '';
    }

    answers.emailEnabled = await askToggle('¿Habilitar Email?', false);
    if (answers.emailEnabled) {
        answers.smtpHost = await ask('SMTP Host', 'smtp.gmail.com');
        answers.smtpUser = await ask('SMTP Usuario');
        answers.smtpPass = await askPassword('SMTP Contraseña');
    } else {
        answers.smtpHost = '';
        answers.smtpUser = '';
        answers.smtpPass = '';
    }

    // Operators
    info('Ahora define los operadores que administrarán al agente.');
    const operators: { name: string; channel: string; role: string }[] = [];
    let addMore = true;
    while (addMore) {
        const opName = await ask('Nombre del operador');
        const opChannel = await askSelect('Canal principal del operador', ['dashboard', 'whatsapp', 'telegram', 'discord']);
        const opRole = await askSelect('Rol', ['admin', 'manager', 'operator', 'viewer']);
        operators.push({ name: opName, channel: opChannel, role: opRole });
        success(`Operador: ${opName} (${opRole})`);
        addMore = await askToggle('¿Agregar otro operador?', false);
    }
    answers.operatorContacts = operators;

    const enabledChannels = [
        answers.whatsappEnabled && 'WhatsApp',
        answers.telegramEnabled && 'Telegram',
        answers.discordEnabled && 'Discord',
        answers.emailEnabled && 'Email'
    ].filter(Boolean);
    success(`Canales: ${enabledChannels.join(', ') || 'Ninguno (solo Dashboard)'}`);

    // ── Step 5: Google APIs ─────────────────
    stepHeader(5, 10, 'Google APIs');

    if (answers.tier === 'basic') {
        warn('Google APIs requieren plan Pro o Max. Saltando...');
        answers.googleEnabled = false;
        answers.googleClientId = '';
        answers.googleClientSecret = '';
    } else {
        answers.googleEnabled = await askToggle('¿Habilitar Google APIs (Calendar, Sheets, Maps)?', true);
        if (answers.googleEnabled) {
            answers.googleClientId = await ask('Google Client ID');
            answers.googleClientSecret = await askPassword('Google Client Secret');
        } else {
            answers.googleClientId = '';
            answers.googleClientSecret = '';
        }
    }

    // ── Step 6: Integrations ────────────────
    stepHeader(6, 10, 'Integraciones');

    answers.wordpressEnabled = await askToggle('¿Conectar WordPress?', false);
    if (answers.wordpressEnabled) {
        answers.wordpressUrl = await ask('URL de WordPress');
        answers.wordpressAppPassword = await askPassword('WordPress App Password');
    } else {
        answers.wordpressUrl = '';
        answers.wordpressAppPassword = '';
    }

    answers.metaAdsEnabled = await askToggle('¿Conectar Meta Ads?', false);
    if (answers.metaAdsEnabled) {
        answers.metaAdsToken = await askPassword('Meta Ads Access Token');
    } else {
        answers.metaAdsToken = '';
    }

    answers.stripeEnabled = await askToggle('¿Conectar Stripe (pagos)?', false);
    if (answers.stripeEnabled) {
        answers.stripeSecretKey = await askPassword('Stripe Secret Key');
    } else {
        answers.stripeSecretKey = '';
    }

    // ── Step 7: Automations ─────────────────
    stepHeader(7, 10, 'Automatizaciones');

    // Load context mapping for business type
    const mappingPath = path.join(rootDir, 'bee-overlay', 'onboarding', 'context-mapping.json');
    let defaultAutomations: string[] = [];
    let suggestedAutomations: string[] = [];
    let automationIndex: Record<string, { name: string; category: string }> = {};

    try {
        const mapping = JSON.parse(fs.readFileSync(mappingPath, 'utf-8'));
        const typeMapping = mapping.mappings[answers.businessType!] || mapping.mappings['Otro'];
        defaultAutomations = typeMapping.default || [];
        suggestedAutomations = typeMapping.suggested || [];
        automationIndex = mapping.automationIndex || {};
    } catch { /* Use empty lists */ }

    const allAutomations = Object.entries(automationIndex).map(([id, info]) => ({
        id,
        label: `${id} — ${info.name} (${info.category})`,
        selected: defaultAutomations.includes(id)
    }));

    if (allAutomations.length > 0) {
        info(`Automatizaciones recomendadas para ${answers.businessType} ya pre-seleccionadas.`);
        answers.automationsSelected = await askMultiSelect(
            'Selecciona automatizaciones adicionales',
            allAutomations
        );
    } else {
        answers.automationsSelected = [];
    }

    const maxAuto = answers.tier === 'basic' ? 3 : answers.tier === 'pro' ? 10 : 20;
    if (answers.automationsSelected.length > maxAuto) {
        warn(`Tu plan ${answers.tier} permite máximo ${maxAuto}. Se seleccionaron las primeras ${maxAuto}.`);
        answers.automationsSelected = answers.automationsSelected.slice(0, maxAuto);
    }

    success(`${answers.automationsSelected.length} automatizaciones seleccionadas`);

    // ── Step 8: Knowledge Base ──────────────
    stepHeader(8, 10, 'Base de Conocimiento');

    info('Proporciona URLs o instrucciones para enseñarle a BEE sobre tu negocio.');
    const urlsStr = await ask('URLs para extraer info (separadas por coma)', '');
    answers.scrapeUrls = urlsStr ? urlsStr.split(',').map(s => s.trim()) : [];

    answers.specialInstructions = await ask('Instrucciones especiales para el agente', '');

    // ── Step 9: Billing ─────────────────────
    stepHeader(9, 10, 'Facturación');

    answers.fiscalName = await ask('Razón social', answers.businessName);
    answers.taxId = await ask('RFC / Tax ID');
    answers.currency = await askSelect('Moneda', ['MXN', 'USD', 'EUR', 'COP']);
    answers.taxRate = parseFloat(await ask('Tasa de impuesto (%)', '16'));

    // ── Step 10: Review ─────────────────────
    stepHeader(10, 10, 'Revisión y Generación');

    console.log(`  ${c.bold}Resumen de configuración:${c.reset}\n`);
    console.log(`  ${c.bold}Negocio${c.reset}:     ${answers.businessName} (${answers.businessType})`);
    console.log(`  ${c.bold}Plan${c.reset}:        ${answers.tier}`);
    console.log(`  ${c.bold}Tono${c.reset}:        ${answers.tone}`);
    console.log(`  ${c.bold}Canales${c.reset}:     ${enabledChannels.join(', ') || 'Solo Dashboard'}`);
    console.log(`  ${c.bold}Operadores${c.reset}:  ${answers.operatorContacts!.map(o => `${o.name} (${o.role})`).join(', ')}`);
    console.log(`  ${c.bold}Automations${c.reset}: ${answers.automationsSelected!.length} activas`);
    console.log(`  ${c.bold}Google${c.reset}:      ${answers.googleEnabled ? 'Sí' : 'No'}`);
    console.log(`  ${c.bold}WordPress${c.reset}:   ${answers.wordpressEnabled ? 'Sí' : 'No'}`);
    console.log(`  ${c.bold}Meta Ads${c.reset}:    ${answers.metaAdsEnabled ? 'Sí' : 'No'}`);
    console.log(`  ${c.bold}Stripe${c.reset}:      ${answers.stripeEnabled ? 'Sí' : 'No'}`);
    console.log('');

    const proceed = await askToggle('¿Generar archivos de configuración?', true);
    if (!proceed) {
        warn('Onboarding cancelado. Puedes ejecutar `bee onboard` de nuevo.');
        process.exit(0);
    }

    return answers as OnboardingAnswers;
}
