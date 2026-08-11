import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:printing/printing.dart';

/// A dedicated, in-app PDF viewer for an invoice.
///
/// Renders the actual generated PDF pages inline using [PdfPreview] instead
/// of handing off to the OS print/share sheet. This makes two things better:
///  1. The person can actually see the finished invoice before sharing it.
///  2. If PDF generation fails or produces something unexpected, the error
///     (or the blank/odd result) shows up right here on screen instead of
///     silently inside a system dialog.
///
/// Takes already-generated [pdfBytes] rather than the raw [InvoiceModel] —
/// building the PDF requires capturing the offscreen receipt widget as an
/// image (for correct Urdu shaping), which only the screen that owns that
/// widget (InvoiceEditorScreen) can do. This screen just previews the result.
class PdfViewerScreen extends StatelessWidget {
  final String invoiceNumber;
  final Uint8List pdfBytes;

  const PdfViewerScreen({
    super.key,
    required this.invoiceNumber,
    required this.pdfBytes,
  });

  @override
  Widget build(BuildContext context) {
    final fileName =
        '${invoiceNumber.isNotEmpty ? invoiceNumber : 'invoice'}.pdf';

    return Scaffold(
      appBar: AppBar(
        title: Text(invoiceNumber.isNotEmpty ? invoiceNumber : 'Invoice PDF'),
      ),
      body: PdfPreview(
        build: (format) async => pdfBytes,
        pdfFileName: fileName,
        allowSharing: true,
        allowPrinting: true,
        canChangePageFormat: false,
        canChangeOrientation: false,
        canDebug: false,
        loadingWidget: const Center(child: CircularProgressIndicator()),
        // If generation throws (e.g. a font failed to download and there
        // was no fallback), show the real error here instead of a blank page.
        onError: (context, error) => Padding(
          padding: const EdgeInsets.all(24.0),
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.error_outline, color: Colors.redAccent, size: 40),
                const SizedBox(height: 12),
                Text(
                  'Failed to render PDF:\n$error',
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.redAccent),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}