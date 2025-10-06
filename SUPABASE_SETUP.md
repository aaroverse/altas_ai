# Supabase Setup for MenuSense App

This guide will help you set up the necessary Supabase configuration for the MenuSense app's profile and subscription management features.

## 1. Database Setup

### Step 1: Run the SQL Schema

1. Open your Supabase dashboard
2. Go to the SQL Editor
3. Copy and paste the contents of `supabase_setup.sql`
4. Run the SQL commands

This will create:

- `profiles` table for user profile information
- `user_subscriptions` table for subscription management
- `usage_tracking` table for analytics (optional)
- Row Level Security (RLS) policies
- Storage bucket for avatar images
- Automatic triggers for new user creation

### Step 2: Configure Authentication

1. In your Supabase dashboard, go to Authentication > Settings
2. Enable the authentication providers you want to use:
   - **Google OAuth**: Configure with your Google OAuth credentials
   - **Facebook OAuth**: Configure with your Facebook app credentials
   - **Email/Password**: Should be enabled by default

### Step 3: Configure Storage

The SQL script automatically creates an `avatars` storage bucket, but you should verify:

1. Go to Storage in your Supabase dashboard
2. Confirm the `avatars` bucket exists
3. Check that the bucket is set to public (for avatar images)

## 2. Flutter App Configuration

### Step 1: Update Supabase Credentials

In your `lib/main.dart` file, replace the placeholder values:

```dart
await Supabase.initialize(
  url: 'YOUR_SUPABASE_URL',
  anonKey: 'YOUR_SUPABASE_ANON_KEY',
);
```

### Step 2: Add Required Dependencies

Make sure your `pubspec.yaml` includes:

```yaml
dependencies:
  supabase_flutter: ^2.0.0
  image_picker: ^1.0.0
  # ... other dependencies
```

## 3. Database Schema Details

### Profiles Table

```sql
profiles (
  id UUID PRIMARY KEY,           -- References auth.users(id)
  full_name TEXT,               -- User's display name
  avatar_url TEXT,              -- URL to user's avatar image
  created_at TIMESTAMP,         -- Account creation time
  updated_at TIMESTAMP          -- Last profile update
)
```

### User Subscriptions Table

```sql
user_subscriptions (
  id UUID PRIMARY KEY,
  user_id UUID,                 -- References auth.users(id)
  subscription_type TEXT,       -- 'pro', 'basic', etc.
  status TEXT,                  -- 'active', 'inactive', 'cancelled', 'expired'
  start_date TIMESTAMP,         -- Subscription start date
  end_date TIMESTAMP,           -- Subscription end date
  platform TEXT,               -- 'ios', 'android', 'web'
  transaction_id TEXT,          -- Platform-specific transaction ID
  created_at TIMESTAMP,
  updated_at TIMESTAMP
)
```

### Usage Tracking Table (Optional)

```sql
usage_tracking (
  id UUID PRIMARY KEY,
  user_id UUID,                 -- References auth.users(id)
  action_type TEXT,             -- 'scan', 'translation', 'recommendation'
  metadata JSONB,               -- Additional action data
  created_at TIMESTAMP
)
```

## 4. Security Features

### Row Level Security (RLS)

All tables have RLS enabled with policies that ensure:

- Users can only access their own data
- Proper authentication is required for all operations
- Storage policies protect avatar uploads

### Automatic User Creation

When a new user signs up:

1. A profile record is automatically created
2. A default subscription record is created (inactive status)
3. User metadata is populated from OAuth providers

## 5. Subscription Management

### Subscription Status Values

- `active`: User has a valid, active subscription
- `inactive`: User doesn't have an active subscription
- `cancelled`: User cancelled but may still have access until end date
- `expired`: Subscription has expired

### Usage Tracking

The app can track user actions for analytics:

- Menu scans
- Translation requests
- AI recommendations
- Feature usage patterns

## 6. Testing the Setup

### Test Profile Updates

1. Sign in to the app
2. Go to Profile & Settings
3. Try updating your name and avatar
4. Check the Supabase dashboard to see the data

### Test Subscription Status

1. Check the subscription management section
2. Verify the subscription status displays correctly
3. Test the subscription management modal

## 7. Production Considerations

### Environment Variables

For production, consider using environment variables for sensitive data:

- Supabase URL
- Supabase anon key
- OAuth client secrets

### Backup Strategy

- Set up automated backups for your Supabase database
- Consider point-in-time recovery options

### Monitoring

- Set up monitoring for database performance
- Track authentication success/failure rates
- Monitor storage usage for avatar images

## 8. Troubleshooting

### Common Issues

1. **RLS Policies**: If users can't access their data, check RLS policies
2. **Storage Permissions**: If avatar uploads fail, verify storage policies
3. **OAuth Setup**: Ensure OAuth providers are correctly configured
4. **Database Triggers**: Check that the user creation trigger is working

### Debug Queries

```sql
-- Check if profiles are being created
SELECT * FROM profiles WHERE id = 'USER_ID';

-- Check subscription status
SELECT * FROM user_subscriptions WHERE user_id = 'USER_ID';

-- Check usage tracking
SELECT * FROM usage_tracking WHERE user_id = 'USER_ID' ORDER BY created_at DESC;
```

This setup provides a robust foundation for user management, subscription tracking, and analytics in your MenuSense app.
