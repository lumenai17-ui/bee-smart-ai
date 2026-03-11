# Social Scheduler — Automation Workflow

## Step 1: Check Content Queue
Read the content queue directory (config: `content_queue_path`) for pending posts:
- Look for `.json` files with post content and images
- Sort by scheduled date/time
- Filter for today's posts

## Step 2: Optimize Posting Times
Check the optimal posting times per platform (config: `optimal_times`):
- Instagram: typically 12:00 (lunch engagement peak)
- Facebook: typically 09:00 (morning check peak)
- Adjust based on past engagement data if available

## Step 3: Schedule Posts
Use the `cron-schedule` skill to queue each post for its optimal time:
- Create a one-time scheduled task for each pending post
- Include the post content, image, and target platform

## Step 4: Publish or Notify
If `auto_publish` is true:
- Use `webhook-send` to post via each platform's API
If `auto_publish` is false:
- Notify the operator: "📱 {count} posts listos para hoy. ¿Los publico?"

## Success Criteria
- All queued posts for today are scheduled at optimal times
- Operator notified of pending publications
