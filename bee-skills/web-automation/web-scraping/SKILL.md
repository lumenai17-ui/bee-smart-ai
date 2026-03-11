---
name: web-scraping
description: "Scrape and extract structured data from websites. Use when the user needs to collect data from web pages: product prices, articles, listings, reviews, or any public data. Uses Cheerio for HTML parsing or Oxylabs for anti-bot sites."
version: 1.0.0
category: web-automation
tier: basic
requires:
  - tool: bash
  - tool: http
---

# web-scraping

Extract structured data from any website.

## Instructions

### Step 1: Fetch the page
```bash
# Simple fetch with curl
curl -s -L "https://example.com" -o /tmp/page.html

# Or with Node.js for JS-rendered pages
node -e "
const response = await fetch('https://example.com');
const html = await response.text();
require('fs').writeFileSync('/tmp/page.html', html);
"
```

### Step 2: Parse with Cheerio
```bash
node -e "
const cheerio = require('cheerio');
const html = require('fs').readFileSync('/tmp/page.html', 'utf-8');
const $ = cheerio.load(html);

// Extract data
const items = [];
$('.product-card').each((i, el) => {
  items.push({
    name: $(el).find('.title').text().trim(),
    price: $(el).find('.price').text().trim(),
    url: $(el).find('a').attr('href')
  });
});
console.log(JSON.stringify(items, null, 2));
"
```

### Step 3: For protected/JS-heavy sites, use Oxylabs
```bash
curl -X POST "https://realtime.oxylabs.io/v1/queries" \
  -u "$OXYLABS_USER:$OXYLABS_PASS" \
  -H "Content-Type: application/json" \
  -d '{ "source": "universal", "url": "https://protected-site.com", "render": "html" }'
```

### Step 4: Present results
Format as a structured table or JSON.

## Environment Variables

| Variable | Required | Description |
|---|---|---|
| `OXYLABS_USER` | Optional | Oxylabs username (1000 req/month) |
| `OXYLABS_PASS` | Optional | Oxylabs password |

## Usage Examples

### Example 1: Product prices
**User**: "Extrae los precios de este catálogo online"

**Response**: 🕷️ 15 productos extraídos:

| Producto | Precio | Disponible |
|---|---|---|
| Laptop Dell XPS | $24,500 | ✅ |
| Monitor LG 27" | $8,900 | ✅ |
| Teclado Logitech | $2,100 | ❌ |

### Example 2: News articles
**User**: "Extrae los titulares de noticias de este sitio"

**Response**: 🕷️ 10 titulares extraídos de hoy:
1. "IA generativa alcanza récord de adopción empresarial"
2. "Mercados suben tras acuerdos comerciales"
...

## Error Handling

| Error | Action |
|---|---|
| 403 Forbidden | Try with Oxylabs proxy, or different User-Agent |
| CAPTCHA detected | Inform user, suggest manual access |
| Empty results | Check selectors, try alternative parsing |
| Rate limited | Add delays between requests |
