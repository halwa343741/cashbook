import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'app/routes/app_router.dart';
import 'core/database/local_storage_service.dart';
import 'core/localization/app_localizations.dart';
import 'core/services/biometric_service.dart';
import 'core/services/excel_export_service.dart';
import 'core/services/google_drive_service.dart';
import 'core/services/pdf_export_service.dart';
import 'core/theme/app_theme.dart';
import 'features/book/cubit/book_cubit.dart';
import 'features/localization/cubit/locale_cubit.dart';
import 'features/theme/cubit/theme_cubit.dart';
import 'features/transaction/cubit/transaction_cubit.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 1. Initialize Database & Local Storage
  final storage = LocalStorageService();
  await storage.init();

  // 2. Initialize Services
  final biometricService = BiometricService();
  final driveService = GoogleDriveService();
  final pdfService = PdfExportService();
  final excelService = ExcelExportService();

  // 3. Create Router
  final router = createAppRouter(
    storage: storage,
    biometricService: biometricService,
    driveService: driveService,
    pdfService: pdfService,
    excelService: excelService,
  );

  runApp(CashbookApp(
    storage: storage,
    router: router,
  ));
}

class CashbookApp extends StatelessWidget {
  final LocalStorageService storage;
  final dynamic router;

  const CashbookApp({
    super.key,
    required this.storage,
    required this.router,
  });

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(create: (_) => ThemeCubit()),
        BlocProvider(create: (_) => LocaleCubit()),
        BlocProvider(create: (_) => BookCubit(storage: storage)),
        BlocProvider(create: (_) => TransactionCubit(storage: storage)),
      ],
      child: BlocBuilder<ThemeCubit, ThemeMode>(
        builder: (context, themeMode) {
          final locale = context.watch<LocaleCubit>().state;
          return MaterialApp.router(
            title: 'Cashbook',
            debugShowCheckedModeBanner: false,
            theme: AppTheme.lightTheme,
            darkTheme: AppTheme.darkTheme,
            themeMode: themeMode,
            locale: locale,
            supportedLocales: const [
              Locale('id'),
              Locale('en'),
              Locale('es'),
              Locale('zh'),
              Locale('ar'),
            ],
            localizationsDelegates: const [
              AppLocalizationsDelegate(),
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            routerConfig: router,
          );
        },
      ),
    );
  }
}
