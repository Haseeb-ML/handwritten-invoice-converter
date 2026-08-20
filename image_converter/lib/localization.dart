import 'package:flutter/material.dart';

class AppLocalization {
  static final ValueNotifier<String> currentLanguage = ValueNotifier<String>('urdu');

  static final Map<String, Map<String, String>> _translations = {
    'english': {
      'home': 'Home',
      'invoices': 'Invoices',
      'history': 'History',
      'settings': 'Settings',
      'camera': 'Camera',
      'take_invoice_photo': 'Take Invoice Photo',
      'take_photo_subtitle': 'Capture invoice from camera',
      'pick_from_gallery': 'Pick from Gallery',
      'view_all': 'View All',
      'recent_activity': 'Recent Activity',
      'quick_tips': 'Quick Tips',
      'whole_invoice': 'Whole Invoice',
      'clear_photo': 'Clear Photo',
      'good_lighting': 'Good Lighting',
      'no_recent_activity': 'No recent activity',
      'unknown_vendor': 'Unknown Vendor',
      'all': 'All',
      'today': 'Today',
      'this_week': 'This Week',
      'no_invoices_found': 'No invoices found. Scan a receipt to get started.',
      'greeting': 'Welcome',
      'ready_to_scan': 'Ready to scan today\'s invoice?',
      'item': 'Item',
      'items': 'Items',
      'processed': 'PROCESSED',
      'next_export': 'Next to Export',
      'vendor_name': 'Customer Name',
      'date': 'Date',
      'invoice_number': 'Invoice #',
      'grand_total': 'Grand Total',
      'language': 'Language',
      'edit_invoice': 'Edit Invoice',
      'save_and_continue': 'Save & Continue',
      'voice_input': 'Voice Input',
      'search_hint': 'Search customers or items...',
      'retake_photo': 'Retake Photo',
      'editing_mode': 'Editing Mode',
      'qty': 'Qty',
      'price': 'Price',
      'total': 'Total',
      'item_name': 'Item Name',
    },
    'urdu': {
      'home': 'ہوم',
      'invoices': 'انوائسز',
      'history': 'ہسٹری',
      'settings': 'سیٹنگز',
      'camera': 'کیمرہ',
      'take_invoice_photo': 'تصویر لیں', // updated from main.dart
      'take_photo_subtitle': 'کیمرے سے تصویر کھینچیں',
      'pick_from_gallery': 'گیلری سے چنیں',
      'view_all': 'سب دیکھیں',
      'recent_activity': 'حالیہ سرگرمی',
      'quick_tips': 'اہم تجاویز',
      'whole_invoice': 'پوری انوائس',
      'clear_photo': 'صاف تصویر',
      'good_lighting': 'اچھی روشنی',
      'no_recent_activity': 'کوئی حالیہ سرگرمی نہیں',
      'unknown_vendor': 'نامعلوم وینڈر',
      'all': 'سب',
      'today': 'آج',
      'this_week': 'اس ہفتے',
      'no_invoices_found': 'کوئی انوائس نہیں ملی۔ شروع کرنے کے لئے رسید اسکین کریں۔',
      'greeting': 'السلام علیکم',
      'ready_to_scan': 'آج کی انوائس اسکین کرنے کے لیے تیار ہیں؟',
      'item': 'آئٹم',
      'items': 'آئٹمز',
      'processed': 'مکمل شد',
      'next_export': 'ایکسپورٹ کریں',
      'vendor_name': 'گاہک کا نام',
      'date': 'تاریخ',
      'invoice_number': 'رسید نمبر',
      'grand_total': 'کل رقم',
      'language': 'زبان',
      'edit_invoice': 'انوائس میں ترمیم کریں',
      'save_and_continue': 'محفوظ کریں اور آگے بڑھیں',
      'voice_input': 'بول کر بتائیں',
      'search_hint': 'کسٹمر یا آئٹم تلاش کریں...',
      'retake_photo': 'دوبارہ تصویر لیں',
      'editing_mode': 'ایڈیٹنگ موڈ',
      'qty': 'مقدار',
      'price': 'قیمت',
      'total': 'کل',
      'item_name': 'آئٹم کا نام',
    }
  };

  static String t(String key) {
    return _translations[currentLanguage.value]?[key] ?? key;
  }

  static void toggleLanguage() {
    currentLanguage.value = currentLanguage.value == 'urdu' ? 'english' : 'urdu';
  }
}
