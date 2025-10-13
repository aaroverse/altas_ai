# Subscription Cancellation Flow

## User Journey

```
┌─────────────────────────────────────────────────────────────┐
│                     Profile Screen                          │
│                                                             │
│  ┌─────────────────────────────────────────────────────┐  │
│  │  Subscription Management                            │  │
│  │                                                     │  │
│  │  Loading...  ──────────────────────────────────►   │  │
│  │  (Skeleton)                                         │  │
│  │                                                     │  │
│  │  Then shows:                                        │  │
│  │  ┌─────────────────────────────────────────────┐  │  │
│  │  │ Traveler Pass                    [PRO]      │  │  │
│  │  │ Active                                      │  │  │
│  │  │ Unlimited scans                             │  │  │
│  │  └─────────────────────────────────────────────┘  │  │
│  └─────────────────────────────────────────────────────┘  │
└─────────────────────────────────────────────────────────────┘
                            │
                            │ User clicks
                            ▼
┌─────────────────────────────────────────────────────────────┐
│              Subscription Details Modal                     │
│                                                             │
│  ✓ Traveler Pass - Annual Plan                             │
│                                                             │
│  ┌─────────────────────────────────────────────────────┐  │
│  │  ✓ Unlimited scans                                  │  │
│  │  ✓ All languages                                    │  │
│  │  ✓ Priority support                                 │  │
│  │  ─────────────────────────────────────────────────  │  │
│  │  Renews on: Jan 15, 2026                            │  │
│  └─────────────────────────────────────────────────────┘  │
│                                                             │
│  [ Cancel Subscription ]  ◄─── Red button                  │
│  [ Close ]                                                  │
└─────────────────────────────────────────────────────────────┘
                            │
                            │ User clicks Cancel
                            ▼
┌─────────────────────────────────────────────────────────────┐
│              First Confirmation Dialog                      │
│                                                             │
│  Cancel Subscription?                                       │
│                                                             │
│  Are you sure you want to cancel your Traveler Pass?       │
│  You will lose access to unlimited scans at the end         │
│  of your current billing period.                            │
│                                                             │
│  [ Keep Subscription ]  [ Cancel Subscription ]            │
└─────────────────────────────────────────────────────────────┘
                            │
                            │ User confirms
                            ▼
┌─────────────────────────────────────────────────────────────┐
│                   Processing...                             │
│                                                             │
│  1. Call SubscriptionManager.cancelSubscription()           │
│  2. Call Supabase Edge Function                             │
│  3. Authenticate user                                       │
│  4. Verify subscription ownership                           │
│  5. Update Stripe: cancel_at_period_end = true              │
│  6. Update Supabase: status = 'cancelling'                  │
└─────────────────────────────────────────────────────────────┘
                            │
                            ▼
┌─────────────────────────────────────────────────────────────┐
│                   Success Message                           │
│                                                             │
│  ✓ Subscription cancelled successfully.                     │
│    You will have access until the end of your               │
│    billing period.                                          │
└─────────────────────────────────────────────────────────────┘
```

## Backend Flow

```
Flutter App                 Supabase Function              Stripe API
    │                              │                           │
    │  cancelSubscription()        │                           │
    ├──────────────────────────────►                           │
    │  POST /cancel-subscription   │                           │
    │  + JWT Token                 │                           │
    │  + subscriptionId            │                           │
    │                              │                           │
    │                              │  Verify JWT               │
    │                              ├───────────►               │
    │                              │  ◄─────────               │
    │                              │  User authenticated       │
    │                              │                           │
    │                              │  Query Supabase DB        │
    │                              │  Verify ownership         │
    │                              │                           │
    │                              │  Update subscription      │
    │                              ├───────────────────────────►
    │                              │  cancel_at_period_end=true│
    │                              │                           │
    │                              │  ◄─────────────────────────
    │                              │  Subscription updated     │
    │                              │                           │
    │                              │  Update Supabase DB       │
    │                              │  status='cancelling'      │
    │                              │                           │
    │  ◄──────────────────────────┤                           │
    │  { success: true }           │                           │
    │                              │                           │
```

## Webhook Flow (At Period End)

```
Stripe                    Webhook Handler              Supabase DB
  │                              │                           │
  │  Billing period ends         │                           │
  │  Subscription cancelled      │                           │
  │                              │                           │
  │  customer.subscription.      │                           │
  │  deleted event               │                           │
  ├──────────────────────────────►                           │
  │                              │                           │
  │                              │  Update subscription      │
  │                              ├───────────────────────────►
  │                              │  status='inactive'        │
  │                              │  end_date=now()           │
  │                              │                           │
  │                              │  ◄─────────────────────────
  │                              │  Updated                  │
  │  ◄──────────────────────────┤                           │
  │  200 OK                      │                           │
```

## Status Transitions

```
┌──────────┐
│  active  │  ◄─── User has Traveler Pass
└────┬─────┘
     │
     │ User clicks "Cancel Subscription"
     │ Stripe: cancel_at_period_end = true
     ▼
┌──────────────┐
│  cancelling  │  ◄─── User still has access
└────┬─────────┘       Subscription will end at period_end
     │
     │ Billing period ends
     │ Stripe cancels subscription
     │ Webhook: customer.subscription.deleted
     ▼
┌──────────┐
│ inactive │  ◄─── User reverts to Free Plan
└──────────┘       3 scans per day limit
```

## Database Schema

```sql
user_subscriptions
├── user_id (uuid, FK to auth.users)
├── subscription_type (text) = 'traveler_pass'
├── status (text) = 'active' | 'cancelling' | 'inactive' | 'past_due'
├── plan_duration (text) = 'monthly' | 'yearly'
├── start_date (timestamp)
├── end_date (timestamp) ◄─── Access until this date
├── stripe_subscription_id (text) ◄─── Used for cancellation
├── stripe_price_id (text)
├── platform (text) = 'stripe'
├── transaction_id (text)
└── updated_at (timestamp)
```

## Key Points

1. **Immediate Cancellation Request:**

   - User clicks cancel
   - Stripe marks subscription for cancellation
   - Database status → 'cancelling'
   - User keeps full access

2. **During Cancelling Period:**

   - User has full Traveler Pass access
   - Unlimited scans continue
   - No new charges
   - Can still use app normally

3. **At Period End:**

   - Stripe automatically cancels
   - Webhook updates database
   - Status → 'inactive'
   - User → Free Plan (3 scans/day)

4. **No Refunds:**
   - User paid for the period
   - Gets access until period ends
   - Fair for both user and business

## Error Handling

```
User Action → Validation → API Call → Success/Error
                                          │
                                          ├─► Success
                                          │   └─► Show confirmation
                                          │       Update UI
                                          │
                                          └─► Error
                                              └─► Show error message
                                                  Allow retry
                                                  Log for debugging
```

## Testing Scenarios

1. ✅ Free user cannot see cancel button
2. ✅ Traveler Pass user sees cancel button
3. ✅ Cancel requires double confirmation
4. ✅ Successful cancellation shows message
5. ✅ Failed cancellation shows error
6. ✅ User keeps access after cancellation
7. ✅ Stripe shows "Cancels on [date]"
8. ✅ Database status = 'cancelling'
9. ✅ Webhook updates to 'inactive' at period end
10. ✅ User reverts to Free Plan after period
