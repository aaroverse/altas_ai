# Resume Subscription & Backend Configuration Guide

## New Features Implemented

### ✅ Feature 1: Resume Subscription

Users who have cancelled their subscription can now resume it before the expiration date.

### ✅ Feature 2: Backend-Configurable Free Plan Quota

The free plan daily scan limit (previously hardcoded as 3) is now stored in the backend and can be changed without redeploying the app.

---

## Feature 1: Resume Subscription

### What It Does

- Adds a "Resume Subscription" button for users with cancelled subscriptions
- Allows users to reactivate their subscription before it expires
- Removes the cancellation and continues billing normally

### User Flow

```
Cancelling Subscription → Click "Resume Subscription" → Confirmation Dialog → Success
         ↓                                                                        ↓
   Orange badge                                                            Green badge
   "Cancelling"                                                            "Active"
   Until [date]                                                            Renews on [date]
```

### UI Changes

**Subscription Details Modal - Cancelling State:**

```
┌─────────────────────────────────────┐
│ ⏰ Traveler Pass                    │
│    Annual Plan                      │
│                                     │
│ ⚠️ Subscription will end on         │
│    Jan 15, 2026                     │
│                                     │
│ ✓ Unlimited scans                   │
│ ✓ All languages                     │
│ ✓ Priority support                  │
│ ─────────────────────────────────   │
│ Access until: Jan 15, 2026          │
│                                     │
│ [Resume Subscription] ← NEW!        │  Green button
│ [Close]                             │
└─────────────────────────────────────┘
```

**Confirmation Dialog:**

```
┌─────────────────────────────────────┐
│ Resume Subscription?                │
│                                     │
│ Your subscription will continue     │
│ and you will be charged at the      │
│ next billing cycle. You will keep   │
│ unlimited access to all features.   │
│                                     │
│ [Cancel] [Resume Subscription]      │
└─────────────────────────────────────┘
```

### Backend Implementation

**New Edge Function:** `supabase/functions/resume-subscription/`

**What it does:**

1. Authenticates user via JWT
2. Verifies subscription belongs to user
3. Checks subscription is in "cancelling" state
4. Calls Stripe API to set `cancel_at_period_end: false`
5. Updates Supabase database status to "active"

**Stripe Changes:**

- Removes the cancellation flag
- Subscription continues normally
- User will be charged at next billing cycle

**Database Changes:**

- Status: `'cancelling'` → `'active'`
- No change to end_date (keeps current billing period)

### Code Changes

**`lib/services/subscription_manager.dart`:**

- Added `resumeSubscription()` method
- Calls `resume-subscription` edge function
- Returns success/failure boolean

**`lib/views/profile_screen.dart`:**

- Added `_showResumeConfirmation()` dialog
- Added `_resumeSubscription()` handler
- Shows green "Resume Subscription" button when `isCancelling` is true
- Hides "Cancel Subscription" button when `isCancelling` is true

---

## Feature 2: Backend-Configurable Free Plan Quota

### What It Does

- Moves the free plan daily scan limit from hardcoded constant to database
- Allows changing the limit via Supabase dashboard without app redeployment
- App fetches the limit on startup

### Database Schema

**New Table:** `app_config`

```sql
CREATE TABLE app_config (
  key TEXT PRIMARY KEY,
  value JSONB NOT NULL,
  description TEXT,
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);
```

**Default Configuration:**

```sql
INSERT INTO app_config (key, value, description)
VALUES ('free_daily_scan_limit', '3', 'Number of free scans allowed per day');
```

### How to Change the Limit

#### Option 1: Supabase Dashboard (Recommended)

1. Go to Supabase Dashboard
2. Navigate to Table Editor
3. Open `app_config` table
4. Find row with key `'free_daily_scan_limit'`
5. Edit the `value` field (e.g., change `'3'` to `'5'`)
6. Save changes
7. Users will get the new limit on next app restart

#### Option 2: SQL Query

```sql
UPDATE app_config
SET value = '5'
WHERE key = 'free_daily_scan_limit';
```

#### Option 3: Supabase SQL Editor

```sql
-- Increase to 5 scans per day
UPDATE app_config
SET value = '5', description = 'Increased for promotion'
WHERE key = 'free_daily_scan_limit';

-- Decrease to 2 scans per day
UPDATE app_config
SET value = '2', description = 'Reduced for testing'
WHERE key = 'free_daily_scan_limit';

-- Set to 10 scans per day
UPDATE app_config
SET value = '10', description = 'Holiday special'
WHERE key = 'free_daily_scan_limit';
```

### Code Changes

**`lib/services/subscription_manager.dart`:**

**Before:**

```dart
static const int freeDailyLimit = 3; // Hardcoded
```

**After:**

```dart
static int _freeDailyLimit = 3; // Default, fetched from backend
static int get freeDailyLimit => _freeDailyLimit;

static Future<void> fetchFreeDailyLimit() async {
  // Fetches from app_config table
}
```

**`lib/views/profile_screen.dart`:**

- Calls `SubscriptionManager.fetchFreeDailyLimit()` in `initState()`
- Fetches config on profile screen load

### When Limit Updates Take Effect

1. **Immediate (for new sessions):** Users who open the app after you change the limit will get the new value
2. **Next restart (for active sessions):** Users currently using the app will get the new limit when they restart
3. **Profile screen visit:** Limit is refreshed when user visits profile screen

### Fallback Behavior

If fetching from backend fails:

- App uses default value of 3
- Logs warning in console
- User experience is not affected

---

## Deployment Steps

### Step 1: Run Database Migration

```bash
# Apply the migration to create app_config table
supabase db push

# Or manually run the SQL file
psql -h [your-db-host] -U postgres -d postgres -f supabase/migrations/add_app_config.sql
```

### Step 2: Deploy Resume Subscription Function

```bash
supabase functions deploy resume-subscription
```

### Step 3: Verify Deployment

```bash
# Check functions are deployed
supabase functions list

# Should show:
# - cancel-subscription
# - resume-subscription
# - create-checkout-session
# - stripe-webhook
```

### Step 4: Test the Features

**Test Resume Subscription:**

1. As Traveler Pass user, cancel subscription
2. Verify status shows "Cancelling"
3. Click subscription card
4. Click "Resume Subscription"
5. Confirm in dialog
6. Verify status changes to "Active"
7. Check Stripe dashboard shows no cancellation

**Test Backend Config:**

1. Check current limit in app (should be 3)
2. Update in Supabase dashboard to 5
3. Restart app
4. Verify new limit shows in profile (5/5 today)

---

## Testing Checklist

### Resume Subscription

- [ ] "Resume Subscription" button appears for cancelling users
- [ ] Button is green and prominent
- [ ] Clicking shows confirmation dialog
- [ ] Dialog explains what will happen
- [ ] Confirming shows full-screen loading
- [ ] Success message appears
- [ ] Status changes from "Cancelling" to "Active"
- [ ] Badge changes from orange to green
- [ ] "Until [date]" changes to "Renews on [date]"
- [ ] Stripe dashboard shows no cancellation
- [ ] Database status is "active"
- [ ] User can cancel again if needed

### Backend Configuration

- [ ] App fetches limit on startup
- [ ] Default value (3) works if fetch fails
- [ ] Changing value in dashboard updates app
- [ ] Profile screen shows correct limit
- [ ] Scan functionality respects new limit
- [ ] No app redeployment needed for changes

---

## Stripe Dashboard Verification

### For Resume Subscription

**Before Resume:**

- Subscription shows "Cancels on [date]"
- Status: Active (but marked for cancellation)
- `cancel_at_period_end`: true

**After Resume:**

- No cancellation notice
- Status: Active
- `cancel_at_period_end`: false
- Will renew normally at period end

---

## Database Verification

### Check Subscription Status

```sql
-- View current subscriptions
SELECT
  user_id,
  status,
  plan_duration,
  end_date,
  stripe_subscription_id
FROM user_subscriptions
WHERE status IN ('active', 'cancelling');
```

### Check App Config

```sql
-- View current configuration
SELECT * FROM app_config;

-- Check free limit specifically
SELECT value FROM app_config WHERE key = 'free_daily_scan_limit';
```

---

## Use Cases

### Resume Subscription

**Scenario 1: User Cancelled by Mistake**

- User accidentally cancelled
- Realizes within billing period
- Clicks "Resume Subscription"
- Subscription continues without interruption

**Scenario 2: User Changed Mind**

- User cancelled to save money
- Realizes they need unlimited scans
- Resumes before expiration
- No need to re-subscribe (keeps current billing cycle)

**Scenario 3: Win-Back Campaign**

- User cancelled subscription
- Receives email about new features
- Decides to resume
- One-click resume from profile

### Backend Configuration

**Scenario 1: Promotional Period**

- Black Friday sale
- Increase free scans from 3 to 10
- Update in dashboard
- All users get more scans
- Revert after promotion ends

**Scenario 2: Server Load Management**

- High server load detected
- Temporarily reduce to 2 scans
- Update in dashboard
- Reduces load immediately
- Increase back when stable

**Scenario 3: A/B Testing**

- Test if 5 scans increases conversions
- Update for test group
- Monitor conversion rates
- Adjust based on results

---

## Important Notes

### Resume Subscription

1. **Only for cancelling users:** Button only shows when status is "cancelling"
2. **Before expiration:** Can only resume before subscription actually expires
3. **No refunds:** Resuming doesn't change billing, just removes cancellation
4. **Immediate effect:** Status changes immediately in app and Stripe

### Backend Configuration

1. **Type safety:** Value is stored as JSONB, parsed as integer
2. **Validation:** App validates the value is a positive integer
3. **Fallback:** Always has default value (3) if fetch fails
4. **Caching:** Value is cached in memory, refreshed on app restart
5. **RLS enabled:** Only authenticated users can read, only service role can update

---

## Troubleshooting

### Resume Not Working

**Check:**

1. Subscription status is "cancelling" in database
2. Stripe subscription has `cancel_at_period_end: true`
3. Edge function is deployed
4. User has valid JWT token
5. Subscription belongs to the user

**Logs:**

```bash
supabase functions logs resume-subscription
```

### Config Not Updating

**Check:**

1. `app_config` table exists
2. Row with key `'free_daily_scan_limit'` exists
3. Value is valid JSON (string or number)
4. RLS policies allow reading
5. App is calling `fetchFreeDailyLimit()`

**Verify:**

```sql
SELECT * FROM app_config WHERE key = 'free_daily_scan_limit';
```

---

## Future Enhancements

### Resume Subscription

- Add "Resume with discount" option
- Track resume rate for analytics
- Send confirmation email
- Show resume option in email campaigns

### Backend Configuration

- Add more configurable values (prices, features, etc.)
- Create admin panel for configuration
- Add configuration history/audit log
- Support A/B testing configurations
- Add real-time config updates (without restart)

---

## Summary

### What You Can Do Now

1. **Users can resume cancelled subscriptions**

   - One-click resume from profile
   - No need to re-subscribe
   - Keeps current billing cycle

2. **Change free plan limit without redeployment**
   - Update in Supabase dashboard
   - Takes effect on next app restart
   - Perfect for promotions and testing

### Benefits

- **Better user experience:** Easy to undo cancellation
- **Operational flexibility:** Adjust limits on the fly
- **Reduced churn:** Users can easily come back
- **No downtime:** Changes without app updates
