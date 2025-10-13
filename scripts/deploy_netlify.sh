#!/bin/bash

# Netlify Deployment Script for Altas AI
# This script builds the Flutter web app locally and prepares it for Netlify deployment

set -e  # Exit on error

echo "🚀 Building Altas AI for Netlify deployment..."

# Check if Flutter is installed
if ! command -v flutter &> /dev/null; then
    echo "❌ Flutter is not installed. Please install Flutter first."
    exit 1
fi

# Environment variables (these will be injected by Netlify at runtime)
# For local testing, you can set them here
SUPABASE_URL="${SUPABASE_URL:-https://gkpanxesanutgpwhsuzr.supabase.co}"
SUPABASE_ANON_KEY="${SUPABASE_ANON_KEY:-eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImdrcGFueGVzYW51dGdwd2hzdXpyIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTk0ODQyNzcsImV4cCI6MjA3NTA2MDI3N30.PX21IVUdTc1jmVDkNdZtUi0BTpK0jHfPJDi3M1NFsDE}"
WEBHOOK_URL="${WEBHOOK_URL:-http://localhost:3000/webhook/afb1492e-cda4-44d5-9906-f91d7525d003}"

echo "📦 Cleaning previous builds..."
flutter clean

echo "📥 Getting dependencies..."
flutter pub get

echo "🔨 Building Flutter web app..."
flutter build web --release \
    --dart-define=SUPABASE_URL="$SUPABASE_URL" \
    --dart-define=SUPABASE_ANON_KEY="$SUPABASE_ANON_KEY" \
    --dart-define=WEBHOOK_URL="$WEBHOOK_URL" \
    --dart-define=PRODUCTION=true

echo "✅ Build complete!"
echo ""
echo "📤 Next steps:"
echo "1. Commit the build/web directory: git add build/web"
echo "2. Commit changes: git commit -m 'Build for Netlify deployment'"
echo "3. Push to repository: git push"
echo "4. Netlify will automatically deploy the pre-built files"
echo ""
echo "🌐 Your app will be live at your Netlify URL shortly!"
