import 'dart:io';
import 'dart:typed_data';
import 'dart:ui';
import 'package:path_provider/path_provider.dart';
import 'package:open_file/open_file.dart';
import 'package:intl/intl.dart';
import 'package:syncfusion_flutter_pdf/pdf.dart';
import 'package:pdf/pdf.dart' as pdf_pkg;
import 'package:pdf/widgets.dart' as pw;

class ReportService {
  static Future<String> generateAttendancePDF(
      List<Map<String, dynamic>> attendanceData,
      String siteName,
      DateTime? startDate,
      DateTime? endDate) async {
    // Create a new PDF document
    final PdfDocument document = PdfDocument();

    // Add a new page
    final PdfPage page = document.pages.add();

    // Get page size
    final Size pageSize = page.getClientSize();

    // Draw header
    final PdfFont headerFont = PdfStandardFont(PdfFontFamily.helvetica, 20);
    final PdfFont subHeaderFont = PdfStandardFont(PdfFontFamily.helvetica, 14);
    final PdfFont contentFont = PdfStandardFont(PdfFontFamily.helvetica, 10);

    // Draw title
    page.graphics.drawString(
      'Attendance Report',
      headerFont,
      brush: PdfBrushes.black,
      bounds: Rect.fromLTWH(0, 0, pageSize.width, 30),
      format: PdfStringFormat(alignment: PdfTextAlignment.center),
    );

    // Draw site and date info
    String dateInfo = 'Site: $siteName';
    if (startDate != null && endDate != null) {
      if (startDate == endDate) {
        dateInfo += ' | Date: ${DateFormat('yyyy-MM-dd').format(startDate)}';
      } else {
        dateInfo += ' | Period: ${DateFormat('yyyy-MM-dd').format(startDate)} to ${DateFormat('yyyy-MM-dd').format(endDate)}';
      }
    } else if (startDate != null) {
      dateInfo += ' | From: ${DateFormat('yyyy-MM-dd').format(startDate)}';
    } else if (endDate != null) {
      dateInfo += ' | Until: ${DateFormat('yyyy-MM-dd').format(endDate)}';
    }

    page.graphics.drawString(
      dateInfo,
      subHeaderFont,
      brush: PdfBrushes.darkBlue,
      bounds: Rect.fromLTWH(0, 40, pageSize.width, 20),
      format: PdfStringFormat(alignment: PdfTextAlignment.center),
    );

    // Create a PDF grid
    final PdfGrid grid = PdfGrid();
    grid.columns.add(count: 7);

    // Add header row
    final PdfGridRow headerRow = grid.headers.add(1)[0];
    headerRow.cells[0].value = 'Worker ID';
    headerRow.cells[1].value = 'Name';
    headerRow.cells[2].value = 'Status';
    headerRow.cells[3].value = 'Time In';
    headerRow.cells[4].value = 'Time Out';
    headerRow.cells[5].value = 'Hours';
    headerRow.cells[6].value = 'Overtime';

    // Style header
    headerRow.style = PdfGridRowStyle(
      backgroundBrush: PdfBrushes.lightBlue,
      textBrush: PdfBrushes.black,
      font: PdfStandardFont(PdfFontFamily.helvetica, 10, style: PdfFontStyle.bold),
    );

    // Add data rows
    for (var record in attendanceData) {
      final PdfGridRow row = grid.rows.add();
      row.cells[0].value = record['workerId']?.toString() ?? '';
      row.cells[1].value = record['workerName']?.toString() ?? '';
      row.cells[2].value = record['status']?.toString() ?? '';
      row.cells[3].value = record['timeIn']?.toString() ?? '';
      row.cells[4].value = record['timeOut']?.toString() ?? '';
      row.cells[5].value = record['hours']?.toString() ?? '0';
      row.cells[6].value = record['overtime']?.toString() ?? '0';
    }

    // Draw the grid
    grid.draw(
      page: page,
      bounds: Rect.fromLTWH(0, 70, pageSize.width, pageSize.height - 100),
    );

    // Add summary
    final int presentCount = attendanceData.where((r) => r['status'] == 'Present').length;
    final int absentCount = attendanceData.where((r) => r['status'] == 'Absent').length;
    final int lateCount = attendanceData.where((r) => r['status'] == 'Late').length;

    page.graphics.drawString(
      'Summary: Present: $presentCount, Absent: $absentCount, Late: $lateCount',
      contentFont,
      brush: PdfBrushes.black,
      bounds: Rect.fromLTWH(0, pageSize.height - 30, pageSize.width, 20),
      format: PdfStringFormat(alignment: PdfTextAlignment.center),
    );

    // Save the document
    final List<int> bytes = document.saveSync();

    // Dispose the document
    document.dispose();

    // Get external storage directory
    final Directory directory = await getApplicationDocumentsDirectory();
    final String timestamp = DateTime.now().millisecondsSinceEpoch.toString();
    final String path = '${directory.path}/attendance_report_$timestamp.pdf';
    final File file = File(path);
    await file.writeAsBytes(bytes, flush: true);

    return path;
  }

  static Future<List<int>> generateConsumptionPDF(
      List<Map<String, dynamic>> consumptionData,
      String siteName,
      DateTime? startDate,
      DateTime? endDate,
      {String? filterType}) async {
    // Create a new PDF document
    final PdfDocument document = PdfDocument();

    // Add a new page
    final PdfPage page = document.pages.add();

    // Get page size
    final Size pageSize = page.getClientSize();

    // Draw header
    final PdfFont headerFont = PdfStandardFont(PdfFontFamily.helvetica, 20);
    final PdfFont subHeaderFont = PdfStandardFont(PdfFontFamily.helvetica, 14);
    final PdfFont contentFont = PdfStandardFont(PdfFontFamily.helvetica, 10);

    // Draw title
    page.graphics.drawString(
      'Consumption Report',
      headerFont,
      brush: PdfBrushes.black,
      bounds: Rect.fromLTWH(0, 0, pageSize.width, 30),
      format: PdfStringFormat(alignment: PdfTextAlignment.center),
    );

    // Draw site and date info
    String dateInfo = 'Site: $siteName';
    if (startDate != null && endDate != null) {
      if (startDate == endDate) {
        dateInfo += ' | Date: ${DateFormat('yyyy-MM-dd').format(startDate)}';
      } else {
        dateInfo += ' | Period: ${DateFormat('yyyy-MM-dd').format(startDate)} to ${DateFormat('yyyy-MM-dd').format(endDate)}';
      }
    } else if (startDate != null) {
      dateInfo += ' | From: ${DateFormat('yyyy-MM-dd').format(startDate)}';
    } else if (endDate != null) {
      dateInfo += ' | Until: ${DateFormat('yyyy-MM-dd').format(endDate)}';
    }

    // Add filter info if present
    if (filterType != null && filterType != 'All') {
      dateInfo += ' | Filter: $filterType';
    }

    page.graphics.drawString(
      dateInfo,
      subHeaderFont,
      brush: PdfBrushes.darkBlue,
      bounds: Rect.fromLTWH(0, 40, pageSize.width, 20),
      format: PdfStringFormat(alignment: PdfTextAlignment.center),
    );

    // Create a PDF grid
    final PdfGrid grid = PdfGrid();
    grid.columns.add(count: 6);

    // Add header row
    final PdfGridRow headerRow = grid.headers.add(1)[0];
    headerRow.cells[0].value = 'Log #';
    headerRow.cells[1].value = 'Date';
    headerRow.cells[2].value = 'Type';
    headerRow.cells[3].value = 'Material/Fuel';
    headerRow.cells[4].value = 'Quantity';
    headerRow.cells[5].value = 'Remarks';

    // Style header
    headerRow.style = PdfGridRowStyle(
      backgroundBrush: PdfBrushes.lightBlue,
      textBrush: PdfBrushes.black,
      font: PdfStandardFont(PdfFontFamily.helvetica, 10, style: PdfFontStyle.bold),
    );

    // Add data rows
    for (var record in consumptionData) {
      final PdfGridRow row = grid.rows.add();
      row.cells[0].value = record['consumptionNo']?.toString() ?? '';
      row.cells[1].value = record['date']?.toString() ?? '';
      row.cells[2].value = record['type']?.toString() ?? '';
      row.cells[3].value = record['material']?.toString() ?? '';
      row.cells[4].value = record['quantity']?.toString() ?? '';
      row.cells[5].value = record['remarks']?.toString() ?? '';
    }

    // Draw the grid
    grid.draw(
      page: page,
      bounds: Rect.fromLTWH(0, 70, pageSize.width, pageSize.height - 100),
    );

    // Save the document
    final List<int> bytes = document.saveSync();

    // Dispose the document
    document.dispose();

    return bytes;
  }


  static Future<String> generateMaterialUsagePDF(
      List<Map<String, dynamic>> usageData,
      String siteName,
      {String? customTitle}) async {
    final pdf = pw.Document();

    pdf.addPage(
      pw.Page(
        build: (pw.Context context) {
          return pw.Column(
            children: [
              pw.Header(
                level: 0,
                child: pw.Text(customTitle ?? 'Material Usage Report', style: pw.TextStyle(fontSize: 20, fontWeight: pw.FontWeight.bold)),
              ),
              pw.Text('Site: $siteName', style: pw.TextStyle(fontSize: 14)),
              pw.SizedBox(height: 20),
              pw.Table.fromTextArray(
                headers: ['Material', 'Quantity Used', 'Purpose', 'Site', 'Date'],
                data: usageData.map((record) => [
                  record['materialName']?.toString() ?? '',
                  record['quantityUsed']?.toString() ?? '',
                  record['purpose']?.toString() ?? '',
                  record['site']?.toString() ?? '',
                  record['date']?.toString() ?? '',
                ]).toList(),
              ),
              pw.SizedBox(height: 20),
              pw.Text('Total Quantity Used: ${usageData.fold(0.0, (sum, r) => sum + (r['quantityUsed'] as num? ?? 0))}'),
            ],
          );
        },
      ),
    );

    // Get temporary directory
    final Directory directory = await getTemporaryDirectory();
    final String path = '${directory.path}/material_usage_report_${DateTime.now().millisecondsSinceEpoch}.pdf';
    final File file = File(path);
    await file.writeAsBytes(await pdf.save(), flush: true);

    return path;
  }

  static Future<String> generateStockPDF(
      List<List<String>> stockData,
      String siteName,
      {String? categoryFilter}) async {
    final pdf = pw.Document();

    // Calculate totals
    final int totalItems = stockData.length;
    final double totalValue = stockData.fold(0.0, (sum, item) {
      final qty = int.tryParse(item[2]) ?? 0;
      final price = double.tryParse(item[4]) ?? 0.0;
      return sum + (qty * price);
    });

    pdf.addPage(
      pw.MultiPage(
        pageFormat: pdf_pkg.PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (pw.Context context) {
          return [
            // Header
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Text(
                  'Stock Report',
                  style: pw.TextStyle(
                    fontSize: 24,
                    fontWeight: pw.FontWeight.bold,
                    color: pdf_pkg.PdfColors.blue,
                  ),
                ),
                pw.Text(
                  'Site: $siteName',
                  style: const pw.TextStyle(fontSize: 12),
                ),
              ],
            ),
            if (categoryFilter != null && categoryFilter != 'All')
              pw.Padding(
                padding: const pw.EdgeInsets.only(top: 5),
                child: pw.Text(
                  'Category: $categoryFilter',
                  style: const pw.TextStyle(fontSize: 12, color: pdf_pkg.PdfColors.grey700),
                ),
              ),
            pw.SizedBox(height: 20),

            // Report Details
            pw.Container(
              decoration: pw.BoxDecoration(
                border: pw.Border.all(width: 1),
                borderRadius: pw.BorderRadius.circular(8),
              ),
              padding: const pw.EdgeInsets.all(12),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text(
                    'Report Date: ${DateFormat('dd MMM yyyy').format(DateTime.now())}',
                    style: pw.TextStyle(
                      fontSize: 14,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                  pw.SizedBox(height: 8),
                  pw.Row(
                    children: [
                      pw.Expanded(
                        child: pw.Text(
                          'Total Items: $totalItems',
                          style: const pw.TextStyle(fontSize: 12),
                        ),
                      ),
                      pw.Expanded(
                        child: pw.Text(
                          'Total Value: ${totalValue.toStringAsFixed(2)}',
                          style: pw.TextStyle(
                            fontSize: 12,
                            fontWeight: pw.FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            pw.SizedBox(height: 25),

            // Stock Data Table
            pw.Text(
              'Stock Details',
              style: pw.TextStyle(
                fontSize: 18,
                fontWeight: pw.FontWeight.bold,
                color: pdf_pkg.PdfColors.blue,
              ),
            ),
            pw.SizedBox(height: 10),

            pw.Table(
              border: pw.TableBorder.all(width: 0.5),
              columnWidths: {
                0: const pw.FlexColumnWidth(2.5), // Material Name
                1: const pw.FlexColumnWidth(1.5), // Category
                2: const pw.FlexColumnWidth(1), // Quantity
                3: const pw.FlexColumnWidth(0.8), // Unit
                4: const pw.FlexColumnWidth(1.2), // Price
              },
              children: [
                // Header
                pw.TableRow(
                  decoration: pw.BoxDecoration(
                    color: pdf_pkg.PdfColors.blue50,
                  ),
                  children: [
                    pw.Padding(
                      child: pw.Text(
                        'Material Name',
                        style: pw.TextStyle(
                          fontWeight: pw.FontWeight.bold,
                          fontSize: 10,
                        ),
                      ),
                      padding: const pw.EdgeInsets.all(6),
                    ),
                    pw.Padding(
                      child: pw.Text(
                        'Category',
                        style: pw.TextStyle(
                          fontWeight: pw.FontWeight.bold,
                          fontSize: 10,
                        ),
                      ),
                      padding: const pw.EdgeInsets.all(6),
                    ),
                    pw.Padding(
                      child: pw.Text(
                        'Quantity',
                        style: pw.TextStyle(
                          fontWeight: pw.FontWeight.bold,
                          fontSize: 10,
                        ),
                      ),
                      padding: const pw.EdgeInsets.all(6),
                    ),
                    pw.Padding(
                      child: pw.Text(
                        'Unit',
                        style: pw.TextStyle(
                          fontWeight: pw.FontWeight.bold,
                          fontSize: 10,
                        ),
                      ),
                      padding: const pw.EdgeInsets.all(6),
                    ),
                    pw.Padding(
                      child: pw.Text(
                        'Price',
                        style: pw.TextStyle(
                          fontWeight: pw.FontWeight.bold,
                          fontSize: 10,
                        ),
                      ),
                      padding: const pw.EdgeInsets.all(6),
                    ),
                  ],
                ),

                // Data rows
                ...stockData.map((item) {
                  return pw.TableRow(
                    children: [
                      pw.Padding(
                        child: pw.Text(
                          item[0],
                          style: const pw.TextStyle(fontSize: 9),
                        ),
                        padding: const pw.EdgeInsets.all(6),
                      ),
                      pw.Padding(
                        child: pw.Text(
                          item[1],
                          style: const pw.TextStyle(fontSize: 9),
                        ),
                        padding: const pw.EdgeInsets.all(6),
                      ),
                      pw.Padding(
                        child: pw.Text(
                          item[2],
                          style: const pw.TextStyle(fontSize: 9),
                        ),
                        padding: const pw.EdgeInsets.all(6),
                      ),
                      pw.Padding(
                        child: pw.Text(
                          item[3],
                          style: const pw.TextStyle(fontSize: 9),
                        ),
                        padding: const pw.EdgeInsets.all(6),
                      ),
                      pw.Padding(
                        child: pw.Text(
                          '${item[4]}',
                          style: const pw.TextStyle(fontSize: 9),
                        ),
                        padding: const pw.EdgeInsets.all(6),
                      ),
                    ],
                  );
                }).toList(),
              ],
            ),

            pw.SizedBox(height: 30),

            // Footer
            pw.Container(
              width: double.infinity,
              padding: const pw.EdgeInsets.all(10),
              decoration: pw.BoxDecoration(
                border: pw.Border.all(width: 0.5),
                color: pdf_pkg.PdfColors.grey200,
              ),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text(
                    'Generated on: ${DateFormat('dd MMM yyyy HH:mm').format(DateTime.now())}',
                    style: const pw.TextStyle(fontSize: 9),
                  ),
                  pw.Text(
                    'Site: $siteName',
                    style: const pw.TextStyle(fontSize: 9),
                  ),
                ],
              ),
            ),
          ];
        },
      ),
    );

    // Get temporary directory
    final Directory directory = await getTemporaryDirectory();
    final String path = '${directory.path}/stock_report_${DateTime.now().millisecondsSinceEpoch}.pdf';
    final File file = File(path);
    await file.writeAsBytes(await pdf.save(), flush: true);

    return path;
  }

  static Future<void> openFile(String filePath) async {
    try {
      // Check if file exists
      final file = File(filePath);
      final exists = await file.exists();

      if (!exists) {
        throw Exception('File does not exist: $filePath');
      }

      // Get file size to verify it's not empty
      final length = await file.length();
      if (length == 0) {
        throw Exception('File is empty: $filePath');
      }

      // Open the file
      final result = await OpenFile.open(filePath);

      // Check the result
      switch (result.type) {
        case ResultType.done:
          print('File opened successfully');
          break;
        case ResultType.noAppToOpen:
          throw Exception('No application found to open PDF files');
        case ResultType.fileNotFound:
          throw Exception('File not found: $filePath');
        case ResultType.permissionDenied:
          throw Exception('Permission denied to open the file');
        case ResultType.error:
          throw Exception('Error opening file: ${result.message}');
      }
    } catch (e) {
      print('Error in openFile: $e');
      rethrow;
    }
  }


}
