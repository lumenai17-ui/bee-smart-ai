# Appointment Bot — Automation Workflow

## Step 1: Check Upcoming Appointments
Use `calendar-manage` to fetch appointments in the next `reminder_hours_before[0]` hours

## Step 2: Send Reminders
For each upcoming appointment, use `whatsapp-send`:
- 24h before: Send `reminder_message` asking for confirmation
- 2h before: Send final reminder to confirmed appointments

## Step 3: Process Responses
Use `memory-search` to check for confirmation/cancellation responses:
- "Sí" / "Confirmo" → Mark as confirmed
- "No" / "Cancelo" → Cancel and open the slot
- No response → Flag for operator attention

## Step 4: Handle New Booking Requests
Monitor incoming messages for appointment requests:
- Check availability using `calendar-manage`
- Offer available slots within `business_hours`
- Create event on confirmation, send `confirmation_message`

## Success Criteria
- All upcoming appointments have received reminders
- Confirmations and cancellations processed
- Available slots accurate and up to date
