# Payment Links — Automation Workflow

## Step 1: Create Payment Link
Generate a Stripe payment link via API:
- Amount and currency from request
- Available payment methods from config
- Description and customer info

## Step 2: Generate QR Code
If `include_qr` is true, use `qr-generate`:
- Encode the payment link URL into a QR code
- High-quality PNG for sharing

## Step 3: Generate Invoice
If `include_invoice` is true, use `invoice-generate`:
- Create a PDF invoice matching the payment details

## Step 4: Send to Customer
Use `whatsapp-send` and/or `email-send`:
- Payment link + QR code image + invoice PDF
- "💳 Liga de pago: {url}. Monto: ${amount} {currency}"

## Success Criteria
- Payment link active and functional
- QR code generated and scannable
- Invoice matches the payment amount
- Customer received via their preferred channel
