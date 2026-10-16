import 'package:extension_google_sign_in_as_googleapis_auth/extension_google_sign_in_as_googleapis_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:googleapis/drive/v3.dart' as drive;

/// Connects the app to the user's own Google Drive for backup (Android's
/// equivalent of iCloud on Apple). Only the hidden app-data folder scope is
/// requested, so the app can never see the rest of the user's Drive — and the
/// data lives in the user's account, not on any server of ours.
class GoogleDriveAuth {
  GoogleDriveAuth()
      : _googleSignIn = GoogleSignIn(
          scopes: <String>[drive.DriveApi.driveAppdataScope],
        );

  final GoogleSignIn _googleSignIn;

  bool get isConnected => _googleSignIn.currentUser != null;

  String? get email => _googleSignIn.currentUser?.email;

  /// Restores a previous session without UI (call once at startup).
  Future<void> restore() async {
    try {
      await _googleSignIn.signInSilently();
    } catch (_) {
      // No cached session — the user simply isn't connected yet.
    }
  }

  /// Interactive sign-in. Returns the connected account's email, or null if
  /// the user cancelled or the sign-in failed.
  Future<String?> connect() async {
    try {
      final GoogleSignInAccount? account = await _googleSignIn.signIn();
      if (account != null) return account.email;
    } catch (_) {
      // signIn() can throw even when the native flow actually signed the
      // account in (e.g. the activity was recreated behind the picker).
      // Fall through and check for a live session before reporting failure.
    }
    if (_googleSignIn.currentUser == null) {
      try {
        await _googleSignIn.signInSilently();
      } catch (_) {
        // Genuinely not signed in.
      }
    }
    return _googleSignIn.currentUser?.email;
  }

  /// Revokes access and forgets the account.
  Future<void> disconnect() async {
    try {
      await _googleSignIn.disconnect();
    } catch (_) {
      await _googleSignIn.signOut();
    }
  }

  /// An authenticated Drive client, or null when the user isn't connected.
  Future<drive.DriveApi?> driveApi() async {
    if (_googleSignIn.currentUser == null) {
      await _googleSignIn.signInSilently();
    }
    final client = await _googleSignIn.authenticatedClient();
    if (client == null) return null;
    return drive.DriveApi(client);
  }
}
