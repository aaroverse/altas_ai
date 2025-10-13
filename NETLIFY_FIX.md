# 🔧 Netlify Deployment Fix

## The Problem

Your Netlify build was failing because it tried to clone and install Flutter during the build process, which is unreliable and often times out.

## The Solution

Deploy pre-built Flutter web files instead of building on Netlify.

## 🚀 How to Deploy

### Step 1: Build Locally

```bash
# Make the script executable
chmod +x scripts/deploy_netlify.sh

# Run the build script
./scripts/deploy_netlify.sh
```

This will:

- Clean previous builds
- Get dependencies
- Build your Flutter web app with production settings
- Create the `build/web` directory

### Step 2: Commit and Push

```bash
# Add the build directory (now allowed in .gitignore)
git add build/web

# Add the updated config files
git add netlify.toml .gitignore scripts/deploy_netlify.sh NETLIFY_FIX.md

# Commit
git commit -m "Fix: Deploy pre-built Flutter web app to Netlify"

# Push to your repository
git push
```

### Step 3: Netlify Auto-Deploys

Netlify will automatically:

- Detect the push
- Run the simple build command (just an echo)
- Deploy the pre-built `build/web` directory
- Your app goes live! 🎉

## ✅ What Changed

1. **netlify.toml**: Simplified build command to just deploy pre-built files
2. **.gitignore**: Now allows `build/web` directory to be committed
3. **scripts/deploy_netlify.sh**: New script to build locally before deployment

## 🔄 Future Deployments

Every time you want to deploy changes:

```bash
./scripts/deploy_netlify.sh
git add build/web
git commit -m "Update: [your changes]"
git push
```

## 🌐 Environment Variables

Make sure these are still set in Netlify Dashboard → Site settings → Environment variables:

- `SUPABASE_URL`
- `SUPABASE_ANON_KEY`
- `WEBHOOK_URL`
- `PRODUCTION`

**Note**: These are baked into the build when you run the script locally, so they're not strictly needed in Netlify anymore, but it's good practice to keep them there.

## 🎯 Why This Works

- **Faster**: No need to install Flutter on Netlify
- **Reliable**: Build happens on your machine where Flutter is already set up
- **Consistent**: Same build environment every time
- **Debuggable**: You can test the build locally before deploying

## 🧪 Test Locally First

Before deploying, test your build:

```bash
# After running the build script
cd build/web
python3 -m http.server 8000
# Visit http://localhost:8000
```

## 📞 Troubleshooting

### Build fails locally?

- Check Flutter is installed: `flutter --version`
- Check dependencies: `flutter pub get`
- Check for errors: `flutter doctor`

### Netlify still fails?

- Check the build/web directory is committed
- Verify netlify.toml is in the root
- Check Netlify build logs for specific errors

### App doesn't work after deployment?

- Check browser console for errors
- Verify Supabase connection
- Check that environment variables were used during build

## 🎉 Success!

Your app should now deploy successfully to Netlify without the "Build script returned non-zero exit code: 2" error.
