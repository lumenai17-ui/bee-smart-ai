# Order Manager — Automation Workflow

## Step 1: Check for New Orders
Use `extract-data` to scan incoming messages for order requests:
- Product name/SKU, quantity, delivery address
- Customer phone/email
- Payment method

## Step 2: Auto-Confirm
If `auto_confirm` is true:
- Change status to "confirmed"
- Use `whatsapp-send` to send `confirmation_message`
- Notify operator via `notification-send`

## Step 3: Track Status Changes
Monitor for status updates from operator:
- For each status in `notify_customer_on`, send WhatsApp update
- "📦 Tu pedido está en camino" / "✅ Tu pedido fue entregado"

## Step 4: Daily Summary
Generate end-of-day summary: orders received, confirmed, shipped, delivered

## Success Criteria
- All new orders detected and confirmed within 15 minutes
- Customer notified at each configured status change
- Operator alerted on new orders
