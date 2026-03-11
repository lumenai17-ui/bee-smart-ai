# Review Responder — Automation Workflow

## Step 1: Fetch New Reviews
Use `review-monitor` to check all `platforms` for new reviews since last run

## Step 2: Analyze Each Review
Use `sentiment-analysis` for each new review:
- Classify sentiment and key themes
- Rating >= `auto_respond_min_rating` → auto-respond
- Rating <= `escalate_max_rating` → escalate to operator

## Step 3: Auto-Respond
Use `review-respond` for eligible reviews:
- Generate contextual response matching `response_tone`
- Post response to the platform

## Step 4: Escalate Critical Reviews
For low-rating reviews, use `notification-send`:
- Send to operator via `escalation_channel`
- Include: review text, suggested response, sentiment analysis

## Success Criteria
- All new reviews processed within 6 hours
- Positive reviews responded to automatically
- Negative reviews escalated immediately
