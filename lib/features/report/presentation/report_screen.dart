import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/constants/colors.dart';
import '../../../core/database/local_storage_service.dart';
import '../../../core/localization/app_localizations.dart';
import '../../../core/services/excel_export_service.dart';
import '../../../core/services/pdf_export_service.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../book/cubit/book_cubit.dart';
import '../../book/presentation/widgets/book_dropdown_selector.dart';
import '../../transaction/domain/models/transaction_model.dart';

class ReportScreen extends StatefulWidget {
  final LocalStorageService storage;
  final PdfExportService pdfService;
  final ExcelExportService excelService;

  const ReportScreen({
    super.key,
    required this.storage,
    required this.pdfService,
    required this.excelService,
  });

  @override
  State<ReportScreen> createState() => _ReportScreenState();
}

class _ReportScreenState extends State<ReportScreen> {
  String _activeTab = 'this_month'; // 'this_month', 'last_month', 'this_year', 'custom'
  DateTime _startDate = DateTime(DateTime.now().year, DateTime.now().month, 1);
  DateTime _endDate = DateTime.now();

  @override
  void initState() {
    super.initState();
    _setPeriod('this_month');
  }

  void _setPeriod(String period) {
    final now = DateTime.now();
    setState(() {
      _activeTab = period;
      if (period == 'this_month') {
        _startDate = DateTime(now.year, now.month, 1);
        _endDate = now;
      } else if (period == 'last_month') {
        _startDate = DateTime(now.year, now.month - 1, 1);
        _endDate = DateTime(now.year, now.month, 0);
      } else if (period == 'this_year') {
        _startDate = DateTime(now.year, 1, 1);
        _endDate = now;
      }
    });
  }

  Future<void> _pickCustomDateRange() async {
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime(2035),
      initialDateRange: DateTimeRange(start: _startDate, end: _endDate),
    );

    if (picked != null) {
      setState(() {
        _activeTab = 'custom';
        _startDate = picked.start;
        _endDate = picked.end;
      });
    }
  }

  List<TransactionModel> _getFilteredTransactions(String? bookId) {
    final all = widget.storage.getTransactions(bookId: bookId);
    return all.where((t) {
      final date = DateTime(t.transactionDate.year, t.transactionDate.month, t.transactionDate.day);
      final start = DateTime(_startDate.year, _startDate.month, _startDate.day);
      final end = DateTime(_endDate.year, _endDate.month, _endDate.day, 23, 59, 59);
      return (date.isAfter(start) || date.isAtSameMomentAs(start)) &&
          (date.isBefore(end) || date.isAtSameMomentAs(end));
    }).toList();
  }

  void _exportPdf(List<TransactionModel> transactions, String bookTitle) {
    widget.pdfService.exportReportPdf(
      transactions: transactions,
      startDate: _startDate,
      endDate: _endDate,
      bookTitle: bookTitle,
    );
  }

  void _exportExcel(List<TransactionModel> transactions, String bookTitle) {
    widget.excelService.exportReportExcel(
      transactions: transactions,
      startDate: _startDate,
      endDate: _endDate,
      bookTitle: bookTitle,
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final loc = AppLocalizations.of(context);
    final localeCode = Localizations.localeOf(context).languageCode;

    return BlocBuilder<BookCubit, BookState>(
      builder: (context, bookState) {
        final activeBook = context.read<BookCubit>().activeBook;
        final transactions = _getFilteredTransactions(activeBook?.id);

        double totalIncome = 0;
        double totalExpense = 0;
        final Map<String, double> categoryExpenses = {};

        for (final t in transactions) {
          if (t.isIncome) {
            totalIncome += t.amount;
          } else {
            totalExpense += t.amount;
            categoryExpenses[t.categoryName] =
                (categoryExpenses[t.categoryName] ?? 0) + t.amount;
          }
        }

        final balance = totalIncome - totalExpense;

        return Scaffold(
          backgroundColor: isDark ? AppColors.darkBackground : AppColors.lightBackground,
          appBar: AppBar(
            title: Text(loc.tr('financial_report')),
            bottom: const PreferredSize(
              preferredSize: Size.fromHeight(40),
              child: Padding(
                padding: EdgeInsets.only(bottom: 8.0),
                child: BookDropdownSelector(),
              ),
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.picture_as_pdf_outlined),
                tooltip: loc.tr('export_pdf'),
                onPressed: () => _exportPdf(transactions, activeBook?.name ?? 'Cashbook'),
              ),
              IconButton(
                icon: const Icon(Icons.table_chart_outlined),
                tooltip: loc.tr('export_excel'),
                onPressed: () => _exportExcel(transactions, activeBook?.name ?? 'Cashbook'),
              ),
            ],
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Period Filters
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _buildPeriodChip('this_month', loc.tr('this_month'), isDark),
                      const SizedBox(width: 8),
                      _buildPeriodChip('last_month', loc.tr('last_month'), isDark),
                      const SizedBox(width: 8),
                      _buildPeriodChip('this_year', loc.tr('this_year'), isDark),
                      const SizedBox(width: 8),
                      ActionChip(
                        avatar: const Icon(Icons.date_range_rounded, size: 16),
                        label: Text(_activeTab == 'custom'
                            ? '${_startDate.day}/${_startDate.month} - ${_endDate.day}/${_endDate.month}'
                            : loc.tr('custom_range')),
                        backgroundColor: _activeTab == 'custom'
                            ? AppColors.primary500.withValues(alpha: 0.2)
                            : (isDark ? AppColors.darkSurface : AppColors.gray100),
                        labelStyle: TextStyle(
                          fontSize: 12,
                          fontWeight:
                              _activeTab == 'custom' ? FontWeight.bold : FontWeight.normal,
                          color: _activeTab == 'custom'
                              ? AppColors.primary500
                              : (isDark ? AppColors.gray300 : AppColors.gray700),
                        ),
                        onPressed: _pickCustomDateRange,
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 16),

                // Summary Overview
                Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: isDark ? AppColors.darkSurface : Colors.white,
                    borderRadius: BorderRadius.circular(18),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.04),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          _buildSummaryItem(
                            loc.tr('cash_in'),
                            totalIncome,
                            AppColors.incomeGreen,
                            Icons.arrow_downward_rounded,
                            localeCode,
                          ),
                          _buildSummaryItem(
                            loc.tr('cash_out'),
                            totalExpense,
                            AppColors.expenseRed,
                            Icons.arrow_upward_rounded,
                            localeCode,
                          ),
                        ],
                      ),
                      const Divider(height: 24),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            loc.tr('net_balance'),
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: isDark ? AppColors.gray300 : AppColors.gray700,
                            ),
                          ),
                          Text(
                            CurrencyFormatter.format(balance, localeCode: localeCode),
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: balance >= 0
                                   ? AppColors.incomeGreen
                                  : AppColors.expenseRed,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                // Chart Section
                Text(
                  loc.tr('cash_flow_comparison'),
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : AppColors.gray900,
                  ),
                ),
                const SizedBox(height: 12),
                Container(
                  height: 200,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: isDark ? AppColors.darkSurface : Colors.white,
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: (totalIncome == 0 && totalExpense == 0)
                      ? Center(child: Text(loc.tr('no_report_data')))
                      : BarChart(
                          BarChartData(
                            alignment: BarChartAlignment.spaceAround,
                            maxY: (totalIncome > totalExpense ? totalIncome : totalExpense) * 1.2,
                            barTouchData: BarTouchData(enabled: true),
                            titlesData: FlTitlesData(
                              leftTitles: const AxisTitles(
                                sideTitles: SideTitles(showTitles: false),
                              ),
                              rightTitles: const AxisTitles(
                                sideTitles: SideTitles(showTitles: false),
                              ),
                              topTitles: const AxisTitles(
                                sideTitles: SideTitles(showTitles: false),
                              ),
                              bottomTitles: AxisTitles(
                                sideTitles: SideTitles(
                                  showTitles: true,
                                  getTitlesWidget: (value, meta) {
                                    switch (value.toInt()) {
                                      case 0:
                                        return Text(loc.tr('cash_in'),
                                            style: const TextStyle(fontSize: 12));
                                      case 1:
                                        return Text(loc.tr('cash_out'),
                                            style: const TextStyle(fontSize: 12));
                                      default:
                                        return const Text('');
                                    }
                                  },
                                ),
                              ),
                            ),
                            gridData: const FlGridData(show: false),
                            borderData: FlBorderData(show: false),
                            barGroups: [
                              BarChartGroupData(
                                x: 0,
                                barRods: [
                                  BarChartRodData(
                                    toY: totalIncome,
                                    color: AppColors.incomeGreen,
                                    width: 38,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                ],
                              ),
                              BarChartGroupData(
                                x: 1,
                                barRods: [
                                  BarChartRodData(
                                    toY: totalExpense,
                                    color: AppColors.expenseRed,
                                    width: 38,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                ),

                const SizedBox(height: 24),

                // Expense by Category Breakdown
                Text(
                  loc.tr('expense_by_category'),
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : AppColors.gray900,
                  ),
                ),
                const SizedBox(height: 12),
                if (categoryExpenses.isEmpty)
                  Container(
                    padding: const EdgeInsets.all(24),
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: isDark ? AppColors.darkSurface : Colors.white,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Text(
                      loc.tr('no_report_data'),
                      style: TextStyle(
                        color: isDark ? AppColors.gray400 : AppColors.gray500,
                      ),
                    ),
                  )
                else
                  ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: categoryExpenses.keys.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 8),
                    itemBuilder: (context, index) {
                      final catName = categoryExpenses.keys.elementAt(index);
                      final amt = categoryExpenses[catName]!;
                      final percentage =
                          totalExpense > 0 ? (amt / totalExpense) * 100 : 0.0;

                      return Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: isDark ? AppColors.darkSurface : Colors.white,
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Column(
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  catName,
                                  style: const TextStyle(fontWeight: FontWeight.w600),
                                ),
                                Text(
                                  CurrencyFormatter.format(amt, localeCode: localeCode),
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.expenseRed,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            ClipRRect(
                              borderRadius: BorderRadius.circular(4),
                              child: LinearProgressIndicator(
                                value: totalExpense > 0 ? amt / totalExpense : 0,
                                backgroundColor: isDark
                                    ? AppColors.gray800
                                    : AppColors.gray200,
                                valueColor: const AlwaysStoppedAnimation<Color>(
                                    AppColors.expenseRed),
                                minHeight: 6,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Align(
                              alignment: Alignment.centerRight,
                              child: Text(
                                '${percentage.toStringAsFixed(1)}%',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: isDark ? AppColors.gray400 : AppColors.gray500,
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),

                const SizedBox(height: 32),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildPeriodChip(String key, String label, bool isDark) {
    final isSelected = _activeTab == key;
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (selected) {
        if (selected) _setPeriod(key);
      },
      selectedColor: AppColors.primary500.withValues(alpha: 0.2),
      labelStyle: TextStyle(
        fontSize: 12,
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        color: isSelected
            ? AppColors.primary500
            : (isDark ? AppColors.gray400 : AppColors.gray700),
      ),
    );
  }

  Widget _buildSummaryItem(
    String title,
    double amount,
    Color color,
    IconData icon,
    String localeCode,
  ) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.15),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: color, size: 18),
        ),
        const SizedBox(width: 10),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: const TextStyle(fontSize: 12, color: AppColors.gray500)),
            const SizedBox(height: 2),
            Text(
              CurrencyFormatter.format(amount, localeCode: localeCode),
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 14,
                color: color,
              ),
            ),
          ],
        ),
      ],
    );
  }
}
