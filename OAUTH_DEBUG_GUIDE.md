# OAuth Debug Guide - Local Development

## Issue: Google Sign-In Stuck Loading

When testing OAuth (Google/Facebook) locally on Flutter web, the browser opens but never redirects back to your app.

## Root Cause

The OAuth callback URL is not configured for localhost in Supabase.

## Fix Steps

### 1. Add Localhost to Supabase Redirect URLs

Go to your Supabase Dashboard:

1. Navigate to **Authentication** → **URL Configuration**
2. Under **Redirect URLs**, add these URLs:

```
http://localhost:3000/*
http://localhost:3000
http://127.0.0.1:3000/*
http://127.0.0.1:3000
```

If you're running on a different port (check your terminal), use that port instead of 3000.

### 2. Check Your Local Development URL

When you run `flutter run -d chrome`, check the terminal output for the actual URL:

```
Launching lib/main.dart on Chrome in debug mode...
Building application for the web...
lib/main.dart is being served at http://localhost:12345/
```

Add that specific localhost URL to Supabase redirect URLs.

### 3. Verify Google OAuth Configuration

In your **Google Cloud Console**:

1. Go to **APIs & Services** → **Credentials**
2. Find your OAuth 2.0 Client ID
3. Under **Authorized redirect URIs**, make sure you have:
   ```
   https://[your-supabase-project-ref].supabase.co/auth/v1/callback
   ```

### 4. Test the Flow

1. Stop your Flutter app
2. Clear browser cache/cookies for localhost
3. Restart: `flutter run -d chrome`
4. Try Google sign-in again

## Expected Behavior

1. Click "Sign in with Google"
2. Browser opens Google sign-in page
3. After signing in, Google redirects to Supabase
4. Supabase redirects back to your localhost
5. Your app detects the auth state change and shows the home page

## Still Not Working?

### Check Browser Console

Open browser DevTools (F12) and check for errors:

- CORS errors → Add localhost to Supabase allowed origins
- Redirect errors → Check redirect URLs in Supabase
- Network errors → Check if Supabase is reachable

### Check Flutter Console

Look for Supabase auth errors in your terminal where Flutter is running.

### Alternative: Test on Mobile Instead

OAuth works more reliably on mobile during development:

```bash
flutter run -d macos  # or ios, android
```

Mobile apps use deep links which are more reliable than web redirects.

## Production vs Development

- **Development (localhost)**: Requires localhost URLs in Supabase
- **Production (your domain)**: Requires your actual domain URLs in Supabase

Make sure both are configured in Supabase redirect URLs!
