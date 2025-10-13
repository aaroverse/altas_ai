# 🔧 Webhook Connection Issue - Fix Guide

## 🚨 Current Problem

Your app is trying to connect to: `http://srv858154.hstgr.cloud:5678/webhook/afb1492e-cda4-44d5-9906-f91d7525d003`

This is failing with: **"ClientException: Failed to fetch"**

## 🔍 Root Causes

### 1. **CORS (Cross-Origin Resource Sharing) Issue**

Your webhook server at `srv858154.hstgr.cloud:5678` likely doesn't have CORS headers configured to allow requests from your Netlify domain.

**What happens:**

- Browser blocks the request for security reasons
- You see "Failed to fetch" error

**Solution:** Configure CORS on your webhook server to allow:

```
Access-Control-Allow-Origin: https://your-netlify-app.netlify.app
Access-Control-Allow-Methods: POST, OPTIONS
Access-Control-Allow-Headers: Content-Type
```

### 2. **HTTP vs HTTPS Mixed Content**

Your Netlify app is served over HTTPS, but your webhook uses HTTP. Modern browsers block HTTP requests from HTTPS pages.

**Solution:** Use HTTPS for your webhook server:

```
https://srv858154.hstgr.cloud:5678/webhook/...
```

### 3. **Server Accessibility**

The webhook server might be:

- Down or not running
- Behind a firewall
- Not publicly accessible

## ✅ Recommended Solutions

### Option 1: Fix Your Current Webhook Server (Quickest)

1. **Enable HTTPS** on `srv858154.hstgr.cloud`

   - Get an SSL certificate (Let's Encrypt is free)
   - Configure your server to use HTTPS

2. **Add CORS Headers** to your webhook endpoint

   ```javascript
   // Example for Node.js/Express
   app.use((req, res, next) => {
     res.header("Access-Control-Allow-Origin", "*"); // Or specific domain
     res.header("Access-Control-Allow-Methods", "POST, OPTIONS");
     res.header("Access-Control-Allow-Headers", "Content-Type");
     if (req.method === "OPTIONS") {
       return res.sendStatus(200);
     }
     next();
   });
   ```

3. **Update the webhook URL** in your code to use HTTPS:

   ```bash
   # In scripts/deploy_netlify.sh, change:
   WEBHOOK_URL="https://srv858154.hstgr.cloud:5678/webhook/afb1492e-cda4-44d5-9906-f91d7525d003"
   ```

4. **Rebuild and redeploy:**
   ```bash
   ./scripts/deploy_netlify.sh
   git add build/web scripts/deploy_netlify.sh
   git commit -m "Fix: Use HTTPS webhook URL"
   git push
   ```

### Option 2: Create a Supabase Edge Function (Recommended for Production)

Create a Supabase Edge Function that acts as a proxy to your webhook:

1. **Create the function:**

   ```bash
   supabase functions new process-menu
   ```

2. **Implement the proxy** (in `supabase/functions/process-menu/index.ts`):

   ```typescript
   import { serve } from "https://deno.land/std@0.168.0/http/server.ts";

   serve(async (req) => {
     // Handle CORS
     if (req.method === "OPTIONS") {
       return new Response("ok", {
         headers: {
           "Access-Control-Allow-Origin": "*",
           "Access-Control-Allow-Methods": "POST",
           "Access-Control-Allow-Headers": "Content-Type",
         },
       });
     }

     try {
       // Forward request to your webhook
       const formData = await req.formData();

       const response = await fetch(
         "http://srv858154.hstgr.cloud:5678/webhook/afb1492e-cda4-44d5-9906-f91d7525d003",
         {
           method: "POST",
           body: formData,
         }
       );

       const data = await response.json();

       return new Response(JSON.stringify(data), {
         headers: {
           "Content-Type": "application/json",
           "Access-Control-Allow-Origin": "*",
         },
       });
     } catch (error) {
       return new Response(JSON.stringify({ error: error.message }), {
         status: 500,
         headers: {
           "Content-Type": "application/json",
           "Access-Control-Allow-Origin": "*",
         },
       });
     }
   });
   ```

3. **Deploy the function:**

   ```bash
   supabase functions deploy process-menu
   ```

4. **Update your app to use the Supabase function:**

   In `lib/config/app_config.dart`:

   ```dart
   static const String webhookUrl = String.fromEnvironment(
     'WEBHOOK_URL',
     defaultValue:
         'https://gkpanxesanutgpwhsuzr.supabase.co/functions/v1/process-menu',
   );
   ```

5. **Update deploy script:**

   ```bash
   # In scripts/deploy_netlify.sh
   WEBHOOK_URL="${WEBHOOK_URL:-https://gkpanxesanutgpwhsuzr.supabase.co/functions/v1/process-menu}"
   ```

6. **Rebuild and redeploy:**
   ```bash
   ./scripts/deploy_netlify.sh
   git add build/web lib/config/app_config.dart scripts/deploy_netlify.sh
   git commit -m "Fix: Use Supabase Edge Function for menu processing"
   git push
   ```

### Option 3: Use Netlify Functions (Alternative)

Create a Netlify Function that proxies to your webhook:

1. **Create `netlify/functions/process-menu.js`:**

   ```javascript
   const fetch = require("node-fetch");
   const FormData = require("form-data");

   exports.handler = async (event) => {
     if (event.httpMethod !== "POST") {
       return { statusCode: 405, body: "Method Not Allowed" };
     }

     try {
       const formData = new FormData();
       // Parse and forward the request

       const response = await fetch(
         "http://srv858154.hstgr.cloud:5678/webhook/afb1492e-cda4-44d5-9906-f91d7525d003",
         {
           method: "POST",
           body: formData,
         }
       );

       const data = await response.json();

       return {
         statusCode: 200,
         headers: {
           "Content-Type": "application/json",
           "Access-Control-Allow-Origin": "*",
         },
         body: JSON.stringify(data),
       };
     } catch (error) {
       return {
         statusCode: 500,
         body: JSON.stringify({ error: error.message }),
       };
     }
   };
   ```

2. **Update webhook URL to use Netlify function:**
   ```
   https://your-app.netlify.app/.netlify/functions/process-menu
   ```

## 🧪 Testing Your Webhook

### Test if webhook is accessible:

```bash
# Test from command line
curl -X POST \
  -F "file=@test-image.jpg" \
  -F "targetLanguage=English" \
  http://srv858154.hstgr.cloud:5678/webhook/afb1492e-cda4-44d5-9906-f91d7525d003
```

### Test CORS:

```bash
curl -X OPTIONS \
  -H "Origin: https://your-app.netlify.app" \
  -H "Access-Control-Request-Method: POST" \
  -v \
  http://srv858154.hstgr.cloud:5678/webhook/afb1492e-cda4-44d5-9906-f91d7525d003
```

Look for these headers in the response:

- `Access-Control-Allow-Origin`
- `Access-Control-Allow-Methods`

## 📝 Files That Reference Webhook URLs

All localhost references have been updated to production URLs:

✅ **Updated Files:**

- `scripts/deploy_netlify.sh` - Uses production webhook
- `NETLIFY_DEPLOYMENT.md` - Documentation updated
- `NETLIFY_CHECKLIST.md` - Checklist updated

⚠️ **Development Files (Keep localhost for local dev):**

- `scripts/run_dev.sh` - Uses localhost (correct for dev)
- `scripts/test_web_build.sh` - Uses localhost (correct for testing)

## 🎯 Next Steps

1. **Choose a solution** (Option 1 is quickest, Option 2 is best for production)
2. **Implement the fix**
3. **Test the webhook** using curl commands above
4. **Rebuild and redeploy** your app
5. **Test in production**

## 🔐 Security Notes

- Never commit API keys or secrets to git
- Use environment variables for sensitive data
- Enable HTTPS for all production endpoints
- Restrict CORS to specific domains in production

## 📞 Manual Changes Needed

### In Your Webhook Server (srv858154.hstgr.cloud):

1. ✅ Enable HTTPS with SSL certificate
2. ✅ Add CORS headers to allow requests from Netlify
3. ✅ Ensure server is publicly accessible
4. ✅ Test endpoint responds correctly

### In Stripe Dashboard (if using Stripe):

No changes needed - Stripe webhooks are separate from this menu processing webhook.

### In Supabase Dashboard:

No changes needed unless you choose Option 2 (Supabase Edge Function).

## 🐛 Debugging

If still not working after fixes:

1. **Check browser console** for detailed error messages
2. **Check Network tab** in browser DevTools to see the actual request
3. **Verify webhook server logs** to see if requests are arriving
4. **Test with curl** to isolate browser vs server issues
5. **Check firewall rules** on srv858154.hstgr.cloud

## ✨ Success Indicators

Your webhook is working when:

- ✅ No CORS errors in browser console
- ✅ Request shows in Network tab with 200 status
- ✅ Menu items are displayed in the app
- ✅ No "Failed to fetch" errors
