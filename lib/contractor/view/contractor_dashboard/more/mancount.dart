import 'dart:typed_data';
import 'dart:io';
import 'package:ecoteam_app/contractor/models/site_model.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:path_provider/path_provider.dart';
import 'package:open_file/open_file.dart';
import 'package:permission_handler/permission_handler.dart';

class ManpowerCountScreen extends StatefulWidget {
  final String? selectedSiteId;
  final Function(String) onSiteChanged;
  final List<Site> sites;
  ManpowerCountScreen({
    super.key,
    required this.selectedSiteId,
    required this.onSiteChanged,
    required this.sites,
  });
  @override
  State<ManpowerCountScreen> createState() => _ManpowerCountScreenState();
}

class _ManpowerCountScreenState extends State<ManpowerCountScreen> {
  final List<String> categories = [
    'Skilled',
    'Unskilled',
    'Supervisor',
    'Engineer',
    'Technician',
    'Labor',
    'Safety Officer',
    'Admin Staff',
  ];
  final Map<String, int> dailyCount = {};
  final Map<DateTime, Map<String, int>> dailyLogs = {};
  DateTime selectedDate = DateTime.now();
  int _selectedTabIndex = 0;
  final TextEditingController _newCategoryController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _initializeCounts();
    _loadSavedData();
  }

  @override
  void dispose() {
    _newCategoryController.dispose();
    super.dispose();
  }

  void _initializeCounts() {
    for (var category in categories) {
      dailyCount[category] = 0;
    }
  }

  void _loadSavedData() {
    final yesterday = DateTime(
      DateTime.now().year,
      DateTime.now().month,
      DateTime.now().day - 1,
    );
    final twoDaysAgo = DateTime(
      DateTime.now().year,
      DateTime.now().month,
      DateTime.now().day - 2,
    );
    final threeDaysAgo = DateTime(
      DateTime.now().year,
      DateTime.now().month,
      DateTime.now().day - 3,
    );

    dailyLogs[yesterday] = {
      'Skilled': 5,
      'Unskilled': 12,
      'Supervisor': 2,
      'Engineer': 3,
      'Technician': 4,
      'Labor': 8,
      'Safety Officer': 1,
      'Admin Staff': 2,
    };

    dailyLogs[twoDaysAgo] = {
      'Skilled': 6,
      'Unskilled': 10,
      'Supervisor': 2,
      'Engineer': 2,
      'Technician': 3,
      'Labor': 7,
      'Safety Officer': 1,
      'Admin Staff': 2,
    };

    dailyLogs[threeDaysAgo] = {
      'Skilled': 4,
      'Unskilled': 8,
      'Supervisor': 1,
      'Engineer': 3,
      'Technician': 5,
      'Labor': 6,
      'Safety Officer': 1,
      'Admin Staff': 1,
    };

    final today = DateTime(
      DateTime.now().year,
      DateTime.now().month,
      DateTime.now().day,
    );

    if (dailyLogs.containsKey(today)) {
      dailyCount.clear();
      dailyCount.addAll(dailyLogs[today]!);
    }
  }

  void _updateCount(String category, int delta) {
    setState(() {
      dailyCount[category] = (dailyCount[category]! + delta).clamp(0, 999);
    });
  }

  void _saveDailyCount() {
    setState(() {
      final dateKey = DateTime(
        selectedDate.year,
        selectedDate.month,
        selectedDate.day,
      );
      dailyLogs[dateKey] = Map.from(dailyCount);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Daily manpower count saved successfully!'),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
        ),
      );
    });
  }

  void _loadDateData(DateTime date) {
    setState(() {
      selectedDate = date;
      final dateKey = DateTime(date.year, date.month, date.day);
      if (dailyLogs.containsKey(dateKey)) {
        dailyCount.clear();
        dailyCount.addAll(dailyLogs[dateKey]!);
      } else {
        _initializeCounts();
      }
    });
  }

  void _generateReport() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _buildReportSheet(),
    );
  }

  Widget _buildReportSheet() {
    final total = dailyCount.values.fold(0, (sum, count) => sum + count);
    final screenHeight = MediaQuery.of(context).size.height;

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      padding: const EdgeInsets.all(16),
      height: screenHeight * 0.7,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Manpower Report',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF2a43a0),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close, color: Color(0xFF2a43a0)),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                children: [
                  _buildReportSummary(total),
                  const SizedBox(height: 16),
                  _buildCategoryBreakdown(),
                  const SizedBox(height: 5),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              ElevatedButton.icon(
                onPressed: () => _downloadPDF(() => Navigator.pop(context)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF4a63c0),
                  foregroundColor: Colors.white,
                  elevation: 4,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 8,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                icon: const Icon(Icons.download, size: 16),
                label: const Text('Download', style: TextStyle(fontSize: 12)),
              ),
              ElevatedButton.icon(
                onPressed: () => _sharePDF(() => Navigator.pop(context)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF4a63c0),
                  foregroundColor: Colors.white,
                  elevation: 4,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 8,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                icon: const Icon(Icons.share, size: 16),
                label: const Text('Share', style: TextStyle(fontSize: 12)),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.grey.shade300,
                  foregroundColor: Colors.black54,
                  elevation: 4,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text('Close', style: TextStyle(fontSize: 12)),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _requestStoragePermission() async {
    if (Platform.isAndroid) {
      final status = await Permission.storage.status;
      if (!status.isGranted) {
        await Permission.storage.request();
      }
    }
  }

  Future<Directory> _getDownloadDirectory() async {
    if (Platform.isAndroid) {
      // For Android, use the downloads directory if accessible
      try {
        final status = await Permission.storage.status;
        if (status.isGranted) {
          // Try to get the downloads directory
          Directory? downloadsDir = Directory('/storage/emulated/0/Download');
          if (await downloadsDir.exists()) {
            return downloadsDir;
          }
        }
      } catch (e) {
        debugPrint('Error accessing downloads directory: $e');
      }
    }

    // Fallback to application documents directory
    return await getApplicationDocumentsDirectory();
  }

  Future<void> _downloadPDF([VoidCallback? onSuccess]) async {
    try {
      // Show loading indicator
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(child: CircularProgressIndicator()),
      );

      // Request storage permission for Android
      if (Platform.isAndroid) {
        await _requestStoragePermission();
      }

      final pdfBytes = await _generatePdfBytes();

      // Get directory
      final directory = await _getDownloadDirectory();
      final fileName =
          'manpower-report-${DateFormat('yyyy-MM-dd').format(selectedDate)}.pdf';
      final file = File('${directory.path}/$fileName');

      debugPrint('Saving PDF to: ${file.path}');

      // Write file
      await file.writeAsBytes(pdfBytes);

      // Close loading indicator
      if (Navigator.canPop(context)) {
        Navigator.pop(context);
      }

      // Close the bottom sheet on success
      if (onSuccess != null) {
        onSuccess();
      }

      // Show success message with option to open file
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('PDF downloaded to ${file.path}'),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
          action: SnackBarAction(
            label: 'Open',
            textColor: Colors.white,
            onPressed: () async {
              final result = await OpenFile.open(file.path);
              if (result.type != ResultType.done) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Could not open file: ${result.message}'),
                    backgroundColor: Colors.red,
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              }
            },
          ),
        ),
      );
    } catch (e) {
      // Close loading indicator if it's showing
      if (Navigator.canPop(context)) {
        Navigator.pop(context);
      }

      debugPrint('PDF download error: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to download PDF: ${e.toString()}'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Future<void> _sharePDF([VoidCallback? onSuccess]) async {
    try {
      // Show loading indicator
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(child: CircularProgressIndicator()),
      );

      final pdfBytes = await _generatePdfBytes();

      // Close loading indicator
      if (Navigator.canPop(context)) {
        Navigator.pop(context);
      }

      await Printing.sharePdf(
        bytes: pdfBytes,
        filename:
            'manpower-report-${DateFormat('yyyy-MM-dd').format(selectedDate)}.pdf',
      );

      // Close the bottom sheet on success
      if (onSuccess != null) {
        onSuccess();
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('PDF shared successfully!'),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (e) {
      // Close loading indicator if it's showing
      if (Navigator.canPop(context)) {
        Navigator.pop(context);
      }

      debugPrint('PDF share error: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to share PDF: ${e.toString()}'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Widget _buildReportSummary(int total) {
    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF4a63c0), Color(0xFF2a43a0)],
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Daily Summary',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 12),
          _buildReportItem(
            'Date',
            DateFormat('yyyy-MM-dd').format(selectedDate),
            Colors.white70,
            Colors.white,
          ),
          _buildReportItem(
            'Site',
            _getCurrentSiteName(),
            Colors.white70,
            Colors.white,
          ),
          _buildReportItem(
            'Total Manpower',
            total.toString(),
            Colors.white70,
            Colors.white,
          ),
          const SizedBox(height: 10),
          const Divider(color: Colors.white30),
          const SizedBox(height: 10),
          _buildReportItem(
            'Report Generated',
            DateFormat('yyyy-MM-dd HH:mm').format(DateTime.now()),
            Colors.white70,
            Colors.white,
          ),
        ],
      ),
    );
  }

  Widget _buildReportItem(
    String label,
    String value,
    Color labelColor,
    Color valueColor,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Text(
              '$label:',
              style: TextStyle(color: labelColor),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.end,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: valueColor,
                fontSize: 14,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryBreakdown() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Category Breakdown',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color(0xFF2a43a0),
            ),
          ),
          const SizedBox(height: 12),
          ...categories.map(
            (category) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      category,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFE8F0FE),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      '${dailyCount[category]}',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF2a43a0),
                        fontSize: 14,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<Uint8List> _generatePdfBytes() async {
    final total = dailyCount.values.fold(0, (sum, count) => sum + count);
    final pdf = pw.Document();

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text(
                'Manpower Report',
                style: pw.TextStyle(
                  fontSize: 24,
                  fontWeight: pw.FontWeight.bold,
                  color: PdfColor.fromInt(0xFF2a43a0),
                ),
              ),
              pw.SizedBox(height: 20),
              pw.Text(
                'Date: ${DateFormat('yyyy-MM-dd').format(selectedDate)}',
                style: pw.TextStyle(fontSize: 14),
              ),
              pw.Text(
                'Site: ${_getCurrentSiteName()}',
                style: pw.TextStyle(fontSize: 14),
              ),
              pw.Text(
                'Total Manpower: $total',
                style: pw.TextStyle(
                  fontSize: 14,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
              pw.SizedBox(height: 20),
              pw.Text(
                'Category Breakdown',
                style: pw.TextStyle(
                  fontSize: 18,
                  fontWeight: pw.FontWeight.bold,
                  color: PdfColor.fromInt(0xFF2a43a0),
                ),
              ),
              pw.SizedBox(height: 10),
              pw.Table(
                border: pw.TableBorder.all(),
                columnWidths: {
                  0: const pw.FlexColumnWidth(3),
                  1: const pw.FlexColumnWidth(1),
                },
                children: [
                  pw.TableRow(
                    children: [
                      pw.Padding(
                        child: pw.Text(
                          'Category',
                          style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                        ),
                        padding: const pw.EdgeInsets.all(8),
                      ),
                      pw.Padding(
                        child: pw.Text(
                          'Count',
                          style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                        ),
                        padding: const pw.EdgeInsets.all(8),
                      ),
                    ],
                    decoration: const pw.BoxDecoration(
                      color: PdfColor.fromInt(0xFFE6E6E6),
                    ),
                  ),
                  ...categories
                      .map(
                        (category) => pw.TableRow(
                          children: [
                            pw.Padding(
                              child: pw.Text(category),
                              padding: const pw.EdgeInsets.all(8),
                            ),
                            pw.Padding(
                              child: pw.Text('${dailyCount[category]}'),
                              padding: const pw.EdgeInsets.all(8),
                            ),
                          ],
                        ),
                      )
                      .toList(),
                  pw.TableRow(
                    children: [
                      pw.Padding(
                        child: pw.Text(
                          'Total',
                          style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                        ),
                        padding: const pw.EdgeInsets.all(8),
                      ),
                      pw.Padding(
                        child: pw.Text(
                          '$total',
                          style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                        ),
                        padding: const pw.EdgeInsets.all(8),
                      ),
                    ],
                    decoration: const pw.BoxDecoration(
                      color: PdfColor.fromInt(0xFFE6F7FF),
                    ),
                  ),
                ],
              ),
              pw.SizedBox(height: 20),
              pw.Text(
                'Report generated: ${DateFormat('yyyy-MM-dd HH:mm').format(DateTime.now())}',
                style: pw.TextStyle(
                  fontSize: 12,
                  fontStyle: pw.FontStyle.italic,
                ),
              ),
            ],
          );
        },
      ),
    );

    return pdf.save();
  }

  Widget _buildCalendarView() {
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallScreen = screenWidth < 360;

    return SingleChildScrollView(
      child: Column(
        children: [
          Container(
            margin: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      IconButton(
                        icon: const Icon(
                          Icons.arrow_back_ios,
                          color: Color(0xFF2a43a0),
                        ),
                        onPressed: () {
                          setState(() {
                            selectedDate = DateTime(
                              selectedDate.year,
                              selectedDate.month - 1,
                              1,
                            );
                          });
                        },
                      ),
                      Text(
                        DateFormat('MMMM yyyy').format(selectedDate),
                        style: TextStyle(
                          fontSize: isSmallScreen ? 16 : 20,
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFF2a43a0),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(
                          Icons.arrow_forward_ios,
                          color: Color(0xFF2a43a0),
                        ),
                        onPressed: () {
                          setState(() {
                            selectedDate = DateTime(
                              selectedDate.year,
                              selectedDate.month + 1,
                              1,
                            );
                          });
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  // Weekday headers
                  Row(
                    children: ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat']
                        .map(
                          (day) => Expanded(
                            child: Container(
                              alignment: Alignment.center,
                              padding: const EdgeInsets.symmetric(vertical: 8),
                              child: Text(
                                day,
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: const Color(0xFF2a43a0),
                                  fontSize: isSmallScreen ? 10 : 12,
                                ),
                              ),
                            ),
                          ),
                        )
                        .toList(),
                  ),
                  // Calendar grid
                  GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 7,
                      childAspectRatio: isSmallScreen ? 0.9 : 1.2,
                    ),
                    itemCount:
                        _getDaysInMonth(selectedDate.year, selectedDate.month) +
                        DateTime(
                          selectedDate.year,
                          selectedDate.month,
                          1,
                        ).weekday,
                    itemBuilder: (context, index) {
                      final firstWeekday = DateTime(
                        selectedDate.year,
                        selectedDate.month,
                        1,
                      ).weekday;
                      final day = index - firstWeekday + 1;

                      if (day < 1 ||
                          day >
                              _getDaysInMonth(
                                selectedDate.year,
                                selectedDate.month,
                              )) {
                        return const SizedBox.shrink();
                      }

                      final currentDay = DateTime(
                        selectedDate.year,
                        selectedDate.month,
                        day,
                      );
                      final isCurrentMonth =
                          currentDay.month == selectedDate.month;
                      final isSelected =
                          currentDay.day == selectedDate.day &&
                          currentDay.month == selectedDate.month &&
                          currentDay.year == selectedDate.year;
                      final dateKey = DateTime(
                        currentDay.year,
                        currentDay.month,
                        currentDay.day,
                      );
                      final hasData = dailyLogs.containsKey(dateKey);
                      final isToday =
                          currentDay.day == DateTime.now().day &&
                          currentDay.month == DateTime.now().month &&
                          currentDay.year == DateTime.now().year;

                      return GestureDetector(
                        onTap: () =>
                            isCurrentMonth ? _loadDateData(currentDay) : null,
                        child: Container(
                          margin: const EdgeInsets.all(2),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? const Color(0xFF4a63c0)
                                : (isToday
                                      ? const Color(0xFFE8F0FE)
                                      : (hasData
                                            ? const Color(0xFFE8F5E9)
                                            : Colors.white)),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: isSelected
                                  ? const Color(0xFF4a63c0)
                                  : (isToday
                                        ? const Color(0xFF4a63c0)
                                        : Colors.grey.withOpacity(0.3)),
                              width: isSelected ? 2 : 1,
                            ),
                            boxShadow: isSelected
                                ? [
                                    BoxShadow(
                                      color: const Color(
                                        0xFF4a63c0,
                                      ).withOpacity(0.3),
                                      blurRadius: 8,
                                      offset: const Offset(0, 4),
                                    ),
                                  ]
                                : null,
                          ),
                          child: Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  day.toString(),
                                  style: TextStyle(
                                    color: isSelected
                                        ? Colors.white
                                        : (isCurrentMonth
                                              ? Colors.black
                                              : Colors.grey),
                                    fontWeight: hasData || isToday
                                        ? FontWeight.bold
                                        : FontWeight.normal,
                                    fontSize: isSmallScreen ? 12 : 14,
                                  ),
                                ),
                                if (hasData)
                                  Container(
                                    margin: const EdgeInsets.only(top: 2),
                                    width: 6,
                                    height: 6,
                                    decoration: const BoxDecoration(
                                      color: Color(0xFF4CAF50),
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: const Color(0xFFE8F0FE),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              'Selected Date: ${DateFormat('yyyy-MM-dd').format(selectedDate)}',
              style: TextStyle(
                fontSize: isSmallScreen ? 12 : 14,
                fontWeight: FontWeight.bold,
                color: const Color(0xFF2a43a0),
              ),
            ),
          ),
          const SizedBox(height: 12),
          if (dailyLogs.containsKey(
            DateTime(selectedDate.year, selectedDate.month, selectedDate.day),
          ))
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: const Color(0xFFE8F5E9),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                'Total: ${dailyLogs[DateTime(selectedDate.year, selectedDate.month, selectedDate.day)]!.values.fold(0, (sum, count) => sum + count)} personnel',
                style: TextStyle(
                  fontSize: isSmallScreen ? 12 : 14,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF4CAF50),
                ),
              ),
            ),
          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Container(
              width: 280.w,
              child: ElevatedButton(
                onPressed: _saveDailyCount,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Color.fromARGB(255, 52, 80, 182),
                  foregroundColor: Colors.white,
                  elevation: 6,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                  minimumSize: const Size(double.infinity, 46),
                ),
                child: Text(
                  'Save Count for Selected Date',
                  style: TextStyle(
                    fontSize: isSmallScreen ? 14 : 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  int _getDaysInMonth(int year, int month) {
    return DateTime(year, month + 1, 0).day;
  }

  Widget _buildHistoryView() {
    if (dailyLogs.isEmpty) {
      return Center(
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 8,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: const Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.history, size: 48, color: Colors.grey),
              SizedBox(height: 12),
              Text(
                'No historical data available',
                style: TextStyle(fontSize: 16, color: Colors.grey),
              ),
            ],
          ),
        ),
      );
    }

    // Sort logs by date (newest first)
    final sortedLogs = dailyLogs.entries.toList()
      ..sort((a, b) => b.key.compareTo(a.key));

    return ListView(
      padding: const EdgeInsets.all(12),
      children: sortedLogs.map((entry) {
        final date = entry.key;
        final data = entry.value;
        final total = data.values.fold(0, (sum, count) => sum + count);
        final isToday =
            date.day == DateTime.now().day &&
            date.month == DateTime.now().month &&
            date.year == DateTime.now().year;

        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            color: isToday ? const Color(0xFFE8F0FE) : Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 8,
                offset: const Offset(0, 4),
              ),
            ],
            border: isToday
                ? Border.all(color: const Color(0xFF4a63c0), width: 1.5)
                : null,
          ),
          child: ListTile(
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 12,
            ),
            leading: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFF4a63c0).withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.calendar_today, color: Color(0xFF2a43a0)),
            ),
            title: Text(
              DateFormat('yyyy-MM-dd').format(date),
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
                color: Color(0xFF2a43a0),
              ),
            ),
            subtitle: Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Text(
                'Total: $total personnel',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: isToday
                      ? const Color(0xFF4a63c0)
                      : Colors.grey.shade700,
                ),
              ),
            ),
            trailing: IconButton(
              icon: const Icon(Icons.delete, color: Color(0xFFE53935)),
              onPressed: () => _deleteHistoryRecord(date),
            ),
            onTap: () => _showEditHistoryBottomSheet(date, data),
          ),
        );
      }).toList(),
    );
  }

  void _deleteHistoryRecord(DateTime date) {
    setState(() {
      dailyLogs.remove(date);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Record deleted successfully'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
    });
  }

  void _showEditHistoryBottomSheet(DateTime date, Map<String, int> data) {
    final Map<String, int> editData = Map.from(data);
    final screenHeight = MediaQuery.of(context).size.height;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return Container(
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
              ),
              padding: const EdgeInsets.all(16),
              height: screenHeight * 0.6,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Edit Manpower for ${DateFormat('yyyy-MM-dd').format(date)}',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF2a43a0),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close, color: Color(0xFF2a43a0)),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Expanded(
                    child: ListView(
                      children: categories.map((category) {
                        return Container(
                          margin: const EdgeInsets.only(bottom: 12),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.05),
                                blurRadius: 8,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 12,
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  flex: 2,
                                  child: Text(
                                    category,
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: Color(0xFF2a43a0),
                                    ),
                                  ),
                                ),
                                Expanded(
                                  flex: 3,
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.end,
                                    children: [
                                      IconButton(
                                        icon: const Icon(
                                          Icons.remove_circle,
                                          color: Color(0xFFE53935),
                                          size: 28,
                                        ),
                                        onPressed: () {
                                          setState(() {
                                            editData[category] =
                                                (editData[category]! - 1).clamp(
                                                  0,
                                                  999,
                                                );
                                          });
                                        },
                                      ),
                                      Container(
                                        width: 50,
                                        height: 36,
                                        alignment: Alignment.center,
                                        decoration: BoxDecoration(
                                          color: const Color(0xFFE8F0FE),
                                          borderRadius: BorderRadius.circular(
                                            8,
                                          ),
                                        ),
                                        child: Text(
                                          '${editData[category]}',
                                          style: const TextStyle(
                                            fontSize: 18,
                                            fontWeight: FontWeight.bold,
                                            color: Color(0xFF2a43a0),
                                          ),
                                        ),
                                      ),
                                      IconButton(
                                        icon: const Icon(
                                          Icons.add_circle,
                                          color: Color(0xFF4CAF50),
                                          size: 28,
                                        ),
                                        onPressed: () {
                                          setState(() {
                                            editData[category] =
                                                (editData[category]! + 1).clamp(
                                                  0,
                                                  999,
                                                );
                                          });
                                        },
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () {
                      // Save the edited data
                      setState(() {
                        dailyLogs[date] = editData;

                        // If editing today's data, also update the dailyCount
                        final today = DateTime(
                          DateTime.now().year,
                          DateTime.now().month,
                          DateTime.now().day,
                        );

                        if (date.year == today.year &&
                            date.month == today.month &&
                            date.day == today.day) {
                          dailyCount.clear();
                          dailyCount.addAll(editData);
                        }

                        Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: const Text(
                              'Manpower count updated successfully!',
                            ),
                            backgroundColor: Colors.green,
                            behavior: SnackBarBehavior.floating,
                          ),
                        );
                      });
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF4CAF50),
                      foregroundColor: Colors.white,
                      elevation: 6,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      minimumSize: const Size(double.infinity, 46),
                    ),
                    child: const Text(
                      'Save Changes',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  void _showManageCategoriesBottomSheet() {
    _newCategoryController.clear();
    final screenHeight = MediaQuery.of(context).size.height;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setBottomSheetState) {
            return Container(
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
              ),
              padding: const EdgeInsets.all(16),
              height: screenHeight * 0.6,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Manage Categories',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF2a43a0),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close, color: Color(0xFF2a43a0)),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _newCategoryController,
                          decoration: InputDecoration(
                            labelText: 'New Category Name',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 10,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      ElevatedButton(
                        onPressed: () {
                          final newCategory = _newCategoryController.text
                              .trim();
                          if (newCategory.isNotEmpty &&
                              !categories.contains(newCategory)) {
                            setState(() {
                              categories.add(newCategory);
                              dailyCount[newCategory] = 0;

                              // Add the new category to all existing logs with 0 count
                              for (final log in dailyLogs.values) {
                                log[newCategory] = 0;
                              }

                              _newCategoryController.clear();
                            });

                            // Update the bottom sheet state to reflect the changes
                            setBottomSheetState(() {});

                            // Close the bottom sheet first
                            Navigator.pop(context);

                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  'Category "$newCategory" added successfully',
                                ),
                                backgroundColor: Colors.green,
                                behavior: SnackBarBehavior.floating,
                              ),
                            );
                          } else if (categories.contains(newCategory)) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: const Text('Category already exists'),
                                backgroundColor: Colors.orange,
                                behavior: SnackBarBehavior.floating,
                              ),
                            );
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF4a63c0),
                          foregroundColor: Colors.white,
                          elevation: 4,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 10,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        child: const Text('Add'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    'Existing Categories',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF2a43a0),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Expanded(
                    child: ListView(
                      children: categories.map((category) {
                        return Container(
                          margin: const EdgeInsets.only(bottom: 10),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(10),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.05),
                                blurRadius: 8,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: ListTile(
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 6,
                            ),
                            title: Text(
                              category,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            trailing: IconButton(
                              icon: const Icon(
                                Icons.delete,
                                color: Color(0xFFE53935),
                              ),
                              onPressed: () {
                                setState(() {
                                  categories.remove(category);
                                  dailyCount.remove(category);

                                  // Remove the category from all existing logs
                                  for (final log in dailyLogs.values) {
                                    log.remove(category);
                                  }
                                });

                                // Update the bottom sheet state to reflect the changes
                                setBottomSheetState(() {});

                                // Close the bottom sheet first
                                Navigator.pop(context);

                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      'Category "$category" deleted successfully',
                                    ),
                                    backgroundColor: Colors.red,
                                    behavior: SnackBarBehavior.floating,
                                  ),
                                );
                              },
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildCategoryCard(String category) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallScreen = screenWidth < 360;

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: [Colors.white, Colors.grey.shade50]),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            // Category Name
            Expanded(
              child: Text(
                category,
                style: TextStyle(
                  fontSize: isSmallScreen ? 14 : 16,
                  fontWeight: FontWeight.bold,
                  color: const Color.fromARGB(255, 68, 67, 68),
                ),
              ),
            ),
            // Counter sticked together
            Container(
              child: Padding(
                padding: const EdgeInsets.all(4.0),
                child: Container(
                  decoration: BoxDecoration(
                    color: const Color.fromARGB(255, 192, 205, 245),
                    borderRadius: BorderRadius.circular(30),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Minus button
                      GestureDetector(
                        onTap: () => _updateCount(category, -1),
                        child: Container(
                          width: isSmallScreen ? 32 : 35,
                          height: isSmallScreen ? 32 : 38,
                          alignment: Alignment.center,
                          child: Text(
                            '−',
                            style: TextStyle(
                              fontSize: isSmallScreen ? 20 : 22,
                              color: Colors.black,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ),

                      // White circular counter (Editable)
                      GestureDetector(
                        onTap: () {
                          _showEditCountBottomSheet(category);
                        },
                        child: Container(
                          width: isSmallScreen ? 25 : 28,
                          height: isSmallScreen ? 25 : 28,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.1),
                                spreadRadius: 1,
                                blurRadius: 2,
                                offset: const Offset(0, 1),
                              ),
                            ],
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            '${dailyCount[category]}',
                            style: TextStyle(
                              fontSize: isSmallScreen ? 15 : 17,
                              fontWeight: FontWeight.bold,
                              color: Colors.black,
                            ),
                          ),
                        ),
                      ),

                      // Plus button
                      GestureDetector(
                        onTap: () => _updateCount(category, 1),
                        child: Container(
                          width: isSmallScreen ? 32 : 35,
                          height: isSmallScreen ? 32 : 38,
                          alignment: Alignment.center,
                          child: Text(
                            '+',
                            style: TextStyle(
                              fontSize: isSmallScreen ? 20 : 22,
                              color: Colors.black,
                              fontWeight: FontWeight.w400,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallScreen = screenWidth < 360;

    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          toolbarHeight: 80.h,
          title: Flexible(
            child: RichText(
              text: TextSpan(
                children: [
                  TextSpan(
                    text: 'ManPower - ',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: isSmallScreen ? 16 : 20,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  TextSpan(
                    text: _getCurrentSiteName(),
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: isSmallScreen ? 14 : 16,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                ],
              ),
            ),
          ),
          iconTheme: const IconThemeData(color: Colors.white),
          backgroundColor: Colors.transparent,
          flexibleSpace: Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Color(0xFF4a63c0),
                  Color(0xFF3a53b0),
                  Color(0xFF2a43a0),
                ],
              ),
              borderRadius: BorderRadius.vertical(bottom: Radius.circular(25)),
            ),
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.playlist_add),
              onPressed: _showManageCategoriesBottomSheet,
              tooltip: 'Manage Categories',
            ),
            IconButton(
              icon: const Icon(Icons.summarize),
              onPressed: _generateReport,
              tooltip: 'Generate Report',
            ),
          ],
        ),
        body: Column(
          children: [
            // TabBar below AppBar without container
            TabBar(
              tabs: const [
                Tab(icon: Icon(Icons.today)),
                Tab(icon: Icon(Icons.calendar_month)),
                Tab(icon: Icon(Icons.history)),
              ],
              onTap: (index) => setState(() => _selectedTabIndex = index),
              labelColor: const Color(0xFF2a43a0),
              unselectedLabelColor: Colors.grey,
              indicatorColor: const Color(0xFF2a43a0),
            ),
            // TabBarView
            Expanded(
              child: TabBarView(
                children: [
                  // Today Tab
                  Column(
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(16),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  DateFormat(
                                    'EEEE, MMMM d',
                                  ).format(selectedDate),
                                  style: TextStyle(
                                    fontSize: isSmallScreen ? 16 : 20,
                                    fontWeight: FontWeight.bold,
                                    color: const Color(0xFF363636),
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 10,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFE8F0FE),
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                  child: Text(
                                    'Today',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: Colors.grey.shade700,
                                      fontSize: isSmallScreen ? 12 : 14,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      Expanded(
                        child: ListView(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          children: categories
                              .map((category) => _buildCategoryCard(category))
                              .toList(),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(16),
                        child: Container(
                          width: 230.w,
                          child: ElevatedButton.icon(
                            onPressed: _saveDailyCount,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Color.fromARGB(255, 52, 80, 182),
                              foregroundColor: Colors.white,
                              elevation: 6,
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(20),
                              ),
                              minimumSize: const Size(double.infinity, 40),
                            ),
                            icon: const Icon(Icons.save),
                            label: Text(
                              'Save Daily Count',
                              style: TextStyle(
                                fontSize: isSmallScreen ? 14 : 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  // Calendar Tab
                  _buildCalendarView(),
                  // History Tab
                  _buildHistoryView(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _getCurrentSiteName() {
    if (widget.selectedSiteId == null) {
      return 'All Sites';
    }
    final site = widget.sites.firstWhere(
      (site) => site.id == widget.selectedSiteId,
      orElse: () =>
          Site(id: '', name: 'Unknown Site', address: '', companyId: ''),
    );
    return site.name;
  }

  void _showEditCountBottomSheet(String category) {
    final controller = TextEditingController(
      text: dailyCount[category].toString(),
    );

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.25,
        minChildSize: 0.2,
        maxChildSize: 0.5,
        builder: (context, scrollController) {
          return Container(
            padding: const EdgeInsets.all(16),
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Edit Count for $category',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: controller,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                    labelText: 'Enter count',
                  ),
                ),
                const SizedBox(height: 12),
                Align(
                  alignment: Alignment.center, // Center the button
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor:  Color.fromARGB(255, 47, 75, 175), // Blue background
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 12,
                      ), // Smaller width
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(
                          15,
                        ), // Rounded corners
                      ),
                    ),
                    onPressed: () {
                      final value = int.tryParse(controller.text) ?? 0;
                      setState(() {
                        dailyCount[category] = value;
                      });
                      Navigator.pop(context);
                    },
                    child: const Text(
                      'Save',
                      style: TextStyle(fontSize: 17, color: Colors.white,fontWeight: FontWeight.w500),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
