import 'dart:io';
import 'package:flutter/services.dart';
import 'package:open_filex/open_filex.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart' show PdfColor, PdfColors, PdfPageFormat;
import 'package:pdf/widgets.dart' as pw;
import 'package:cashsify_app/core/utils/logger.dart';
import 'package:cashsify_app/core/services/storage_service.dart';
import 'package:cashsify_app/core/config/app_config.dart';

class PdfUtils {
  static final _storageService = StorageService();

  static Future<String?> generateWithdrawalPdf({
    required int amount,
    required String method,
    String? upiId,
    Map<String, dynamic>? bankDetails,
    required String status,
    required DateTime requestedAt,
    String? withdrawalId,
    String? userId,
    String? note,
    String? transactionId,
    DateTime? processedAt,
    DateTime? approvedAt,
    DateTime? rejectedAt,
  }) async {
    try {
      // Validate required inputs
      if (amount <= 0) {
        AppLogger.error('Invalid amount provided: $amount');
        return null;
      }
      
      if (method.isEmpty) {
        AppLogger.error('Invalid method provided: $method');
        return null;
      }
      
      if (status.isEmpty) {
        AppLogger.error('Invalid status provided: $status');
        return null;
      }
      
      AppLogger.info('Generating withdrawal summary PDF for amount: $amount, method: $method, status: $status');
      
      final pdf = pw.Document();

      // Load logo with error handling
      pw.MemoryImage? logoImage;
      try {
        final ByteData bytes = await rootBundle.load('assets/logo/logo.png');
        final Uint8List list = bytes.buffer.asUint8List();
        logoImage = pw.MemoryImage(list);
      } catch (logoError) {
        AppLogger.warning('Failed to load logo: $logoError. Continuing without logo.');
      }

      pdf.addPage(
        pw.Page(
          pageFormat: PdfPageFormat.a4,
          build: (pw.Context context) {
            return pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                // Header
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        // Logo (if available)
                        if (logoImage != null) ...[
                          pw.Image(logoImage!, width: 70, height: 70),
                          pw.SizedBox(height: 5),
                        ],
                        pw.Text(
                          'Watch2Earn',
                          style: pw.TextStyle(fontSize: 20, fontWeight: pw.FontWeight.bold),
                        ),
                        pw.Text(
                          'Earn Cash Simply!',
                          style: pw.TextStyle(fontSize: 10),
                        ),
                        pw.Text(
                          'app.watch2earn@gmail.com | +91 80722 23275',
                          style: pw.TextStyle(fontSize: 10),
                        ),
                      ],
                    ),
                    pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.end,
                      children: [
                        pw.Text(
                          'WITHDRAWAL SUMMARY',
                          style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold, color: PdfColors.blue700),
                        ),
                        pw.SizedBox(height: 5),
                        pw.Text(
                          'Date: ${DateTime.now().toLocal().toString().split('.')[0]}',
                          style: pw.TextStyle(fontSize: 12),
                        ),
                        pw.Text(
                          'Request ID: ${withdrawalId ?? 'N/A'}',
                          style: pw.TextStyle(fontSize: 12),
                        ),
                      ],
                    ),
                  ],
                ),
                pw.SizedBox(height: 30),
                pw.Divider(thickness: 1),
                pw.SizedBox(height: 20),

                // Basic Withdrawal Details
                pw.Text(
                  'Withdrawal Details',
                  style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold, color: PdfColors.blueGrey800),
                ),
                pw.SizedBox(height: 10),
                pw.TableHelper.fromTextArray(
                  headers: ['Detail', 'Value'],
                  data: _buildBasicDetails(
                    amount: amount,
                    method: method,
                    upiId: upiId,
                    bankDetails: bankDetails,
                    status: status,
                    requestedAt: requestedAt,
                  ),
                  border: pw.TableBorder.all(color: PdfColors.grey400),
                  headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, color: PdfColors.white),
                  headerDecoration: const pw.BoxDecoration(color: PdfColors.blueGrey700),
                  cellAlignment: pw.Alignment.centerLeft,
                  cellStyle: const pw.TextStyle(fontSize: 10),
                  columnWidths: {0: const pw.FixedColumnWidth(100), 1: const pw.FlexColumnWidth(300)},
                ),
                pw.SizedBox(height: 30),

                // Status Timeline
                pw.Text(
                  'Status Timeline',
                  style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold, color: PdfColors.blueGrey800),
                ),
                pw.SizedBox(height: 10),
                ..._buildStatusTimeline(
                  status: status,
                  requestedAt: requestedAt,
                  processedAt: processedAt,
                  approvedAt: approvedAt,
                  rejectedAt: rejectedAt,
                  note: note,
                  transactionId: transactionId,
                ),
                pw.SizedBox(height: 30),

                // Footer
                pw.Text(
                  'Note: Coins are virtual rewards within the app and do not have a direct monetary value unless redeemed as per app policy.',
                  style: pw.TextStyle(fontSize: 10, font: pw.Font.courier()),
                ),
                pw.Spacer(),
                pw.Divider(thickness: 1),
                pw.SizedBox(height: 10),
                pw.Center(
                  child: pw.Text(
                    'Thank you for using ${AppConfig.appName} App!',
                    style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold),
                  ),
                ),
                pw.Align(
                  alignment: pw.Alignment.centerRight,
                  child: pw.Text(
                    'Page ${context.pageNumber} of ${context.pagesCount}',
                    style: pw.TextStyle(fontSize: 8, color: PdfColors.grey600),
                  ),
                ),
              ],
            );
          },
        ),
      );

      // Save to documents directory for permanent storage
      final documentsDir = await getApplicationDocumentsDirectory();
      final fileName = 'withdrawal_summary_${DateTime.now().millisecondsSinceEpoch}.pdf';
      final filePath = '${documentsDir.path}/$fileName';
      final file = File(filePath);
      
      AppLogger.info('Saving withdrawal summary PDF to: $filePath');
      
      // Generate PDF bytes with error handling
      final pdfBytes = await pdf.save();
      await file.writeAsBytes(pdfBytes);
      
      // Verify file was created
      if (await file.exists()) {
        final fileSize = await file.length();
        AppLogger.info('Withdrawal summary PDF saved successfully. File size: $fileSize bytes');
        
        // Upload to Supabase storage if userId and withdrawalId are provided
        if (userId != null && withdrawalId != null) {
          AppLogger.info('Uploading withdrawal summary PDF to Supabase storage');
          final storageUrl = await _storageService.uploadWithdrawalPdf(
            userId: userId,
            withdrawalId: withdrawalId,
            pdfFile: file,
          );
          
          if (storageUrl != null) {
            AppLogger.info('Withdrawal summary PDF uploaded to Supabase storage: $storageUrl');
          } else {
            AppLogger.error('Failed to upload withdrawal summary PDF to Supabase storage');
          }
        }
        
        // Open the PDF
        try {
          await OpenFilex.open(file.path);
        } catch (openError) {
          AppLogger.warning('Failed to open PDF automatically: $openError');
        }
        
        return filePath; // Return the file path for reference
      } else {
        AppLogger.error('Withdrawal summary PDF file was not created successfully');
        return null;
      }
    } catch (e, stackTrace) {
      AppLogger.error('Error generating withdrawal summary PDF: $e', e, stackTrace);
      return null;
    }
  }

  /// Get all saved PDF files
  static Future<List<File>> getSavedPdfs() async {
    try {
      final documentsDir = await getApplicationDocumentsDirectory();
      final files = documentsDir.listSync()
          .whereType<File>()
          .where((file) => file.path.endsWith('.pdf'))
          .toList();
      
      AppLogger.info('Found ${files.length} saved PDF files');
      return files;
    } catch (e) {
      AppLogger.error('Error getting saved PDFs: $e');
      return [];
    }
  }

  /// Delete a specific PDF file
  static Future<bool> deletePdf(String filePath) async {
    try {
      final file = File(filePath);
      if (await file.exists()) {
        await file.delete();
        AppLogger.info('PDF deleted: $filePath');
        return true;
      }
      return false;
    } catch (e) {
      AppLogger.error('Error deleting PDF: $e');
      return false;
    }
  }

  /// Clear all PDF files
  static Future<void> clearAllPdfs() async {
    try {
      final files = await getSavedPdfs();
      for (final file in files) {
        await file.delete();
      }
      AppLogger.info('All PDF files cleared');
    } catch (e) {
      AppLogger.error('Error clearing PDF files: $e');
    }
  }

  /// Open a PDF file
  static Future<void> openPdf(String filePath) async {
    try {
      AppLogger.info('Opening PDF: $filePath');
      await OpenFilex.open(filePath);
    } catch (e) {
      AppLogger.error('Error opening PDF: $e');
      rethrow;
    }
  }

  static List<List<String>> _buildBasicDetails({
    required int amount,
    required String method,
    String? upiId,
    Map<String, dynamic>? bankDetails,
    required String status,
    required DateTime requestedAt,
  }) {
    return [
      ['Amount', '$amount Coins'],
      ['Method', method.toUpperCase()],
      if (method == 'upi' && upiId != null)
        ['UPI ID', upiId],
      if (method == 'bank' && bankDetails != null) ...[
        ['Account Holder Name', bankDetails['name'] ?? 'N/A'],
        ['Account Number', bankDetails['account_no'] ?? 'N/A'],
        ['IFSC Code', bankDetails['ifsc'] ?? 'N/A'],
      ],
      ['Current Status', status.toUpperCase()],
      ['Requested At', requestedAt.toLocal().toString().split('.')[0]],
    ];
  }

  static List<pw.Widget> _buildStatusTimeline({
    required String status,
    required DateTime requestedAt,
    DateTime? processedAt,
    DateTime? approvedAt,
    DateTime? rejectedAt,
    String? note,
    String? transactionId,
  }) {
    final timeline = <pw.Widget>[];

    // Request Status (always present)
    timeline.add(_buildTimelineItem(
      title: 'Request Submitted',
      timestamp: requestedAt,
      description: 'Withdrawal request has been submitted and is under review.',
      status: 'completed',
    ));

    // Processed Status
    if (processedAt != null) {
      timeline.add(_buildTimelineItem(
        title: 'Request Processed',
        timestamp: processedAt,
        description: 'Your withdrawal request has been processed and is being reviewed for approval.',
        status: 'completed',
      ));
    }

    // Approved Status
    if (approvedAt != null) {
      timeline.add(_buildTimelineItem(
        title: 'Request Approved',
        timestamp: approvedAt,
        description: transactionId != null 
            ? 'Your withdrawal request has been approved. Transaction ID: $transactionId'
            : 'Your withdrawal request has been approved.',
        status: 'completed',
      ));
    }

    // Rejected Status
    if (rejectedAt != null) {
      timeline.add(_buildTimelineItem(
        title: 'Request Rejected',
        timestamp: rejectedAt,
        description: note != null 
            ? 'Your withdrawal request has been rejected. Reason: $note'
            : 'Your withdrawal request has been rejected.',
        status: 'rejected',
      ));
    }

    // Pending Status (if not processed yet)
    if (status == 'pending' && processedAt == null) {
      timeline.add(_buildTimelineItem(
        title: 'Under Review',
        timestamp: null,
        description: 'Your withdrawal request is currently under review. Please wait for updates.',
        status: 'pending',
      ));
    }

    return timeline;
  }

  static pw.Widget _buildTimelineItem({
    required String title,
    required DateTime? timestamp,
    required String description,
    required String status,
  }) {
    PdfColor statusColor;
    switch (status) {
      case 'completed':
        statusColor = PdfColors.green;
        break;
      case 'rejected':
        statusColor = PdfColors.red;
        break;
      case 'pending':
        statusColor = PdfColors.orange;
        break;
      default:
        statusColor = PdfColors.grey;
    }

    return pw.Container(
      margin: const pw.EdgeInsets.only(bottom: 15),
      padding: const pw.EdgeInsets.all(12),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: statusColor, width: 1),
        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8)),
        color: PdfColors.grey50,
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Row(
            children: [
              pw.Container(
                width: 8,
                height: 8,
                decoration: pw.BoxDecoration(
                  color: statusColor,
                  shape: pw.BoxShape.circle,
                ),
              ),
              pw.SizedBox(width: 8),
              pw.Text(
                title,
                style: pw.TextStyle(
                  fontWeight: pw.FontWeight.bold,
                  fontSize: 12,
                  color: statusColor,
                ),
              ),
              pw.Spacer(),
              if (timestamp != null)
                pw.Text(
                  timestamp.toLocal().toString().split('.')[0],
                  style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey600),
                ),
            ],
          ),
          pw.SizedBox(height: 8),
          pw.Text(
            description,
            style: const pw.TextStyle(fontSize: 10),
          ),
        ],
      ),
    );
  }
} 
