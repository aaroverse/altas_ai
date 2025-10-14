# Language Preference Feature

## Overview

Added a default translation language setting that persists across app sessions and syncs between Profile Settings and Advanced Options.

## Changes Made

### 1. New Files Created

- **`lib/services/preferences_manager.dart`**: Manages language preferences using SharedPreferences
  - `getDefaultLanguage()`: Retrieves saved language (defaults to 'English')
  - `setDefaultLanguage()`: Saves language preference
  - `availableLanguages`: List of supported languages

### 2. Dependencies Added

- **`pubspec.yaml`**: Added `shared_preferences: ^2.3.3`

### 3. Updated Files

#### `lib/main.dart`

- Imported `PreferencesManager`
- Added `initState()` to load saved language preference on app start
- Updated `_handleLanguageChanged()` to save language preference when changed
- Removed language reset in `_resetState()` - now persists across sessions

#### `lib/views/profile_screen.dart`

- Imported `PreferencesManager`
- Added `_defaultLanguage` state variable
- Added `_loadLanguagePreference()` method
- Created `_buildLanguagePreferenceCard()` widget with dropdown selector
- Added "Preferences" section in profile screen with language setting

## How It Works

1. **On App Start**: Language preference is loaded from SharedPreferences
2. **In Advanced Options**: User can change language, which saves to SharedPreferences
3. **In Profile Settings**: User can view and change default language
4. **Persistence**: Language choice persists until user changes it (even after logout/login)
5. **Sync**: Both Advanced Options and Profile Settings use the same preference

## User Experience

- Default language: **English**
- Available languages: Chinese, English, Japanese, Korean
- Language persists across:
  - App restarts
  - Different scans
  - Login sessions
- User sees confirmation when changing language in Profile Settings

## Next Steps

1. Run `flutter pub get` to install shared_preferences
2. Hot restart the app (not just hot reload)
3. Test the feature:
   - Change language in Advanced Options → Check Profile Settings
   - Change language in Profile Settings → Check Advanced Options
   - Restart app → Language should persist
