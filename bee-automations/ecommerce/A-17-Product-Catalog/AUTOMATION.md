# Product Catalog — Automation Workflow

## Step 1: Fetch Product Data
Use `web-scraping` to pull current product data from `catalog_source`:
- Product names, descriptions, SKUs
- Current prices and stock levels
- Product images

## Step 2: Process Images
If `include_images` is true, use `image-edit`:
- Resize product images to standard dimensions
- Optimize for file size

## Step 3: Generate Catalog Exports
For each format in `output_formats`:
- **Excel**: Use `excel-generate` — product table with prices, stock, categories
- **PDF**: Use `pdf-generate` — formatted catalog with images and descriptions

## Step 4: Save and Notify
Save exports to `output_dir`, notify operator that catalog is updated

## Success Criteria
- All products fetched with current prices and stock
- Catalog generated in all configured formats
- Images processed and included
