# Landing Page Express — Automation Workflow

## Step 1: Receive Promotion Details
From the operator or trigger, gather:
- Product/service name and description
- Key benefits (3-5 bullet points)
- Price and offer (discounts, limited time)
- Call-to-action text and destination

## Step 2: Generate Page
Use `web-create` to build a responsive landing page:
- Hero section with headline, subheading, CTA button
- Benefits section with icons
- Social proof / testimonials
- Contact form if `include_contact_form` is true
- WhatsApp button if `include_whatsapp_button` is true
- Apply brand colors from config

## Step 3: Generate Visuals
Use `image-generate` to create hero image and product visuals

## Step 4: Publish
If `auto_publish` is true, use `cloudflare-tunnel` to publish instantly

## Step 5: Generate QR Code
Use `qr-generate` to create a QR code linking to the published page

## Success Criteria
- Responsive landing page generated and published
- QR code ready for sharing
- Page loads in under 3 seconds
