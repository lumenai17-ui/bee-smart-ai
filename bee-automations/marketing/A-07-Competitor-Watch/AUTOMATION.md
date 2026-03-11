# Competitor Watch — Automation Workflow

## Step 1: Scrape Competitor Data
Use `web-scraping` to visit each URL in `monitor_urls`:
- Extract pricing information if `track_prices` is true
- Capture any new products, services, or promotions
- Check for website changes (new pages, updated content)

## Step 2: Monitor Social Media
If `track_social` is true, scrape competitor social profiles:
- Count new posts since last check
- Note engagement levels (likes, comments, shares)
- Identify trending content themes

## Step 3: Check Reviews
If `track_reviews` is true:
- Use `web-scraping` to check Google/Yelp reviews for competitors
- Compare their average rating vs ours
- Identify strengths/weaknesses mentioned in reviews

## Step 4: Analyze and Compare
Use `summarize` to generate competitive intelligence:
- Price comparison table
- Social media activity summary
- Review sentiment comparison
- Notable changes since last report

## Step 5: Alert on Significant Changes
If `alert_on_changes` is true:
- Price drops > 10%: "⚠️ {competitor} bajó precios en {product}"
- New product launches: "🆕 {competitor} lanzó {product}"
- Viral social post: "📈 {competitor} tiene un post viral ({engagement})"

## Success Criteria
- All competitor URLs successfully scraped
- Change detection vs previous day
- Daily intelligence summary generated
