#!/bin/bash

# Test script for the Supabase Edge Function

SUPABASE_URL="https://gkpanxesanutgpwhsuzr.supabase.co"
SUPABASE_ANON_KEY="eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImdrcGFueGVzYW51dGdwd2hzdXpyIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTk0ODQyNzcsImV4cCI6MjA3NTA2MDI3N30.PX21IVUdTc1jmVDkNdZtUi0BTpK0jHfPJDi3M1NFsDE"

echo "Testing Supabase Edge Function with authorization..."
echo ""

# Test OPTIONS request (CORS preflight)
echo "1. Testing CORS preflight..."
curl -X OPTIONS \
  -H "Origin: https://netlify.app" \
  -H "Access-Control-Request-Method: POST" \
  -v \
  "${SUPABASE_URL}/functions/v1/process-menu" 2>&1 | grep -E "(HTTP|Access-Control)"

echo ""
echo ""

# Test POST request with authorization
echo "2. Testing POST with authorization (needs a test image)..."
echo "   Create a test image first: echo 'test' > test.txt"
echo ""
echo "   Then run:"
echo "   curl -X POST \\"
echo "     -H \"Authorization: Bearer ${SUPABASE_ANON_KEY}\" \\"
echo "     -H \"apikey: ${SUPABASE_ANON_KEY}\" \\"
echo "     -F \"file=@test.txt\" \\"
echo "     -F \"targetLanguage=English\" \\"
echo "     ${SUPABASE_URL}/functions/v1/process-menu"
echo ""
