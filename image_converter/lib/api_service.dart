import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'invoice_model.dart';

class ApiService {
  // Configurable backend URL. Replace with your actual server IP or Domain.
  // E.g., "http://192.168.1.100:8000/api/extract-invoice"
  static String backendUrl = "https://api.scanner-invoice-ocr.com/api/extract";

  // If set, direct calls will be routed to Google Gemini Multimodal model
  static String? geminiApiKey;

  // Which Gemini model the user has chosen via the toggle buttons in the app.
  // Defaults to Gemini 1.5 Pro as it is much more capable for Urdu handwriting.
  static String preferredModel = geminiModel15Pro;

  // Model IDs. Kept as constants so the UI toggle and the API calls always
  // agree on the exact string Google expects.
  static const String geminiModel15Pro = 'gemini-3.6-flash';
  static const String geminiModel36Flash = 'gemini-3.5-flash';
  static const String geminiModel35FlashLite = 'gemini-3.5-flash-lite';

  // Used internally as the automatic fallback when the preferred model's
  // free-tier quota (429) is exhausted.
  static const String _fallbackModel = geminiModel36Flash;

  /// Sends the captured image file to the OCR extraction endpoint.
  /// If the server is offline or not configured, it throws an exception
  /// allowing the caller to decide whether to fall back to simulated offline OCR.
  static Future<InvoiceModel> extractInvoice(XFile imageFile) async {
    // If Gemini API Key is configured, we can extract details directly via Gemini API
    if (geminiApiKey != null && geminiApiKey!.isNotEmpty) {
      return await _extractViaGemini(imageFile);
    }

    final uri = Uri.parse(backendUrl);
    final request = http.MultipartRequest('POST', uri);

    // Attach image using bytes to support Web blob URLs
    final bytes = await imageFile.readAsBytes();
    final file = http.MultipartFile.fromBytes(
      'image',
      bytes,
      filename: imageFile.name.isNotEmpty ? imageFile.name : 'invoice.jpg',
    );
    request.files.add(file);

    // Optional metadata headers
    request.headers.addAll({
      'Accept': 'application/json',
    });

    final streamedResponse = await request.send().timeout(
          const Duration(seconds: 15),
        );
    final response = await http.Response.fromStream(streamedResponse);

    if (response.statusCode == 200) {
      final Map<String, dynamic> data = json.decode(response.body);
      return _parseJsonToInvoice(data);
    } else {
      throw Exception(
        'Server returned status: ${response.statusCode}. Details: ${response.body}',
      );
    }
  }

  /// Helper to convert backend JSON format into our Flutter InvoiceModel structure.
  static InvoiceModel _parseJsonToInvoice(Map<String, dynamic> json) {
    final vendor = json['vendor'] ?? {};
    final client = json['client'] ?? {};
    final metadata = json['metadata'] ?? {};
    final summary = json['summary'] ?? {};
    
    final List<dynamic> itemsList = json['items'] ?? [];
    final List<InvoiceItem> parsedItems = itemsList.map((item) {
      return InvoiceItem(
        description: item['description'] ?? 'Scanned Item',
        quantity: item['quantity'] ?? 1,
        unitPrice: (item['unitPrice'] ?? 0).toDouble(),
        serialNumber: _fallbackIfBlank(item['serialNumber'], ''),
      );
    }).toList();

    return InvoiceModel(
      vendorName: vendor['name'] ?? 'AI Extracted Store',
      vendorAddress: vendor['address'] ?? '',
      invoiceTitle: metadata['title'] ?? 'INVOICE',
      invoiceNumber: metadata['invoiceNumber'] ?? 'EXT-${DateTime.now().millisecondsSinceEpoch.toString().substring(8)}',
      date: _fallbackIfBlank(metadata['date'], DateTime.now().toString().substring(0, 10)),
      dueDate: _fallbackIfBlank(metadata['dueDate'], DateTime.now().add(const Duration(days: 7)).toString().substring(0, 10)),
      clientName: client['name'] ?? 'Valued Customer',
      clientAddress: client['address'] ?? '',
      items: parsedItems.isNotEmpty ? parsedItems : [InvoiceItem(description: 'Scanned Item', quantity: 1, unitPrice: 0.0)],
      taxRate: (summary['taxRate'] ?? 10.0).toDouble(),
      discount: (summary['discount'] ?? 0.0).toDouble(),
      notes: json['notes'] ?? 'Scanned by ScanInvoice AI Pro.',
    );
  }

  /// Returns [value] as-is (preserving whatever format the bill used) unless it's
  /// null or blank, in which case [fallback] is used.
  static String _fallbackIfBlank(dynamic value, String fallback) {
    if (value == null) return fallback;
    final text = value.toString().trim();
    return text.isEmpty ? fallback : text;
  }

  /// Multimodal Gemini extraction directly from client (Optional implementation)
  ///
  /// Tries [preferredModel] first (whichever the user picked via the toggle
  /// buttons — 3.6 Flash by default). If that model's free-tier quota is
  /// exhausted (HTTP 429, after our one retry-with-delay already failed),
  /// and the preferred model isn't already the fallback, we automatically
  /// retry the whole request once more against Gemini 3.5 Flash-Lite so the
  /// scan doesn't just fail on the user.
  static Future<InvoiceModel> _extractViaGemini(XFile imageFile) async {
    final imageBytes = await imageFile.readAsBytes();
    final base64Image = base64Encode(imageBytes);

    try {
      return await _callGeminiModel(preferredModel, base64Image);
    } on _GeminiQuotaExhausted {
      if (preferredModel == _fallbackModel) {
        rethrow;
      }
      // Preferred model (3.6 Flash) is rate-limited — fall back automatically.
      return await _callGeminiModel(_fallbackModel, base64Image);
    }
  }

  /// Calls a specific Gemini model by [modelId] with the given image and
  /// returns the parsed invoice. Throws [_GeminiQuotaExhausted] specifically
  /// when the model's quota is used up, so the caller can decide to fall
  /// back to a different model.
  static Future<InvoiceModel> _callGeminiModel(String modelId, String base64Image) async {
    final url = 'https://generativelanguage.googleapis.com/v1beta/models/$modelId:generateContent?key=$geminiApiKey';

    final systemInstruction = "You are a professional receipt and invoice scanner. Extract all details from the receipt image. "
        "Return the details in JSON matching this exact structure: "
        "{"
        "  'thought_process': 'string (First, analyze the image line by line. Identify the vendor, date, and each item row with its serial, qty, and price. Write your transcription and reasoning here in detail before outputting the fields)',"
        "  'vendor': {'name': 'string', 'address': 'string'},"
        "  'metadata': {'title': 'string', 'invoiceNumber': 'string', 'date': 'string', 'dueDate': 'string'},"
        "  'client': {'name': 'string', 'address': 'string'},"
        "  'items': [{'description': 'string', 'quantity': number, 'unitPrice': number, 'serialNumber': 'string'}],"
        "  'summary': {'taxRate': number, 'discount': number},"
        "  'notes': 'string'"
        "}"
        "For the 'date' and 'dueDate' fields: copy the date EXACTLY as it is printed/written on the receipt, in its original format "
        "(e.g. if the bill shows '29/07/2026', '29-07-2026', '29 Jul 2026', or in Urdu digits, return it exactly like that). "
        "Do NOT reformat, reorder, or convert it to YYYY-MM-DD or any other standard format. If no due date is printed, leave dueDate the same as date. "
        "If no date is visible at all, return an empty string for that field. "
        "For Urdu handwritten text, translate/transliterate items to English or keep Urdu text (e.g. 'بریک شو (Break Shoe)') so they can be read. Extract prices exactly. "
        "For 'serialNumber': if the receipt has a serial/row/S.No. column or a number written next to that specific item, copy that "
        "number or text exactly as written. If no such number is visible for that item, return an empty string for it — never invent, "
        "guess, or auto-count a serial number that isn't actually printed or handwritten on the receipt. "
        "CRITICAL: Do NOT confuse the serial number (S.No.) with the quantity! In Urdu/RTL invoices, the right-most column is often the serial number (شماره), followed by description (تفصیل), then quantity (تعداد) or weight. "
        "A serial number (like 1, 2, 3 in order at the start of a row) is just the row index and MUST go in 'serialNumber', NEVER in 'quantity'. "
        "The 'quantity' is how many items were bought. If the quantity is not explicitly written, default to 1. If you see sequential numbers (1, 2, 3, 4) down a column, they are serial numbers, not quantities.";

    final payload = {
      "contents": [
        {
          "parts": [
            {"text": "Extract all fields from this invoice or receipt image accurately. Remember to fill the 'thought_process' first to transcribe the messy handwriting line-by-line before mapping to fields. Respond ONLY with valid JSON raw text. Do not wrap in markdown code blocks."},
            {
              "inlineData": {
                "mimeType": "image/jpeg",
                "data": base64Image
              }
            }
          ]
        }
      ],
      "systemInstruction": {
        "parts": [
          {"text": systemInstruction}
        ]
      },
      "generationConfig": {
        "responseMimeType": "application/json"
      }
    };

    var response = await http.post(
      Uri.parse(url),
      headers: {'Content-Type': 'application/json'},
      body: json.encode(payload),
    );

    // Free-tier quota is easy to hit while testing (10-15 requests/minute).
    // 503 Service Unavailable happens when Gemini servers are overloaded.
    // If we get rate-limited or 503, wait briefly and try once more before giving up.
    if (response.statusCode == 429 || response.statusCode == 503) {
      await Future.delayed(const Duration(seconds: 8));
      response = await http.post(
        Uri.parse(url),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(payload),
      );
    }

    if (response.statusCode == 200) {
      final responseData = json.decode(response.body);
      final String textResponse = responseData['candidates'][0]['content']['parts'][0]['text'];
      final Map<String, dynamic> extractedJson = json.decode(textResponse.trim());
      return _parseJsonToInvoice(extractedJson);
    } else if (response.statusCode == 429) {
      // Quota exhausted for this specific model even after our retry above.
      // The caller (_extractViaGemini) catches this to try the fallback model.
      throw _GeminiQuotaExhausted(modelId);
    } else if (response.statusCode == 503) {
      throw Exception('Gemini servers are currently overloaded (503 Service Unavailable). Please try again in a few minutes.');
    } else {
      throw Exception('Gemini extraction failed ($modelId): ${response.statusCode} - ${response.body}');
    }
  }
}

/// Internal marker exception: this specific model's free-tier quota is used
/// up right now. Distinct from a generic [Exception] so [ApiService] can
/// tell "try a different model" apart from "something is actually broken."
class _GeminiQuotaExhausted implements Exception {
  final String modelId;
  _GeminiQuotaExhausted(this.modelId);

  @override
  String toString() =>
      'Too many scans in a short time on $modelId (free API limit reached). '
      'Please wait about a minute and try again.';
}