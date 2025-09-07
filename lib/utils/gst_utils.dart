class GSTUtils {
  // Validate GSTIN format
  static bool isValidGSTIN(String gstin) {
    if (gstin.length != 15) return false;

    // GSTIN format: 2 digits (state code) + 10 digits (PAN) + 1 digit (entity number) + 1 digit (Z) + 1 check digit
    final gstinRegex = RegExp(r'^[0-9]{2}[A-Z]{5}[0-9]{4}[A-Z]{1}[1-9A-Z]{1}[Z]{1}[0-9A-Z]{1}$');
    return gstinRegex.hasMatch(gstin.toUpperCase());
  }

  // Extract state code from GSTIN
  static String getStateCodeFromGSTIN(String gstin) {
    if (gstin.length >= 2) {
      return gstin.substring(0, 2);
    }
    return '';
  }

  // Check if transaction is interstate (different state codes)
  static bool isInterstateTransaction(String sellerGSTIN, String buyerGSTIN) {
    if (sellerGSTIN.isEmpty || buyerGSTIN.isEmpty) return false;
    return getStateCodeFromGSTIN(sellerGSTIN) != getStateCodeFromGSTIN(buyerGSTIN);
  }

  // Calculate GST based on location and tax rates
  static Map<String, double> calculateGST(
      double taxableAmount,
      double cgstRate,
      double sgstRate,
      double igstRate,
      bool isInterstate,
      ) {
    if (isInterstate) {
      return {
        'cgst': 0.0,
        'sgst': 0.0,
        'igst': (taxableAmount * igstRate) / 100,
        'totalTax': (taxableAmount * igstRate) / 100,
      };
    } else {
      final cgst = (taxableAmount * cgstRate) / 100;
      final sgst = (taxableAmount * sgstRate) / 100;
      return {
        'cgst': cgst,
        'sgst': sgst,
        'igst': 0.0,
        'totalTax': cgst + sgst,
      };
    }
  }

  // Get state name from state code
  static String getStateName(String stateCode) {
    final stateMap = {
      '01': 'Jammu and Kashmir',
      '02': 'Himachal Pradesh',
      '03': 'Punjab',
      '04': 'Chandigarh',
      '05': 'Uttarakhand',
      '06': 'Haryana',
      '07': 'Delhi',
      '08': 'Rajasthan',
      '09': 'Uttar Pradesh',
      '10': 'Bihar',
      '11': 'Sikkim',
      '12': 'Arunachal Pradesh',
      '13': 'Nagaland',
      '14': 'Manipur',
      '15': 'Mizoram',
      '16': 'Tripura',
      '17': 'Meghalaya',
      '18': 'Assam',
      '19': 'West Bengal',
      '20': 'Jharkhand',
      '21': 'Odisha',
      '22': 'Chhattisgarh',
      '23': 'Madhya Pradesh',
      '24': 'Gujarat',
      '25': 'Daman and Diu',
      '26': 'Dadra and Nagar Haveli',
      '27': 'Maharashtra',
      '28': 'Andhra Pradesh',
      '29': 'Karnataka',
      '30': 'Goa',
      '31': 'Lakshadweep',
      '32': 'Kerala',
      '33': 'Tamil Nadu',
      '34': 'Puducherry',
      '35': 'Andaman and Nicobar Islands',
      '36': 'Telangana',
      '37': 'Andhra Pradesh (New)',
    };

    return stateMap[stateCode] ?? 'Unknown State';
  }
}
