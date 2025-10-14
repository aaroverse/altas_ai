# Netlify Deployment Guide

## Environment Variables Required

Add these environment variables in your Netlify dashboard under **Site settings** → **Environment variables**:

### Required Variables

```bash
# Supabase Configuration
SUPABASE_URL=https://gkpanxesanutgpwhsuzr.supabase.co
SUPABASE_ANON_KEY=eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImdrcGFueGVzYW51dGdwd2hzdXpyIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTk0ODQyNzcsImV4cCI6MjA3NTA2MDI3N30.PX21IVUdTc1jmVDkNdZtUi0BTpK0jHfPJDi3M1NFsDE

# Webhook Configuration (Supabase Edge Function)
WEBHOOK_URL=https://gkpanxesanutgpwhsuzr.supabase.co/functions/v1/process-menu

# Production Flag
PRODUCTION=true
```

## Build Settings

### Build Command

```bash
flutter build web --dart-define=SUPABASE_URL=$SUPABASE_URL --dart-define=SUPABASE_ANON_KEY=$SUPABASE_ANON_KEY --dart-define=WEBHOOK_URL=$WEBHOOK_URL --dart-define=PRODUCTION=$PRODUCTION --release
```

### Publish Directory

```
build/web
```

### Base Directory

```
(leave empty or set to root)
```

## Step-by-Step Deployment

### 1. Install Flutter Build Plugin (if needed)

If Netlify doesn't have Flutter pre-installed, you may need to add a build plugin or use a custom Docker image.

**Option A: Use Netlify Build Plugin**
Create a `netlify.toml` file in your project root:

```toml
[build]
  command = "flutter build web --dart-define=SUPABASE_URL=$SUPABASE_URL --dart-define=SUPABASE_ANON_KEY=$SUPABASE_ANON_KEY --dart-define=WEBHOOK_URL=$WEBHOOK_URL --dart-define=PRODUCTION=$PRODUCTION --release"
  publish = "build/web"

[build.environment]
  FLUTTER_VERSION = "3.24.0"  # Use your Flutter version

[[plugins]]
  package = "netlify-plugin-flutter"
```

**Option B: Use Custom Build Image**
In Netlify UI, set the build image to one that includes Flutter, or use GitHub Actions to build and deploy.

### 2. Configure Redirect Rules

Create a `_redirects` file in your `web` folder (or it will be in `build/web` after build):

```
/*    /index.html   200
```

This ensures Flutter's routing works correctly.

### 3. Add Environment Variables in Netlify

1. Go to your Netlify site dashboard
2. Navigate to **Site settings** → **Environment variables**
3. Click **Add a variable**
4. Add each variable listed above

### 4. Configure Supabase for Netlify Domain

Once deployed, you need to add your Netlify URL to Supabase:

1. Go to Supabase Dashboard → **Authentication** → **URL Configuration**
2. Add your Netlify URLs to **Redirect URLs**:
   ```
   https://your-site-name.netlify.app/*
   https://your-site-name.netlify.app
   ```
3. Set **Site URL** to: `https://your-site-name.netlify.app`

### 5. Configure OAuth Providers

For Google/Facebook OAuth to work on your Netlify domain:

**In Supabase:**

- Already configured (uses Supabase callback URL)

**In Google Cloud Console:**

1. Go to **APIs & Services** → **Credentials**
2. Edit your OAuth 2.0 Client ID
3. Add to **Authorized JavaScript origins**:
   ```
   https://your-site-name.netlify.app
   ```
4. Authorized redirect URIs should already have:
   ```
   https://gkpanxesanutgpwhsuzr.supabase.co/auth/v1/callback
   ```

**In Facebook Developers:**

1. Go to your app → **Settings** → **Basic**
2. Add your Netlify domain to **App Domains**
3. In **Facebook Login** → **Settings**, add:
   ```
   https://gkpanxesanutgpwhsuzr.supabase.co/auth/v1/callback
   ```

## Alternative: Deploy via GitHub Actions

If Netlify's Flutter support is limited, you can build locally or via GitHub Actions and deploy the `build/web` folder.

### GitHub Actions Workflow

Create `.github/workflows/deploy.yml`:

```yaml
name: Deploy to Netlify

on:
  push:
    branches: [main]

jobs:
  build-and-deploy:
    runs-on: ubuntu-latest

    steps:
      - uses: actions/checkout@v3

      - uses: subosito/flutter-action@v2
        with:
          flutter-version: "3.24.0"

      - name: Install dependencies
        run: flutter pub get

      - name: Build web
        run: flutter build web --dart-define=SUPABASE_URL=${{ secrets.SUPABASE_URL }} --dart-define=SUPABASE_ANON_KEY=${{ secrets.SUPABASE_ANON_KEY }} --dart-define=WEBHOOK_URL=${{ secrets.WEBHOOK_URL }} --dart-define=PRODUCTION=true --release

      - name: Deploy to Netlify
        uses: nwtgck/actions-netlify@v2.0
        with:
          publish-dir: "./build/web"
          production-branch: main
          github-token: ${{ secrets.GITHUB_TOKEN }}
          deploy-message: "Deploy from GitHub Actions"
        env:
          NETLIFY_AUTH_TOKEN: ${{ secrets.NETLIFY_AUTH_TOKEN }}
          NETLIFY_SITE_ID: ${{ secrets.NETLIFY_SITE_ID }}
```

Then add these secrets to your GitHub repository:

- `SUPABASE_URL`
- `SUPABASE_ANON_KEY`
- `WEBHOOK_URL`
- `NETLIFY_AUTH_TOKEN` (from Netlify)
- `NETLIFY_SITE_ID` (from Netlify)

## Troubleshooting

### Build Fails

- Check Flutter version compatibility
- Ensure all dependencies are compatible with web
- Check build logs for specific errors

### OAuth Not Working

- Verify redirect URLs in Supabase
- Check OAuth provider settings (Google/Facebook)
- Ensure CORS is configured correctly

### App Shows Dev Config

- Verify environment variables are set in Netlify
- Check that `PRODUCTION=true` is set
- Rebuild and redeploy

### Images/Assets Not Loading

- Check that assets are properly included in `pubspec.yaml`
- Verify paths are correct for web deployment

## Post-Deployment Checklist

- [ ] Environment variables are set in Netlify
- [ ] Netlify URL is added to Supabase redirect URLs
- [ ] OAuth providers are configured with Netlify domain
- [ ] Test sign-up with email
- [ ] Test sign-in with Facebook (Google is disabled)
- [ ] Test password reset
- [ ] Test menu scanning
- [ ] Test subscription upgrade flow
- [ ] Verify all images and assets load correctly

## Security Notes

⚠️ **Important**:

- The `SUPABASE_ANON_KEY` is safe to expose in client-side code (it's public)
- Never expose your Supabase service role key
- Keep your Netlify auth token and site ID secret
- Use Row Level Security (RLS) in Supabase to protect data
