# Post Creator — Automation Workflow

## Step 1: Research Trending Topics
Use the `web-search` skill to find trending topics in the business's industry:
- Search for industry news and trends
- Check competitor social media activity
- Identify relevant hashtags

## Step 2: Generate Copy
Use the `rewrite` skill to create platform-specific copy:
- **Instagram**: Short, punchy, emoji-rich, 5 hashtags
- **Facebook**: Conversational, longer posts, questions to drive engagement
- **Twitter/X**: Concise (<280 chars), link-friendly, 2-3 hashtags
- Apply the brand tone from config (`brand_tone`)

## Step 3: Generate Image
Use the `image-generate` skill to create a matching visual:
- Style consistent with brand colors (config: `brand_colors`)
- Optimized dimensions per platform (1080x1080 IG, 1200x630 FB, 1600x900 X)
- No text on image (add text in post copy instead)

## Step 4: Prepare for Publishing
Save the generated content as a draft:
- File: `./output/posts/{date}-{platform}.json`
- Include: copy, image path, hashtags, suggested posting time
- Notify operator: "📱 Post listo para {platform}. ¿Lo publico?"

## Success Criteria
- 1 post draft generated per configured platform
- Image created matching brand identity
- Copy optimized for each platform's format
