import 'package:cloud_firestore/cloud_firestore.dart';

class DynamicGSTUtils {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Calculate GST based on transaction type with dynamic rates
  static Map<String, double> calculateGST(
      double taxableValue,
      double cgstRate,
      double sgstRate,
      double igstRate,
      bool isInterstate,
      ) {
    double cgstAmount = 0.0;
    double sgstAmount = 0.0;
    double igstAmount = 0.0;

    if (isInterstate) {
      // Interstate transaction - use IGST
      igstAmount = (taxableValue * igstRate) / 100;
    } else {
      // Intrastate transaction - use CGST + SGST
      cgstAmount = (taxableValue * cgstRate) / 100;
      sgstAmount = (taxableValue * sgstRate) / 100;
    }

    final totalTax = cgstAmount + sgstAmount + igstAmount;

    return {
      'cgst': cgstAmount,
      'sgst': sgstAmount,
      'igst': igstAmount,
      'totalTax': totalTax,
      'totalAmount': taxableValue + totalTax,
    };
  }

  // Check if transaction is interstate using dynamic state codes
  static Future<bool> isInterstateTransaction(String businessGSTIN, String partyGSTIN) async {
    if (businessGSTIN.isEmpty || partyGSTIN.isEmpty) return false;

    final businessStateCode = businessGSTIN.substring(0, 2);
    final partyStateCode = partyGSTIN.substring(0, 2);

    // Validate state codes against dynamic database
    final isBusinessStateValid = await _isValidStateCode(businessStateCode);
    final isPartyStateValid = await _isValidStateCode(partyStateCode);

    if (!isBusinessStateValid || !isPartyStateValid) {
      throw Exception('Invalid state code in GSTIN');
    }

    return businessStateCode != partyStateCode;
  }

  // Validate GSTIN with dynamic validation rules
  static Future<bool> isValidGSTIN(String gstin) async {
    if (gstin.length != 15) return false;

    try {
      // Get validation rules from database
      final validationDoc = await _firestore
          .collection('gst_config')
          .doc('validation_rules')
          .get();

      if (!validationDoc.exists) {
        // Fallback to basic validation
        final gstinRegex = RegExp(r'^[0-9]{2}[A-Z]{5}[0-9]{4}[A-Z]{1}[1-9A-Z]{1}Z[0-9A-Z]{1}$');
        return gstinRegex.hasMatch(gstin);
      }

      final rules = validationDoc.data() as Map<String, dynamic>;
      final regexPattern = rules['gstin_regex'] ?? r'^[0-9]{2}[A-Z]{5}[0-9]{4}[A-Z]{1}[1-9A-Z]{1}Z[0-9A-Z]{1}$';

      final gstinRegex = RegExp(regexPattern);
      final basicValidation = gstinRegex.hasMatch(gstin);

      if (!basicValidation) return false;

      // Validate state code
      final stateCode = gstin.substring(0, 2);
      return await _isValidStateCode(stateCode);

    } catch (e) {
      print('Error validating GSTIN: $e');
      return false;
    }
  }

  // Get state code from GSTIN with validation
  static Future<String> getStateCodeFromGSTIN(String gstin) async {
    if (gstin.length < 2) return '';

    final stateCode = gstin.substring(0, 2);
    final isValid = await _isValidStateCode(stateCode);

    return isValid ? stateCode : '';
  }

  // Get state name from state code dynamically
  static Future<String> getStateName(String stateCode) async {
    try {
      final stateDoc = await _firestore
          .collection('indian_states')
          .doc(stateCode)
          .get();

      if (stateDoc.exists) {
        final data = stateDoc.data() as Map<String, dynamic>;
        return data['name'] ?? 'Unknown State';
      }

      return 'Unknown State';
    } catch (e) {
      print('Error getting state name: $e');
      return 'Unknown State';
    }
  }

  // Get HSN/SAC description dynamically from database
  static Future<String> getHSNDescription(String hsnCode) async {
    try {
      final hsnDoc = await _firestore
          .collection('hsn_sac_codes')
          .doc(hsnCode)
          .get();

      if (hsnDoc.exists) {
        final data = hsnDoc.data() as Map<String, dynamic>;
        return data['description'] ?? 'Unknown HSN/SAC';
      }

      // If not found, try to search in the collection
      final querySnapshot = await _firestore
          .collection('hsn_sac_codes')
          .where('code', isEqualTo: hsnCode)
          .limit(1)
          .get();

      if (querySnapshot.docs.isNotEmpty) {
        final data = querySnapshot.docs.first.data();
        return data['description'] ?? 'Unknown HSN/SAC';
      }

      return 'Unknown HSN/SAC';
    } catch (e) {
      print('Error getting HSN description: $e');
      return 'Unknown HSN/SAC';
    }
  }

  // Get GST rates for HSN/SAC code dynamically
  static Future<Map<String, double>> getGSTRatesForHSN(String hsnCode) async {
    try {
      final hsnDoc = await _firestore
          .collection('hsn_sac_codes')
          .doc(hsnCode)
          .get();

      if (hsnDoc.exists) {
        final data = hsnDoc.data() as Map<String, dynamic>;
        return {
          'cgst': (data['cgst_rate'] ?? 0).toDouble(),
          'sgst': (data['sgst_rate'] ?? 0).toDouble(),
          'igst': (data['igst_rate'] ?? 0).toDouble(),
          'cess': (data['cess_rate'] ?? 0).toDouble(),
        };
      }

      // Default rates if not found
      return {
        'cgst': 0.0,
        'sgst': 0.0,
        'igst': 0.0,
        'cess': 0.0,
      };
    } catch (e) {
      print('Error getting GST rates: $e');
      return {
        'cgst': 0.0,
        'sgst': 0.0,
        'igst': 0.0,
        'cess': 0.0,
      };
    }
  }

  // Search HSN/SAC codes dynamically
  static Future<List<Map<String, dynamic>>> searchHSNCodes(String query) async {
    try {
      final querySnapshot = await _firestore
          .collection('hsn_sac_codes')
          .where('searchTerms', arrayContains: query.toLowerCase())
          .limit(20)
          .get();

      return querySnapshot.docs.map((doc) {
        final data = doc.data();
        return {
          'code': data['code'] ?? '',
          'description': data['description'] ?? '',
          'cgst_rate': data['cgst_rate'] ?? 0,
          'sgst_rate': data['sgst_rate'] ?? 0,
          'igst_rate': data['igst_rate'] ?? 0,
          'cess_rate': data['cess_rate'] ?? 0,
          'category': data['category'] ?? '',
        };
      }).toList();
    } catch (e) {
      print('Error searching HSN codes: $e');
      return [];
    }
  }

  // Get current GST rates from configuration
  static Future<Map<String, double>> getCurrentGSTRates() async {
    try {
      final configDoc = await _firestore
          .collection('gst_config')
          .doc('current_rates')
          .get();

      if (configDoc.exists) {
        final data = configDoc.data() as Map<String, dynamic>;
        return {
          'standard_cgst': (data['standard_cgst'] ?? 9.0).toDouble(),
          'standard_sgst': (data['standard_sgst'] ?? 9.0).toDouble(),
          'standard_igst': (data['standard_igst'] ?? 18.0).toDouble(),
          'reduced_cgst': (data['reduced_cgst'] ?? 2.5).toDouble(),
          'reduced_sgst': (data['reduced_sgst'] ?? 2.5).toDouble(),
          'reduced_igst': (data['reduced_igst'] ?? 5.0).toDouble(),
        };
      }

      // Default rates
      return {
        'standard_cgst': 9.0,
        'standard_sgst': 9.0,
        'standard_igst': 18.0,
        'reduced_cgst': 2.5,
        'reduced_sgst': 2.5,
        'reduced_igst': 5.0,
      };
    } catch (e) {
      print('Error getting current GST rates: $e');
      return {
        'standard_cgst': 9.0,
        'standard_sgst': 9.0,
        'standard_igst': 18.0,
        'reduced_cgst': 2.5,
        'reduced_sgst': 2.5,
        'reduced_igst': 5.0,
      };
    }
  }

  // Private method to validate state code
  static Future<bool> _isValidStateCode(String stateCode) async {
    try {
      final stateDoc = await _firestore
          .collection('indian_states')
          .doc(stateCode)
          .get();

      return stateDoc.exists;
    } catch (e) {
      print('Error validating state code: $e');
      return false;
    }
  }

  // Get tax exemption categories dynamically
  static Future<List<String>> getTaxExemptionCategories() async {
    try {
      final configDoc = await _firestore
          .collection('gst_config')
          .doc('exemption_categories')
          .get();

      if (configDoc.exists) {
        final data = configDoc.data() as Map<String, dynamic>;
        return List<String>.from(data['categories'] ?? []);
      }

      return ['exempt', 'zero_rated', 'nil_rated'];
    } catch (e) {
      print('Error getting exemption categories: $e');
      return ['exempt', 'zero_rated', 'nil_rated'];
    }
  }

  // Check if item is tax exempt
  static Future<bool> isItemTaxExempt(String hsnCode) async {
    try {
      final hsnDoc = await _firestore
          .collection('hsn_sac_codes')
          .doc(hsnCode)
          .get();

      if (hsnDoc.exists) {
        final data = hsnDoc.data() as Map<String, dynamic>;
        return data['is_exempt'] ?? false;
      }

      return false;
    } catch (e) {
      print('Error checking tax exemption: $e');
      return false;
    }
  }

  // Get reverse charge applicable items
  static Future<bool> isReverseChargeApplicable(String hsnCode) async {
    try {
      final hsnDoc = await _firestore
          .collection('hsn_sac_codes')
          .doc(hsnCode)
          .get();

      if (hsnDoc.exists) {
        final data = hsnDoc.data() as Map<String, dynamic>;
        return data['reverse_charge'] ?? false;
      }

      return false;
    } catch (e) {
      print('Error checking reverse charge: $e');
      return false;
    }
  }
}
