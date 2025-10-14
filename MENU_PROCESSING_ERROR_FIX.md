# Menu Processing Error Fix

## Error

```
"Failed to process menu image", "details": "Unexpected end of JSON input"
```

## Root Cause

The `process-menu` Edge Function is receiving an invalid JSON response from your n8n webhook. This happens when:

1. **n8n webhook is down** - The webhook URL is not responding
2. **n8n returns HTML error page** - Instead of JSON
3. **Response timeout** - The AI processing takes too long and response is cut off
4. **Network issue** - Connection between Supabase and n8n fails

## What I Fixed

Updated `supabase/functions/process-menu/index.ts` to:

1. **Better error handling** - Catches JSON parse errors
2. **Detailed logging** - Shows what the webhook actually returned
3. **Response preview** - Shows first 500 chars of response for debugging

## Immediate Actions

### 1. Check if n8n Webhook is Running

Test the webhook directly:

```bash
curl -X POST http://srv858154.hstgr.cloud:5678/webhook/afb1492e-cda4-44d5-9906-f91d7525d003 \
  -F "file=@test-image.jpg" \
  -F "targetLanguage=English"
```

Expected response: Valid JSON with menu items

### 2. Check n8n Workflow

1. Go to your n8n instance: `http://srv858154.hstgr.cloud:5678`
2. Find the menu processing workflow
3. Check if it's **active** (not paused)
4. Test the workflow manually
5. Check for any errors in the workflow

### 3. Deploy the Updated Edge Function

```bash
supabase functions deploy process-menu
```

This will give you better error messages showing what the webhook actually returned.

### 4. Check Edge Function Logs

After deploying, try scanning a menu again and check the logs:

1. Go to Supabase Dashboard → **Edge Functions** → **process-menu**
2. Click **Logs**
3. Look for the error details and response preview

## Common Issues & Solutions

### Issue 1: n8n Webhook Returns HTML

**Symptom**: Response starts with `<!DOCTYPE html>` or `<html>`

**Solution**:

- n8n is returning an error page
- Check n8n logs for the actual error
- Make sure the workflow is active
- Verify the webhook URL is correct

### Issue 2: Timeout

**Symptom**: Response is empty or cut off

**Solution**:

- Increase timeout in Edge Function (add to deno.json):
  ```json
  {
    "timeout": 300
  }
  ```
- Optimize your n8n workflow to process faster
- Consider using async processing with webhooks

### Issue 3: CORS Error

**Symptom**: Request blocked by CORS policy

**Solution**: Already handled in the Edge Function with CORS headers

### Issue 4: n8n is Down

**Symptom**: Connection refused or timeout

**Solution**:

- Check if n8n server is running
- Verify the URL is accessible from Supabase
- Check firewall rules
- Consider using a more reliable hosting

## Alternative: Use Supabase Edge Function Directly

Instead of proxying to n8n, you could process images directly in the Edge Function:

```typescript
// Use OpenAI API directly in Edge Function
const openai = new OpenAI({
  apiKey: Deno.env.get("OPENAI_API_KEY"),
});

const response = await openai.chat.completions.create({
  model: "gpt-4-vision-preview",
  messages: [
    {
      role: "user",
      content: [
        { type: "text", text: "Analyze this menu..." },
        { type: "image_url", image_url: { url: imageUrl } },
      ],
    },
  ],
});
```

This would be more reliable but requires moving your AI logic from n8n to the Edge Function.

## Testing After Fix

1. Deploy the updated Edge Function
2. Try scanning a menu in production
3. Check the Edge Function logs for detailed error info
4. The error message will now show what the webhook actually returned
5. Use that info to debug the n8n workflow

## Environment Variables

Make sure this is set in Supabase Edge Functions:

```
MENU_WEBHOOK_URL=http://srv858154.hstgr.cloud:5678/webhook/afb1492e-cda4-44d5-9906-f91d7525d003
```

## Next Steps

1. **Don't deploy yet** - Wait for your approval
2. Test n8n webhook manually first
3. Deploy the updated Edge Function
4. Check logs for detailed error info
5. Fix the root cause based on the logs
