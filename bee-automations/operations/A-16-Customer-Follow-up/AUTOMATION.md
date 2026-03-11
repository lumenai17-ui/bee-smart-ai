# Customer Follow-up — Automation Workflow

## Step 1: Find Inactive Customers
Use `memory-search` to identify customers not contacted in `inactivity_days` days:
- Exclude contacts with tags in `exclude_tags`
- Sort by last interaction date (oldest first)
- Limit to `max_followups_per_day`

## Step 2: Personalize Messages
For each customer, use `summarize`:
- Get their last conversation topic
- Note their purchasing history
- Personalize the `message_template` with context

## Step 3: Send Follow-up
Use `whatsapp-send` (or `email-send` depending on `followup_channel`):
- Send personalized message
- Include relevant context (their last topic)

## Step 4: Log Results
Record which customers were followed up and update their last contact date

## Success Criteria
- Up to `max_followups_per_day` customers contacted
- Messages are personalized (not generic)
- No do-not-contact customers messaged
