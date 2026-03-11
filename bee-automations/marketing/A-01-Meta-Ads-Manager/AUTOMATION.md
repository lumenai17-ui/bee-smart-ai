# Meta Ads Manager — Automation Workflow

## Step 1: Fetch Campaign Data
Use the `web-scraping` skill to query the Meta Graph API for ad campaign performance:
- Endpoint: `https://graph.facebook.com/v18.0/{ad_account_id}/campaigns`
- Metrics: impressions, clicks, CTR, spend, conversions, CPA
- Date range: last 24 hours

## Step 2: Analyze Performance
Use the `summarize` skill to analyze the metrics:
- Compare today's metrics vs 7-day average
- Identify campaigns with CTR below threshold (config: `alert_threshold_ctr`)
- Identify campaigns with CPA above threshold (config: `alert_threshold_cpa`)
- Flag any campaigns with $0 spend (may be paused unintentionally)

## Step 3: Generate Report
Use the `report-generate` skill to create a daily ads report:
- Executive summary with total spend, total conversions, overall ROAS
- Per-campaign breakdown table
- Trend charts (spend & conversions over last 7 days)
- Recommendations for underperforming campaigns

## Step 4: Alert on Issues
If any campaign triggers an alert threshold, use `notification-send`:
- High priority if CPA > 2x threshold or CTR < 50% of target
- Medium priority for minor deviations
- Include specific campaign name, metric, and recommended action

## Step 5: Deliver Report
Send the daily report to `report_recipients` via email.

## Success Criteria
- All active campaigns metrics fetched successfully
- Report generated and delivered
- Alerts sent for any underperforming campaigns
