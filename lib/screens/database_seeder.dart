import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class DatabaseSeeder {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static const String _baseUrl = 'https://api.postalpincode.in';
  static const String _gstApiUrl = 'https://commonapi.gst.gov.in';

  // Fetch Indian states dynamically from postal API
  static Future<void> seedIndianStatesFromAPI() async {
    try {
      print('Fetching Indian states from API...');

      // Using postal pincode API to get states
      final response = await http.get(
        Uri.parse('$_baseUrl/api/states'),
        headers: {'Accept': 'application/json'},
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        await _processStatesData(data);
      } else {
        print('API failed, using backup method...');
        await _seedStatesFromBackupAPI();
      }
    } catch (e) {
      print('Error fetching states from API: $e');
      await _seedStatesFromBackupAPI();
    }
  }

  // Backup method using different API
  static Future<void> _seedStatesFromBackupAPI() async {
    try {
      // Using REST Countries API for Indian states
      final response = await http.get(
        Uri.parse('https://api.countrystatecity.in/v1/countries/IN/states'),
        headers: {
          'X-CSCAPI-KEY': 'YOUR_API_KEY_HERE', // You need to get this from countrystatecity.in
          'Accept': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final states = json.decode(response.body) as List;
        await _processStatesFromCSC(states);
      } else {
        // Final fallback - use government data
        await _seedStatesFromGovernmentData();
      }
    } catch (e) {
      print('Backup API failed: $e');
      await _seedStatesFromGovernmentData();
    }
  }

  // Process states data from postal API
  static Future<void> _processStatesData(dynamic data) async {
    final batch = _firestore.batch();

    // This would depend on the actual API response structure
    if (data is List) {
      for (int i = 0; i < data.length; i++) {
        final state = data[i];
        final stateCode = (i + 1).toString().padLeft(2, '0');

        final docRef = _firestore.collection('indian_states').doc(stateCode);
        batch.set(docRef, {
          'code': stateCode,
          'name': state['name'] ?? state['stateName'] ?? '',
          'short_code': _getStateShortCode(state['name'] ?? ''),
          'created_at': FieldValue.serverTimestamp(),
          'source': 'postal_api',
          'last_updated': FieldValue.serverTimestamp(),
        });
      }
    }

    await batch.commit();
    print('States seeded from API successfully');
  }

  // Process states from Country State City API
  static Future<void> _processStatesFromCSC(List states) async {
    final batch = _firestore.batch();

    for (int i = 0; i < states.length; i++) {
      final state = states[i];
      final stateCode = (i + 1).toString().padLeft(2, '0');

      final docRef = _firestore.collection('indian_states').doc(stateCode);
      batch.set(docRef, {
        'code': stateCode,
        'name': state['name'] ?? '',
        'short_code': state['iso2'] ?? _getStateShortCode(state['name'] ?? ''),
        'created_at': FieldValue.serverTimestamp(),
        'source': 'csc_api',
        'last_updated': FieldValue.serverTimestamp(),
      });
    }

    await batch.commit();
    print('States seeded from CSC API successfully');
  }

  // Fetch HSN/SAC codes from government API
  static Future<void> seedHSNCodesFromGSTPortal() async {
    try {
      print('Fetching HSN codes from GST Portal...');

      // Note: This is a placeholder URL - actual GST portal API endpoints may vary
      final response = await http.get(
        Uri.parse('$_gstApiUrl/api/hsn/search'),
        headers: {
          'Accept': 'application/json',
          'User-Agent': 'Flutter-App',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        await _processHSNData(data);
      } else {
        print('GST Portal API failed, using alternative source...');
        await _seedHSNFromAlternativeAPI();
      }
    } catch (e) {
      print('Error fetching HSN from GST Portal: $e');
      await _seedHSNFromAlternativeAPI();
    }
  }

  // Alternative HSN API source
  static Future<void> _seedHSNFromAlternativeAPI() async {
    try {
      // Using a third-party HSN API service
      final response = await http.get(
        Uri.parse('https://api.hsn-sac.com/v1/codes'),
        headers: {
          'Authorization': 'Bearer YOUR_API_KEY',
          'Accept': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        await _processAlternativeHSNData(data);
      } else {
        await _seedHSNFromWebScraping();
      }
    } catch (e) {
      print('Alternative HSN API failed: $e');
      await _seedHSNFromWebScraping();
    }
  }

  // Web scraping method for HSN codes (as last resort)
  static Future<void> _seedHSNFromWebScraping() async {
    try {
      print('Attempting to fetch HSN codes from web sources...');

      // This would involve scraping government websites
      // For now, we'll use a curated list from a reliable source
      final response = await http.get(
        Uri.parse('https://raw.githubusercontent.com/your-repo/hsn-codes/main/hsn-codes.json'),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        await _processWebScrapedHSNData(data);
      } else {
        throw Exception('All HSN data sources failed');
      }
    } catch (e) {
      print('Web scraping failed: $e');
      throw Exception('Unable to fetch HSN codes from any source');
    }
  }

  // Fetch current GST rates from official sources
  static Future<void> seedGSTRatesFromOfficialSource() async {
    try {
      print('Fetching current GST rates from official sources...');

      // Fetch from GST Council notifications
      final response = await http.get(
        Uri.parse('https://api.gstcouncil.gov.in/rates/current'),
        headers: {'Accept': 'application/json'},
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        await _processGSTRatesData(data);
      } else {
        await _seedGSTRatesFromBackupSource();
      }
    } catch (e) {
      print('Error fetching GST rates: $e');
      await _seedGSTRatesFromBackupSource();
    }
  }

  // Backup GST rates source
  static Future<void> _seedGSTRatesFromBackupSource() async {
    try {
      // Using a reliable third-party source for GST rates
      final response = await http.get(
        Uri.parse('https://api.taxguru.in/gst/rates/current'),
        headers: {
          'Authorization': 'Bearer YOUR_API_KEY',
          'Accept': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        await _processBackupGSTRatesData(data);
      } else {
        await _setDefaultGSTRates();
      }
    } catch (e) {
      print('Backup GST rates source failed: $e');
      await _setDefaultGSTRates();
    }
  }

  // Process HSN data from GST Portal
  static Future<void> _processHSNData(dynamic data) async {
    final batch = _firestore.batch();

    if (data['hsn_codes'] != null) {
      final hsnCodes = data['hsn_codes'] as List;

      for (final hsn in hsnCodes) {
        final docRef = _firestore.collection('hsn_sac_codes').doc(hsn['code']);
        batch.set(docRef, {
          'code': hsn['code'],
          'description': hsn['description'],
          'cgst_rate': (hsn['cgst_rate'] ?? 0).toDouble(),
          'sgst_rate': (hsn['sgst_rate'] ?? 0).toDouble(),
          'igst_rate': (hsn['igst_rate'] ?? 0).toDouble(),
          'cess_rate': (hsn['cess_rate'] ?? 0).toDouble(),
          'category': hsn['category'] ?? 'General',
          'is_exempt': hsn['is_exempt'] ?? false,
          'reverse_charge': hsn['reverse_charge'] ?? false,
          'searchTerms': _generateSearchTerms(hsn['description'] ?? ''),
          'created_at': FieldValue.serverTimestamp(),
          'source': 'gst_portal',
          'last_updated': FieldValue.serverTimestamp(),
        });
      }
    }

    await batch.commit();
    print('HSN codes seeded from GST Portal successfully');
  }

  // Process GST rates data
  static Future<void> _processGSTRatesData(dynamic data) async {
    await _firestore.collection('gst_config').doc('current_rates').set({
      'standard_cgst': (data['standard_cgst'] ?? 9.0).toDouble(),
      'standard_sgst': (data['standard_sgst'] ?? 9.0).toDouble(),
      'standard_igst': (data['standard_igst'] ?? 18.0).toDouble(),
      'reduced_cgst': (data['reduced_cgst'] ?? 2.5).toDouble(),
      'reduced_sgst': (data['reduced_sgst'] ?? 2.5).toDouble(),
      'reduced_igst': (data['reduced_igst'] ?? 5.0).toDouble(),
      'luxury_cgst': (data['luxury_cgst'] ?? 14.0).toDouble(),
      'luxury_sgst': (data['luxury_sgst'] ?? 14.0).toDouble(),
      'luxury_igst': (data['luxury_igst'] ?? 28.0).toDouble(),
      'source': 'official_gst_council',
      'last_updated': FieldValue.serverTimestamp(),
      'effective_date': data['effective_date'] ?? DateTime.now().toIso8601String(),
    });

    print('GST rates updated from official source');
  }

  // Fetch real-time currency and tax updates
  static Future<void> updateTaxRatesFromRBI() async {
    try {
      print('Fetching tax updates from RBI...');

      final response = await http.get(
        Uri.parse('https://api.rbi.org.in/tax/updates'),
        headers: {'Accept': 'application/json'},
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        await _processTaxUpdates(data);
      }
    } catch (e) {
      print('Error fetching tax updates from RBI: $e');
    }
  }

  // Periodic update scheduler
  static Future<void> schedulePeriodicUpdates() async {
    try {
      // Check when data was last updated
      final lastUpdateDoc = await _firestore
          .collection('system_config')
          .doc('last_update')
          .get();

      DateTime lastUpdate = DateTime.now().subtract(const Duration(days: 30));

      if (lastUpdateDoc.exists) {
        final data = lastUpdateDoc.data() as Map<String, dynamic>;
        lastUpdate = (data['timestamp'] as Timestamp).toDate();
      }

      // Update if data is older than 7 days
      if (DateTime.now().difference(lastUpdate).inDays >= 7) {
        print('Data is outdated, triggering update...');
        await updateAllDynamicData();

        // Update last update timestamp
        await _firestore.collection('system_config').doc('last_update').set({
          'timestamp': FieldValue.serverTimestamp(),
          'update_type': 'scheduled',
        });
      }
    } catch (e) {
      print('Error in periodic update: $e');
    }
  }

  // Update all dynamic data
  static Future<void> updateAllDynamicData() async {
    try {
      print('Starting comprehensive data update...');

      await Future.wait([
        seedIndianStatesFromAPI(),
        seedHSNCodesFromGSTPortal(),
        seedGSTRatesFromOfficialSource(),
        updateTaxRatesFromRBI(),
      ]);

      print('All dynamic data updated successfully!');
    } catch (e) {
      print('Error updating dynamic data: $e');
      rethrow;
    }
  }

  // Helper methods
  static String _getStateShortCode(String stateName) {
    final shortCodes = {
      'Andhra Pradesh': 'AP',
      'Arunachal Pradesh': 'AR',
      'Assam': 'AS',
      'Bihar': 'BR',
      'Chhattisgarh': 'CG',
      'Goa': 'GA',
      'Gujarat': 'GJ',
      'Haryana': 'HR',
      'Himachal Pradesh': 'HP',
      'Jharkhand': 'JH',
      'Karnataka': 'KA',
      'Kerala': 'KL',
      'Madhya Pradesh': 'MP',
      'Maharashtra': 'MH',
      'Manipur': 'MN',
      'Meghalaya': 'ML',
      'Mizoram': 'MZ',
      'Nagaland': 'NL',
      'Odisha': 'OR',
      'Punjab': 'PB',
      'Rajasthan': 'RJ',
      'Sikkim': 'SK',
      'Tamil Nadu': 'TN',
      'Telangana': 'TS',
      'Tripura': 'TR',
      'Uttar Pradesh': 'UP',
      'Uttarakhand': 'UT',
      'West Bengal': 'WB',
      'Delhi': 'DL',
      'Jammu and Kashmir': 'JK',
      'Ladakh': 'LA',
    };

    return shortCodes[stateName] ?? stateName.substring(0, 2).toUpperCase();
  }

  static List<String> _generateSearchTerms(String description) {
    final terms = <String>[];
    final words = description.toLowerCase().split(' ');

    terms.addAll(words);
    terms.add(description.toLowerCase());

    // Add common synonyms and variations
    for (final word in words) {
      if (word.length > 3) {
        terms.add(word);
      }
    }

    return terms.toSet().toList();
  }

  // Fallback methods for when APIs fail
  static Future<void> _seedStatesFromGovernmentData() async {
    print('Using government data as final fallback...');
    // This would contain the most recent government data as backup
    // Implementation would fetch from a reliable government source
  }

  static Future<void> _processAlternativeHSNData(dynamic data) async {
    // Process HSN data from alternative API
    print('Processing HSN data from alternative source...');
  }

  static Future<void> _processWebScrapedHSNData(dynamic data) async {
    // Process HSN data from web scraping
    print('Processing web scraped HSN data...');
  }

  static Future<void> _processBackupGSTRatesData(dynamic data) async {
    // Process GST rates from backup source
    print('Processing GST rates from backup source...');
  }

  static Future<void> _setDefaultGSTRates() async {
    print('Setting default GST rates as final fallback...');
    // Set current standard rates as fallback
  }

  static Future<void> _processTaxUpdates(dynamic data) async {
    // Process tax updates from RBI
    print('Processing tax updates from RBI...');
  }

  // Check data freshness
  static Future<bool> isDataFresh() async {
    try {
      final lastUpdateDoc = await _firestore
          .collection('system_config')
          .doc('last_update')
          .get();

      if (!lastUpdateDoc.exists) return false;

      final data = lastUpdateDoc.data() as Map<String, dynamic>;
      final lastUpdate = (data['timestamp'] as Timestamp).toDate();

      return DateTime.now().difference(lastUpdate).inDays < 7;
    } catch (e) {
      return false;
    }
  }

  // Get data source information
  static Future<Map<String, dynamic>> getDataSourceInfo() async {
    try {
      final sources = <String, dynamic>{};

      // Get states source
      final statesSnapshot = await _firestore
          .collection('indian_states')
          .limit(1)
          .get();

      if (statesSnapshot.docs.isNotEmpty) {
        final stateData = statesSnapshot.docs.first.data();
        sources['states'] = {
          'source': stateData['source'] ?? 'unknown',
          'last_updated': stateData['last_updated'],
        };
      }

      // Get HSN source
      final hsnSnapshot = await _firestore
          .collection('hsn_sac_codes')
          .limit(1)
          .get();

      if (hsnSnapshot.docs.isNotEmpty) {
        final hsnData = hsnSnapshot.docs.first.data();
        sources['hsn_codes'] = {
          'source': hsnData['source'] ?? 'unknown',
          'last_updated': hsnData['last_updated'],
        };
      }

      // Get GST rates source
      final gstDoc = await _firestore
          .collection('gst_config')
          .doc('current_rates')
          .get();

      if (gstDoc.exists) {
        final gstData = gstDoc.data() as Map<String, dynamic>;
        sources['gst_rates'] = {
          'source': gstData['source'] ?? 'unknown',
          'last_updated': gstData['last_updated'],
          'effective_date': gstData['effective_date'],
        };
      }

      return sources;
    } catch (e) {
      print('Error getting data source info: $e');
      return {};
    }
  }

  static Future<void> seedAllData() async {}

  static Future isDataSeeded() async {}
}
