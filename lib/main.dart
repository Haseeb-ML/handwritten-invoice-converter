import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:printing/printing.dart';
import 'package:widgets_to_image/widgets_to_image.dart';

import 'invoice_model.dart';
import 'api_service.dart';
import 'pdf_generator.dart';
import 'pdf_viewer_screen.dart';
import 'language_selection_screen.dart';
import 'invoices_list_screen.dart';
import 'database_helper.dart';
import 'localization.dart';
import 'settings_screen.dart';

void main() {
  // TODO: Replace with your actual Gemini API key from https://aistudio.google.com/apikey
  ApiService.geminiApiKey = "YOUR_API_KEY_HERE";
  runApp(const ScanInvoiceApp());
}

class AppTheme {
  static final ValueNotifier<ThemeMode> themeMode = ValueNotifier<ThemeMode>(ThemeMode.light);
}

class ScanInvoiceApp extends StatelessWidget {
  const ScanInvoiceApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: AppTheme.themeMode,
      builder: (context, theme, child) {
        return ValueListenableBuilder<String>(
          valueListenable: AppLocalization.currentLanguage,
          builder: (context, language, child) {
            return MaterialApp(
              title: 'Invoice AI',
              debugShowCheckedModeBanner: false,
              themeMode: theme,
              theme: ThemeData(
                primaryColor: const Color(0xFF0C4A4A),
                scaffoldBackgroundColor: const Color(0xFFF9FAFB),
                fontFamily: 'Roboto',
                colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF0C4A4A), brightness: Brightness.light),
              ),
              darkTheme: ThemeData(
                primaryColor: const Color(0xFF0C4A4A),
                scaffoldBackgroundColor: const Color(0xFF121212),
                fontFamily: 'Roboto',
                colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF0C4A4A), brightness: Brightness.dark),
                appBarTheme: const AppBarTheme(backgroundColor: Color(0xFF121212), foregroundColor: Colors.white),
                cardColor: const Color(0xFF1E1E1E),
                bottomNavigationBarTheme: const BottomNavigationBarThemeData(
                  backgroundColor: Color(0xFF1E1E1E),
                  unselectedItemColor: Colors.white54,
                ),
              ),
              home: const LanguageSelectionScreen(),
            );
          },
        );
      },
    );
  }
}

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final ImagePicker _picker = ImagePicker();

  late String _selectedModel = ApiService.preferredModel;
  List<InvoiceModel> _recentInvoices = [];

  @override
  void initState() {
    super.initState();
    _loadRecentInvoices();
  }

  Future<void> _loadRecentInvoices() async {
    final invoices = await DatabaseHelper.instance.getInvoices();
    if (!mounted) return;
    setState(() {
      _recentInvoices = invoices.take(3).toList();
    });
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final XFile? image = await _picker.pickImage(
        source: source,
        imageQuality: 85,
      );
      if (image != null) {
        if (!context.mounted) return;
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => OcrScanScreen(
              imageFile: image,
            ),
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to pick image: $e'),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : Colors.black87;
    final cardColor = isDark ? const Color(0xFF1E1E1E) : Colors.white;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          'InvoiceAI',
          style: TextStyle(color: textColor, fontWeight: FontWeight.bold),
        ),
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: isDark ? Colors.white : const Color(0xFF0C4A4A)),
          onPressed: () {
            Navigator.of(context).pushReplacement(
              MaterialPageRoute(builder: (context) => const LanguageSelectionScreen()),
            );
          },
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(AppLocalization.t('greeting'), style: const TextStyle(fontSize: 16, color: Colors.grey)),
            const SizedBox(height: 4),
            Text(
              AppLocalization.t('ready_to_scan'),
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: textColor),
            ),
            const SizedBox(height: 30),

            // Main Action Card
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: cardColor,
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(color: Colors.black.withOpacity(isDark ? 0.2 : 0.05), blurRadius: 20, offset: const Offset(0, 10)),
                ],
              ),
              child: Column(
                children: [
                  GestureDetector(
                    onTap: () => _pickImage(ImageSource.camera),
                    child: Container(
                      width: 80,
                      height: 80,
                      decoration: const BoxDecoration(
                        color: Color(0xFF075E54),
                        shape: BoxShape.circle,
                        boxShadow: [
                           BoxShadow(color: Color(0x66075E54), blurRadius: 15, offset: Offset(0, 8)),
                        ]
                      ),
                      child: const Icon(Icons.camera_alt_outlined, color: Colors.white, size: 40),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(AppLocalization.t('take_invoice_photo'), style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: textColor)),
                  const SizedBox(height: 4),
                  Text(AppLocalization.t('take_photo_subtitle'), style: const TextStyle(fontSize: 14, color: Color(0xFF075E54), fontWeight: FontWeight.w600)),
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      Expanded(
                        child: _ActionSubButton(
                          icon: Icons.camera_alt_outlined,
                          title: AppLocalization.t('take_invoice_photo'),
                          onTap: () => _pickImage(ImageSource.camera),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: _ActionSubButton(
                          icon: Icons.photo_library_outlined,
                          title: AppLocalization.t('pick_from_gallery'),
                          onTap: () => _pickImage(ImageSource.gallery),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 30),

            // Quick Tips
            Align(
              alignment: Alignment.centerRight,
              child: Text(AppLocalization.t('quick_tips'), style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: textColor)),
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _QuickTipCard(icon: Icons.crop_free, title: AppLocalization.t('whole_invoice')),
                _QuickTipCard(icon: Icons.center_focus_strong_outlined, title: AppLocalization.t('clear_photo')),
                _QuickTipCard(icon: Icons.wb_sunny_outlined, title: AppLocalization.t('good_lighting')),
              ],
            ),
            const SizedBox(height: 30),

            // Recent Activity
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                GestureDetector(
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(builder: (context) => const InvoicesListScreen()),
                    );
                  },
                  child: Text(AppLocalization.t('view_all'), style: const TextStyle(fontSize: 14, color: Color(0xFF075E54), fontWeight: FontWeight.w600)),
                ),
                Text(AppLocalization.t('recent_activity'), style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: textColor)),
              ],
            ),
            const SizedBox(height: 16),
            if (_recentInvoices.isEmpty)
              Center(
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Text(AppLocalization.t('no_recent_activity'), style: const TextStyle(color: Colors.grey)),
                ),
              )
            else
              ..._recentInvoices.map((invoice) {
                return GestureDetector(
                  onTap: () async {
                    if (invoice.imagePath != null && File(invoice.imagePath!).existsSync()) {
                      final bytes = await File(invoice.imagePath!).readAsBytes();
                      if (!context.mounted) return;
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (context) => PdfViewerScreen(
                            invoiceNumber: invoice.invoiceNumber.replaceAll('#', ''),
                            pdfBytes: bytes,
                          ),
                        ),
                      );
                    }
                  },
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: cardColor,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: isDark ? Colors.white10 : const Color(0xFFE5E7EB)),
                      boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 8, offset: const Offset(0, 4))],
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 50,
                          height: 50,
                          decoration: BoxDecoration(color: const Color(0xFFE5E7EB), borderRadius: BorderRadius.circular(8)),
                          child: const Icon(Icons.picture_as_pdf, color: Colors.redAccent),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(invoice.vendorName.isNotEmpty ? invoice.vendorName : AppLocalization.t('unknown_vendor'), style: TextStyle(fontWeight: FontWeight.bold, color: textColor)),
                              const SizedBox(height: 4),
                              Text('${AppLocalization.t('invoice_number')} ${invoice.invoiceNumber}', style: const TextStyle(color: Colors.grey, fontSize: 12)),
                            ],
                          ),
                        ),
                        Text('PKR ${invoice.grandTotal.toStringAsFixed(0)}', style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF0C4A4A))),
                      ],
                    ),
                  ),
                );
              }),
            const SizedBox(height: 40),
          ],
        ),
      ),
      // Custom Bottom Navigation
      bottomNavigationBar: Container(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 20),
        decoration: BoxDecoration(
          color: cardColor,
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(isDark ? 0.3 : 0.05), blurRadius: 10, offset: const Offset(0, -5))],
        ),
        child: SafeArea(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _BottomNavItem(
                icon: Icons.home,
                title: AppLocalization.t('home'),
                isActive: true,
                onTap: () {},
              ),
              _BottomNavItem(
                icon: Icons.receipt_long,
                title: AppLocalization.t('invoices'),
                isActive: false,
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: (context) => const InvoicesListScreen()),
                  );
                },
              ),
              // Center FAB-like button
              Container(
                width: 60,
                height: 60,
                decoration: const BoxDecoration(
                  color: Color(0xFF0C4A4A),
                  shape: BoxShape.circle,
                  boxShadow: [BoxShadow(color: Color(0x66075E54), blurRadius: 10, offset: Offset(0, 5))],
                ),
                child: IconButton(
                  icon: const Icon(Icons.camera_alt, color: Colors.white, size: 28),
                  onPressed: () => _pickImage(ImageSource.camera),
                ),
              ),
              _BottomNavItem(
                icon: Icons.settings,
                title: AppLocalization.t('settings'),
                isActive: false,
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: (context) => const SettingsScreen()),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ActionSubButton extends StatelessWidget {
  final IconData icon;
  final String title;
  final VoidCallback onTap;
  const _ActionSubButton({required this.icon, required this.title, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: const Color(0xFFF3F4F6),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.black12),
        ),
        child: Column(
          children: [
            Icon(icon, color: const Color(0xFF075E54)),
            const SizedBox(height: 8),
            Text(title, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.black87)),
          ],
        ),
      ),
    );
  }
}

class _QuickTipCard extends StatelessWidget {
  final IconData icon;
  final String title;
  const _QuickTipCard({required this.icon, required this.title});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 4),
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.black12),
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: const BoxDecoration(
                color: Color(0xFFE8F0FE),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: Colors.blueAccent, size: 20),
            ),
            const SizedBox(height: 8),
            Text(title, textAlign: TextAlign.center, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.black87)),
          ],
        ),
      ),
    );
  }
}

class _BottomNavItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final bool isActive;
  final VoidCallback onTap;
  const _BottomNavItem({required this.icon, required this.title, required this.isActive, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final color = isActive ? const Color(0xFF075E54) : Colors.black54;
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color),
          const SizedBox(height: 4),
          Text(title, style: TextStyle(fontSize: 12, color: color, fontWeight: isActive ? FontWeight.bold : FontWeight.normal)),
        ],
      ),
    );
  }
}

class OcrScanScreen extends StatefulWidget {
  final XFile? imageFile;

  const OcrScanScreen({
    super.key,
    this.imageFile,
  });

  @override
  State<OcrScanScreen> createState() => _OcrScanScreenState();
}

class _OcrScanScreenState extends State<OcrScanScreen> with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scanAnimation;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat(reverse: true);

    _scanAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(_animationController);

    _startExtraction();
  }

  Future<void> _startExtraction() async {
    setState(() => _errorMessage = null);

    if (widget.imageFile == null) {
      setState(() => _errorMessage = 'No image was provided.');
      return;
    }

    try {
      final extracted = await ApiService.extractInvoice(widget.imageFile!);
      if (!mounted) return;
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (context) => InvoiceEditorScreen(invoice: extracted),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _errorMessage = e.toString());
    }
  }

  void _enterManually() {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (context) => InvoiceEditorScreen(
          invoice: _blankInvoice(),
        ),
      ),
    );
  }

  InvoiceModel _blankInvoice() {
    final today = DateTime.now().toString().substring(0, 10);
    return InvoiceModel(
      vendorName: '',
      vendorAddress: '',
      invoiceTitle: 'رسید / بل',
      invoiceNumber: '',
      date: today,
      dueDate: today,
      clientName: '',
      clientAddress: '',
      taxRate: 0.0,
      discount: 0.0,
      notes: '',
      items: [InvoiceItem(description: '', quantity: 1, unitPrice: 0.0)],
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6F8FA),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF6F8FA),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.translate, color: Color(0xFF0C4A4A)),
          onPressed: () {
            Navigator.of(context).pushReplacement(
              MaterialPageRoute(builder: (context) => const DashboardScreen()),
            );
          },
        ),
        title: const Text(
          'InvoiceAI',
          style: TextStyle(color: Color(0xFF0C4A4A), fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 20.0),
          child: Column(
            children: [
              // Image Container with Center Pulse
              Expanded(
                child: Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 15, offset: const Offset(0, 5)),
                    ],
                  ),
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      if (widget.imageFile != null)
                        ClipRRect(
                          borderRadius: BorderRadius.circular(16),
                          child: kIsWeb
                              ? Image.network(widget.imageFile!.path, fit: BoxFit.cover, width: double.infinity, height: double.infinity)
                              : Image.file(File(widget.imageFile!.path), fit: BoxFit.cover, width: double.infinity, height: double.infinity),
                        ),
                      // Line Scan Animation
                      if (_errorMessage == null)
                        AnimatedBuilder(
                          animation: _scanAnimation,
                          builder: (context, child) {
                            return Align(
                              alignment: Alignment(0, -1 + (_scanAnimation.value * 2)),
                              child: Container(
                                height: 4,
                                width: double.infinity,
                                decoration: const BoxDecoration(
                                  color: Color(0xFF075E54),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Color(0xFF075E54),
                                      blurRadius: 8,
                                      spreadRadius: 2,
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                      // Error overlay
                      if (_errorMessage != null)
                         Container(
                           color: Colors.black54,
                           padding: const EdgeInsets.all(16),
                           alignment: Alignment.center,
                           child: Column(
                             mainAxisSize: MainAxisSize.min,
                             children: [
                               const Icon(Icons.error_outline, color: Colors.redAccent, size: 40),
                               const SizedBox(height: 8),
                               Text(_errorMessage!, style: const TextStyle(color: Colors.white), textAlign: TextAlign.center),
                               const SizedBox(height: 16),
                               Row(
                                 mainAxisAlignment: MainAxisAlignment.center,
                                 children: [
                                    ElevatedButton(onPressed: _startExtraction, child: const Text('Retry')),
                                    const SizedBox(width: 8),
                                    ElevatedButton(onPressed: _enterManually, child: const Text('Enter Manually')),
                                 ]
                               )
                             ]
                           )
                         )
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 40),
              
              // Privacy and Cancel
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: const [
                  Text(
                    'آپ کا ڈیٹا محفوظ اور پرائیویٹ ہے',
                    style: TextStyle(fontSize: 12, color: Colors.black87),
                    textDirection: TextDirection.rtl,
                  ),
                  SizedBox(width: 6),
                  Icon(Icons.lock_outline, size: 14, color: Colors.black87),
                ],
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: () {
                    Navigator.of(context).pushReplacement(
                      MaterialPageRoute(builder: (context) => const DashboardScreen()),
                    );
                  },
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    side: const BorderSide(color: Colors.redAccent, width: 1.5),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text(
                    'کینسل (Cancel)',
                    style: TextStyle(color: Colors.redAccent, fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class InvoiceEditorScreen extends StatefulWidget {
  final InvoiceModel invoice;

  const InvoiceEditorScreen({super.key, required this.invoice});

  @override
  State<InvoiceEditorScreen> createState() => _InvoiceEditorScreenState();
}

class _InvoiceEditorScreenState extends State<InvoiceEditorScreen> {
  late InvoiceModel _editableInvoice;
  final WidgetsToImageController _imageController = WidgetsToImageController();

  final _vendorNameController = TextEditingController();
  final _vendorAddressController = TextEditingController();
  final _invoiceTitleController = TextEditingController();
  final _invoiceNumController = TextEditingController();
  final _dateController = TextEditingController();
  final _dueDateController = TextEditingController();
  final _clientNameController = TextEditingController();
  final _clientAddressController = TextEditingController();
  final _notesController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _editableInvoice = widget.invoice;
    _editableInvoice.taxRate = 0.0;
    _editableInvoice.discount = 0.0;
    _populateControllers();
  }

  void _populateControllers() {
    _vendorNameController.text = _editableInvoice.vendorName;
    _vendorAddressController.text = _editableInvoice.vendorAddress;
    _invoiceTitleController.text = _editableInvoice.invoiceTitle;
    _invoiceNumController.text = _editableInvoice.invoiceNumber;
    _dateController.text = _editableInvoice.date;
    _dueDateController.text = _editableInvoice.dueDate;
    _clientNameController.text = _editableInvoice.clientName;
    _clientAddressController.text = _editableInvoice.clientAddress;
    _notesController.text = _editableInvoice.notes;
  }

  @override
  void dispose() {
    _vendorNameController.dispose();
    _vendorAddressController.dispose();
    _invoiceTitleController.dispose();
    _invoiceNumController.dispose();
    _dateController.dispose();
    _dueDateController.dispose();
    _clientNameController.dispose();
    _clientAddressController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  void _recalculate() {
    setState(() {
      _editableInvoice.vendorName = _vendorNameController.text;
      _editableInvoice.vendorAddress = _vendorAddressController.text;
      _editableInvoice.invoiceTitle = _invoiceTitleController.text;
      _editableInvoice.invoiceNumber = _invoiceNumController.text;
      _editableInvoice.date = _dateController.text;
      _editableInvoice.dueDate = _dueDateController.text;
      _editableInvoice.clientName = _clientNameController.text;
      _editableInvoice.clientAddress = _clientAddressController.text;
      _editableInvoice.taxRate = 0.0;
      _editableInvoice.discount = 0.0;
      _editableInvoice.notes = _notesController.text;
    });
  }

  void _deleteItem(int index) {
    setState(() {
      _editableInvoice.items.removeAt(index);
      if (_editableInvoice.items.isEmpty) {
        _editableInvoice.items.add(
          InvoiceItem(description: '', quantity: 1, unitPrice: 0.0, serialNumber: '1'),
        );
      }
    });
  }

  Future<Uint8List> _generatePdfBytes() async {
    await WidgetsBinding.instance.endOfFrame;
    final imageBytes = await _imageController.capture();
    if (imageBytes == null) throw Exception("Failed to render receipt image");
    return PdfGenerator.generateInvoicePdfFromBytes(imageBytes);
  }

  Widget buildCalcRow(String label, String value, bool isUrdu) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(color: isUrdu ? const Color(0x990C2461) : const Color(0xFF9CA3AF)),
        ),
        Text(
          value,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: isUrdu ? const Color(0xFF0C2461) : Colors.white,
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6F8FA),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF6F8FA),
        elevation: 0,
        leadingWidth: 56,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF0C4A4A)),
          onPressed: () {
            Navigator.of(context).pushReplacement(
              MaterialPageRoute(builder: (context) => const DashboardScreen()),
            );
          },
        ),
        title: Text(AppLocalization.t('edit_invoice'), style: const TextStyle(color: Color(0xFF0C4A4A), fontWeight: FontWeight.bold)),
        centerTitle: true,
        actions: const [
          SizedBox(width: 8),
        ],
      ),
      body: Stack(
        children: [
          // Offscreen blueprint for capturing pixel-perfect PDF images
          Positioned(
            left: -5000,
            top: 0,
            child: IgnorePointer(
              child: ExcludeSemantics(
                child: ReceiptSnapshotLayout(
                  invoice: _editableInvoice,
                  controller: _imageController,
                ),
              ),
            ),
          ),

          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
              child: Column(
                children: [
                  // Badges Row
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: const Color(0xFFE6F4EA),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.check_circle_outline, color: Color(0xFF137333), size: 14),
                            const SizedBox(width: 4),
                            Text('98% Accurate', style: const TextStyle(color: Color(0xFF137333), fontSize: 12, fontWeight: FontWeight.bold)),
                          ],
                        ),
                      ),
                      Row(
                        children: [
                          Text(AppLocalization.t('editing_mode'), style: const TextStyle(color: Colors.black54, fontSize: 12)),
                          const SizedBox(width: 8),
                          Switch(
                            value: true,
                            onChanged: (val) {},
                            activeColor: Colors.white,
                            activeTrackColor: const Color(0xFF0C4A4A),
                          ),
                        ],
                      )
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Main Card
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4)),
                      ],
                      border: Border.all(color: const Color(0xFFE5E7EB)),
                    ),
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Customer Name
                        Text(AppLocalization.t('vendor_name'), style: const TextStyle(fontSize: 12, color: Colors.black87), textDirection: TextDirection.rtl),
                        const SizedBox(height: 6),
                        Container(
                          decoration: BoxDecoration(
                            color: const Color(0xFFF3F4F6),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: TextField(
                            controller: _clientNameController,
                            style: const TextStyle(color: Colors.black87),
                            onChanged: (_) => _recalculate(),
                            textAlign: TextAlign.left,
                            decoration: const InputDecoration(
                              filled: false,
                              border: InputBorder.none,
                              contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                              suffixIcon: Icon(Icons.edit, color: Colors.black26, size: 20),
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Invoice Number
                        Text(AppLocalization.t('invoice_number'), style: const TextStyle(fontSize: 12, color: Colors.black87), textDirection: TextDirection.rtl),
                        const SizedBox(height: 6),
                        Container(
                          decoration: BoxDecoration(
                            color: const Color(0xFFF3F4F6),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: TextField(
                            controller: _invoiceNumController,
                            style: const TextStyle(color: Colors.black87),
                            onChanged: (_) => _recalculate(),
                            textAlign: TextAlign.left,
                            decoration: const InputDecoration(
                              filled: false,
                              border: InputBorder.none,
                              contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                              suffixIcon: Icon(Icons.edit, color: Colors.black26, size: 20),
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Date
                        const Text('Date / تاریخ', style: TextStyle(fontSize: 12, color: Colors.black87), textDirection: TextDirection.rtl),
                        const SizedBox(height: 6),
                        Container(
                          decoration: BoxDecoration(
                            color: const Color(0xFFF3F4F6),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: TextField(
                            controller: _dateController,
                            style: const TextStyle(color: Colors.black87),
                            onChanged: (_) => _recalculate(),
                            textAlign: TextAlign.left,
                            decoration: const InputDecoration(
                              filled: false,
                              border: InputBorder.none,
                              contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                              suffixIcon: Icon(Icons.calendar_today_outlined, color: Colors.black26, size: 20),
                            ),
                          ),
                        ),
                        const SizedBox(height: 24),

                        // Table Header
                        Row(
                          children: [
                            Expanded(flex: 3, child: Text(AppLocalization.t('item_name'), style: const TextStyle(fontSize: 12, color: Colors.black54, fontWeight: FontWeight.bold))),
                            Expanded(flex: 1, child: Text(AppLocalization.t('qty'), style: const TextStyle(fontSize: 12, color: Colors.black54, fontWeight: FontWeight.bold))),
                            Expanded(flex: 2, child: Text(AppLocalization.t('price'), style: const TextStyle(fontSize: 12, color: Colors.black54, fontWeight: FontWeight.bold), textAlign: TextAlign.right)),
                            Expanded(flex: 2, child: Text(AppLocalization.t('total'), style: const TextStyle(fontSize: 12, color: Colors.black54, fontWeight: FontWeight.bold), textAlign: TextAlign.right)),
                          ],
                        ),
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 8),
                          child: Divider(color: Color(0xFFE5E7EB)),
                        ),

                        // Items List
                        ListView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: _editableInvoice.items.length,
                          itemBuilder: (context, index) {
                            final item = _editableInvoice.items[index];
                            return Padding(
                              padding: const EdgeInsets.symmetric(vertical: 8.0),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  // Item Name
                                  Expanded(
                                    flex: 3,
                                    child: TextFormField(
                                      initialValue: item.description,
                                      onChanged: (val) {
                                        item.description = val;
                                        _recalculate();
                                      },
                                      style: const TextStyle(fontSize: 13, color: Colors.black87),
                                      decoration: const InputDecoration(filled: false, border: InputBorder.none, isDense: true, contentPadding: EdgeInsets.zero),
                                    ),
                                  ),
                                  // Qty
                                  Expanded(
                                    flex: 1,
                                    child: TextFormField(
                                      initialValue: item.quantity.toString(),
                                      textAlign: TextAlign.center,
                                      keyboardType: TextInputType.number,
                                      onChanged: (val) {
                                        item.quantity = int.tryParse(val) ?? 1;
                                        _recalculate();
                                      },
                                      style: const TextStyle(fontSize: 13, color: Colors.black87),
                                      decoration: const InputDecoration(filled: false, border: InputBorder.none, isDense: true, contentPadding: EdgeInsets.zero),
                                    ),
                                  ),
                                  // Price
                                  Expanded(
                                    flex: 2,
                                    child: TextFormField(
                                      initialValue: item.unitPrice.toStringAsFixed(0),
                                      textAlign: TextAlign.right,
                                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                      onChanged: (val) {
                                        item.unitPrice = double.tryParse(val) ?? 0.0;
                                        _recalculate();
                                      },
                                      style: const TextStyle(fontSize: 13, color: Colors.black87),
                                      decoration: const InputDecoration(filled: false, border: InputBorder.none, isDense: true, contentPadding: EdgeInsets.zero),
                                    ),
                                  ),
                                  // Total
                                  Expanded(
                                    flex: 2,
                                    child: Text(
                                      item.total.toStringAsFixed(0),
                                      textAlign: TextAlign.right,
                                      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.black87),
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                        
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 16),
                          child: Divider(color: Color(0xFFC7D2FE), thickness: 1.5),
                        ),

                        // Summary
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('Subtotal:', style: TextStyle(fontSize: 14, color: Colors.black54)),
                            Text(_editableInvoice.items.fold(0.0, (sum, i) => sum + i.total).toStringAsFixed(0), style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.black87)),
                          ],
                        ),
                        const SizedBox(height: 20),
                        const Divider(color: Color(0xFFE5E7EB)),
                        const SizedBox(height: 12),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(AppLocalization.t('grand_total'), style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black87), textDirection: TextDirection.rtl),
                            Text('PKR ${_editableInvoice.grandTotal.toStringAsFixed(0)}', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF0C4A4A))),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Bottom Buttons
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () async {
                        try {
                          // 1. Generate PDF
                          final pdfBytes = await _generatePdfBytes();
                          
                          // 2. Save PDF to local storage
                          final cleanNum = _editableInvoice.invoiceNumber.replaceAll(RegExp(r'[\u0600-\u06FF\/]'), '').trim();
                          final fileName = '${cleanNum.isNotEmpty ? cleanNum : 'receipt'}_${DateTime.now().millisecondsSinceEpoch}.pdf';
                          
                          Directory docsDir = await getApplicationDocumentsDirectory();
                          final filePath = '${docsDir.path}/$fileName';
                          final file = File(filePath);
                          await file.writeAsBytes(pdfBytes);

                          // 3. Save to SQLite with PDF path
                          _editableInvoice.createdAt = DateTime.now().toIso8601String();
                          _editableInvoice.imagePath = filePath; // Now saving PDF path instead of image
                          await DatabaseHelper.instance.insertInvoice(_editableInvoice);

                          // 4. Navigate to list screen
                          if (!context.mounted) return;
                          Navigator.of(context).pushReplacement(
                            MaterialPageRoute(builder: (context) => const InvoicesListScreen()),
                          );
                        } catch (e) {
                          if (!context.mounted) return;
                          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF0C4A4A),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(AppLocalization.t('next_export'), style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white), textDirection: TextDirection.rtl),
                          const SizedBox(width: 8),
                          const Icon(Icons.arrow_forward, color: Colors.white),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton(
                      onPressed: () {
                        Navigator.of(context).pushReplacement(
                          MaterialPageRoute(builder: (context) => const DashboardScreen()),
                        );
                      },
                      style: OutlinedButton.styleFrom(
                        backgroundColor: const Color(0xFFEBF0FF),
                        side: const BorderSide(color: Colors.transparent),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.camera_alt_outlined, color: Colors.black87),
                          const SizedBox(width: 8),
                          Text(AppLocalization.t('retake_photo'), style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black87), textDirection: TextDirection.rtl),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class LinedPaperPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final linePaint = Paint()
      ..color = const Color(0x220C2461)
      ..strokeWidth = 1.0;

    double y = 48.0;
    while (y < size.height) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), linePaint);
      y += 42.0;
    }

    final marginPaint = Paint()
      ..color = const Color(0x44FF0000)
      ..strokeWidth = 1.5;
    canvas.drawLine(const Offset(68, 0), Offset(68, size.height), marginPaint);
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}