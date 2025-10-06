# MenuSense Subscription Model Implementation

## Overview

Implemented a new subscription model with Free Plan and Traveler Pass options.

## Subscription Plans

### Free Plan

- **3 scans per day** (resets every 24 hours)
- Basic features
- Ad-supported experience

### Traveler Pass

- **Unlimited scans**
- **Ad-free experience**
- **Priority support**
- **Pricing**:
  - Monthly: $4.99/month
  - Yearly: $34.99/year (40% savings - "Best Value")

## Database Changes

### New Tables

1. **`daily_usage`** - Tracks daily scan usage for free users
2. **Updated `user_subscriptions`** - Modified for new subscription types

### Key Fields

- `subscription_type`: 'free' or 'traveler_pass'
- `plan_duration`: 'monthly' or 'yearly'
- `scans_used`: Daily scan counter
- `usage_date`: Date for daily tracking

## UI Changes

### 1. Main Screen (Ready View)

- **Profile icon**: Now positioned at top-right corner (0px from top/right)
- **Scan limit checking**: Prevents scanning when daily limit reached
- **Usage tracking**: Increments scan count after successful scan

### 2. Auth Screen

- **Title**: Changed to "Get Traveler Pass"
- **Features**: Updated to include "Ad-free experience"
- **Pricing**: Shows both monthly and yearly options with "Best Value" badge
- **Button**: Changed to "Get Traveler Pass"

### 3. Profile Screen

- **Edit button**: Changed to icon-only (removed text)
- **Subscription card**: Shows current plan, status, and remaining scans
- **Plan display**:
  - Free Plan: Shows "X/3 today" remaining scans
  - Traveler Pass: Shows "Unlimited" with PRO badge
- **Management modal**: Different content based on subscription status

## Technical Implementation

### New Service: `SubscriptionManager`

- `canScan()`: Check if user can perform a scan
- `getRemainingScans()`: Get remaining scans for today
- `incrementScanUsage()`: Track scan usage
- `hasTravelerPass()`: Check for active subscription
- `getSubscriptionInfo()`: Get display information

### Database Functions

- `increment_daily_usage()`: SQL function to safely increment daily usage
- Automatic user creation with free plan
- Daily usage tracking with date-based resets

## Setup Instructions

### 1. Run Database Migration

```sql
-- Execute the updated supabase_setup.sql file
-- This creates new tables and functions
```

### 2. Update App Dependencies

```yaml
# No new dependencies required
# Uses existing Supabase and Flutter packages
```

### 3. Test the Implementation

1. **Free users**: Can scan 3 times per day
2. **Limit reached**: Shows upgrade prompt
3. **Traveler Pass**: Unlimited scans
4. **Daily reset**: Usage resets at midnight

## User Experience Flow

### Free User Journey

1. User gets 3 free scans per day
2. After 3 scans, sees upgrade prompt
3. Can upgrade to Traveler Pass for unlimited access
4. Usage resets daily at midnight

### Traveler Pass User Journey

1. Unlimited scans
2. Ad-free experience
3. Priority support
4. Subscription management through device settings

## Business Model Benefits

- **Freemium approach**: Attracts users with free tier
- **Clear value proposition**: Unlimited scans for travelers
- **Competitive pricing**: Monthly and yearly options
- **Retention strategy**: Daily usage creates habit formation

## Future Enhancements

- In-app purchase integration
- Usage analytics dashboard
- Promotional campaigns
- Referral system
- Family plans
