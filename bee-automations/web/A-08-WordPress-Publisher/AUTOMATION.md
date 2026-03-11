# WordPress Publisher — Automation Workflow

## Step 1: Generate Blog Content
Use `rewrite` to create a blog post based on the business's industry and audience:
- Research trending topics relevant to the business
- Write 800-1500 word article with proper H2/H3 structure
- Include meta description and SEO keywords

## Step 2: Generate Featured Image
If `featured_image` is true, use `image-generate`:
- Create a relevant image matching the post topic
- Size: 1200x630px (WordPress standard)

## Step 3: Publish to WordPress
Use `webhook-send` to POST to the WordPress REST API:
```
POST {wordpress_url}/wp-json/wp/v2/posts
Authorization: Basic (user:app_password)
Body: { title, content, status, categories, featured_media }
```

## Step 4: Confirm Publication
Report: "📝 Artículo publicado en WordPress: '{title}' — Estado: {status}"

## Success Criteria
- Blog post created with proper formatting and SEO
- Featured image uploaded and linked
- Post published/drafted on WordPress
