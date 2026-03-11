# Invoice Autopilot — Automation Workflow

## Step 1: Identify Pending Invoices
Use `extract-data` to scan recent conversations and orders for uninvoiced items:
- Completed services or deliveries today
- Confirmed orders without invoices
- Recurring billing due dates

## Step 2: Generate Invoices
For each pending item, use `invoice-generate`:
- Apply business info from config (name, RFC, address)
- Calculate tax at `tax_rate`
- Sequential invoice number with `invoice_prefix`
- Payment terms: `payment_terms_days` days

## Step 3: Create PDF
Use `pdf-generate` to render each invoice as a professional PDF

## Step 4: Send to Client
If `auto_send` is true, use `email-send`:
- Attach the PDF invoice
- Professional email body with payment details
- Include payment due date

## Step 5: Log
Record: "🧾 Factura {number} generada y enviada a {client} — Total: ${amount} {currency}"

## Success Criteria
- All pending invoices generated with correct data
- PDFs created and sent to clients
- Invoice numbers are sequential and unique
