# Quick Deploy: Resume Subscription & Backend Config

## What's New

1. ✅ **Resume Subscription** - Users can reactivate cancelled subscriptions
2. ✅ **Backend Config** - Free plan quota (3 scans) now configurable from backend

---

## Deploy in 3 Steps

### Step 1: Database Migration

```bash
# Create the app_config table
supabase db push
```

Or run manually:

```bash
psql -h [your-db-host] -U postgres -d postgres -f supabase/migrations/add_app_config.sql
```

### Step 2: Deploy Edge Function

```bash
# Deploy the resume subscription function
supabase functions deploy resume-subscription
```

### Step 3: Run Your App

```bash
flutter run
```

---

## Test It Works

### Test Resume Subscription

1. **Cancel a subscription:**

   - As Traveler Pass user, go to Profile
   - Click subscription card
   - Click "Cancel Subscription"
   - Confirm cancellation
   - Status shows "Cancelling" (orange)

2. **Resume the subscription:**

   - Click subscription card again
   - See green "Resume Subscription" button
   - Click it
   - Confirm in dialog
   - Status changes to "Active" (green)

3. **Verify in Stripe:**
   - Go to Stripe Dashboard
   - Find the customer
   - Subscription should show no cancellation

### Test Backend Config

1. **Check current limit:**

   - Go to Profile screen
   - See "3/3 today" for free users

2. **Change the limit:**

   - Go to Supabase Dashboard
   - Open `app_config` table
   - Find `free_daily_scan_limit` row
   - Change value from `'3'` to `'5'`
   - Save

3. **Verify new limit:**
   - Restart your app
   - Go to Profile screen
   - Should now show "5/5 today"

---

## How to Change Free Scan Limit

### Via Supabase Dashboard (Easiest)

1. Go to Supabase Dashboard
2. Table Editor → `app_config`
3. Edit `free_daily_scan_limit` value
4. Save

### Via SQL

```sql
-- Set to 5 scans
UPDATE app_config SET value = '5' WHERE key = 'free_daily_scan_limit';

-- Set to 10 scans (promotion)
UPDATE app_config SET value = '10' WHERE key = 'free_daily_scan_limit';

-- Back to 3 scans
UPDATE app_config SET value = '3' WHERE key = 'free_daily_scan_limit';
```

---

## What Happens

### Resume Subscription Flow

```
User clicks "Resume Subscription"
         ↓
Confirmation dialog
         ↓
Full-screen loading
         ↓
Call resume-subscription function
         ↓
Stripe: cancel_at_period_end = false
         ↓
Database: status = 'active'
         ↓
Success message
         ↓
UI updates: Orange → Green
```

### Backend Config Flow

```
App starts
         ↓
Fetch free_daily_scan_limit from app_config
         ↓
Store in memory
         ↓
Use for all scan limit checks
         ↓
(If fetch fails, use default: 3)
```

---

## Files Changed

### New Files

- ✅ `supabase/migrations/add_app_config.sql` - Database table
- ✅ `supabase/functions/resume-subscription/` - Edge function

### Modified Files

- ✅ `lib/services/subscription_manager.dart` - Added resume + config fetch
- ✅ `lib/views/profile_screen.dart` - Added resume button + dialog

---

## Quick Reference

### Edge Functions

```bash
# Deploy all functions
supabase functions deploy cancel-subscription
supabase functions deploy resume-subscription
supabase functions deploy create-checkout-session
supabase functions deploy stripe-webhook

# View logs
supabase functions logs resume-subscription
```

### Database Queries

```sql
-- View all config
SELECT * FROM app_config;

-- View subscriptions
SELECT user_id, status, end_date FROM user_subscriptions;

-- Change free limit
UPDATE app_config SET value = '5' WHERE key = 'free_daily_scan_limit';
```

---

## Troubleshooting

### Resume Button Not Showing

- Check subscription status is "cancelling"
- Verify `isCancelling` flag is true
- Check subscription info loaded correctly

### Config Not Updating

- Verify `app_config` table exists
- Check row exists with key `'free_daily_scan_limit'`
- Restart app after changing value
- Check console for fetch errors

### Function Errors

```bash
# Check function logs
supabase functions logs resume-subscription --tail

# Redeploy if needed
supabase functions deploy resume-subscription
```

---

## Benefits

### For Users

- ✅ Easy to undo cancellation
- ✅ No need to re-subscribe
- ✅ Keeps current billing cycle
- ✅ One-click resume

### For You

- ✅ Change scan limits without redeployment
- ✅ Run promotions easily (increase free scans)
- ✅ Manage server load (decrease if needed)
- ✅ A/B test different limits
- ✅ Reduce churn with easy resume

---

## Next Steps

1. Deploy the changes (3 commands above)
2. Test both features
3. Update your Stripe webhook if needed
4. Consider promotional campaigns with higher free limits
5. Monitor resume rate in analytics

---

## Need More Details?

See `RESUME_SUBSCRIPTION_AND_CONFIG_GUIDE.md` for comprehensive documentation.
