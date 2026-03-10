/**
 * BEE Smart AI — SQLite Database Layer
 * Provides the persistence layer for contact records and messages.
 * Uses better-sqlite3 for synchronous, fast access.
 */

import Database from 'better-sqlite3';
import * as path from 'path';
import * as fs from 'fs';
import { Contact, Message, MessageRole, ContactMetadata } from './types';

export class ContactDatabase {
    private db: Database.Database;

    constructor(dbPath: string) {
        // Ensure directory exists
        const dir = path.dirname(dbPath);
        if (!fs.existsSync(dir)) {
            fs.mkdirSync(dir, { recursive: true });
        }

        this.db = new Database(dbPath);
        this.db.pragma('journal_mode = WAL');
        this.db.pragma('foreign_keys = ON');
        this.initialize();
    }

    // ═══════════════════════════════════════
    // Schema Initialization
    // ═══════════════════════════════════════

    private initialize(): void {
        this.db.exec(`
      CREATE TABLE IF NOT EXISTS contacts (
        contact_id     TEXT PRIMARY KEY,
        phone          TEXT,
        email          TEXT,
        username       TEXT,
        display_name   TEXT NOT NULL DEFAULT 'Unknown',
        first_seen     TEXT NOT NULL,
        last_interaction TEXT NOT NULL,
        channels_used  TEXT NOT NULL DEFAULT '[]',
        preferred_channel TEXT DEFAULT '',
        language       TEXT DEFAULT 'es',
        current_topic  TEXT DEFAULT '',
        summary        TEXT DEFAULT '',
        intent_history TEXT DEFAULT '[]',
        handoff_status TEXT DEFAULT 'agent',
        handoff_operator TEXT,
        satisfaction_score REAL DEFAULT 0,
        tags           TEXT DEFAULT '[]',
        custom_fields  TEXT DEFAULT '{}',
        total_interactions INTEGER DEFAULT 0
      );

      CREATE TABLE IF NOT EXISTS messages (
        id         INTEGER PRIMARY KEY AUTOINCREMENT,
        contact_id TEXT NOT NULL,
        role       TEXT NOT NULL CHECK(role IN ('customer', 'agent', 'operator')),
        channel    TEXT NOT NULL,
        text       TEXT NOT NULL,
        timestamp  TEXT NOT NULL,
        metadata   TEXT DEFAULT '{}',
        FOREIGN KEY (contact_id) REFERENCES contacts(contact_id) ON DELETE CASCADE
      );

      CREATE INDEX IF NOT EXISTS idx_messages_contact ON messages(contact_id);
      CREATE INDEX IF NOT EXISTS idx_messages_timestamp ON messages(timestamp);
      CREATE INDEX IF NOT EXISTS idx_contacts_phone ON contacts(phone);
      CREATE INDEX IF NOT EXISTS idx_contacts_email ON contacts(email);
      CREATE INDEX IF NOT EXISTS idx_contacts_last ON contacts(last_interaction);
    `);
    }

    // ═══════════════════════════════════════
    // Contact CRUD
    // ═══════════════════════════════════════

    findByPhone(phone: string): Contact | null {
        const row = this.db.prepare('SELECT * FROM contacts WHERE phone = ?').get(phone) as any;
        return row ? this.rowToContact(row) : null;
    }

    findByEmail(email: string): Contact | null {
        const row = this.db.prepare('SELECT * FROM contacts WHERE email = ?').get(email) as any;
        return row ? this.rowToContact(row) : null;
    }

    findByUsername(channel: string, username: string): Contact | null {
        const escapedChannel = this.escapeLike(channel);
        const row = this.db.prepare('SELECT * FROM contacts WHERE username = ? AND channels_used LIKE ?').get(username, `%${escapedChannel}%`) as any;
        return row ? this.rowToContact(row) : null;
    }

    findById(contactId: string): Contact | null {
        const row = this.db.prepare('SELECT * FROM contacts WHERE contact_id = ?').get(contactId) as any;
        return row ? this.rowToContact(row) : null;
    }

    createContact(contact: Contact): void {
        this.db.prepare(`
      INSERT INTO contacts (contact_id, phone, email, username, display_name, first_seen, last_interaction, channels_used, preferred_channel, language)
      VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
    `).run(
            contact.contactId, contact.phone, contact.email, contact.username,
            contact.displayName, contact.firstSeen, contact.lastInteraction,
            JSON.stringify(contact.channelsUsed), contact.preferredChannel, contact.language
        );
    }

    private static readonly ALLOWED_COLUMNS = new Set([
        'phone', 'email', 'username', 'display_name', 'first_seen',
        'last_interaction', 'channels_used', 'preferred_channel', 'language',
        'current_topic', 'summary', 'intent_history', 'handoff_status',
        'handoff_operator', 'satisfaction_score', 'tags', 'custom_fields',
        'total_interactions'
    ]);

    updateContact(contactId: string, updates: Partial<Record<string, any>>): void {
        const fields: string[] = [];
        const values: any[] = [];

        for (const [key, value] of Object.entries(updates)) {
            const col = this.camelToSnake(key);
            if (!ContactDatabase.ALLOWED_COLUMNS.has(col)) continue; // Skip unknown columns
            fields.push(`${col} = ?`);
            values.push(typeof value === 'object' ? JSON.stringify(value) : value);
        }

        if (fields.length === 0) return;
        values.push(contactId);

        this.db.prepare(`UPDATE contacts SET ${fields.join(', ')} WHERE contact_id = ?`).run(...values);
    }

    private static readonly ALLOWED_ORDER_BY = new Set([
        'last_interaction', 'display_name', 'first_seen', 'total_interactions', 'satisfaction_score'
    ]);

    listContacts(page: number = 1, pageSize: number = 50, orderBy: string = 'last_interaction'): { contacts: Contact[], total: number } {
        const safeOrder = ContactDatabase.ALLOWED_ORDER_BY.has(orderBy) ? orderBy : 'last_interaction';
        const safePageSize = Math.min(Math.max(1, pageSize), 200);
        const total = (this.db.prepare('SELECT COUNT(*) as count FROM contacts').get() as any).count;
        const offset = (page - 1) * safePageSize;
        const rows = this.db.prepare(`SELECT * FROM contacts ORDER BY ${safeOrder} DESC LIMIT ? OFFSET ?`).all(safePageSize, offset) as any[];
        return { contacts: rows.map(r => this.rowToContact(r)), total };
    }

    searchContacts(query: string): Contact[] {
        const escaped = this.escapeLike(query);
        const rows = this.db.prepare(`
      SELECT * FROM contacts
      WHERE display_name LIKE ? OR phone LIKE ? OR email LIKE ? OR summary LIKE ?
      ORDER BY last_interaction DESC LIMIT 20
    `).all(`%${escaped}%`, `%${escaped}%`, `%${escaped}%`, `%${escaped}%`) as any[];
        return rows.map(r => this.rowToContact(r));
    }

    // ═══════════════════════════════════════
    // Message Operations
    // ═══════════════════════════════════════

    addMessage(msg: Omit<Message, 'id'>): number {
        const result = this.db.prepare(`
      INSERT INTO messages (contact_id, role, channel, text, timestamp, metadata)
      VALUES (?, ?, ?, ?, ?, ?)
    `).run(msg.contactId, msg.role, msg.channel, msg.text, msg.timestamp, JSON.stringify(msg.metadata || {}));

        // Update contact
        this.db.prepare(`
      UPDATE contacts SET
        last_interaction = ?,
        total_interactions = total_interactions + 1
      WHERE contact_id = ?
    `).run(msg.timestamp, msg.contactId);

        return result.lastInsertRowid as number;
    }

    getMessages(contactId: string, limit: number = 50, before?: string): Message[] {
        let query = 'SELECT * FROM messages WHERE contact_id = ?';
        const params: any[] = [contactId];

        if (before) {
            query += ' AND timestamp < ?';
            params.push(before);
        }

        query += ' ORDER BY timestamp DESC LIMIT ?';
        params.push(limit);

        const rows = this.db.prepare(query).all(...params) as any[];
        return rows.reverse().map(r => this.rowToMessage(r));
    }

    getMessageCount(contactId: string): number {
        return (this.db.prepare('SELECT COUNT(*) as count FROM messages WHERE contact_id = ?').get(contactId) as any).count;
    }

    deleteOldMessages(contactId: string, keepCount: number): number {
        const result = this.db.prepare(`
      DELETE FROM messages WHERE contact_id = ? AND id NOT IN (
        SELECT id FROM messages WHERE contact_id = ? ORDER BY timestamp DESC LIMIT ?
      )
    `).run(contactId, contactId, keepCount);
        return result.changes;
    }

    searchMessages(query: string, contactId?: string): Message[] {
        let sql = 'SELECT * FROM messages WHERE text LIKE ?';
        const params: any[] = [`%${query}%`];

        if (contactId) {
            sql += ' AND contact_id = ?';
            params.push(contactId);
        }

        sql += ' ORDER BY timestamp DESC LIMIT 50';
        const rows = this.db.prepare(sql).all(...params) as any[];
        return rows.map(r => this.rowToMessage(r));
    }

    // ═══════════════════════════════════════
    // Context Fields
    // ═══════════════════════════════════════

    getContextFields(contactId: string): { topic: string; summary: string; intents: string[]; handoffStatus: string; handoffOperator: string | null; satisfaction: number; tags: string[]; customFields: Record<string, any> } | null {
        const row = this.db.prepare('SELECT current_topic, summary, intent_history, handoff_status, handoff_operator, satisfaction_score, tags, custom_fields FROM contacts WHERE contact_id = ?').get(contactId) as any;
        if (!row) return null;

        return {
            topic: row.current_topic || '',
            summary: row.summary || '',
            intents: JSON.parse(row.intent_history || '[]'),
            handoffStatus: row.handoff_status || 'agent',
            handoffOperator: row.handoff_operator,
            satisfaction: row.satisfaction_score || 0,
            tags: JSON.parse(row.tags || '[]'),
            customFields: JSON.parse(row.custom_fields || '{}')
        };
    }

    updateContextFields(contactId: string, fields: {
        topic?: string;
        summary?: string;
        intents?: string[];
        handoffStatus?: string;
        handoffOperator?: string | null;
        satisfaction?: number;
        tags?: string[];
    }): void {
        const updates: Record<string, any> = {};
        if (fields.topic !== undefined) updates.currentTopic = fields.topic;
        if (fields.summary !== undefined) updates.summary = fields.summary;
        if (fields.intents !== undefined) updates.intentHistory = fields.intents;
        if (fields.handoffStatus !== undefined) updates.handoffStatus = fields.handoffStatus;
        if (fields.handoffOperator !== undefined) updates.handoffOperator = fields.handoffOperator;
        if (fields.satisfaction !== undefined) updates.satisfactionScore = fields.satisfaction;
        if (fields.tags !== undefined) updates.tags = fields.tags;
        this.updateContact(contactId, updates);
    }

    // ═══════════════════════════════════════
    // Summarization Helpers
    // ═══════════════════════════════════════

    getContactsNeedingSummarization(threshold: number): string[] {
        const rows = this.db.prepare(`
      SELECT c.contact_id FROM contacts c
      JOIN (SELECT contact_id, COUNT(*) as cnt FROM messages GROUP BY contact_id HAVING cnt > ?) m
      ON c.contact_id = m.contact_id
    `).all(threshold) as any[];
        return rows.map(r => r.contact_id);
    }

    // ═══════════════════════════════════════
    // Channel Management
    // ═══════════════════════════════════════

    addChannelToContact(contactId: string, channel: string): void {
        const contact = this.findById(contactId);
        if (!contact) return;

        if (!contact.channelsUsed.includes(channel)) {
            contact.channelsUsed.push(channel);
            this.updateContact(contactId, { channelsUsed: contact.channelsUsed });
        }
    }

    // ═══════════════════════════════════════
    // Row Conversions
    // ═══════════════════════════════════════

    private rowToContact(row: any): Contact {
        return {
            contactId: row.contact_id,
            phone: row.phone,
            email: row.email,
            username: row.username,
            displayName: row.display_name,
            firstSeen: row.first_seen,
            lastInteraction: row.last_interaction,
            channelsUsed: this.safeJsonParse(row.channels_used || '[]', []),
            preferredChannel: row.preferred_channel || '',
            language: row.language || 'es'
        };
    }

    private rowToMessage(row: any): Message {
        return {
            id: row.id,
            contactId: row.contact_id,
            role: row.role as MessageRole,
            channel: row.channel,
            text: row.text,
            timestamp: row.timestamp,
            metadata: this.safeJsonParse(row.metadata || '{}', {})
        };
    }

    private camelToSnake(str: string): string {
        return str.replace(/[A-Z]/g, letter => `_${letter.toLowerCase()}`);
    }

    /** Escape special LIKE characters to prevent pattern injection */
    private escapeLike(str: string): string {
        return str.replace(/[%_\\]/g, char => `\\${char}`);
    }

    /** Safe JSON.parse with fallback */
    private safeJsonParse<T>(str: string, fallback: T): T {
        try { return JSON.parse(str); }
        catch { return fallback; }
    }

    // ═══════════════════════════════════════
    // Lifecycle
    // ═══════════════════════════════════════

    close(): void {
        this.db.close();
    }
}
