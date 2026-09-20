import 'dart:convert';
import 'dart:io';
import 'package:extension_google_sign_in_as_googleapis_auth/extension_google_sign_in_as_googleapis_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:googleapis/drive/v3.dart' as drive;
import 'package:path_provider/path_provider.dart';
import '../database/local_storage_service.dart';

class GoogleDriveService {
  static final GoogleDriveService instance = GoogleDriveService._internal();
  GoogleDriveService._internal();

  factory GoogleDriveService() => instance;

  final GoogleSignIn _googleSignIn = GoogleSignIn(
    scopes: [
      drive.DriveApi.driveFileScope,
      drive.DriveApi.driveAppdataScope,
    ],
  );

  GoogleSignInAccount? _currentUser;
  GoogleSignInAccount? get currentUser => _currentUser;

  bool get isSignedIn => _currentUser != null;

  Future<GoogleSignInAccount?> signIn() async {
    try {
      final account = await _googleSignIn.signIn();
      _currentUser = account;
      return account;
    } catch (e) {
      return null;
    }
  }

  Future<GoogleSignInAccount?> signInSilently() async {
    try {
      final account = await _googleSignIn.signInSilently();
      _currentUser = account;
      return account;
    } catch (_) {
      return null;
    }
  }

  Future<void> signOut() async {
    try {
      await _googleSignIn.signOut();
      _currentUser = null;
    } catch (_) {}
  }

  Future<drive.DriveApi?> _getDriveApi() async {
    final client = await _googleSignIn.authenticatedClient();
    if (client == null) return null;
    return drive.DriveApi(client);
  }

  Future<String?> findCashbookFileId() async {
    final driveApi = await _getDriveApi();
    if (driveApi == null) return null;

    final fileList = await driveApi.files.list(
      spaces: 'drive,appDataFolder',
      q: "name = 'data.cashbook' and trashed = false",
      $fields: 'files(id, name, modifiedTime)',
    );

    if (fileList.files != null && fileList.files!.isNotEmpty) {
      return fileList.files!.first.id;
    }
    return null;
  }

  Future<bool> syncWithGoogleDrive() async {
    try {
      final driveApi = await _getDriveApi();
      if (driveApi == null) return false;

      final existingFileId = await findCashbookFileId();

      final dir = await getApplicationDocumentsDirectory();
      final localFile = File('${dir.path}/data.cashbook');

      if (!await localFile.exists()) {
        await LocalStorageService.instance.saveToFile();
      }

      if (existingFileId == null) {
        // Upload new file to Drive
        final driveFile = drive.File()
          ..name = 'data.cashbook'
          ..description = 'Cashbook Mobile Database';

        await driveApi.files.create(
          driveFile,
          uploadMedia: drive.Media(localFile.openRead(), await localFile.length()),
        );
      } else {
        // Download and merge
        final drive.Media downloadedMedia = await driveApi.files.get(
          existingFileId,
          downloadOptions: drive.DownloadOptions.fullMedia,
        ) as drive.Media;

        final List<int> bytes = [];
        await for (final chunk in downloadedMedia.stream) {
          bytes.addAll(chunk);
        }

        final remoteContent = utf8.decode(bytes);
        if (remoteContent.isNotEmpty) {
          final Map<String, dynamic> remoteJson = jsonDecode(remoteContent);
          // If local has no transactions, adopt remote data directly
          if (LocalStorageService.instance.getTransactions(includeDeleted: true).isEmpty &&
              remoteJson['transactions'] != null) {
            await localFile.writeAsString(remoteContent);
            await LocalStorageService.instance.initialize();
          } else {
            // Otherwise, update Drive with current local master
            await driveApi.files.update(
              drive.File(),
              existingFileId,
              uploadMedia: drive.Media(localFile.openRead(), await localFile.length()),
            );
          }
        }
      }

      return true;
    } catch (_) {
      return false;
    }
  }

  Future<bool> syncWithDrive([LocalStorageService? storage]) => syncWithGoogleDrive();

  Future<bool> restoreFromGoogleDrive() async {
    try {
      final driveApi = await _getDriveApi();
      if (driveApi == null) return false;

      final existingFileId = await findCashbookFileId();
      if (existingFileId == null) return false;

      final drive.Media downloadedMedia = await driveApi.files.get(
        existingFileId,
        downloadOptions: drive.DownloadOptions.fullMedia,
      ) as drive.Media;

      final List<int> bytes = [];
      await for (final chunk in downloadedMedia.stream) {
        bytes.addAll(chunk);
      }

      final remoteContent = utf8.decode(bytes);
      final dir = await getApplicationDocumentsDirectory();
      final localFile = File('${dir.path}/data.cashbook');
      await localFile.writeAsString(remoteContent);

      await LocalStorageService.instance.initialize();
      return true;
    } catch (_) {
      return false;
    }
  }
}
