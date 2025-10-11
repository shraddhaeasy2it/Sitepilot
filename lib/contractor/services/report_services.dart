import 'dart:io';
import 'dart:typed_data';
import 'dart:ui';
import 'package:path_provider/path_provider.dart';
import 'package:open_file/open_file.dart';
import 'package:intl/intl.dart';
import 'package:syncfusion_flutter_pdf/pdf.dart';
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