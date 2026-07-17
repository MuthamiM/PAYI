import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:googleapis/drive/v3.dart' as drive;
import 'package:http/http.dart' as http;

class _GoogleAuthClient extends http.BaseClient {
  final Map<String, String> _headers;
  final http.Client _client = http.Client();

  _GoogleAuthClient(this._headers);

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) {
    return _client.send(request..headers.addAll(_headers));
  }
}

class GoogleDriveService {
  final GoogleSignIn _googleSignIn = GoogleSignIn.instance;

  GoogleSignInAccount? _currentUser;
  drive.DriveApi? _driveApi;

  static const String _backupFileName = "payi_wallet_recovery_phrase.txt";

  Future<void> initialize() async {
    // initialize is required once in 7.2.0
    await _googleSignIn.initialize();
    
    // Equivalent to signInSilently in 7.2.0
    final result = _googleSignIn.attemptLightweightAuthentication();
    if (result != null) {
      _currentUser = await result;
      if (_currentUser != null) {
        await _setupDriveApi();
      }
    }
  }

  Future<bool> signIn() async {
    try {
      // In 7.2.0, use authenticate()
      _currentUser = await _googleSignIn.authenticate();
      if (_currentUser != null) {
        await _setupDriveApi();
        return true;
      }
    } catch (e) {
      debugPrint("Error signing in to Google: $e");
    }
    return false;
  }

  Future<void> signOut() async {
    await _googleSignIn.signOut();
    _currentUser = null;
    _driveApi = null;
  }

  Future<void> _setupDriveApi() async {
    if (_currentUser == null) return;

    final authHeaders = await _currentUser!.authorizationClient.authorizationHeaders(
      [drive.DriveApi.driveFileScope],
      promptIfNecessary: true,
    );

    if (authHeaders != null) {
      final authenticateClient = _GoogleAuthClient(authHeaders);
      _driveApi = drive.DriveApi(authenticateClient);
    }
  }

  bool get isSigned => _currentUser != null && _driveApi != null;
  String? get currentUserEmail => _currentUser?.email;

  Future<bool> backupPassphrase(String passphrase) async {
    if (!isSigned) return false;

    try {
      // 1. Check if backup already exists
      final drive.FileList fileList = await _driveApi!.files.list(
        q: "name = '$_backupFileName' and trashed = false",
        spaces: 'drive',
      );

      String? existingFileId;
      if (fileList.files != null && fileList.files!.isNotEmpty) {
        existingFileId = fileList.files!.first.id;
      }

      // 2. Prepare the content
      final content = utf8.encode(passphrase);
      final media = drive.Media(
        Stream.value(content).asBroadcastStream(),
        content.length,
      );

      // 3. Create or update the file
      if (existingFileId != null) {
        await _driveApi!.files.update(
          drive.File(),
          existingFileId,
          uploadMedia: media,
        );
      } else {
        final driveFile = drive.File()..name = _backupFileName;
        await _driveApi!.files.create(
          driveFile,
          uploadMedia: media,
        );
      }
      return true;
    } catch (e) {
      debugPrint("Error backing up to Google Drive: $e");
      return false;
    }
  }

  Future<String?> restorePassphrase() async {
    if (!isSigned) return null;

    try {
      final drive.FileList fileList = await _driveApi!.files.list(
        q: "name = '$_backupFileName' and trashed = false",
        spaces: 'drive',
      );

      if (fileList.files != null && fileList.files!.isNotEmpty) {
        final fileId = fileList.files!.first.id!;
        final drive.Media response = await _driveApi!.files.get(
          fileId,
          downloadOptions: drive.DownloadOptions.fullMedia,
        ) as drive.Media;

        final List<int> dataStore = [];
        await for (var data in response.stream) {
          dataStore.addAll(data);
        }

        return utf8.decode(dataStore);
      }
    } catch (e) {
      debugPrint("Error restoring from Google Drive: $e");
    }
    return null;
  }
}
