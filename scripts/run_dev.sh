#!/bin/bash

# Development Server Script for Altas AI
# This script runs the Flutter web app on localhost:3000

echo "🚀 Starting Altas AI Development Server on localhost:3000..."

# Set development environment variables
export SUPABASE_URL="https://gkpanxesanutgpwhsuzr.supabase.co"
export SUPABASE_ANON_KEY="eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImdrcGFueGVzYW51dGdwd2hzdXpyIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTk0ODQyNzcsImV4cCI6MjA3NTA2MDI3N30.PX21IVUdTc1jmVDkNdZtUi0BTpK0jHfPJDi3M1NFsDE"
export WEBHOOK_URL="http://localhost:3000/webhook/afb1492e-cda4-44d5-9906-f91d7525d003"
export PRODUCTION="false"

echo "✅ Environment variables configured for development"
echo "🌐 Starting Flutter web server on port 3000..."

# Run Flutter web on port 3000
flutter run -d web-server --web-port=3000 \
    --dart-define=SUPABASE_URL="$SUPABASE_URL" \
    --dart-define=SUPABASE_ANON_KEY="$SUPABASE_ANON_KEY" \
    --dart-define=WEBHOOK_URL="$WEBHOOK_URL" \
    --dart-define=PRODUCTION=false

echo "🎉 Development server started!"
echo "🌐 Open http://localhost:3000 in your browser"