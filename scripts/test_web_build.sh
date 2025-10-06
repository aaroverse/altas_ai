#!/bin/bash

# Test Web Build Script for Altas AI
echo "🧪 Testing Altas AI Web Build..."

# Set test environment variables (using dev config)
export SUPABASE_URL="https://gkpanxesanutgpwhsuzr.supabase.co"
export SUPABASE_ANON_KEY="eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImdrcGFueGVzYW51dGdwd2hzdXpyIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTk0ODQyNzcsImV4cCI6MjA3NTA2MDI3N30.PX21IVUdTc1jmVDkNdZtUi0BTpK0jHfPJDi3M1NFsDE"
export WEBHOOK_URL="http://srv858154.hstgr.cloud:5678/webhook/afb1492e-cda4-44d5-9906-f91d7525d003"
export PRODUCTION="false"

echo "🔧 Building web app..."
flutter build web --release \
    --dart-define=SUPABASE_URL="$SUPABASE_URL" \
    --dart-define=SUPABASE_ANON_KEY="$SUPABASE_ANON_KEY" \
    --dart-define=WEBHOOK_URL="$WEBHOOK_URL" \
    --dart-define=PRODUCTION="$PRODUCTION" \
    --web-renderer canvaskit

if [ $? -eq 0 ]; then
    echo "✅ Web build successful!"
    echo "📁 Output: build/web/"
    echo "🌐 To test locally, run: flutter run -d chrome"
    echo "📦 Build size:"
    du -sh build/web/
else
    echo "❌ Web build failed!"
    exit 1
fi