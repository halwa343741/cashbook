import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/database/local_storage_service.dart';
import '../../core/services/biometric_service.dart';
import '../../core/services/excel_export_service.dart';
import '../../core/services/google_drive_service.dart';
import '../../core/services/pdf_export_service.dart';
import '../../core/services/share_service.dart';
import '../../features/account/presentation/account_screen.dart';
import '../../features/auth/presentation/login_screen.dart';
import '../../features/auth/presentation/splash_screen.dart';
import '../../features/book/presentation/create_initial_book_screen.dart';
import '../../features/book/presentation/manage_books_screen.dart';
import '../../features/category/presentation/category_list_screen.dart';
import '../../features/dashboard/presentation/home_screen.dart';
import '../../features/report/presentation/report_screen.dart';
import '../../features/security/presentation/lock_screen.dart';
import '../../features/transaction/presentation/add_expense_screen.dart';
import '../../features/transaction/presentation/add_income_screen.dart';
import '../../features/transaction/presentation/transaction_detail_screen.dart';
import '../../features/transaction/presentation/transaction_list_screen.dart';
import '../../features/trash/presentation/trash_screen.dart';
import '../presentation/main_scaffold.dart';

final _rootNavigatorKey = GlobalKey<NavigatorState>();

GoRouter createAppRouter({
  required LocalStorageService storage,
  required BiometricService biometricService,
  required GoogleDriveService driveService,
  required ShareService shareService,
  required PdfExportService pdfService,
  required ExcelExportService excelService,
}) {
  return GoRouter(
    navigatorKey: _rootNavigatorKey,
    initialLocation: '/',
    routes: [
      GoRoute(
        path: '/',
        builder: (context, state) => SplashScreen(
          storage: storage,
          biometricService: biometricService,
          driveService: driveService,
        ),
      ),
      GoRoute(
        path: '/lock',
        builder: (context, state) => LockScreen(
          storage: storage,
          biometricService: biometricService,
          driveService: driveService,
        ),
      ),
      GoRoute(
        path: '/login',
        builder: (context, state) => LoginScreen(
          driveService: driveService,
          storage: storage,
        ),
      ),
      GoRoute(
        path: '/create-initial-book',
        builder: (context, state) => const CreateInitialBookScreen(),
      ),
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) {
          return MainScaffold(navigationShell: navigationShell);
        },
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/home',
                builder: (context, state) => HomeScreen(
                  driveService: driveService,
                  storage: storage,
                ),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/transactions',
                builder: (context, state) => const TransactionListScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/report',
                builder: (context, state) => ReportScreen(
                  storage: storage,
                  pdfService: pdfService,
                  excelService: excelService,
                ),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/account',
                builder: (context, state) => AccountScreen(
                  driveService: driveService,
                  storage: storage,
                  biometricService: biometricService,
                  shareService: shareService,
                ),
              ),
            ],
          ),
        ],
      ),
      GoRoute(
        path: '/add-income',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => AddIncomeScreen(storage: storage),
      ),
      GoRoute(
        path: '/add-expense',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => AddExpenseScreen(storage: storage),
      ),
      GoRoute(
        path: '/transaction-detail/:id',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) {
          final id = state.pathParameters['id'] ?? '';
          return TransactionDetailScreen(transactionId: id, storage: storage);
        },
      ),
      GoRoute(
        path: '/manage-books',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => ManageBooksScreen(shareService: shareService),
      ),
      GoRoute(
        path: '/categories',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => CategoryListScreen(storage: storage),
      ),
      GoRoute(
        path: '/trash',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => TrashScreen(storage: storage),
      ),
    ],
  );
}
