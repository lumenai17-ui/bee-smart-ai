# Newsletter Auto — Automation Workflow

## Step 1: Gather Content
Use `summarize` to compile the week's highlights:
- Top blog posts or content published this week
- Key business metrics (sales, new clients, milestones)
- Industry tips or advice relevant to subscribers
- Upcoming events or promotions

## Step 2: Build Template
Use `email-template` to create a responsive MJML newsletter with configured `sections`

## Step 3: Generate and Review
Use `newsletter-create` to compose the final newsletter:
- Subject line optimized for open rates
- Preview text (preheader)
- Content sections filled with this week's data
- CTA button linking to the business website

## Step 4: Send to Subscribers
Send to all addresses in `subscriber_list` via Resend batch API

## Step 5: Report
"📧 Newsletter '{newsletter_name}' enviado a {count} suscriptores"

## Success Criteria
- Newsletter compiled with this week's content
- Sent to all subscribers without bounces
- Responsive on mobile and desktop
