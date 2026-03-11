# Daily Report — Automation Workflow

## Step 1: Gather Metrics
Use `memory-search` to collect data from the past 24 hours:
- Total conversations by channel
- New leads captured and qualified
- Sales/orders completed
- Customer satisfaction scores
- Response time averages

## Step 2: Analyze Trends
Use `summarize` to compare vs `compare_period`:
- Which metrics improved/declined?
- Notable events or anomalies
- Action items for today

## Step 3: Generate Report
Use `report-generate` to create the daily report:
- Executive summary (3 bullet points)
- KPI table with trend indicators (↑↓→)
- Charts if `include_chart` is true
- Recommended actions

## Step 4: Deliver
Send to all `recipients` via `delivery_channel` using `email-send`

## Success Criteria
- Report covers all configured `metrics`
- Trend comparison is accurate
- Delivered before 9:30am
