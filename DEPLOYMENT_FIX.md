# Deployment Fix - Why Changes Weren't Showing

## The Problem

Your Netlify was configured to deploy **pre-built files** from `build/web`, but the build command was just `echo 'Deploy pre-built Flutter web app'` which doesn't actually build anything.

So when you pushed code changes:

1. Netlify detected the push
2. Ran the echo command (did nothing)
3. Deployed the old `build/web` files from your repo
4. Your changes never appeared

## The Solution

I've updated `netlify.toml` to **build Flutter on Netlify's servers** automatically.

### What Changed

**Before:**

```toml
command = "echo 'Deploy pre-built Flutter web app'"
```

**After:**

```toml
command = """
  git clone https://github.com/flutter/flutter.git -b stable --depth 1
  export PATH="$PATH:`pwd`/flutter/bin"
  flutter doctor
  flutter pub get
  flutter build web --release --dart-define=SUPABASE_URL=$SUPABASE_URL ...
"""
```

## Next Steps

### 1. Push the Updated Config

```bash
git push origin main
```

### 2. Verify Environment Variables in Netlify

Make sure these are set in **Netlify Dashboard** → **Site settings** → **Environment variables**:

- `SUPABASE_URL`
- `SUPABASE_ANON_KEY`
- `WEBHOOK_URL`
- `PRODUCTION` (set to `true`)

### 3. Trigger a New Deploy

After pushing, Netlify will:

1. Clone your repo
2. Install Flutter
3. Build your app with the latest code
4. Deploy the fresh build

This will take 5-10 minutes (first build is slower because it installs Flutter).

### 4. Verify the Changes

Once deployed, check your Netlify URL and you should see:

- ✅ Google sign-in button removed
- ✅ Traveler Pass teaser removed
- ✅ Reset password dialog with new layout
- ✅ All your latest changes

## Alternative: Build Locally (Faster Deploys)

If you prefer faster deploys, you can build locally:

```bash
# Build locally
./scripts/deploy_netlify.sh

# Commit the built files
git add build/web
git commit -m "Build for deployment"

# Push
git push
```

Then revert `netlify.toml` back to:

```toml
command = "echo 'Deploy pre-built Flutter web app'"
```

**Pros**: Faster Netlify deploys (no build time)
**Cons**: Must build locally before each push, larger repo

## Recommended Approach

**Use server-side builds** (current setup) because:

- ✅ Automatic - just push code
- ✅ Consistent builds
- ✅ No need to build locally
- ✅ Smaller repo size
- ❌ Slower first deploy (5-10 min)

The build time is only slow the first time. Subsequent builds are cached and faster.
