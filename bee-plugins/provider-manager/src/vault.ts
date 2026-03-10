/**
 * BEE Smart AI — Vault Manager
 * Handles encrypted storage and retrieval of provider API keys.
 * 
 * Uses AES-256-GCM for encryption at rest.
 * The vault file (providers.vault.json) stores encrypted provider configs.
 */

import * as crypto from 'crypto';
import * as fs from 'fs';
import * as path from 'path';
import { VaultData, ProviderConfig } from './types';

const ALGORITHM = 'aes-256-gcm';
const IV_LENGTH = 16;
const SALT_LENGTH = 64;
const TAG_LENGTH = 16;
const KEY_LENGTH = 32;
const ITERATIONS = 100000;

export class VaultManager {
    private vaultPath: string;
    private passphrase: string;

    constructor(vaultPath: string, passphrase: string) {
        this.vaultPath = vaultPath;
        this.passphrase = passphrase;
    }

    // ═══════════════════════════════════════
    // Core Operations
    // ═══════════════════════════════════════

    /**
     * Load and decrypt providers from vault file
     */
    load(): ProviderConfig[] {
        if (!fs.existsSync(this.vaultPath)) {
            return [];
        }

        try {
            const raw = fs.readFileSync(this.vaultPath, 'utf-8');
            const envelope = JSON.parse(raw);

            if (envelope.encrypted) {
                const decrypted = this.decrypt(envelope.data);
                const vaultData: VaultData = JSON.parse(decrypted);
                return vaultData.providers;
            } else {
                // Plain JSON (development mode)
                return envelope.providers || [];
            }
        } catch (err: any) {
            console.error(`[VaultManager] Failed to load vault: ${err.message}`);
            return [];
        }
    }

    /**
     * Encrypt and save providers to vault file
     */
    save(providers: ProviderConfig[]): void {
        const vaultData: VaultData = {
            version: '1.0.0',
            encryptedAt: new Date().toISOString(),
            providers
        };

        const plaintext = JSON.stringify(vaultData, null, 2);
        const encrypted = this.encrypt(plaintext);

        const envelope = {
            encrypted: true,
            algorithm: ALGORITHM,
            data: encrypted,
            savedAt: new Date().toISOString()
        };

        // Ensure directory exists
        const dir = path.dirname(this.vaultPath);
        if (!fs.existsSync(dir)) {
            fs.mkdirSync(dir, { recursive: true });
        }

        fs.writeFileSync(this.vaultPath, JSON.stringify(envelope, null, 2), 'utf-8');

        // Set restrictive permissions (owner-only)
        try {
            fs.chmodSync(this.vaultPath, 0o600);
        } catch {
            // chmod may not work on Windows, silently skip
        }
    }

    // ═══════════════════════════════════════
    // Encryption Helpers
    // ═══════════════════════════════════════

    private deriveKey(salt: Buffer): Buffer {
        return crypto.pbkdf2Sync(this.passphrase, salt, ITERATIONS, KEY_LENGTH, 'sha512');
    }

    private encrypt(plaintext: string): string {
        const salt = crypto.randomBytes(SALT_LENGTH);
        const iv = crypto.randomBytes(IV_LENGTH);
        const key = this.deriveKey(salt);

        const cipher = crypto.createCipheriv(ALGORITHM, key, iv);
        const encrypted = Buffer.concat([cipher.update(plaintext, 'utf-8'), cipher.final()]);
        const tag = cipher.getAuthTag();

        // Format: salt:iv:tag:ciphertext (all base64)
        return [
            salt.toString('base64'),
            iv.toString('base64'),
            tag.toString('base64'),
            encrypted.toString('base64')
        ].join(':');
    }

    private decrypt(data: string): string {
        const parts = data.split(':');
        if (parts.length !== 4) {
            throw new Error('Invalid vault data format');
        }

        const salt = Buffer.from(parts[0], 'base64');
        const iv = Buffer.from(parts[1], 'base64');
        const tag = Buffer.from(parts[2], 'base64');
        const ciphertext = Buffer.from(parts[3], 'base64');

        const key = this.deriveKey(salt);
        const decipher = crypto.createDecipheriv(ALGORITHM, key, iv);
        decipher.setAuthTag(tag);

        const decrypted = Buffer.concat([decipher.update(ciphertext), decipher.final()]);
        return decrypted.toString('utf-8');
    }

    // ═══════════════════════════════════════
    // Utility
    // ═══════════════════════════════════════

    /**
     * Check if vault file exists
     */
    exists(): boolean {
        return fs.existsSync(this.vaultPath);
    }

    /**
     * Export vault as unencrypted JSON (for backup, HANDLE WITH CARE)
     */
    exportPlain(outputPath: string): void {
        const providers = this.load();
        fs.writeFileSync(outputPath, JSON.stringify({ providers }, null, 2), 'utf-8');
    }

    /**
     * Import from unencrypted JSON and save encrypted
     */
    importPlain(inputPath: string): void {
        const raw = fs.readFileSync(inputPath, 'utf-8');
        const data = JSON.parse(raw);
        this.save(data.providers || []);
    }

    /**
     * Mask a key for display (show first 4 and last 4 chars)
     */
    static maskKey(key: string): string {
        if (key.length <= 8) return '****';
        return `${key.slice(0, 4)}...${key.slice(-4)}`;
    }
}
