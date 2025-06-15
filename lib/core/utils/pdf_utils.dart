import 'dart:io';
import 'package:flutter/services.dart';
import 'package:open_filex/open_filex.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

class PdfUtils {
  static Future<void> generateWithdrawalPdf({
    required int amount,
    required String method,
    String? upiId,
    Map<String, dynamic>? bankDetails,
    required String status,
    required DateTime requestedAt,
    String? withdrawalId,
  }) async {
    final pdf = pw.Document();

    final ByteData bytes = await rootBundle.load('assets/images/logo.jpg');
    final Uint8List list = bytes.buffer.asUint8List();
    final pw.MemoryImage logoImage = pw.MemoryImage(list);

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      // Logo
                      pw.Image(logoImage, width: 70, height: 70),
                      pw.SizedBox(height: 5),
                      pw.Text(
                        'CashSify App',
                        style: pw.TextStyle(fontSize: 20, fontWeight: pw.FontWeight.bold),
                      ),
                      pw.Text(
                        '123 Reward Lane, Digital City, 12345',
                        style: pw.TextStyle(fontSize: 10),
                      ),
                      pw.Text(
                        'contact@cashsify.com | +1 234 567 890',
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
              pw.Text(
                'Withdrawal Details',
                style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold, color: PdfColors.blueGrey800),
              ),
              pw.SizedBox(height: 10),
              pw.Table.fromTextArray(
                headers: ['Detail', 'Value'],
                data: <List<String>>[
                  ['Amount', '$amount Coins'],
                  ['Method', method.toUpperCase()],
                  if (method == 'upi' && upiId != null)
                    ['UPI ID', upiId],
                  if (method == 'bank' && bankDetails != null) ...[
                    ['Account Holder Name', bankDetails['name'] ?? 'N/A'],
                    ['Account Number', bankDetails['account_no'] ?? 'N/A'],
                    ['IFSC Code', bankDetails['ifsc'] ?? 'N/A'],
                  ],
                  ['Status', status.toUpperCase()],
                  ['Requested At', requestedAt.toLocal().toString().split('.')[0]],
                  // Add more details from the schema if available from the backend response
                  // ['Processed At', processedAt?.toLocal().toString().split('.')[0] ?? 'N/A'],
                  // ['Approved At', approvedAt?.toLocal().toString().split('.')[0] ?? 'N/A'],
                  // ['Rejected At', rejectedAt?.toLocal().toString().split('.')[0] ?? 'N/A'],
                  // ['Note', note ?? 'N/A'],
                  // ['Transaction ID', transactionId ?? 'N/A'],
                ],
                border: pw.TableBorder.all(color: PdfColors.grey400),
                headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, color: PdfColors.white),
                headerDecoration: const pw.BoxDecoration(color: PdfColors.blueGrey700),
                cellAlignment: pw.Alignment.centerLeft,
                cellStyle: const pw.TextStyle(fontSize: 10),
                columnWidths: {0: const pw.FixedColumnWidth(100), 1: const pw.FlexColumnWidth(300)},
              ),
              pw.SizedBox(height: 30),
              pw.Text(
                'Note: Coins are virtual rewards within the app and do not have a direct monetary value unless redeemed as per app policy.',
                style: pw.TextStyle(fontSize: 10, font: pw.Font.courier()),
              ),
              pw.Spacer(),
              pw.Divider(thickness: 1),
              pw.SizedBox(height: 10),
              pw.Center(
                child: pw.Text(
                  'Thank you for using CashSify App!',
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

    final output = await getTemporaryDirectory();
    final file = File("${output.path}/withdrawal_summary_${DateTime.now().millisecondsSinceEpoch}.pdf");
    await file.writeAsBytes(await pdf.save());

    await OpenFilex.open(file.path);
  }

  static pw.Widget _buildDetailRow(String label, String value) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 5),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(
            label,
            style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
          ),
          pw.Text(
            value,
          ),
        ],
      ),
    );
  }
} 