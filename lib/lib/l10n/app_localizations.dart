import 'package:flutter/material.dart';

class AppLocalizations {
  final Locale locale;

  AppLocalizations(this.locale);

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate = _AppLocalizationsDelegate();

  static final Map<String, Map<String, String>> _localizedValues = {
    'en': {
      // App Name
      'app_name': 'TaxEase GST',
      'app_subtitle': 'Management System',
      'app_tagline': 'Your Professional Business Partner',

      // Auth
      'loading': 'Loading...',
      'logout': 'Logout',
      'logout_confirm': 'Are you sure you want to logout?',
      'cancel': 'Cancel',
      'yes': 'Yes',
      'no': 'No',

      // Tabs
      'inventory': 'Inventory',
      'dashboard': 'Dashboard',
      'parties': 'Parties',
      'gst': 'GST',
      'subscription': 'Subscription',
      'sales': 'Sales',
      'items': 'Items',
      'stock': 'Stock',
      'reports': 'Reports',

      // Inventory
      'my_inventory': 'My Inventory',
      'add_new_sale': 'Add New Sale',
      'add_item': 'Add Item',
      'add_stock': 'Add Stock',

      // Items
      'search_items': 'Search items...',
      'no_items_found': 'No items found',
      'add_first_item': 'Add your first item to get started',
      'no_items_match': 'No items match your search',
      'try_different_search': 'Try a different search term',
      'total_items': 'Total Items',
      'generate_items_report': 'Generate My Items Report',

      // Item Details
      'item_code': 'Item Code',
      'description': 'Description',
      'hsn_sac_code': 'HSN/SAC Code',
      'unit_of_measurement': 'Unit of Measurement',
      'cgst_rate': 'CGST Rate %',
      'sgst_rate': 'SGST Rate %',
      'igst_rate': 'IGST Rate %',
      'cess_rate': 'Cess Rate %',
      'cost_price': 'Cost Price',
      'selling_price': 'Selling Price',
      'profit_margin': 'Profit Margin',
      'edit_item': 'Edit Item',
      'add_new_item': 'Add New Item',
      'delete_item': 'Delete Item',
      'delete_confirm': 'Are you sure you want to delete',
      'delete': 'Delete',

      // Stock
      'select_item': 'Select Item',
      'location': 'Location',
      'current_stock': 'Current Stock',
      'minimum_stock_level': 'Minimum Stock Level',
      'low_stock': 'Low Stock',
      'save': 'Save',
      'no_stock_found': 'No stock records found',
      'stock_levels_appear_here': 'Your stock levels will appear here',
      'last_updated': 'Last updated',
      'good': 'Good',
      'low': 'Low',

      // Sales
      'search_sales': 'Search sales by customer...',
      'no_sales_yet': 'No sales yet',
      'no_matching_sales': 'No matching sales',
      'add_sale': 'Add Sale',
      'generate_sales_report': 'Generate My Sales Report',
      'invoice': 'Invoice',
      'customer': 'Customer',
      'date': 'Date',
      'items_count': 'Items',

      // Reports
      'my_inventory_reports': 'My Inventory Reports',
      'stock_summary': 'Stock Summary',
      'stock_summary_desc': 'Overview of current stock levels',
      'low_stock_alert': 'Low Stock Alert',
      'low_stock_alert_desc': 'Items running low on stock',
      'sales_performance': 'Sales Performance (HSN)',
      'sales_performance_desc': 'Track sales trends and performance by HSN/SAC code',
      'valuation_report': 'Valuation Report',
      'valuation_report_desc': 'Total inventory valuation',
      'profit_analysis': 'Profit Analysis',
      'profit_analysis_desc': 'Analyze profit margins by item',

      // Actions
      'download_pdf': 'Download PDF',
      'share_pdf': 'Share PDF',
      'print_pdf': 'Print PDF',
      'edit': 'Edit',
      'close': 'Close',
      'update': 'Update',
      'refresh_token': 'Refresh Token',
      'subscribe_to_topic': 'Subscribe to Topic',

      // Messages
      'item_added_success': 'Item added successfully',
      'item_updated_success': 'Item updated successfully',
      'item_deleted_success': 'Item deleted successfully',
      'stock_added_success': 'Stock added successfully',
      'sale_deleted_success': 'Sale deleted',
      'error': 'Error',
      'success': 'Success',

      // Validation
      'required_field': 'This field is required',
      'valid_number_required': 'Valid number required',
      'select_item_required': 'Please select an item',
      'enter_location': 'Please enter location',
      'enter_current_stock': 'Please enter current stock',
      'enter_min_stock': 'Please enter minimum stock level',
      'valid_positive_number': 'Please enter a valid positive number',
    },
    'ta': {
      // App Name
      'app_name': 'டேக்ஸ்ஈஸ் ஜிஎஸ்டி',
      'app_subtitle': 'மேலாண்மை அமைப்பு',
      'app_tagline': 'உங்கள் தொழில்முறை வணிக கூட்டாளி',

      // Auth
      'loading': 'ஏற்றுகிறது...',
      'logout': 'வெளியேறு',
      'logout_confirm': 'நீங்கள் நிச்சயமாக வெளியேற விரும்புகிறீர்களா?',
      'cancel': 'ரத்து',
      'yes': 'ஆம்',
      'no': 'இல்லை',

      // Tabs
      'inventory': 'சரக்கு',
      'dashboard': 'முகப்பு',
      'parties': 'தரப்பினர்',
      'gst': 'ஜிஎஸ்டி',
      'subscription': 'சந்தா',
      'sales': 'விற்பனை',
      'items': 'பொருட்கள்',
      'stock': 'இருப்பு',
      'reports': 'அறிக்கைகள்',

      // Inventory
      'my_inventory': 'எனது சரக்கு',
      'add_new_sale': 'புதிய விற்பனையைச் சேர்',
      'add_item': 'பொருளைச் சேர்',
      'add_stock': 'இருப்பு சேர்',

      // Items
      'search_items': 'பொருட்களைத் தேடு...',
      'no_items_found': 'பொருட்கள் இல்லை',
      'add_first_item': 'தொடங்க உங்கள் முதல் பொருளைச் சேர்க்கவும்',
      'no_items_match': 'எந்த பொருளும் பொருந்தவில்லை',
      'try_different_search': 'வேறு தேடல் சொல்லை முயற்சிக்கவும்',
      'total_items': 'மொத்த பொருட்கள்',
      'generate_items_report': 'எனது பொருள் அறிக்கையை உருவாக்கு',

      // Item Details
      'item_code': 'பொருள் குறியீடு',
      'description': 'விளக்கம்',
      'hsn_sac_code': 'HSN/SAC குறியீடு',
      'unit_of_measurement': 'அளவீட்டு அலகு',
      'cgst_rate': 'CGST விகிதம் %',
      'sgst_rate': 'SGST விகிதம் %',
      'igst_rate': 'IGST விகிதம் %',
      'cess_rate': 'செஸ் விகிதம் %',
      'cost_price': 'செலவு விலை',
      'selling_price': 'விற்பனை விலை',
      'profit_margin': 'லாப வரம்பு',
      'edit_item': 'பொருளைத் திருத்து',
      'add_new_item': 'புதிய பொருளைச் சேர்',
      'delete_item': 'பொருளை நீக்கு',
      'delete_confirm': 'நீங்கள் நிச்சயமாக நீக்க விரும்புகிறீர்களா',
      'delete': 'நீக்கு',

      // Stock
      'select_item': 'பொருளைத் தேர்ந்தெடு',
      'location': 'இடம்',
      'current_stock': 'தற்போதைய இருப்பு',
      'minimum_stock_level': 'குறைந்தபட்ச இருப்பு நிலை',
      'low_stock': 'குறைந்த இருப்பு',
      'save': 'சேமி',
      'no_stock_found': 'இருப்பு பதிவுகள் இல்லை',
      'stock_levels_appear_here': 'உங்கள் இருப்பு நிலைகள் இங்கே தோன்றும்',
      'last_updated': 'கடைசியாக புதுப்பிக்கப்பட்டது',
      'good': 'நல்லது',
      'low': 'குறைவு',

      // Sales
      'search_sales': 'வாடிக்கையாளர் மூலம் விற்பனையைத் தேடு...',
      'no_sales_yet': 'இன்னும் விற்பனை இல்லை',
      'no_matching_sales': 'பொருந்தும் விற்பனை இல்லை',
      'add_sale': 'விற்பனை சேர்',
      'generate_sales_report': 'எனது விற்பனை அறிக்கையை உருவாக்கு',
      'invoice': 'விலைப்பட்டியல்',
      'customer': 'வாடிக்கையாளர்',
      'date': 'தேதி',
      'items_count': 'பொருட்கள்',

      // Reports
      'my_inventory_reports': 'எனது சரக்கு அறிக்கைகள்',
      'stock_summary': 'இருப்பு சுருக்கம்',
      'stock_summary_desc': 'தற்போதைய இருப்பு நிலைகளின் மேலோட்டம்',
      'low_stock_alert': 'குறைந்த இருப்பு எச்சரிக்கை',
      'low_stock_alert_desc': 'இருப்பு குறைவாக உள்ள பொருட்கள்',
      'sales_performance': 'விற்பனை செயல்திறன் (HSN)',
      'sales_performance_desc': 'HSN/SAC குறியீடு மூலம் விற்பனை போக்குகளைக் கண்காணிக்கவும்',
      'valuation_report': 'மதிப்பீட்டு அறிக்கை',
      'valuation_report_desc': 'மொத்த சரக்கு மதிப்பீடு',
      'profit_analysis': 'லாப பகுப்பாய்வு',
      'profit_analysis_desc': 'பொருள் வாரியாக லாப வரம்புகளை பகுப்பாய்வு செய்யவும்',

      // Actions
      'download_pdf': 'PDF பதிவிறக்கம்',
      'share_pdf': 'PDF பகிர்',
      'print_pdf': 'PDF அச்சிடு',
      'edit': 'திருத்து',
      'close': 'மூடு',
      'update': 'புதுப்பி',
      'refresh_token': 'டோக்கனை புதுப்பி',
      'subscribe_to_topic': 'தலைப்புக்கு குழுசேர்',

      // Messages
      'item_added_success': 'பொருள் வெற்றிகரமாக சேர்க்கப்பட்டது',
      'item_updated_success': 'பொருள் வெற்றிகரமாக புதுப்பிக்கப்பட்டது',
      'item_deleted_success': 'பொருள் வெற்றிகரமாக நீக்கப்பட்டது',
      'stock_added_success': 'இருப்பு வெற்றிகரமாக சேர்க்கப்பட்டது',
      'sale_deleted_success': 'விற்பனை நீக்கப்பட்டது',
      'error': 'பிழை',
      'success': 'வெற்றி',

      // Validation
      'required_field': 'இந்த புலம் அவசியம்',
      'valid_number_required': 'சரியான எண் தேவை',
      'select_item_required': 'தயவுசெய்து ஒரு பொருளைத் தேர்ந்தெடுக்கவும்',
      'enter_location': 'தயவுசெய்து இடத்தை உள்ளிடவும்',
      'enter_current_stock': 'தயவுசெய்து தற்போதைய இருப்பை உள்ளிடவும்',
      'enter_min_stock': 'தயவுசெய்து குறைந்தபட்ச இருப்பு நிலையை உள்ளிடவும்',
      'valid_positive_number': 'தயவுசெய்து சரியான நேர்மறை எண்ணை உள்ளிடவும்',
    },
  };

  String translate(String key) {
    return _localizedValues[locale.languageCode]?[key] ?? key;
  }
}

class _AppLocalizationsDelegate extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) => ['en', 'ta'].contains(locale.languageCode);

  @override
  Future<AppLocalizations> load(Locale locale) async {
    return AppLocalizations(locale);
  }

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}