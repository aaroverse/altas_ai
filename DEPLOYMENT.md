# 🚀 Altas AI Deployment Guide

## 🔐 Security Configuration

### Environment Variables Required

Before deploying, you must set these environment variables:

```bash
export SUPABASE_URL="https://your-project.supabase.co"
export SUPABASE_ANON_KEY="your-anon-key-here"
export WEBHOOK_URL="https://your-webhook-url.com"
export PRODUCTION=true
```

### 🛡️ Security Best Practices

1. **Never commit sensitive keys** to version control
2. **Use environment variables** for production builds
3. **Rotate keys regularly** in production
4. **Use different keys** for development vs production

## 📱 Building for Production

### Android

#### Option 1: Using the Build Script

```bash
chmod +x scripts/build_production.sh
./scripts/build_production.sh
```

#### Option 2: Manual Build

```bash
# APK for direct installation
flutter build apk --release \
    --dart-define=SUPABASE_URL="$SUPABASE_URL" \
    --dart-define=SUPABASE_ANON_KEY="$SUPABASE_ANON_KEY" \
    --dart-define=WEBHOOK_URL="$WEBHOOK_URL" \
    --dart-define=PRODUCTION=true

# App Bundle for Google Play Store
flutter build appbundle --release \
    --dart-define=SUPABASE_URL="$SUPABASE_URL" \
    --dart-define=SUPABASE_ANON_KEY="$SUPABASE_ANON_KEY" \
    --dart-define=WEBHOOK_URL="$WEBHOOK_URL" \
    --dart-define=PRODUCTION=true
```

### iOS

```bash
flutter build ios --release \
    --dart-define=SUPABASE_URL="$SUPABASE_URL" \
    --dart-define=SUPABASE_ANON_KEY="$SUPABASE_ANON_KEY" \
    --dart-define=WEBHOOK_URL="$WEBHOOK_URL" \
    --dart-define=PRODUCTION=true
```

### Web

```bash
flutter build web --release \
    --dart-define=SUPABASE_URL="$SUPABASE_URL" \
    --dart-define=SUPABASE_ANON_KEY="$SUPABASE_ANON_KEY" \
    --dart-define=WEBHOOK_URL="$WEBHOOK_URL" \
    --dart-define=PRODUCTION=true
```

## 🔧 CI/CD Configuration

### GitHub Actions Example

```yaml
name: Build and Deploy
on:
  push:
    branches: [main]

jobs:
  build:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      - uses: subosito/flutter-action@v2

      - name: Build APK
        env:
          SUPABASE_URL: ${{ secrets.SUPABASE_URL }}
          SUPABASE_ANON_KEY: ${{ secrets.SUPABASE_ANON_KEY }}
          WEBHOOK_URL: ${{ secrets.WEBHOOK_URL }}
        run: |
          flutter build apk --release \
            --dart-define=SUPABASE_URL="$SUPABASE_URL" \
            --dart-define=SUPABASE_ANON_KEY="$SUPABASE_ANON_KEY" \
            --dart-define=WEBHOOK_URL="$WEBHOOK_URL" \
            --dart-define=PRODUCTION=true
```

## 🏪 App Store Deployment

### Google Play Store

1. Build App Bundle: `flutter build appbundle --release`
2. Upload to Google Play Console
3. Configure store listing with "Altas AI" branding

### Apple App Store

1. Build iOS app: `flutter build ios --release`
2. Archive in Xcode
3. Upload to App Store Connect
4. Configure store listing with "Altas AI" branding

## 🔍 Verification

After building, verify your configuration:

```bash
# Check that sensitive data is not in the build
grep -r "gkpanxesanutgpwhsuzr" build/ || echo "✅ No hardcoded URLs found"
grep -r "eyJhbGciOiJIUzI1NiIs" build/ || echo "✅ No hardcoded keys found"
```

## 🚨 Security Checklist

- [ ] Environment variables are set
- [ ] `dev_config.dart` is in `.gitignore`
- [ ] No hardcoded keys in source code
- [ ] Production keys are different from development
- [ ] Keys are stored securely (not in plain text files)
- [ ] App is built with `PRODUCTION=true`

## 📞 Support

For deployment issues, check:

1. Environment variables are correctly set
2. Flutter version compatibility
3. Platform-specific build requirements
4. Supabase project configuration
