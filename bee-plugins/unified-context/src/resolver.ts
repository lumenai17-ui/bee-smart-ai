/**
 * BEE Smart AI — Contact Identity Resolver
 * Maps incoming identifiers (phone, email, username) to a unified contact_id.
 * Creates new contacts when first seen.
 */

import { ContactDatabase } from './database';
import { Contact, ContactIdentifier } from './types';

export class ContactResolver {
    private db: ContactDatabase;

    constructor(db: ContactDatabase) {
        this.db = db;
    }

    /**
     * Resolve an identifier to a contact_id.
     * Creates the contact if it doesn't exist.
     * Returns the contact_id.
     */
    resolve(identifier: ContactIdentifier): string {
        // Try each identifier type in priority order
        const existing = this.findExisting(identifier);
        if (existing) {
            // Update channel access
            this.db.addChannelToContact(existing.contactId, identifier.channel);
            return existing.contactId;
        }

        // Create new contact
        return this.createNew(identifier);
    }

    /**
     * Try to find an existing contact by any identifier
     */
    private findExisting(identifier: ContactIdentifier): Contact | null {
        if (identifier.phone) {
            const normalized = this.normalizePhone(identifier.phone);
            const contact = this.db.findByPhone(normalized);
            if (contact) return contact;
        }

        if (identifier.email) {
            const contact = this.db.findByEmail(identifier.email.toLowerCase());
            if (contact) return contact;
        }

        if (identifier.username) {
            const contact = this.db.findByUsername(identifier.channel, identifier.username);
            if (contact) return contact;
        }

        return null;
    }

    /**
     * Create a new contact from an identifier
     */
    private createNew(identifier: ContactIdentifier): string {
        const now = new Date().toISOString();
        const contactId = this.generateId(identifier);
        const phone = identifier.phone ? this.normalizePhone(identifier.phone) : null;

        const contact: Contact = {
            contactId,
            phone,
            email: identifier.email?.toLowerCase() || null,
            username: identifier.username || null,
            displayName: identifier.displayName || this.inferName(identifier),
            firstSeen: now,
            lastInteraction: now,
            channelsUsed: [identifier.channel],
            preferredChannel: identifier.channel,
            language: 'es'
        };

        this.db.createContact(contact);
        return contactId;
    }

    /**
     * Merge two contacts into one (when we discover they're the same person)
     */
    mergeContacts(primaryId: string, secondaryId: string): boolean {
        const primary = this.db.findById(primaryId);
        const secondary = this.db.findById(secondaryId);
        if (!primary || !secondary) return false;

        // Merge channels
        const allChannels = [...new Set([...primary.channelsUsed, ...secondary.channelsUsed])];

        // Update primary with any missing info from secondary
        const updates: Record<string, any> = {
            channelsUsed: allChannels
        };

        if (!primary.phone && secondary.phone) updates.phone = secondary.phone;
        if (!primary.email && secondary.email) updates.email = secondary.email;
        if (!primary.username && secondary.username) updates.username = secondary.username;

        this.db.updateContact(primaryId, updates);

        // TODO: Move messages from secondary to primary
        // TODO: Delete secondary contact

        return true;
    }

    // ═══════════════════════════════════════
    // Helpers
    // ═══════════════════════════════════════

    private generateId(identifier: ContactIdentifier): string {
        const ts = Date.now().toString(36);
        if (identifier.phone) return `ph_${this.normalizePhone(identifier.phone).replace(/\+/g, '')}`;
        if (identifier.email) return `em_${identifier.email.split('@')[0]}`;
        if (identifier.username) return `${identifier.channel}_${identifier.username.replace('@', '')}`;
        return `anon_${ts}`;
    }

    private normalizePhone(phone: string): string {
        // Remove all non-digit chars except leading +
        let normalized = phone.replace(/[^\d+]/g, '');
        if (!normalized.startsWith('+')) {
            normalized = '+' + normalized;
        }
        return normalized;
    }

    private inferName(identifier: ContactIdentifier): string {
        if (identifier.displayName) return identifier.displayName;
        if (identifier.username) return identifier.username;
        if (identifier.phone) return identifier.phone;
        if (identifier.email) return identifier.email.split('@')[0];
        return 'Unknown';
    }
}
