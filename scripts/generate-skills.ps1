$base = "C:\Users\Usuario\.gemini\antigravity\scratch\bee-smart-ai"

# ═══════════════════════════════════════
# BEE SKILLS — 58 skills in 10 categories
# ═══════════════════════════════════════

$skills = @{
  "communication" = @(
    @{name="email-send"; desc="Send emails via SMTP"; version="1.0.0"; tools=@("email","bash")},
    @{name="email-read"; desc="Read and parse incoming emails via IMAP"; version="1.0.0"; tools=@("email","bash")},
    @{name="sms-send"; desc="Send SMS messages via Twilio or local gateway"; version="1.0.0"; tools=@("http")},
    @{name="whatsapp-send"; desc="Send WhatsApp messages via Business API"; version="1.0.0"; tools=@("http")},
    @{name="telegram-send"; desc="Send Telegram messages via Bot API"; version="1.0.0"; tools=@("http")},
    @{name="discord-send"; desc="Send Discord messages via Bot API"; version="1.0.0"; tools=@("http")},
    @{name="voice-receive"; desc="Receive and transcribe voice messages"; version="1.0.0"; tools=@("http","bash")},
    @{name="voice-send"; desc="Generate and send voice messages via TTS"; version="1.0.0"; tools=@("http")},
    @{name="voice-transcribe"; desc="Transcribe audio files to text using Deepgram"; version="1.0.0"; tools=@("http","bash")}
  )
  "multimedia" = @(
    @{name="image-receive"; desc="Receive and process incoming images"; version="1.0.0"; tools=@("file","bash")},
    @{name="image-generate"; desc="Generate images using Stable Diffusion API"; version="1.0.0"; tools=@("http")},
    @{name="image-edit"; desc="Edit images (resize, crop, overlay text)"; version="1.0.0"; tools=@("bash")},
    @{name="video-process"; desc="Process videos (cut, join, extract frames) via FFmpeg"; version="1.0.0"; tools=@("bash")},
    @{name="video-create"; desc="Create videos using Kling 2.1 via fal.ai"; version="1.0.0"; tools=@("http")},
    @{name="video-edit"; desc="Edit videos (text overlay, transitions) via FFmpeg"; version="1.0.0"; tools=@("bash")},
    @{name="ocr"; desc="Extract text from images using OCR"; version="1.0.0"; tools=@("bash")}
  )
  "documents" = @(
    @{name="pdf-generate"; desc="Generate PDF documents using wkhtmltopdf"; version="1.0.0"; tools=@("bash")},
    @{name="pdf-read"; desc="Read and extract text from PDFs using pdftotext/Tika"; version="1.0.0"; tools=@("bash")},
    @{name="pdf-edit"; desc="Edit PDF documents (merge, split, annotate)"; version="1.0.0"; tools=@("bash")},
    @{name="word-generate"; desc="Generate Word/DOCX documents using Pandoc"; version="1.0.0"; tools=@("bash")},
    @{name="excel-generate"; desc="Generate Excel spreadsheets using openpyxl"; version="1.0.0"; tools=@("bash")},
    @{name="excel-read"; desc="Read and parse Excel files"; version="1.0.0"; tools=@("bash")},
    @{name="powerpoint-create"; desc="Create PowerPoint presentations using python-pptx"; version="1.0.0"; tools=@("bash")},
    @{name="invoice-generate"; desc="Generate professional invoices in PDF format"; version="1.0.0"; tools=@("bash")}
  )
  "web-automation" = @(
    @{name="browser-navigate"; desc="Navigate and interact with web pages using Puppeteer"; version="1.0.0"; tools=@("browser","bash")},
    @{name="web-scraping"; desc="Scrape and extract data from websites using Cheerio"; version="1.0.0"; tools=@("bash","http")},
    @{name="webhook-receive"; desc="Receive and process incoming webhooks"; version="1.0.0"; tools=@("http")},
    @{name="webhook-send"; desc="Send outgoing webhook notifications"; version="1.0.0"; tools=@("http")},
    @{name="cron-schedule"; desc="Schedule recurring tasks using Cron/Systemd"; version="1.0.0"; tools=@("bash")},
    @{name="web-search"; desc="Search the web using Brave Search API"; version="1.0.0"; tools=@("http")},
    @{name="web-create"; desc="Create and publish web pages"; version="1.0.0"; tools=@("bash","file")},
    @{name="cloudflare-tunnel"; desc="Expose local services via Cloudflare Tunnel"; version="1.0.0"; tools=@("bash")}
  )
  "intelligence" = @(
    @{name="summarize"; desc="Summarize long texts and documents"; version="1.0.0"; tools=@()},
    @{name="translate"; desc="Translate text between languages"; version="1.0.0"; tools=@()},
    @{name="extract-data"; desc="Extract structured data from unstructured text"; version="1.0.0"; tools=@()},
    @{name="sentiment-analysis"; desc="Analyze sentiment of messages and reviews"; version="1.0.0"; tools=@()},
    @{name="classify"; desc="Classify text into predefined categories"; version="1.0.0"; tools=@()},
    @{name="rewrite"; desc="Rewrite text in a different tone or style"; version="1.0.0"; tools=@()},
    @{name="memory-search"; desc="Search through agent memory and conversation history"; version="1.0.0"; tools=@("memory")}
  )
  "business" = @(
    @{name="report-generate"; desc="Generate business reports with charts and data"; version="1.0.0"; tools=@("bash","file")},
    @{name="dashboard-create"; desc="Create visual dashboards from business data"; version="1.0.0"; tools=@("bash","file")},
    @{name="qr-generate"; desc="Generate QR codes for links, payments, menus"; version="1.0.0"; tools=@("bash")},
    @{name="notification-send"; desc="Send push notifications to operators"; version="1.0.0"; tools=@("http")},
    @{name="review-monitor"; desc="Monitor and alert on new business reviews"; version="1.0.0"; tools=@("http","browser")},
    @{name="review-respond"; desc="Draft and post responses to business reviews"; version="1.0.0"; tools=@("http","browser")}
  )
  "email-marketing" = @(
    @{name="newsletter-create"; desc="Create and send email newsletters"; version="1.0.0"; tools=@("email","bash")},
    @{name="email-template"; desc="Design and manage email templates"; version="1.0.0"; tools=@("file","bash")},
    @{name="email-tracking"; desc="Track email opens, clicks, and engagement"; version="1.0.0"; tools=@("http")},
    @{name="drip-campaign"; desc="Create and manage automated drip email campaigns"; version="1.0.0"; tools=@("email","bash")}
  )
  "code-dev" = @(
    @{name="code-execute"; desc="Execute code snippets in Python, Node.js, or Bash"; version="1.0.0"; tools=@("bash")},
    @{name="git-commit"; desc="Stage, commit, and push changes to Git repositories"; version="1.0.0"; tools=@("bash")},
    @{name="repo-read"; desc="Read and analyze code repository contents"; version="1.0.0"; tools=@("bash","file")}
  )
  "productivity" = @(
    @{name="reminder-set"; desc="Set and manage reminders for the business"; version="1.0.0"; tools=@("bash")},
    @{name="task-manage"; desc="Create, update, and track tasks and to-do lists"; version="1.0.0"; tools=@("file")},
    @{name="calendar-manage"; desc="Manage Google Calendar events and appointments"; version="1.0.0"; tools=@("http")},
    @{name="sheets-manage"; desc="Read and write Google Sheets data"; version="1.0.0"; tools=@("http")}
  )
  "location" = @(
    @{name="maps-lookup"; desc="Look up locations and display maps via Google Maps"; version="1.0.0"; tools=@("http")},
    @{name="directions-get"; desc="Get driving/walking directions between locations"; version="1.0.0"; tools=@("http")}
  )
}

$totalCreated = 0

foreach ($category in $skills.Keys) {
  foreach ($skill in $skills[$category]) {
    $dir = "$base\bee-skills\$category\$($skill.name)"
    $file = "$dir\SKILL.md"
    
    $toolsYaml = if ($skill.tools.Count -gt 0) {
      ($skill.tools | ForEach-Object { "  - tool: $_" }) -join "`n"
    } else {
      "  # Uses LLM capabilities directly"
    }
    
    $content = @"
---
name: $($skill.name)
description: $($skill.desc)
version: $($skill.version)
category: $category
requires:
$toolsYaml
---

# $($skill.name)

$($skill.desc)

## Instructions

<!-- TODO: Add detailed instructions for this skill -->

## Usage Examples

<!-- TODO: Add usage examples -->
"@
    
    New-Item -ItemType Directory -Path $dir -Force | Out-Null
    Set-Content -Path $file -Value $content -Encoding UTF8
    $totalCreated++
  }
}

Write-Host "Created $totalCreated skill stubs across $($skills.Keys.Count) categories"
