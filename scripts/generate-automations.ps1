$base = "C:\Users\Usuario\.gemini\antigravity\scratch\bee-smart-ai"

$automations = @{
    "marketing"  = @(
        @{id = "A-01"; name = "Meta Ads Manager"; desc = "Automated Meta/Facebook ads campaign management" },
        @{id = "A-02"; name = "Post Creator"; desc = "Generate and schedule social media posts" },
        @{id = "A-03"; name = "Social Scheduler"; desc = "Schedule posts across multiple social platforms" },
        @{id = "A-04"; name = "Google My Business"; desc = "Manage Google My Business profile and posts" },
        @{id = "A-05"; name = "SEO Content"; desc = "Generate SEO-optimized content for web" },
        @{id = "A-06"; name = "Lead Capture"; desc = "Capture and qualify leads from conversations" },
        @{id = "A-07"; name = "Competitor Watch"; desc = "Monitor competitor activity and pricing" }
    )
    "web"        = @(
        @{id = "A-08"; name = "WordPress Publisher"; desc = "Publish content to WordPress sites" },
        @{id = "A-09"; name = "Blog Autopilot"; desc = "Auto-generate and publish blog posts" },
        @{id = "A-10"; name = "Landing Page Express"; desc = "Create landing pages from templates" },
        @{id = "A-11"; name = "Newsletter Auto"; desc = "Auto-generate and send newsletters" }
    )
    "operations" = @(
        @{id = "A-12"; name = "Invoice Autopilot"; desc = "Auto-generate and send invoices" },
        @{id = "A-13"; name = "Appointment Bot"; desc = "Manage appointments and reservations" },
        @{id = "A-14"; name = "Review Responder"; desc = "Auto-respond to business reviews" },
        @{id = "A-15"; name = "Daily Report"; desc = "Generate and send daily business reports" },
        @{id = "A-16"; name = "Customer Follow-up"; desc = "Automated customer follow-up messages" }
    )
    "ecommerce"  = @(
        @{id = "A-17"; name = "Product Catalog"; desc = "Manage product catalog and listings" },
        @{id = "A-18"; name = "Order Manager"; desc = "Track and manage customer orders" },
        @{id = "A-19"; name = "Payment Links"; desc = "Generate and send payment links via Stripe" },
        @{id = "A-20"; name = "Inventory Alert"; desc = "Monitor inventory levels and send alerts" }
    )
}

$totalCreated = 0
foreach ($category in $automations.Keys) {
    foreach ($auto in $automations[$category]) {
        $dir = "$base\bee-automations\$category\$($auto.id)-$($auto.name -replace ' ','-' -replace '[^a-zA-Z0-9-]','')"
        $file = "$dir\automation.json"
    
        $content = @"
{
  "id": "$($auto.id)",
  "name": "$($auto.name)",
  "description": "$($auto.desc)",
  "category": "$category",
  "version": "1.0.0",
  "enabled": false,
  "schedule": {
    "type": "cron",
    "expression": "0 9 * * *",
    "_comment": "Default: daily at 9am, customize per client"
  },
  "skills_required": [],
  "providers_required": [],
  "tier_minimum": "basic",
  "config": {}
}
"@
    
        New-Item -ItemType Directory -Path $dir -Force | Out-Null
        Set-Content -Path $file -Value $content -Encoding UTF8
        $totalCreated++
    }
}

Write-Host "Created $totalCreated automation stubs across $($automations.Keys.Count) categories"
