# Google My Business — Automation Workflow

## Step 1: Fetch New Reviews
Use the `review-monitor` skill to check for new Google Business reviews:
- Query the Google Business Profile API
- Filter reviews from the last 24 hours
- Extract: rating, text, reviewer name, date

## Step 2: Analyze Sentiment
For each new review, use `sentiment-analysis`:
- Classify as positive (4-5 stars) or negative (1-3 stars)
- Identify key themes: service, product, price, staff, wait time
- Determine urgency level

## Step 3: Auto-Respond to Positive Reviews
If `auto_respond_positive` is true and rating >= `min_rating_auto_respond`:
- Use `review-respond` to generate a personalized thank-you response
- Apply the configured `response_tone`
- Post the response to Google

## Step 4: Alert on Negative Reviews
For reviews with rating < `min_rating_auto_respond`:
- If `auto_respond_negative` is false: send alert to operator via `negative_alert_channel`
- Include: review text, rating, suggested response draft
- If `auto_respond_negative` is true: post an empathetic response with contact offer

## Step 5: Generate Summary
Create a daily review summary:
- New reviews count, average rating, trend vs last week
- Positive/negative breakdown with key themes
- Any reviews requiring manual attention

## Success Criteria
- All new reviews processed and categorized
- Positive reviews responded to automatically
- Negative reviews flagged with suggested responses
- Daily summary delivered to operator
