import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:widgets_to_image/widgets_to_image.dart';
import 'invoice_model.dart';

class PdfGenerator {
  /// Converts captured PNG image bytes into a PDF page.
  ///
  /// The page is sized to match the captured image's own aspect ratio
  /// (keeping the A4 width) instead of forcing the image into a fixed
  /// standard A4 page. Since [ReceiptSnapshotLayout] now sizes itself to
  /// its actual content (no more fixed-height fake "pages"), the image
  /// height already matches the real receipt height — so the PDF page
  /// fits it exactly, with no leftover blank space and no unnecessary
  /// page breaks.
  static Future<Uint8List> generateInvoicePdfFromBytes(Uint8List imageBytes) async {
    final codec = await ui.instantiateImageCodec(imageBytes);
    final frame = await codec.getNextFrame();
    final imageWidth = frame.image.width.toDouble();
    final imageHeight = frame.image.height.toDouble();

    final doc = pw.Document();
    final pdfImage = pw.MemoryImage(imageBytes);

    final pageWidth = PdfPageFormat.a4.width;
    final pageHeight = pageWidth * (imageHeight / imageWidth);
    final pageFormat = PdfPageFormat(pageWidth, pageHeight, marginAll: 0);

    doc.addPage(
      pw.Page(
        pageFormat: pageFormat,
        margin: pw.EdgeInsets.zero,
        build: (pw.Context context) {
          // Image and page now share the exact same aspect ratio, so fill
          // is safe here — there's nothing to crop or letterbox.
          return pw.Image(pdfImage, fit: pw.BoxFit.fill);
        },
      ),
    );

    return doc.save();
  }
}

/// A clean blueprint for receipt layout used for capturing pixel-perfect image for PDF.
/// This runs offscreen. Sizes itself to its actual content (no fixed page
/// height, no artificial pagination) so the resulting PDF has no wasted
/// blank space and no unnecessary page breaks — however long the item list
/// actually is, this widget (and the PDF page built from it) grows to match.
class ReceiptSnapshotLayout extends StatelessWidget {
  final InvoiceModel invoice;
  final WidgetsToImageController controller;

  const ReceiptSnapshotLayout({
    super.key,
    required this.invoice,
    required this.controller,
  });

  /// Flutter's own text rendering already shapes Arabic/Urdu script correctly
  /// (ligatures, joining forms, RTL order) when it paints Text widgets, so no
  /// extra shaping step is needed here. This just keeps the call site name
  /// around in case per-string cleanup (trimming, normalization) is needed later.
  String fixUrdu(String text) => text;

  @override
  Widget build(BuildContext context) {
    return WidgetsToImage(
      controller: controller,
      child: Container(
        width: 650, // Optimal resolution for crisp print output
        color: Colors.white,
        padding: const EdgeInsets.all(28),
        child: Directionality(
          textDirection: TextDirection.rtl,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Vendor Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        fixUrdu(invoice.vendorName.isNotEmpty ? invoice.vendorName : 'رسید / بل'),
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF0C2461),
                        ),
                      ),
                      if (invoice.vendorAddress.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(
                          fixUrdu(invoice.vendorAddress),
                          style: const TextStyle(fontSize: 12, color: Colors.black87),
                        ),
                      ],
                    ],
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        fixUrdu(invoice.invoiceTitle),
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF0C2461),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(fixUrdu('رسید نمبر: ${invoice.invoiceNumber}'), style: const TextStyle(fontSize: 12, color: Colors.black87)),
                      Text(fixUrdu('تاریخ: ${invoice.date}'), style: const TextStyle(fontSize: 12, color: Colors.black87)),
                    ],
                  ),
                ],
              ),
              const Divider(height: 30, thickness: 1.5, color: Color(0xFF0C2461)),

              // Table Header
              Container(
                color: const Color(0xFFEBE9DF),
                padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                child: Row(
                  children: [
                    Expanded(flex: 5, child: Text(fixUrdu('تفصیل (Items)'), style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF0C2461)))),
                    Expanded(flex: 2, child: Text(fixUrdu('رقم (Amount)'), textAlign: TextAlign.right, style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF0C2461)))),
                  ],
                ),
              ),

              // Table Body Items — plain Column since the parent now sizes
              // to content (no bounded height, so no Expanded/ListView needed).
              Column(
                children: invoice.items.asMap().entries.map((entry) {
                  final item = entry.value;
                  final displayNumber = item.serialNumber.trim().isNotEmpty
                      ? item.serialNumber.trim()
                      : '${entry.key + 1}';

                  return Container(
                    padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                    decoration: const BoxDecoration(
                      border: Border(bottom: BorderSide(color: Colors.black12)),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          flex: 5,
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                width: 22,
                                height: 22,
                                margin: const EdgeInsets.only(left: 6),
                                alignment: Alignment.center,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  border: Border.all(color: const Color(0xFF0C2461), width: 1.1),
                                ),
                                child: Text(
                                  fixUrdu(displayNumber),
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(fontSize: 10, color: Colors.black),
                                ),
                              ),
                              Expanded(
                                child: Text(
                                  fixUrdu(item.description),
                                  style: const TextStyle(fontSize: 13, color: Colors.black),
                                ),
                              ),
                            ],
                          ),
                        ),
                        Expanded(
                          flex: 2,
                          child: Text(
                            fixUrdu('Rs ${item.total.toStringAsFixed(0)}'),
                            textAlign: TextAlign.right,
                            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.black),
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ),

              // Footer — always shown once, right after the last item.
              const SizedBox(height: 20),
              Align(
                alignment: Alignment.centerLeft,
                child: Container(
                  width: 250,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF9F7F1),
                    border: Border.all(color: const Color(0xFF0C2461)),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(fixUrdu('سب ٹوٹل:'), style: const TextStyle(fontSize: 12, color: Colors.black)),
                          Text(fixUrdu('Rs ${invoice.subtotal.toStringAsFixed(0)}'), style: const TextStyle(fontSize: 12, color: Colors.black)),
                        ],
                      ),
                      if (invoice.taxAmount > 0) ...[
                        const SizedBox(height: 4),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(fixUrdu('ٹیکس (${invoice.taxRate}%):'), style: const TextStyle(fontSize: 12, color: Colors.black)),
                            Text(fixUrdu('Rs ${invoice.taxAmount.toStringAsFixed(0)}'), style: const TextStyle(fontSize: 12, color: Colors.black)),
                          ],
                        ),
                      ],
                      if (invoice.discount > 0) ...[
                        const SizedBox(height: 4),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(fixUrdu('ڈسکاؤنٹ:'), style: const TextStyle(fontSize: 12, color: Colors.black)),
                            Text(fixUrdu('- Rs ${invoice.discount.toStringAsFixed(0)}'), style: const TextStyle(fontSize: 12, color: Colors.black)),
                          ],
                        ),
                      ],
                      const Divider(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(fixUrdu('مجموعی بل:'), style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Color(0xFF0C2461))),
                          Text(fixUrdu('Rs ${invoice.grandTotal.toStringAsFixed(0)}'), style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Color(0xFF0C2461))),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              if (invoice.notes.isNotEmpty) ...[
                const SizedBox(height: 16),
                Text(fixUrdu('نوٹ: ${invoice.notes}'), style: const TextStyle(fontSize: 11, fontStyle: FontStyle.italic, color: Colors.black87)),
              ],
            ],
          ),
        ),
      ),
    );
  }
}