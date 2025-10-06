#!/bin/bash

# Web Build Script for Altas AI on Netlify
echo "🌐 Building Altas AI for Web Deployment..."

# Check if environment variables are set
if [ -z "$SUPABASE_URL" ] || [ -z "$SUPABASE_ANON_KEY" ]; then
    echo "❌ Error: SUPABASE_URL and SUPABASE_ANON_KEY environment variables must be set"
    echo "Set them in Netlify dashboard under Site settings > Environment variables"
    exit 1
fi

echo "✅ Environment variables configured"
echo "🔧 Installing Flutter..."

# Install Flutter (for Netlify build environment)
if [ ! -d "flutter" ]; then
    git clone https://github.com/flutter/flutter.git -b stable --depth 1
fi

export PATH="$PATH:`pwd`/flutter/bin"

echo "📦 Getting dependencies..."
flutter pub get

echo "🌐 Building web app..."
flutter build web --release \
    --dart-define=SUPABASE_URL="$SUPABASE_URL" \
    --dart-define=SUPABASE_ANON_KEY="$SUPABASE_ANON_KEY" \
    --dart-define=WEBHOOK_URL="$WEBHOOK_URL" \
    --dart-define=PRODUCTION=true \
    --web-renderer canvaskit

echo "✅ Web build complete!"
echo "📁 Output directory: build/web"