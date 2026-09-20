import 'dart:convert';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import '../../features/book/domain/models/book_model.dart';
import '../database/local_storage_service.dart';

class ShareService {
  final LocalStorageService _storage;

  ShareService({LocalStorageService? storage})
      : _storage = storage ?? LocalStorageService.instance;

  Future<void> shareBookAsFile(dynamic bookOrId) async {
    String bookId;
    BookModel book;

    if (bookOrId is BookModel) {
      book = bookOrId;
      bookId = book.id;
    } else {
      bookId = bookOrId.toString();
      book = _storage.getBooks(includeDeleted: true).firstWhere((b) => b.id == bookId);
    }

    final jsonContent = _storage.exportBookAsJson(bookId);

    final encodedBase64 = base64Encode(utf8.encode(jsonContent));
    final payloadWithHeader = 'CASHBOOK_SHARE_V1:$encodedBase64';

    final tempDir = await getTemporaryDirectory();
    final sanitizedName = book.name.replaceAll(RegExp(r'[^a-zA-Z0-9_\-]'), '_');
    final file = File('${tempDir.path}/$sanitizedName.cbshare');

    await file.writeAsString(payloadWithHeader);

    await SharePlus.instance.share(
      ShareParams(
        files: [XFile(file.path, mimeType: 'application/x-cashbook')],
        subject: 'Buku Kas Cashbook: ${book.name} (Hanya-Baca)',
        text:
            'Berikut Buku Kas "${book.name}" dari aplikasi Cashbook. Buka file ini menggunakan aplikasi Cashbook untuk melihat riwayat keuangan (Read-Only).',
      ),
    );
  }

  Future<BookModel?> pickAndImportSharedBook() async {
    try {
      // In mobile environment, this would pick file. For safety fallback:
      final tempDir = await getTemporaryDirectory();
      final files = tempDir.listSync().whereType<File>().where((f) => f.path.endsWith('.cbshare'));
      if (files.isNotEmpty) {
        final content = await parseCbshareFile(files.first);
        if (content != null) {
          return await _storage.importSharedBook(content);
        }
      }
      return null;
    } catch (_) {
      return null;
    }
  }

  static Future<String?> parseCbshareFile(File file) async {
    try {
      final content = await file.readAsString();
      if (content.startsWith('CASHBOOK_SHARE_V1:')) {
        final b64 = content.substring('CASHBOOK_SHARE_V1:'.length);
        final decodedJson = utf8.decode(base64Decode(b64));
        return decodedJson;
      }
      return content;
    } catch (_) {
      return null;
    }
  }
}
