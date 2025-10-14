# Recent Changes - Not Pushed to GitHub

## Changes Made

### 1. ✅ Google Sign-Up Temporarily Disabled

- Commented out the Google sign-in button in the auth screen
- Added `// ignore: unused_element` to suppress warnings
- The function is still there for when you want to re-enable it
- **To re-enable**: Just uncomment the Google button code in `lib/views/auth_screen.dart` (around line 810)

### 2. ✅ Reset Password Dialog Layout Fixed

- Changed button layout to vertical (stacked)
- "Send Reset Link" button is now full-width and primary
- "Cancel" button is below it, centered, and secondary style
- Applied to both:
  - Auth screen (forgot password)
  - Profile screen (reset password)

## Files Modified

- `lib/views/auth_screen.dart`
- `lib/views/profile_screen.dart`

## Testing

- [x] Google button is hidden
- [ ] Test forgot password dialog layout
- [ ] Test reset password in profile dialog layout
- [ ] Test email sign-up still works
- [ ] Test Facebook sign-in still works

## Notes

- These changes are NOT pushed to GitHub yet
- Ready to test locally
