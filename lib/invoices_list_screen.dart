import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'main.dart';
import 'database_helper.dart';
import 'invoice_model.dart';
import 'localization.dart';
import 'pdf_viewer_screen.dart';
import 'settings_screen.dart';

class InvoicesListScreen extends StatefulWidget {
  const InvoicesListScreen({super.key});

  @override
  State<InvoicesListScreen> createState() => _InvoicesListScreenState();
}

class _InvoicesListScreenState extends State<InvoicesListScreen> {
  int _selectedIndex = 1;
  List<InvoiceModel> _allInvoices = [];
  bool _isLoading = true;
  String _selectedFilter = 'All';

  @override
  void initState() {
    super.initState();
    _loadInvoices();
  }

  Future<void> _loadInvoices() async {
    final invoices = await DatabaseHelper.instance.getInvoices();
    setState(() {
      _allInvoices = invoices;
      _isLoading = false;
    });
  }

  Future<void> _deleteInvoice(InvoiceModel invoice) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Invoice?'),
        content: const Text('Are you sure you want to delete this invoice?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Delete', style: TextStyle(color: Colors.red))),
        ],
      ),
    );

    if (confirm == true && invoice.id != null) {
      await DatabaseHelper.instance.deleteInvoice(invoice.id!);
      _loadInvoices();
    }
  }

  String _formatDateToGroup(String isoDate) {
    if (isoDate.isEmpty) return 'Earlier';
    try {
      final date = DateTime.parse(isoDate);
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      final yesterday = today.subtract(const Duration(days: 1));
      final dateToCheck = DateTime(date.year, date.month, date.day);

      if (dateToCheck == today) {
        return AppLocalization.t('today');
      } else if (dateToCheck == yesterday) {
        return 'Yesterday'; // Can be added to translation later if needed
      } else {
        return DateFormat('MMM dd, yyyy').format(date);
      }
    } catch (e) {
      return 'Earlier';
    }
  }

  @override
  Widget build(BuildContext context) {
    // Filter invoices based on selected filter
    List<InvoiceModel> filteredInvoices = _allInvoices;
    final now = DateTime.now();
    
    if (_selectedFilter == 'Today') {
      filteredInvoices = _allInvoices.where((i) {
        if (i.createdAt == null) return false;
        try {
          final d = DateTime.parse(i.createdAt!);
          return d.year == now.year && d.month == now.month && d.day == now.day;
        } catch (_) { return false; }
      }).toList();
    } else if (_selectedFilter == 'This Week') {
      filteredInvoices = _allInvoices.where((i) {
        if (i.createdAt == null) return false;
        try {
          final d = DateTime.parse(i.createdAt!);
          return now.difference(d).inDays <= 7;
        } catch (_) { return false; }
      }).toList();
    }

    // Group invoices
    final Map<String, List<InvoiceModel>> groupedInvoices = {};
    for (var invoice in filteredInvoices) {
      final group = _formatDateToGroup(invoice.createdAt ?? '');
      if (!groupedInvoices.containsKey(group)) {
        groupedInvoices[group] = [];
      }
      groupedInvoices[group]!.add(invoice);
    }

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : Colors.black87;
    final cardColor = isDark ? const Color(0xFF1E1E1E) : Colors.white;
    final borderColor = isDark ? Colors.white10 : const Color(0xFFE5E7EB);

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        title: Text(
          AppLocalization.t('invoices'),
          style: TextStyle(color: textColor, fontWeight: FontWeight.bold),
        ),
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: isDark ? Colors.white : const Color(0xFF0C4A4A)),
          onPressed: () {
            if (Navigator.canPop(context)) {
              Navigator.pop(context);
            } else {
              SystemNavigator.pop();
            }
          },
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Search Bar
                  Container(
                    decoration: BoxDecoration(
                      color: cardColor,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(color: Colors.black.withOpacity(isDark ? 0.2 : 0.02), blurRadius: 10, offset: const Offset(0, 4)),
                      ],
                      border: Border.all(color: borderColor),
                    ),
                    child: TextField(
                      style: TextStyle(color: textColor),
                      decoration: InputDecoration(
                        hintText: AppLocalization.t('search_hint'),
                        hintStyle: const TextStyle(color: Colors.grey),
                        prefixIcon: const Icon(Icons.search, color: Colors.grey),
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Filter Chips (3 Buttons, Equal Width)
                  Row(
                    children: [
                      Expanded(child: _buildFilterChip(context, AppLocalization.t('all'), isSelected: _selectedFilter == 'All')),
                      const SizedBox(width: 8),
                      Expanded(child: _buildFilterChip(context, AppLocalization.t('today'), isSelected: _selectedFilter == 'Today')),
                      const SizedBox(width: 8),
                      Expanded(child: _buildFilterChip(context, AppLocalization.t('this_week'), isSelected: _selectedFilter == 'This Week')),
                    ],
                  ),
                  const SizedBox(height: 28),

                  if (_allInvoices.isEmpty)
                    Center(
                      child: Padding(
                        padding: const EdgeInsets.only(top: 40.0),
                        child: Text(
                          AppLocalization.t('no_invoices_found'),
                          style: const TextStyle(color: Colors.grey, fontSize: 16),
                        ),
                      ),
                    ),

                  // Grouped List
                  ...groupedInvoices.entries.map((entry) {
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          entry.key,
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: textColor,
                          ),
                        ),
                        const SizedBox(height: 12),
                        ...entry.value.map((invoice) {
                          String time = '';
                          try {
                            if (invoice.createdAt != null) {
                              time = DateFormat('HH:mm').format(DateTime.parse(invoice.createdAt!));
                            }
                          } catch (_) {}

                          return Padding(
                            padding: const EdgeInsets.only(bottom: 12.0),
                            child: _buildInvoiceCard(
                              context: context,
                              title: invoice.vendorName.isNotEmpty ? invoice.vendorName : AppLocalization.t('unknown_vendor'),
                              id: invoice.invoiceNumber.isNotEmpty ? '${AppLocalization.t('invoice_number')} ${invoice.invoiceNumber}' : '${AppLocalization.t('invoice_number')} --',
                              time: time,
                              itemsCount: '${invoice.items.length}',
                              amount: 'PKR ${invoice.grandTotal.toStringAsFixed(0)}',
                              isProcessed: true,
                              imagePath: invoice.imagePath,
                              onDelete: () => _deleteInvoice(invoice),
                            ),
                          );
                        }).toList(),
                        const SizedBox(height: 16),
                      ],
                    );
                  }).toList(),

                  const SizedBox(height: 80),
                ],
              ),
            ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: cardColor,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(isDark ? 0.3 : 0.05),
              blurRadius: 10,
              offset: const Offset(0, -5),
            ),
          ],
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildNavItem(Icons.home_outlined, AppLocalization.t('home'), false, () {
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: (context) => const DashboardScreen()),
                  );
                }),
                _buildNavItem(Icons.receipt_long, AppLocalization.t('invoices'), true, () {}),
                // Center Camera Button
                Container(
                  margin: const EdgeInsets.only(bottom: 10),
                  width: 56,
                  height: 56,
                  decoration: const BoxDecoration(
                    color: Color(0xFF075E54),
                    shape: BoxShape.circle,
                    boxShadow: [BoxShadow(color: Color(0x66075E54), blurRadius: 10, offset: Offset(0, 5))],
                  ),
                  child: IconButton(
                    icon: const Icon(Icons.camera_alt, color: Colors.white),
                    onPressed: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(builder: (context) => const DashboardScreen()),
                      );
                    },
                  ),
                ),
                _buildNavItem(Icons.settings_outlined, AppLocalization.t('settings'), false, () {
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: (context) => const SettingsScreen()),
                  );
                }),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFilterChip(BuildContext context, String label, {bool isSelected = false}) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    String filterValue = 'All';
    if (label == AppLocalization.t('today')) filterValue = 'Today';
    if (label == AppLocalization.t('this_week')) filterValue = 'This Week';

    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedFilter = filterValue;
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF107065) : (isDark ? const Color(0xFF2A2A2A) : const Color(0xFFEBF0FF)),
          borderRadius: BorderRadius.circular(24),
        ),
        child: Text(
          label,
          textAlign: TextAlign.center,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            color: isSelected ? Colors.white : (isDark ? Colors.white70 : const Color(0xFF4B5563)),
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
            fontSize: 13,
          ),
        ),
      ),
    );
  }

  Widget _buildInvoiceCard({
    required BuildContext context,
    required String title,
    required String id,
    required String time,
    required String itemsCount,
    required String amount,
    required bool isProcessed,
    String? imagePath,
    VoidCallback? onDelete,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardColor = isDark ? const Color(0xFF1E1E1E) : Colors.white;
    final borderColor = isDark ? Colors.white10 : const Color(0xFFE5E7EB);
    
    return GestureDetector(
      onTap: () async {
        if (imagePath != null && File(imagePath).existsSync()) {
          final bytes = await File(imagePath).readAsBytes();
          if (!context.mounted) return;
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => PdfViewerScreen(
                invoiceNumber: id.replaceAll('#', ''),
                pdfBytes: bytes,
              ),
            ),
          );
        }
      },
      child: Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: borderColor),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.2 : 0.02),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: const Color(0xFFE5E7EB),
              borderRadius: BorderRadius.circular(8),
            ),
            clipBehavior: Clip.hardEdge,
            child: imagePath != null && imagePath.toLowerCase().endsWith('.pdf')
                ? const Icon(Icons.picture_as_pdf, color: Colors.redAccent, size: 30)
                : imagePath != null && File(imagePath).existsSync()
                    ? Image.file(File(imagePath), fit: BoxFit.cover)
                    : const Icon(Icons.receipt_long, color: Colors.grey),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Text(
                        '$title\n$id',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: isDark ? Colors.white : const Color(0xFF111827),
                          height: 1.3,
                        ),
                      ),
                    ),
                    if (onDelete != null)
                      IconButton(
                        icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                        onPressed: onDelete,
                      )
                    else if (isProcessed)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: const Color(0xFFDEF7EC),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          AppLocalization.t('processed'),
                          style: const TextStyle(
                            color: Color(0xFF03543F),
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '$time • $itemsCount ${AppLocalization.t('items')}',
                      style: const TextStyle(
                        fontSize: 13,
                        color: Color(0xFF6B7280),
                      ),
                    ),
                    Text(
                      amount,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: isDark ? const Color(0xFF4DB6AC) : const Color(0xFF0C4A4A),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    ));
  }

  Widget _buildNavItem(IconData icon, String label, bool isActive, VoidCallback onTap) {
    final color = isActive ? const Color(0xFF075E54) : Colors.black54;
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color),
          const SizedBox(height: 4),
          Text(label, style: TextStyle(color: color, fontSize: 12, fontWeight: isActive ? FontWeight.bold : FontWeight.normal)),
        ],
      ),
    );
  }
}
