# ✅ Netlify Deployment Checklist for Altas AI

## 📋 Pre-Deployment Checklist

### 🔧 Files Added/Updated:

- [x] `netlify.toml` - Build configuration
- [x] `web/index.html` - Updated metadata and SEO
- [x] `web/manifest.json` - Enhanced PWA configuration
- [x] `web/_redirects` - SPA routing backup
- [x] `NETLIFY_DEPLOYMENT.md` - Complete deployment guide
- [x] `scripts/build_web.sh` - Web build script
- [x] `scripts/test_web_build.sh` - Local testing script

### 🔐 Security Configuration:

- [x] Environment variables configured in code
- [x] No hardcoded secrets in repository
- [x] Production/development config separation

## 🚀 Deployment Steps

### 1. Repository Setup

- [ ] Push all changes to your Git repository
- [ ] Ensure `netlify.toml` is in the root directory

### 2. Netlify Account Setup

- [ ] Create/login to Netlify account
- [ ] Connect your Git provider (GitHub/GitLab)

### 3. Site Creation

- [ ] Click "New site from Git"
- [ ] Select your repository
- [ ] Verify build settings (should auto-detect from `netlify.toml`)

### 4. Environment Variables

Go to Site settings → Environment variables and add:

- [ ] `SUPABASE_URL` = `https://gkpanxesanutgpwhsuzr.supabase.co`
- [ ] `SUPABASE_ANON_KEY` = `eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImdrcGFueGVzYW51dGdwd2hzdXpyIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTk0ODQyNzcsImV4cCI6MjA3NTA2MDI3N30.PX21IVUdTc1jmVDkNdZtUi0BTpK0jHfPJDi3M1NFsDE`
- [ ] `WEBHOOK_URL` = `http://localhost:3000/webhook/afb1492e-cda4-44d5-9906-f91d7525d003`
- [ ] `PRODUCTION` = `true`

### 5. Deploy

- [ ] Click "Deploy site"
- [ ] Wait for build to complete (5-10 minutes)
- [ ] Check build logs for any errors

## 🧪 Testing

### Local Testing (Optional):

```bash
# Test build locally first
./scripts/test_web_build.sh

# Run locally to test
flutter run -d chrome
```

### Live Testing:

- [ ] Visit your Netlify URL (e.g., `https://amazing-app-123.netlify.app`)
- [ ] Test core functionality:
  - [ ] App loads correctly
  - [ ] Authentication works
  - [ ] Image upload/scanning works
  - [ ] Subscription features work
  - [ ] Profile management works

## 🌍 Post-Deployment

### Custom Domain (Optional):

- [ ] Add custom domain in Netlify
- [ ] Configure DNS settings
- [ ] SSL certificate (automatic)

### Performance:

- [ ] Check Core Web Vitals
- [ ] Test on mobile devices
- [ ] Verify PWA installation works

### Monitoring:

- [ ] Set up Netlify Analytics (optional)
- [ ] Monitor build logs
- [ ] Check error reporting

## 🔍 Troubleshooting

### If Build Fails:

1. Check environment variables are set correctly
2. Review build logs in Netlify dashboard
3. Test build locally with `./scripts/test_web_build.sh`
4. Ensure Flutter version compatibility

### If App Doesn't Work:

1. Check browser console for errors
2. Verify Supabase connection
3. Test API endpoints
4. Check network requests in DevTools

### Common Issues:

- **404 on refresh**: Redirects should be configured in `netlify.toml`
- **Blank page**: Check console for JavaScript errors
- **API errors**: Verify environment variables and Supabase setup

## 🎉 Success Indicators

Your deployment is successful when:

- [x] Build completes without errors
- [x] App loads at your Netlify URL
- [x] All core features work
- [x] PWA can be installed
- [x] Mobile responsive design works

## 📞 Support Resources

- **Netlify Docs**: https://docs.netlify.com
- **Flutter Web**: https://flutter.dev/web
- **Build Logs**: Netlify Dashboard → Deploys
- **Community**: Netlify Community Forum

---

**Your Altas AI web app will be live at**: `https://your-site-name.netlify.app` 🚀

**Estimated deployment time**: 5-10 minutes for first build
