#!/bin/bash

# Production Build Script for Altas AI
# This script builds the app with production environment variables

echo "🚀 Building Altas AI for Production..."

# Check if environment variables are set
if [ -z "$SUPABASE_URL" ] || [ -z "$SUPABASE_ANON_KEY" ]; then
    echo "❌ Error: SUPABASE_URL and SUPABASE_ANON_KEY environment variables must be set"
    echo "Example:"
    echo "export SUPABASE_URL='https://your-project.supabase.co'"
    echo "export SUPABASE_ANON_KEY='your-anon-key-here'"
    exit 1
fi

echo "✅ Environment variables configured"
echo "📱 Building Android APK..."

# Build Android APK with environment variables
flutter build apk --release \
    --dart-define=SUPABASE_URL="$SUPABASE_URL" \
    --dart-define=SUPABASE_ANON_KEY="$SUPABASE_ANON_KEY" \
    --dart-define=WEBHOOK_URL="$WEBHOOK_URL" \
    --dart-define=PRODUCTION=true

echo "✅ Android APK built successfully!"
echo "📱 Building Android App Bundle..."

# Build Android App Bundle for Play Store
flutter build appbundle --release \
    --dart-define=SUPABASE_URL="$SUPABASE_URL" \
    --dart-define=SUPABASE_ANON_KEY="$SUPABASE_ANON_KEY" \
    --dart-define=WEBHOOK_URL="$WEBHOOK_URL" \
    --dart-define=PRODUCTION=true

echo "✅ Android App Bundle built successfully!"
echo "🎉 Production build complete!"
echo "📦 Files located in:"
echo "   - APK: build/app/outputs/flutter-apk/app-release.apk"
echo "   - AAB: build/app/outputs/bundle/release/app-release.aab"