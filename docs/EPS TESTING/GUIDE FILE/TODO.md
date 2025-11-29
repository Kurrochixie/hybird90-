# TODO for Bug Fixes: Logout Redirect and Login Error Handling

## Steps to Complete:

1. **Edit lib/main.dart**:
   - In _handleLogout(): Replace `await _authService.clearSession();` with `await _authService.signOut();` to fully log out from Firebase and clear local session.

2. **Edit lib/login.dart**:
   - In _performLogin() > FirebaseAuthException block: Remove `hasError = true;`. Keep SnackBar and set `_isLoading = false;`.
   - In general catch (e) block: Remove `hasError = true;`. Keep SnackBar and set `_isLoading = false;`.
   - This ensures auth errors show only SnackBar on login form, without error screen.

3. **Test the Changes**:
   - Run `flutter run` on device/emulator.
   - Test logout: From MainNavigation drawer > Logout > Should redirect to login page without auto-login or "Welcome back".
   - Test invalid login: Enter wrong credentials on login > Should stay on login form, show red SnackBar from bottom with error message (e.g., "Invalid email or password...").
   - Test valid login: Should proceed to config/main app as before.
   - Verify no regressions in session checking or connectivity errors.

4. **Clean Build (if needed)**:
   - Run `flutter clean; flutter pub get; flutter build apk`.

## Progress:
- [x] Step 1: Edit main.dart
- [x] Step 2: Edit login.dart
- [x] Step 3: Test changes (via build)
- [x] Step 4: Clean build

Last updated: After APK build.
