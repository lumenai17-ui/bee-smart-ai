# SEO Content — Automation Workflow

## Step 1: Keyword Research
Use the `web-search` skill to research target keywords:
- Search for `target_keywords` and analyze top 10 results
- Identify related keywords and long-tail variations
- Check search volume and competition level

## Step 2: Competitor Analysis
For each URL in `competitors`, use `web-search` and `summarize`:
- What topics are they ranking for?
- What content gaps exist that we can fill?
- What's their average content length and format?

## Step 3: Generate SEO-Optimized Content
Use `rewrite` to create a blog post (~`content_length` words):
- Include primary keyword in title, H1, first paragraph, and conclusion
- Use related keywords naturally throughout
- Structure: H1 > introduction > H2 sections > conclusion > CTA
- Meta description (155 chars) and suggested URL slug

## Step 4: Create the HTML
Use `web-create` to format as a ready-to-publish HTML page:
- Semantic HTML with proper heading hierarchy
- Schema.org structured data (Article)
- Open Graph meta tags
- Save to `./output/seo/{date}-{keyword}.html`

## Success Criteria
- 1 SEO-optimized article generated per week
- Content includes target keyword with natural density
- HTML is valid, semantic, and includes structured data
