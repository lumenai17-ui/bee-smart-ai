# Inventory Alert — Automation Workflow

## Step 1: Read Inventory Data
Use `excel-read` to load current inventory from `inventory_source`:
- Product name, SKU, current stock level
- Minimum stock thresholds per product

## Step 2: Identify Low Stock Items
Compare each product against thresholds:
- **Critical** (stock <= `critical_stock_threshold`): Immediate alert
- **Low** (stock <= `low_stock_threshold`): Warning alert
- **Out of stock** (stock = 0): Urgent alert

## Step 3: Send Alerts
Use `notification-send` via `alert_channel`:
- Critical: "🚨 URGENTE: {product} tiene solo {stock} unidades"
- Low: "⚠️ Stock bajo: {product} — {stock} unidades restantes"
- Out of stock: "❌ AGOTADO: {product} — 0 unidades"

## Step 4: Generate Report
If `daily_report` is true, use `report-generate`:
- Table of all products with stock levels
- Highlight items below threshold
- Suggested reorder quantities

## Step 5: Reorder Notification
If `reorder_notify` is true, send reorder suggestions via `email-send`

## Success Criteria
- All products checked against thresholds
- Alerts sent for low/critical/out-of-stock items
- Daily inventory report generated
