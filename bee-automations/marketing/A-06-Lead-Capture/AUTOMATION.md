# Lead Capture — Automation Workflow

## Step 1: Scan Recent Conversations
Use `memory-search` to find conversations from the last hour that contain potential lead signals:
- Questions about pricing, availability, services
- Requests for quotes or information
- First-time contacts who haven't been classified yet

## Step 2: Extract Contact Data
For each potential lead, use `extract-data`:
- Name, email, phone number, company
- What product/service they're interested in
- How they found the business (channel)

## Step 3: Score and Classify
Use `classify` to score each lead:
- **Hot (80-100)**: Ready to buy, requesting pricing/quotes
- **Warm (50-79)**: Interested, asking questions
- **Cold (0-49)**: Just browsing, general inquiry
- Filter: only process leads above `score_threshold`

## Step 4: Auto-Reply
If `auto_reply` is true and the lead hasn't received a response:
- Send the `auto_reply_template` via the same channel they contacted through

## Step 5: Notify Operator
If `notify_operator` is true:
- Send alert: "🔥 Nuevo lead: {name} ({score}pts) — Interesado en: {interest}"
- Include contact details and conversation summary

## Success Criteria
- All new leads identified and scored
- Contact details extracted and stored
- Hot leads immediately flagged to operator
