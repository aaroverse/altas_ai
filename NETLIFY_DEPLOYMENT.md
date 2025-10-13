# 🌐 Netlify Deployment Guide for Altas AI

## 🚀 Quick Setup

### 1. Connect Your Repository

1. Go to [Netlify](https://netlify.com)
2. Click "New site from Git"
3. Connect your GitHub/GitLab repository
4. Select your Altas AI repository

### 2. Configure Build Settings

Netlify will automatically detect the `netlify.toml` file, but verify these settings:

- **Build command**: `flutter build web --release --dart-define=SUPABASE_URL=$SUPABASE_URL --dart-define=SUPABASE_ANON_KEY=$SUPABASE_ANON_KEY --dart-define=WEBHOOK_URL=$WEBHOOK_URL --dart-define=PRODUCTION=true`
- **Publish directory**: `build/web`
- **Base directory**: (leave empty)

### 3. Set Environment Variables

In Netlify Dashboard → Site settings → Environment variables, add:

```
SUPABASE_URL = https://gkpanxesanutgpwhsuzr.supabase.co
SUPABASE_ANON_KEY = eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImdrcGFueGVzYW51dGdwd2hzdXpyIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTk0ODQyNzcsImV4cCI6MjA3NTA2MDI3N30.PX21IVUdTc1jmVDkNdZtUi0BTpK0jHfPJDi3M1NFsDE
WEBHOOK_URL = http://srv858154.hstgr.cloud:5678/webhook/afb1492e-cda4-44d5-9906-f91d7525d003
PRODUCTION = true
```

### 4. Deploy!

Click "Deploy site" and Netlify will:

1. Install Flutter
2. Build your web app
3. Deploy to a live URL

## 🔧 Configuration Files

### `netlify.toml` Features:

- ✅ Automatic Flutter web builds
- ✅ SPA routing support (redirects)
- ✅ Security headers
- ✅ Caching optimization
- ✅ Environment variable injection

### Build Process:

1. Netlify clones your repo
2. Installs Flutter SDK
3. Runs `flutter pub get`
4. Builds with your environment variables
5. Deploys to CDN

## 🌍 Custom Domain (Optional)

### Add Your Domain:

1. Go to Site settings → Domain management
2. Click "Add custom domain"
3. Enter your domain (e.g., `altasai.com`)
4. Follow DNS configuration instructions

### SSL Certificate:

Netlify provides free SSL certificates automatically!

## 🔍 Monitoring & Analytics

### Build Logs:

- Check Deploys tab for build status
- View detailed logs for troubleshooting

### Performance:

- Netlify provides built-in analytics
- Monitor Core Web Vitals
- Track user engagement

## 🚨 Troubleshooting

### Common Issues:

#### Build Fails - Flutter Not Found

**Solution**: Netlify automatically installs Flutter, but if it fails:

```toml
[build.environment]
  FLUTTER_VERSION = "3.24.0"
```

#### Environment Variables Not Working

**Solution**:

1. Check spelling in Netlify dashboard
2. Ensure no extra spaces
3. Redeploy after adding variables

#### Routing Issues (404 on refresh)

**Solution**: The `netlify.toml` includes redirect rules:

```toml
[[redirects]]
  from = "/*"
  to = "/index.html"
  status = 200
```

#### Supabase Connection Issues

**Solution**:

1. Verify environment variables are set
2. Check Supabase project is active
3. Ensure anon key has correct permissions

## 📱 Progressive Web App (PWA)

Your app is PWA-ready with:

- ✅ Web manifest (`manifest.json`)
- ✅ Service worker (Flutter generates)
- ✅ Installable on mobile devices
- ✅ Offline capabilities

## 🔄 Continuous Deployment

Every push to your main branch will:

1. Trigger automatic build
2. Deploy new version
3. Update live site
4. Maintain zero downtime

## 📊 Performance Optimization

Netlify automatically provides:

- **CDN**: Global content delivery
- **Compression**: Gzip/Brotli
- **Caching**: Static asset optimization
- **HTTP/2**: Modern protocol support

## 🎯 Next Steps

1. **Deploy**: Follow the setup steps above
2. **Test**: Verify all features work on live site
3. **Monitor**: Check build logs and performance
4. **Optimize**: Use Netlify analytics for insights
5. **Scale**: Add custom domain and advanced features

## 📞 Support

- **Netlify Docs**: https://docs.netlify.com
- **Flutter Web**: https://flutter.dev/web
- **Build Issues**: Check Netlify build logs
- **App Issues**: Test locally first with `flutter run -d chrome`

Your Altas AI web app will be live at: `https://your-site-name.netlify.app` 🚀
