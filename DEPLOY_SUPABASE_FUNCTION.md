# 🚀 Deploy Supabase Edge Function

## What We Created

A Supabase Edge Function called `process-menu` that acts as an HTTPS proxy to your HTTP webhook server. This solves the Mixed Content issue.

## 📋 Deployment Steps

### 1. Deploy the Edge Function

```bash
# Make sure you're logged in to Supabase CLI
supabase login

# Link to your project (if not already linked)
supabase link --project-ref gkpanxesanutgpwhsuzr

# Deploy the function
supabase functions deploy process-menu
```

### 2. Set Environment Variable (Optional)

If you want to change the webhook URL without redeploying:

```bash
# Set the webhook URL as a secret
supabase secrets set MENU_WEBHOOK_URL=http://srv858154.hstgr.cloud:5678/webhook/afb1492e-cda4-44d5-9906-f91d7525d003
```

### 3. Test the Function

```bash
# Test with curl
curl -X POST \
  -H "Authorization: Bearer YOUR_SUPABASE_ANON_KEY" \
  -F "file=@test-image.jpg" \
  -F "targetLanguage=English" \
  https://gkpanxesanutgpwhsuzr.supabase.co/functions/v1/process-menu
```

### 4. Rebuild and Deploy Your App

```bash
# Build with the new webhook URL
./scripts/deploy_netlify.sh

# Commit and push
git add build/web lib/config/app_config.dart scripts/deploy_netlify.sh supabase/functions/process-menu
git commit -m "Fix: Use Supabase Edge Function for menu processing"
git push
```

## 🔍 How It Works

```
Your App (HTTPS)
    ↓
Supabase Edge Function (HTTPS)
    ↓
Your Webhook Server (HTTP)
    ↓
Response back through the chain
```

**Benefits:**

- ✅ HTTPS all the way from browser to Supabase
- ✅ No Mixed Content errors
- ✅ CORS handled automatically
- ✅ No changes needed to your webhook server
- ✅ Secure and reliable

## 📝 What Changed

### Files Created:

- `supabase/functions/process-menu/index.ts` - The proxy function
- `supabase/functions/process-menu/deno.json` - Deno configuration
- `supabase/functions/process-menu/import_map.json` - Import mappings
- `supabase/functions/process-menu/.npmrc` - NPM configuration

### Files Updated:

- `lib/config/app_config.dart` - Now uses Supabase function URL
- `scripts/deploy_netlify.sh` - Updated default webhook URL

## 🧪 Testing

### Check Function Logs:

```bash
# View real-time logs
supabase functions logs process-menu --follow
```

### Test from Browser Console:

```javascript
// Test the function directly
const formData = new FormData();
formData.append("file", fileInput.files[0]);
formData.append("targetLanguage", "English");

fetch("https://gkpanxesanutgpwhsuzr.supabase.co/functions/v1/process-menu", {
  method: "POST",
  body: formData,
})
  .then((r) => r.json())
  .then(console.log);
```

## 🔐 Security Notes

- The function allows all origins (`*`) for CORS - you can restrict this if needed
- No authentication required (same as your original webhook)
- The actual webhook URL is hidden from the client

## 🐛 Troubleshooting

### Function not found?

```bash
# List all functions
supabase functions list

# Redeploy
supabase functions deploy process-menu
```

### Webhook still not working?

```bash
# Check logs
supabase functions logs process-menu

# Test webhook directly
curl -X POST \
  -F "file=@test.jpg" \
  -F "targetLanguage=English" \
  http://srv858154.hstgr.cloud:5678/webhook/afb1492e-cda4-44d5-9906-f91d7525d003
```

### CORS errors?

The function includes CORS headers for all origins. If you still see CORS errors, check browser console for details.

## 📞 Need Help?

If deployment fails:

1. Check you're logged in: `supabase status`
2. Check project is linked: `supabase projects list`
3. Check function syntax: `deno check supabase/functions/process-menu/index.ts`
4. View deployment logs for errors

## ✨ Success Indicators

Your function is working when:

- ✅ `supabase functions list` shows `process-menu`
- ✅ Test curl command returns menu data
- ✅ App successfully processes images
- ✅ No CORS or Mixed Content errors in browser
