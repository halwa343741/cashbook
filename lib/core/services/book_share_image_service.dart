import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:image/image.dart' as img;
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../constants/colors.dart';
import '../database/local_storage_service.dart';
import '../localization/app_localizations.dart';
import '../utils/currency_formatter.dart';
import '../../features/book/domain/models/book_model.dart';
import '../../features/book/presentation/widgets/book_share_card.dart';

class BookShareImageService {
  static final BookShareImageService instance = BookShareImageService._internal();
  BookShareImageService._internal();

  factory BookShareImageService() => instance;

  /// Menampilkan lembar pratinjau kartu ringkasan dan opsi berbagi berkas JPEG
  Future<void> showShareModal({
    required BuildContext context,
    required BookModel book,
    required LocalStorageService storage,
  }) async {
    final transactions = storage.getTransactions(bookId: book.id, includeDeleted: false);
    final balance = storage.getBalance(book.id);
    final localeCode = Localizations.localeOf(context).languageCode;
    final initialIsDark = Theme.of(context).brightness == Brightness.dark;

    if (!context.mounted) return;

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        return _BookShareModalContent(
          book: book,
          transactions: transactions,
          balance: balance,
          localeCode: localeCode,
          initialIsDark: initialIsDark,
        );
      },
    );
  }
}

class _BookShareModalContent extends StatefulWidget {
  final BookModel book;
  final List<dynamic> transactions;
  final double balance;
  final String localeCode;
  final bool initialIsDark;

  const _BookShareModalContent({
    required this.book,
    required this.transactions,
    required this.balance,
    required this.localeCode,
    required this.initialIsDark,
  });

  @override
  State<_BookShareModalContent> createState() => _BookShareModalContentState();
}

class _BookShareModalContentState extends State<_BookShareModalContent> {
  final GlobalKey _cardKey = GlobalKey();
  late bool _isDarkCard;
  bool _isSharing = false;

  @override
  void initState() {
    super.initState();
    _isDarkCard = widget.initialIsDark;
  }

  Future<void> _captureAndShare(AppLocalizations loc) async {
    if (_isSharing) return;

    setState(() {
      _isSharing = true;
    });

    try {
      // 1. Ambil Boundary dari RepaintBoundary
      final boundary = _cardKey.currentContext?.findRenderObject() as RenderRepaintBoundary?;
      if (boundary == null) {
        throw Exception('Gagal menemukan elemen tampilan kartu.');
      }

      // 2. Render ke ui.Image dengan pixelRatio 3.0 (resolusi tinggi dan jernih)
      final ui.Image image = await boundary.toImage(pixelRatio: 3.0);
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      if (byteData == null) {
        throw Exception('Gagal mengekstrak data grafis.');
      }

      // 3. Konversi PNG bytes ke JPEG murni dengan kualitas 95%
      final pngBytes = byteData.buffer.asUint8List();
      final decodedImage = img.decodeImage(pngBytes);
      if (decodedImage == null) {
        throw Exception('Gagal mengonversi format gambar.');
      }

      final jpgBytes = img.encodeJpg(decodedImage, quality: 95);

      // 4. Simpan ke berkas temporer di perangkat
      final tempDir = await getTemporaryDirectory();
      final sanitizedName = widget.book.name.replaceAll(RegExp(r'[^\w\s\-]'), '_').trim();
      final fileName = '${sanitizedName.isEmpty ? 'cashbook' : sanitizedName}_ringkasan.jpg';
      final file = File('${tempDir.path}/$fileName');
      await file.writeAsBytes(jpgBytes);

      // 5. Panggil native SharePlus sheet (WhatsApp, dll.)
      if (mounted) {
        Navigator.pop(context); // Tutup bottom sheet sebelum membuka share dialog
      }

      await SharePlus.instance.share(
        ShareParams(
          files: [
            XFile(
              file.path,
              mimeType: 'image/jpeg',
              name: fileName,
            ),
          ],
          subject: '${widget.book.name} - ${loc.tr('financial_summary')}',
          text: '${loc.tr('financial_summary')}: ${widget.book.name}\n${loc.tr('total_balance')}: ${CurrencyFormatter.format(widget.balance, localeCode: widget.localeCode)}',
        ),
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: AppColors.expenseRed,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSharing = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDarkUi = Theme.of(context).brightness == Brightness.dark;
    final loc = AppLocalizations(Locale(widget.localeCode));
    final isRtl = widget.localeCode == 'ar';

    return Directionality(
      textDirection: isRtl ? TextDirection.rtl : TextDirection.ltr,
      child: Container(
        decoration: BoxDecoration(
          color: isDarkUi ? AppColors.darkSurface : Colors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
        child: SafeArea(
          top: false,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Drag Handle
              Center(
                child: Container(
                  width: 38,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 12),
                  decoration: BoxDecoration(
                    color: isDarkUi ? AppColors.gray700 : AppColors.gray300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),

              // Top Header & Theme Selector
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          loc.tr('financial_summary'),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: isDarkUi ? Colors.white : AppColors.gray900,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          loc.tr('share_summary_title'),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 12,
                            color: isDarkUi ? AppColors.gray400 : AppColors.gray600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  // Toggle Dark/Light Theme for the Card
                  Container(
                    decoration: BoxDecoration(
                      color: isDarkUi ? AppColors.darkBackground : AppColors.gray100,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: isDarkUi ? AppColors.gray700 : AppColors.gray300,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _buildThemeButton(
                          icon: Icons.dark_mode_rounded,
                          isSelected: _isDarkCard,
                          onTap: () => setState(() => _isDarkCard = true),
                        ),
                        _buildThemeButton(
                          icon: Icons.light_mode_rounded,
                          isSelected: !_isDarkCard,
                          onTap: () => setState(() => _isDarkCard = false),
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 14),

              // Card Preview Area (Scrollable with max height)
              ConstrainedBox(
                constraints: BoxConstraints(
                  maxHeight: MediaQuery.of(context).size.height * 0.58,
                ),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  decoration: BoxDecoration(
                    color: isDarkUi ? const Color(0xFF0B0F19) : const Color(0xFFF1F5F9),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: SingleChildScrollView(
                    child: Center(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 4.0),
                        child: RepaintBoundary(
                          key: _cardKey,
                          child: BookShareCard(
                            book: widget.book,
                            transactions: widget.transactions.cast(),
                            balance: widget.balance,
                            isDark: _isDarkCard,
                            localeCode: widget.localeCode,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // Share Action Button
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton.icon(
                  onPressed: _isSharing ? null : () => _captureAndShare(loc),
                  icon: _isSharing
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                        )
                      : const Icon(Icons.share_rounded, size: 20),
                  label: Text(
                    _isSharing ? loc.tr('preparing_image') : loc.tr('share_summary_image'),
                    style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary500,
                    foregroundColor: Colors.white,
                    elevation: 2,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildThemeButton({
    required IconData icon,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary500 : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Icon(
          icon,
          size: 16,
          color: isSelected ? Colors.white : AppColors.gray500,
        ),
      ),
    );
  }
}
