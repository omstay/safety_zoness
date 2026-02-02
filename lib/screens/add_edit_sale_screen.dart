import 'dart:io';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:signature/signature.dart';
import '../model/SaleMaster.dart';
import 'inventory_management.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// A screen for adding a new sale or editing an existing one with invoice format.
class AddEditSaleScreen extends StatefulWidget {
  final String userId;
  final String? saleId;
  final DocumentSnapshot? saleDoc;




  const AddEditSaleScreen({
    super.key,
    required this.userId,
    this.saleId,
    this.saleDoc,
  });

  @override
  State<AddEditSaleScreen> createState() => _AddEditSaleScreenState();
}

class _AddEditSaleScreenState extends State<AddEditSaleScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final _formKey = GlobalKey<FormState>();

  // Basic controllers
  final TextEditingController _customerNameController = TextEditingController();
  final TextEditingController _invoiceController = TextEditingController();
  final TextEditingController _termsController = TextEditingController(
      text: 'Net 30');
  DateTime _selectedDate = DateTime.now();
  DateTime _dueDate = DateTime.now().add(Duration(days: 30));
  List<SaleItem> _saleItems = [];
  double _totalSaleAmount = 0.0;
  bool _isLoading = false;
  File? _signatureImageFile;
  Uint8List? _signatureImageBytes;
  SignatureController? _signatureController;
  bool _isSignaturePadVisible = false;

  // Customer Address controllers
  final TextEditingController _customerAddressLine1Controller = TextEditingController();
  final TextEditingController _customerAddressLine2Controller = TextEditingController();
  final TextEditingController _customerCityController = TextEditingController();
  final TextEditingController _customerStateController = TextEditingController();
  final TextEditingController _customerPincodeController = TextEditingController();

  // Shipping Address controllers (Bill To / Ship To)
  final TextEditingController _shippingAddressLine1Controller = TextEditingController();
  final TextEditingController _shippingAddressLine2Controller = TextEditingController();
  final TextEditingController _shippingCityController = TextEditingController();
  final TextEditingController _shippingStateController = TextEditingController();
  final TextEditingController _shippingPincodeController = TextEditingController();
  bool _sameAsBilling = true;

  // Business/Company Info (from AuthService)
  String _businessName = '';
  String _businessAddress = '';
  String _businessGSTIN = '';
  String _businessPhone = '';
  String _businessEmail = '';

  // Bank Details (from AuthService)
  String _bankName = '';
  String _accountNumber = '';
  String _ifscCode = '';
  String _accountHolderName = '';

  // GST controllers
  final TextEditingController _recipientGSTINController = TextEditingController();
  final TextEditingController _eWayBillController = TextEditingController();
  final TextEditingController _distanceController = TextEditingController();
// GST Rate controllers for manual entry
  final TextEditingController _sgstRateController = TextEditingController();
  final TextEditingController _cgstRateController = TextEditingController();
  final TextEditingController _igstRateController = TextEditingController();
  // GST dropdowns
  String _selectedPlaceOfSupply = '';
  String _selectedSupplyType = 'INTRA';
  String _selectedSaleType = 'CASH';
  String _selectedDocumentType = 'INV';
  String _selectedTransportMode = 'Road';
  bool _isReverseCharge = false;
  // Add this with your other state variables
  List<String> _cachedCustomerNames = [];

  // State codes for Place of Supply
  final List<Map<String, String>> _stateCodes = [
    {'code': '01', 'name': 'Jammu and Kashmir'},
    {'code': '02', 'name': 'Himachal Pradesh'},
    {'code': '03', 'name': 'Punjab'},
    {'code': '04', 'name': 'Chandigarh'},
    {'code': '05', 'name': 'Uttarakhand'},
    {'code': '06', 'name': 'Haryana'},
    {'code': '07', 'name': 'Delhi'},
    {'code': '08', 'name': 'Rajasthan'},
    {'code': '09', 'name': 'Uttar Pradesh'},
    {'code': '10', 'name': 'Bihar'},
    {'code': '11', 'name': 'Sikkim'},
    {'code': '12', 'name': 'Arunachal Pradesh'},
    {'code': '13', 'name': 'Nagaland'},
    {'code': '14', 'name': 'Manipur'},
    {'code': '15', 'name': 'Mizoram'},
    {'code': '16', 'name': 'Tripura'},
    {'code': '17', 'name': 'Meghalaya'},
    {'code': '18', 'name': 'Assam'},
    {'code': '19', 'name': 'West Bengal'},
    {'code': '20', 'name': 'Jharkhand'},
    {'code': '21', 'name': 'Odisha'},
    {'code': '22', 'name': 'Chhattisgarh'},
    {'code': '23', 'name': 'Madhya Pradesh'},
    {'code': '24', 'name': 'Gujarat'},
    {'code': '25', 'name': 'Daman and Diu'},
    {'code': '26', 'name': 'Dadra and Nagar Haveli'},
    {'code': '27', 'name': 'Maharashtra'},
    {'code': '28', 'name': 'Andhra Pradesh'},
    {'code': '29', 'name': 'Karnataka'},
    {'code': '30', 'name': 'Goa'},
    {'code': '31', 'name': 'Lakshadweep'},
    {'code': '32', 'name': 'Kerala'},
    {'code': '33', 'name': 'Tamil Nadu'},
    {'code': '34', 'name': 'Puducherry'},
    {'code': '35', 'name': 'Andaman and Nicobar Islands'},
    {'code': '36', 'name': 'Telangana'},
    {'code': '37', 'name': 'Andhra Pradesh (New)'},
    {'code': '97', 'name': 'Other Territory'},
  ];

  @override
  void initState() {
    super.initState();
    _loadBusinessData();
    _selectedPlaceOfSupply = '33';

    _loadCustomerNames(); // ADD THIS LINE
    if (widget.saleId != null && widget.saleId!.isNotEmpty) {
      _loadSaleData();
    } else {
      // Generate invoice number for new sales
      _generateInvoiceNumber();
      // Update supply type based on default state
      _updateSupplyType();
    }
  }
  /// Save customer details to Firestore
  /// Save customer details to Firestore
  Future<void> _saveCustomerDetails() async {
    if (_customerNameController.text.trim().isEmpty) return;

    try {
      final customerData = {
        'name': _customerNameController.text.trim(),
        'gstin': _recipientGSTINController.text.trim().toUpperCase(),
        'addressLine1': _customerAddressLine1Controller.text.trim(),
        'addressLine2': _customerAddressLine2Controller.text.trim(),
        'city': _customerCityController.text.trim(),
        'state': _customerStateController.text.trim(),
        'pincode': _customerPincodeController.text.trim(),
        'userId': widget.userId,
        'lastUsed': FieldValue.serverTimestamp(),
      };

      final customerId = _customerNameController.text.trim().toLowerCase().replaceAll(' ', '_');

      await _firestore
          .collection('customers')
          .doc(customerId)
          .set(customerData, SetOptions(merge: true));

      debugPrint('Customer details saved: ${_customerNameController.text}');

      // Reload customer names after saving
      await _loadCustomerNames(); // ADD THIS LINE

    } catch (e) {
      debugPrint('Error saving customer details: $e');
    }
  }
  /// Load customer details from Firestore
  Future<void> _loadCustomerDetails(String customerName) async {
    if (customerName.trim().isEmpty) return;

    try {
      final customerId = customerName.trim().toLowerCase().replaceAll(' ', '_');
      final customerDoc = await _firestore
          .collection('customers')
          .doc(customerId)
          .get();

      if (customerDoc.exists) {
        final data = customerDoc.data()!;
        setState(() {
          _recipientGSTINController.text = data['gstin'] ?? '';
          _customerAddressLine1Controller.text = data['addressLine1'] ?? '';
          _customerAddressLine2Controller.text = data['addressLine2'] ?? '';
          _customerCityController.text = data['city'] ?? '';
          _customerStateController.text = data['state'] ?? '';
          _customerPincodeController.text = data['pincode'] ?? '';

          // Auto-fill shipping address if same as billing
          if (_sameAsBilling) {
            _shippingAddressLine1Controller.text = _customerAddressLine1Controller.text;
            _shippingCityController.text = _customerCityController.text;
            _shippingStateController.text = _customerStateController.text;
          }
        });

        _updateSupplyType(); // Update supply type based on GSTIN

        debugPrint('Customer details loaded: $customerName');
      }
    } catch (e) {
      debugPrint('Error loading customer details: $e');
    }
  }
  Future<void> _generateInvoiceNumber() async {
    final now = DateTime.now();
    final year = now.year;

    final counterRef = FirebaseFirestore.instance
        .collection('metadata')
        .doc('invoiceCounter');

    await FirebaseFirestore.instance.runTransaction((transaction) async {
      final snapshot = await transaction.get(counterRef);

      // Handle if document doesn't exist
      int lastNumber = 0;
      if (snapshot.exists) {
        lastNumber = snapshot.data()?['lastNumber'] ?? 0;
      }

      int newNumber = lastNumber + 1;

      // Format to 3 digits: 001, 002, 003...
      String padded = newNumber.toString().padLeft(3, '0');

      String invoice = "INV-$year-$padded";

      // Update the controller
      setState(() {
        _invoiceController.text = invoice;
      });

      // Save to Firestore
      if (snapshot.exists) {
        transaction.update(counterRef, {"lastNumber": newNumber});
      } else {
        transaction.set(counterRef, {"lastNumber": newNumber});
      }
    });
  }

  /// Load customer names for autocomplete
  /// Load customer names for autocomplete
  Future<void> _loadCustomerNames() async {
    try {
      final querySnapshot = await _firestore
          .collection('customers')
          .where('userId', isEqualTo: widget.userId)
      // Temporarily remove orderBy until index is ready
      // .orderBy('lastUsed', descending: true)
          .limit(50)
          .get();

      // Sort in memory instead
      final customerDocs = querySnapshot.docs;
      customerDocs.sort((a, b) {
        final aTime = a.data()['lastUsed'] as Timestamp?;
        final bTime = b.data()['lastUsed'] as Timestamp?;
        if (aTime == null && bTime == null) return 0;
        if (aTime == null) return 1;
        if (bTime == null) return -1;
        return bTime.compareTo(aTime); // Descending order
      });

      setState(() {
        _cachedCustomerNames = customerDocs
            .map((doc) => doc['name'] as String)
            .toList();
      });

      debugPrint('Loaded ${_cachedCustomerNames.length} customer names');
    } catch (e) {
      debugPrint('Error loading customer names: $e');
      // If there's an error, show a user-friendly message
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Could not load customer history: $e'),
            backgroundColor: Colors.orange,
          ),
        );
      }
    }
  }

  /// Load business data from user profile
  Future<void> _loadBusinessData() async {
    try {
      final userId = FirebaseAuth.instance.currentUser?.uid;
      if (userId != null) {
        final userDoc = await _firestore.collection('users').doc(userId).get();
        if (userDoc.exists) {
          final userData = userDoc.data()!;
          setState(() {
            _businessName = userData['businessName'] ?? '';
            _businessPhone = userData['phone'] ?? '';
            _businessEmail = userData['email'] ?? '';
            _bankName = userData['bankName'] ?? '';
            _accountNumber = userData['accountNumber'] ?? '';
            _ifscCode = userData['ifscCode'] ?? '';
            _accountHolderName = userData['accountHolderName'] ?? '';
            // You might want to add business address and GSTIN fields to user model
            _businessAddress =
            '${userData['businessName'] ?? 'Your Business Address'}';
            _businessGSTIN = userData['gstin'] ?? 'YOUR_GSTIN_HERE';
          });
        }
      }
    } catch (e) {
      debugPrint('Error loading business data: $e');
    }
  }

  /// Load existing sale data for editing
  Future<void> _loadSaleData() async {
    setState(() => _isLoading = true);
    try {
      DocumentSnapshot doc;
      if (widget.saleDoc != null) {
        doc = widget.saleDoc!;
      } else {
        doc = await _firestore.collection('sales').doc(widget.saleId).get();
      }

      if (doc.exists) {
        final sale = SaleMaster.fromFirestore(doc);
        _customerNameController.text = sale.customerName;
        _invoiceController.text = sale.invoice;
        _selectedDate = sale.date;
        _saleItems = List.from(sale.items);

        // Load customer address if available (you'd need to add these fields to SaleMaster)
        // For now, using placeholder logic

        // Load GST fields
        _recipientGSTINController.text = sale.recipientGSTIN ?? '';
        _selectedPlaceOfSupply = sale.placeOfSupply ?? '';
        _selectedSupplyType = sale.supplyType ?? 'INTRA';
        _selectedSaleType = sale.saleType ?? 'CASH';
        _selectedDocumentType = sale.documentType ?? 'INV';
        _isReverseCharge = sale.isReverseCharge ?? false;
        _eWayBillController.text = sale.eWayBillNo ?? '';
        _selectedTransportMode = sale.transportMode ?? 'Road';
        _distanceController.text = sale.distance?.toString() ?? '';

        _calculateOverallTotal();
        debugPrint('Sale data loaded for ID: ${widget.saleId}');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading sale: $e'),
              backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  /// Calculate overall total
  void _calculateOverallTotal() {
    double total = 0.0;
    for (var item in _saleItems) {
      total += item.itemTotal;
    }
    setState(() {
      _totalSaleAmount = total;
    });
  }

  /// Date picker
  Future<void> _selectDate(BuildContext context, bool isInvoiceDate) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: isInvoiceDate ? _selectedDate : _dueDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
    );
    if (picked != null) {
      setState(() {
        if (isInvoiceDate) {
          _selectedDate = picked;
        } else {
          _dueDate = picked;
        }
      });
    }
  }

  /// Build invoice header section
  Widget _buildInvoiceHeader() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          // -------------------------------------------------
          // Business Info + Logo + Generated By (Top Section)
          // -------------------------------------------------
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Left: Business Details
              Expanded(
                flex: 2,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _businessName.isNotEmpty ? _businessName : '',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      'GSTIN: $_businessGSTIN',
                      style: TextStyle(
                        color: Colors.grey.shade700,
                        fontSize: 12,
                      ),
                    ),
                    Text(
                      _businessPhone,
                      style: TextStyle(
                        color: Colors.grey.shade700,
                        fontSize: 12,
                      ),
                    ),
                    Text(
                      _businessEmail,
                      style: TextStyle(
                        color: Colors.grey.shade700,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(width: 20),

              // Right: Logo + Generated By
              Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // Logo Image
                  Container(
                    width: 90,
                    height: 90,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.grey.shade300),
                      image: const DecorationImage(
                        image: AssetImage('lib/assets/images/logo.jpeg'),
                        fit: BoxFit.cover,



                      ),
                    ),
                  ),

                  const SizedBox(height: 8),

                  // Generated By Text
                  const Text(
                    "Generated by Safety Zoness App",
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 12,
                      color: Colors.black87,
                    ),
                  ),
                ],
              ),
            ],
          ),

          const SizedBox(height: 20),

          // -------------------------------------------------
          // Invoice Details Section
          // -------------------------------------------------
          Row(
            children: [
              // Left Column - Invoice Details
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildDetailRow(
                      'Invoice #',
                      _invoiceController.text.isEmpty
                          ? 'INV-001'
                          : _invoiceController.text,
                    ),
                    _buildDetailRow(
                      'Invoice Date',
                      DateFormat('dd/MM/yyyy').format(_selectedDate),
                    ),
                    _buildDetailRow('Terms', _termsController.text),
                    _buildDetailRow(
                      'Due Date',
                      DateFormat('dd/MM/yyyy').format(_dueDate),
                    ),
                  ],
                ),
              ),

              // Right Column - Place of Supply
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildDetailRow(
                      'Place of Supply',
                      _selectedPlaceOfSupply.isNotEmpty
                          ? '${_stateCodes.firstWhere(
                            (state) =>
                        state['code'] == _selectedPlaceOfSupply,
                        orElse: () => {'name': 'Select State'},
                      )['name']} ($_selectedPlaceOfSupply)'
                          : 'Select Place of Supply',
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }


  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(
              '$label:',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey.shade700,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Build Bill To / Ship To section
  Widget _buildAddressSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Customer & Shipping Details',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),

          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Bill To Section
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          vertical: 8, horizontal: 12),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: const Text(
                        'Bill To',
                        style: TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 14),
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Customer Name with Autocomplete
                    Autocomplete<String>(
                      initialValue: TextEditingValue(text: _customerNameController.text),
                      optionsBuilder: (TextEditingValue textEditingValue) {
                        if (textEditingValue.text.isEmpty) {
                          return const Iterable<String>.empty();
                        }
                        return _cachedCustomerNames.where((String option) {
                          return option.toLowerCase().contains(
                              textEditingValue.text.toLowerCase());
                        });
                      },
                      onSelected: (String selection) {
                        setState(() {
                          _customerNameController.text = selection;
                        });
                        _loadCustomerDetails(selection);
                      },
                      fieldViewBuilder: (context, controller, focusNode, onEditingComplete) {
                        // Keep controller in sync with main controller
                        if (controller.text != _customerNameController.text) {
                          controller.text = _customerNameController.text;
                        }

                        // Listen to changes and sync back
                        controller.addListener(() {
                          if (_customerNameController.text != controller.text) {
                            _customerNameController.text = controller.text;
                          }
                        });

                        return TextFormField(
                          controller: controller,
                          focusNode: focusNode,
                          decoration: InputDecoration(
                            labelText: 'Customer Name *',
                            border: const OutlineInputBorder(),
                            isDense: true,
                            contentPadding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 8),
                            suffixIcon: _cachedCustomerNames.isNotEmpty
                                ? const Icon(Icons.arrow_drop_down, size: 20)
                                : null,
                            hintText: _cachedCustomerNames.isEmpty
                                ? 'No saved customers yet'
                                : 'Type or select customer',
                          ),
                          validator: (value) =>
                          value?.trim().isEmpty == true ? 'Required' : null,
                          onEditingComplete: onEditingComplete,
                        );
                      },
                      optionsViewBuilder: (context, onSelected, options) {
                        return Align(
                          alignment: Alignment.topLeft,
                          child: Material(
                            elevation: 4.0,
                            child: ConstrainedBox(
                              constraints: const BoxConstraints(
                                  maxHeight: 200, maxWidth: 300),
                              child: ListView.builder(
                                padding: const EdgeInsets.all(8.0),
                                itemCount: options.length,
                                itemBuilder: (BuildContext context, int index) {
                                  final String option = options.elementAt(index);
                                  return InkWell(
                                    onTap: () {
                                      onSelected(option);
                                    },
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(
                                          vertical: 12, horizontal: 16),
                                      decoration: BoxDecoration(
                                        border: Border(
                                          bottom: BorderSide(
                                            color: Colors.grey.shade200,
                                            width: 1,
                                          ),
                                        ),
                                      ),
                                      child: Row(
                                        children: [
                                          const Icon(Icons.person_outline,
                                              size: 18, color: Colors.grey),
                                          const SizedBox(width: 8),
                                          Expanded(
                                            child: Text(
                                              option,
                                              style: const TextStyle(fontSize: 14),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 8),

                    // Customer GSTIN
                    TextFormField(
                      controller: _recipientGSTINController,
                      decoration: const InputDecoration(
                        labelText: 'GSTIN (Optional)',
                        border: OutlineInputBorder(),
                        isDense: true,
                        contentPadding: EdgeInsets.symmetric(
                            horizontal: 12, vertical: 8),
                      ),
                      textCapitalization: TextCapitalization.characters,
                      maxLength: 15,
                      onChanged: (value) => _updateSupplyType(),
                    ),
                    const SizedBox(height: 8),

                    // Customer Address
                    TextFormField(
                      controller: _customerAddressLine1Controller,
                      decoration: const InputDecoration(
                        labelText: 'Address Line 1',
                        border: OutlineInputBorder(),
                        isDense: true,
                        contentPadding: EdgeInsets.symmetric(
                            horizontal: 12, vertical: 8),
                      ),
                    ),
                    const SizedBox(height: 8),

                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: _customerCityController,
                            decoration: const InputDecoration(
                              labelText: 'City',
                              border: OutlineInputBorder(),
                              isDense: true,
                              contentPadding: EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 8),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: TextFormField(
                            controller: _customerStateController,
                            decoration: const InputDecoration(
                              labelText: 'State',
                              border: OutlineInputBorder(),
                              isDense: true,
                              contentPadding: EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 8),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(width: 16),

              // Ship To Section
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          vertical: 8, horizontal: 12),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: const Text(
                        'Ship To',
                        style: TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 14),
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Same as Billing Checkbox
                    CheckboxListTile(
                      title: const Text(
                          'Same as Bill To', style: TextStyle(fontSize: 13)),
                      value: _sameAsBilling,
                      onChanged: (value) {
                        setState(() {
                          _sameAsBilling = value ?? false;
                          if (_sameAsBilling) {
                            _shippingAddressLine1Controller.text =
                                _customerAddressLine1Controller.text;
                            _shippingCityController.text =
                                _customerCityController.text;
                            _shippingStateController.text =
                                _customerStateController.text;
                          }
                        });
                      },
                      contentPadding: EdgeInsets.zero,
                      dense: true,
                    ),

                    if (!_sameAsBilling) ...[
                      TextFormField(
                        controller: _shippingAddressLine1Controller,
                        decoration: const InputDecoration(
                          labelText: 'Shipping Address',
                          border: OutlineInputBorder(),
                          isDense: true,
                          contentPadding: EdgeInsets.symmetric(
                              horizontal: 12, vertical: 8),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: _shippingCityController,
                              decoration: const InputDecoration(
                                labelText: 'City',
                                border: OutlineInputBorder(),
                                isDense: true,
                                contentPadding: EdgeInsets.symmetric(
                                    horizontal: 12, vertical: 8),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: TextFormField(
                              controller: _shippingStateController,
                              decoration: const InputDecoration(
                                labelText: 'State',
                                border: OutlineInputBorder(),
                                isDense: true,
                                contentPadding: EdgeInsets.symmetric(
                                    horizontal: 12, vertical: 8),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ] else
                      ...[
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.grey.shade50,
                            borderRadius: BorderRadius.circular(4),
                            border: Border.all(color: Colors.grey.shade300),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(_customerAddressLine1Controller.text.isEmpty
                                  ? 'Same as billing address'
                                  : _customerAddressLine1Controller.text),
                              if (_customerCityController.text.isNotEmpty ||
                                  _customerStateController.text.isNotEmpty)
                                Text('${_customerCityController
                                    .text}, ${_customerStateController.text}'),
                            ],
                          ),
                        ),
                      ],
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }  /// Build GST and other details
  /// Build GST and other details
  /// Build GST and other details
  Widget _buildGSTDetails() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'GST & Other Details',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),

          // First Row: Place of Supply & Supply Type
          Row(
            children: [
              // Place of Supply
              Expanded(
                child: DropdownButtonFormField<String>(
                  value: _selectedPlaceOfSupply.isEmpty
                      ? null
                      : _selectedPlaceOfSupply,
                  decoration: const InputDecoration(
                    labelText: 'Place of Supply *',
                    border: OutlineInputBorder(),
                    isDense: true,
                    contentPadding: EdgeInsets.symmetric(
                        horizontal: 12, vertical: 8),
                  ),
                  items: _stateCodes.map((state) {
                    return DropdownMenuItem<String>(
                      value: state['code'],
                      child: Text('${state['code']} - ${state['name']}',
                          style: const TextStyle(fontSize: 12)),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setState(() {
                      _selectedPlaceOfSupply = value ?? '';
                    });
                    _updateSupplyType();
                  },
                  validator: (value) => value == null ? 'Required' : null,
                ),
              ),
              const SizedBox(width: 12),

              // Supply Type - FIXED HERE
              Expanded(
                child: DropdownButtonFormField<String>(
                  value: _selectedSupplyType,
                  decoration: const InputDecoration(
                    labelText: 'Supply Type',
                    border: OutlineInputBorder(),
                    isDense: true,
                    contentPadding: EdgeInsets.symmetric(
                        horizontal: 12, vertical: 8),
                  ),
                  items: const [
                    DropdownMenuItem(
                        value: 'INTRA', child: Text('(CGST+SGST)')),
                    DropdownMenuItem(
                        value: 'INTER', child: Text('IGST)')),
                  ],
                  onChanged: (value) {
                    setState(() {
                      _selectedSupplyType = value ?? 'INTRA';
                      // Clear GST rate controllers when switching
                      _cgstRateController.clear();
                      _sgstRateController.clear();
                      _igstRateController.clear();
                    });
                    _updateAllItemsTaxStructure();
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Divider
          Divider(color: Colors.grey.shade300, thickness: 1),
          const SizedBox(height: 16),

          // Second Row: GST Rates
          const Text(
            'Override GST Rates (Optional)',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'Leave empty to use item default rates, or enter to override all items',
            style: TextStyle(
              fontSize: 11,
              fontStyle: FontStyle.italic,
              color: Colors.grey,
            ),
          ),
          const SizedBox(height: 12),

          // GST Rate Fields based on Supply Type
          if (_selectedSupplyType == 'INTRA') ...[
            // Show CGST and SGST for Intra State
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _cgstRateController,
                    decoration: const InputDecoration(
                      labelText: 'CGST Rate (%)',
                      border: OutlineInputBorder(),
                      isDense: true,
                      contentPadding: EdgeInsets.symmetric(
                          horizontal: 12, vertical: 8),
                      hintText: 'e.g., 9',
                      prefixIcon: Icon(Icons.percent, size: 18),
                    ),
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    onChanged: (value) {
                      // Auto-fill SGST with same value
                      if (value.isNotEmpty) {
                        _sgstRateController.text = value;
                      }
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextFormField(
                    controller: _sgstRateController,
                    decoration: const InputDecoration(
                      labelText: 'SGST Rate (%)',
                      border: OutlineInputBorder(),
                      isDense: true,
                      contentPadding: EdgeInsets.symmetric(
                          horizontal: 12, vertical: 8),
                      hintText: 'e.g., 9',
                      prefixIcon: Icon(Icons.percent, size: 18),
                    ),
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  ),
                ),
              ],
            ),
          ] else ...[
            // Show IGST for Inter State
            TextFormField(
              controller: _igstRateController,
              decoration: const InputDecoration(
                labelText: 'IGST Rate (%)',
                border: OutlineInputBorder(),
                isDense: true,
                contentPadding: EdgeInsets.symmetric(
                    horizontal: 12, vertical: 8),
                hintText: 'e.g., 18',
                prefixIcon: Icon(Icons.percent, size: 18),
              ),
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
            ),
          ],

          const SizedBox(height: 12),

          // Apply button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _saleItems.isEmpty ? null : _applyGSTRatesToAllItems,
              icon: const Icon(Icons.check_circle_outline, size: 18),
              label: const Text('Apply GST Rates to All Items'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF667eea),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                disabledBackgroundColor: Colors.grey.shade300,
              ),
            ),
          ),

          if (_saleItems.isEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(
                'Add items first to apply GST rates',
                style: TextStyle(
                  fontSize: 11,
                  color: Colors.grey.shade600,
                  fontStyle: FontStyle.italic,
                ),
                textAlign: TextAlign.center,
              ),
            ),
        ],
      ),
    );
  }

  /// Apply manually entered GST rates to all items
  void _applyGSTRatesToAllItems() {
    // Validate that rates are entered
    if (_selectedSupplyType == 'INTRA') {
      if (_cgstRateController.text.isEmpty || _sgstRateController.text.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please enter both CGST and SGST rates'),
            backgroundColor: Colors.orange,
          ),
        );
        return;
      }
    } else {
      if (_igstRateController.text.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please enter IGST rate'),
            backgroundColor: Colors.orange,
          ),
        );
        return;
      }
    }

    if (_saleItems.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No items to apply rates to. Please add items first.'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    // Parse rates
    final cgstRate = double.tryParse(_cgstRateController.text) ?? 0.0;
    final sgstRate = double.tryParse(_sgstRateController.text) ?? 0.0;
    final igstRate = double.tryParse(_igstRateController.text) ?? 0.0;

    // Apply to all items
    for (int i = 0; i < _saleItems.length; i++) {
      final item = _saleItems[i];

      // Recalculate tax amounts with new rates
      final cgstAmount = _selectedSupplyType == 'INTRA'
          ? item.totalTaxableValue * (cgstRate / 100)
          : 0.0;

      final sgstAmount = _selectedSupplyType == 'INTRA'
          ? item.totalTaxableValue * (sgstRate / 100)
          : 0.0;

      final igstAmount = _selectedSupplyType == 'INTER'
          ? item.totalTaxableValue * (igstRate / 100)
          : 0.0;

      final cessAmount = item.totalTaxableValue * (item.cessRate / 100);

      final itemTotal = item.totalTaxableValue + cgstAmount + sgstAmount +
          igstAmount + cessAmount;

      final newItem = SaleItem(
        itemId: item.itemId,
        itemCode: item.itemCode,
        description: item.description,
        hsnSacCode: item.hsnSacCode,
        unitOfMeasurement: item.unitOfMeasurement,
        quantity: item.quantity,
        sellingPricePerUnit: item.sellingPricePerUnit,
        cgstRate: cgstRate,
        sgstRate: sgstRate,
        igstRate: igstRate,
        cessRate: item.cessRate,
        totalTaxableValue: item.totalTaxableValue,
        integratedTaxAmount: igstAmount.toDouble(),
        centralTaxAmount: cgstAmount.toDouble(),
        stateTaxAmount: sgstAmount.toDouble(),
        cessAmount: cessAmount.toDouble(),
        itemTotal: itemTotal.toDouble(),
        supplyType: _selectedSupplyType,
      );

      _saleItems[i] = newItem;
    }

    setState(() {
      _calculateOverallTotal();
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'GST rates applied to ${_saleItems.length} item(s) successfully',
        ),
        backgroundColor: Colors.green,
      ),
    );
  }
  /// Build bank details section
  Widget _buildBankDetailsSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius: BorderRadius.circular(4),
            ),
            child: const Text(
              'Bank Details',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
            ),
          ),
          const SizedBox(height: 12),

          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Bank: $_bankName', style: const TextStyle(fontSize: 12)),
              Text('A/C No: $_accountNumber',
                  style: const TextStyle(fontSize: 12)),
              Text('IFSC: $_ifscCode', style: const TextStyle(fontSize: 12)),
              const SizedBox(height: 8),
              const Text(
                'THANKS FOR YOUR BUSINESS.',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// Build signature section
  Widget _buildSignatureSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          // Signature area
          Container(
            width: double.infinity,
            height: _isSignaturePadVisible ? 200 : 80,
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey.shade300),
              borderRadius: BorderRadius.circular(4),
              color: Colors.grey.shade50,
            ),
            child: _buildSignatureContent(),
          ),
          const SizedBox(height: 8),

          // Action buttons
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              if (_isSignaturePadVisible) ...[
                // Clear signature
                TextButton.icon(
                  onPressed: () {
                    _signatureController?.clear();
                  },
                  icon: const Icon(Icons.clear, size: 16),
                  label: const Text('Clear'),
                  style: TextButton.styleFrom(
                    foregroundColor: Colors.red,
                    textStyle: const TextStyle(fontSize: 12),
                  ),
                ),
                const SizedBox(width: 8),
                // Save signature
                ElevatedButton.icon(
                  onPressed: _saveSignature,
                  icon: const Icon(Icons.save, size: 16),
                  label: const Text('Save'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                    textStyle: const TextStyle(fontSize: 12),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 4),
                  ),
                ),
              ] else
                ...[
                  // Upload photo button
                  TextButton.icon(
                    onPressed: _uploadSignatureImage,
                    icon: const Icon(Icons.photo_camera, size: 16),
                    label: const Text('Upload'),
                    style: TextButton.styleFrom(
                      foregroundColor: Colors.blue,
                      textStyle: const TextStyle(fontSize: 12),
                    ),
                  ),
                  const SizedBox(width: 8),
                  // Digital sign button
                  ElevatedButton.icon(
                    onPressed: _showSignaturePad,
                    icon: const Icon(Icons.edit, size: 16),
                    label: const Text('Sign'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF667eea),
                      foregroundColor: Colors.white,
                      textStyle: const TextStyle(fontSize: 12),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 4),
                    ),
                  ),
                ],
            ],
          ),
          const SizedBox(height: 4),

          // Signature label
          Container(
            width: 200,
            height: 1,
            color: Colors.grey.shade400,
          ),
          const SizedBox(height: 4),
          const Text(
            'Authorized Signature',
            style: TextStyle(fontSize: 12, color: Colors.grey),
          ),
        ],
      ),
    );
  }

// Helper method to build signature content
  Widget _buildSignatureContent() {
    if (_isSignaturePadVisible) {
      // Show signature pad
      _signatureController ??= SignatureController(
        penStrokeWidth: 2,
        penColor: Colors.black,
        exportBackgroundColor: Colors.transparent,
      );

      return Signature(
        controller: _signatureController!,
        backgroundColor: Colors.transparent,
      );
    } else if (_signatureImageFile != null || _signatureImageBytes != null) {
      // Show uploaded/saved signature
      return Container(
        width: double.infinity,
        height: double.infinity,
        padding: const EdgeInsets.all(8),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            Expanded(
              child: _signatureImageFile != null
                  ? Image.file(
                _signatureImageFile!,
                fit: BoxFit.contain,
                height: 60,
              )
                  : _signatureImageBytes != null
                  ? Image.memory(
                _signatureImageBytes!,
                fit: BoxFit.contain,
                height: 60,
              )
                  : const SizedBox(),
            ),
            // Remove signature button
            IconButton(
              onPressed: _removeSignature,
              icon: const Icon(Icons.close, size: 16, color: Colors.red),
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
            ),
          ],
        ),
      );
    } else {
      // Show empty state
      return const Center(
        child: Text(
          'No signature added',
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey,
            fontStyle: FontStyle.italic,
          ),
        ),
      );
    }
  }

// Method to upload signature image
  Future<void> _uploadSignatureImage() async {
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 800,
        maxHeight: 400,
        imageQuality: 85,
      );

      if (image != null) {
        setState(() {
          _signatureImageFile = File(image.path);
          _signatureImageBytes = null; // Clear any drawn signature
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Signature image uploaded successfully'),
              backgroundColor: Colors.green,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error uploading image: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

// Method to show signature pad
  void _showSignaturePad() {
    setState(() {
      _isSignaturePadVisible = true;
      _signatureImageFile = null; // Clear any uploaded image
    });
  }

// Method to save drawn signature
  Future<void> _saveSignature() async {
    if (_signatureController != null) {
      if (_signatureController!.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please draw a signature first'),
            backgroundColor: Colors.orange,
          ),
        );
        return;
      }

      try {
        final Uint8List? signature = await _signatureController!.toPngBytes();
        if (signature != null) {
          setState(() {
            _signatureImageBytes = signature;
            _isSignaturePadVisible = false;
          });

          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Signature saved successfully'),
                backgroundColor: Colors.green,
              ),
            );
          }
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error saving signature: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

// Method to remove signature
  void _removeSignature() {
    setState(() {
      _signatureImageFile = null;
      _signatureImageBytes = null;
      _isSignaturePadVisible = false;
      _signatureController?.clear();
    });

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Signature removed'),
          backgroundColor: Colors.orange,
        ),
      );
    }
  }




// Add this to your dispose method
//   @override
//   void dispose() {
//     // ... your existing dispose code ...
//     _signatureController?.dispose();
//     super.dispose();
//   }

  /// Auto-determine supply type based on GSTIN
  void _updateSupplyType() {
    if (_recipientGSTINController.text.length >= 2 &&
        _selectedPlaceOfSupply.isNotEmpty) {
      final recipientStateCode = _recipientGSTINController.text.substring(0, 2);
      final posStateCode = _selectedPlaceOfSupply;

      setState(() {
        _selectedSupplyType =
        (recipientStateCode == posStateCode) ? 'INTRA' : 'INTER';
      });

      _updateAllItemsTaxStructure();
    }
  }

  /// Update tax structure for all items based on supply type
  void _updateAllItemsTaxStructure() {
    for (int i = 0; i < _saleItems.length; i++) {
      final item = _saleItems[i];

      // Recalculate tax amounts based on supply type
      final cgstAmount = _selectedSupplyType == 'INTRA' ?
      item.totalTaxableValue * (item.cgstRate / 100) : 0.0;
      final sgstAmount = _selectedSupplyType == 'INTRA' ?
      item.totalTaxableValue * (item.sgstRate / 100) : 0.0;
      final igstAmount = _selectedSupplyType == 'INTER' ?
      item.totalTaxableValue * (item.igstRate / 100) : 0.0;
      final cessAmount = item.totalTaxableValue * (item.cessRate / 100);

      final itemTotal = item.totalTaxableValue + cgstAmount + sgstAmount +
          igstAmount + cessAmount;

      final newItem = SaleItem(
        itemId: item.itemId,
        itemCode: item.itemCode,
        description: item.description,
        hsnSacCode: item.hsnSacCode,
        unitOfMeasurement: item.unitOfMeasurement,
        quantity: item.quantity,
        sellingPricePerUnit: item.sellingPricePerUnit,
        cgstRate: item.cgstRate,
        sgstRate: item.sgstRate,
        igstRate: item.igstRate,
        cessRate: item.cessRate,
        totalTaxableValue: item.totalTaxableValue,
        integratedTaxAmount: igstAmount.toDouble(),
        centralTaxAmount: cgstAmount.toDouble(),
        stateTaxAmount: sgstAmount.toDouble(),
        cessAmount: cessAmount.toDouble(),
        itemTotal: itemTotal.toDouble(),
        supplyType: _selectedSupplyType,
      );
      _saleItems[i] = newItem;
    }
    _calculateOverallTotal();
  }

  // Include the existing methods for item management and saving
  // (keeping _addItemToSale, _calculateAndAddSaleItem, _removeItemFromSale, _saveSale methods from original code)

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.saleId != null ? 'Edit Sale' : 'New Sale'),
        backgroundColor: const Color(0xFF667eea),
        foregroundColor: Colors.white,
      ),
      body: _isLoading && widget.saleId != null
          ? const Center(child: CircularProgressIndicator())
          : Form(
        key: _formKey,
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Invoice Header
                    _buildInvoiceHeader(),
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.blue.shade50,
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(color: Colors.blue.shade200),
                      ),
                      child: Row(
                        children: [
                          const Text(
                            'Payment Type:',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Row(
                              children: [
                                Radio<String>(
                                  value: 'CASH',
                                  groupValue: _selectedSaleType,
                                  onChanged: (value) {
                                    setState(() {
                                      _selectedSaleType = value!;
                                    });
                                  },
                                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                ),
                                const Text('Cash', style: TextStyle(fontSize: 13)),
                                const SizedBox(width: 24),
                                Radio<String>(
                                  value: 'CREDIT',
                                  groupValue: _selectedSaleType,
                                  onChanged: (value) {
                                    setState(() {
                                      _selectedSaleType = value!;
                                    });
                                  },
                                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                ),
                                const Text('Credit', style: TextStyle(fontSize: 13)),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    // Basic Invoice Fieldsconst SizedBox(height: 16),
                    const SizedBox(height: 16),

                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: _invoiceController,
                            decoration: const InputDecoration(
                              labelText: 'Invoice Number',
                              border: OutlineInputBorder(),
                              isDense: true,
                            ),
                            // Keep it editable - NO enabled: false
                            validator: (value) {
                              if (value == null || value.trim().isEmpty) {
                                return 'Required';
                              }
                              return null;
                            },
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: TextFormField(
                            controller: _termsController,
                            decoration: const InputDecoration(
                              labelText: 'Terms',
                              border: OutlineInputBorder(),
                              isDense: true,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    Row(
                      children: [
                        Expanded(
                          child: GestureDetector(
                            onTap: () => _selectDate(context, true),
                            child: AbsorbPointer(
                              child: TextFormField(
                                decoration: InputDecoration(
                                  labelText: 'Invoice Date',
                                  border: const OutlineInputBorder(),
                                  suffixIcon: const Icon(Icons.calendar_today),
                                  isDense: true,
                                ),
                                controller: TextEditingController(
                                  text: DateFormat('dd/MM/yyyy').format(
                                      _selectedDate),
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: GestureDetector(
                            onTap: () => _selectDate(context, false),
                            child: AbsorbPointer(
                              child: TextFormField(
                                decoration: InputDecoration(
                                  labelText: 'Due Date',
                                  border: const OutlineInputBorder(),
                                  suffixIcon: const Icon(Icons.calendar_today),
                                  isDense: true,
                                ),
                                controller: TextEditingController(
                                  text: DateFormat('dd/MM/yyyy').format(
                                      _dueDate),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Customer & Shipping Address
                    _buildAddressSection(),
                    const SizedBox(height: 16),

                    // GST Details
                    _buildGSTDetails(),
                    const SizedBox(height: 16),

                    // Items Section
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Items',
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight
                              .bold),
                        ),
                        ElevatedButton.icon(
                          onPressed: _addItemToSale,
                          icon: const Icon(Icons.add),
                          label: const Text('Add Item'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF4CAF50),
                            foregroundColor: Colors.white,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    // Items Table
                    // Items Table
                    _saleItems.isEmpty
                        ? Container(
                      padding: const EdgeInsets.all(32),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey.shade300),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Center(
                        child: Text(
                          'No items added yet. Click "Add Item" to start.',
                          style: TextStyle(color: Colors.grey),
                        ),
                      ),
                    )
                        : Container(
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey.shade300),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: DataTable(
                          columnSpacing: 12,
                          horizontalMargin: 12,
                          columns: [
                            DataColumn(label: Text('Sr', style: TextStyle(
                                fontWeight: FontWeight.bold, fontSize: 12))),
                            DataColumn(label: Text('Item & Description',
                                style: TextStyle(fontWeight: FontWeight.bold,
                                    fontSize: 12))),
                            DataColumn(label: Text('Qty', style: TextStyle(
                                fontWeight: FontWeight.bold, fontSize: 12))),
                            DataColumn(label: Text('Rate', style: TextStyle(
                                fontWeight: FontWeight.bold, fontSize: 12))),

                            // 👇 ADD CONDITIONAL COLUMNS BASED ON SUPPLY TYPE
                            if (_selectedSupplyType == 'INTRA') ...[
                              DataColumn(label: Text('CGST', style: TextStyle(
                                  fontWeight: FontWeight.bold, fontSize: 12))),
                              DataColumn(label: Text('SGST', style: TextStyle(
                                  fontWeight: FontWeight.bold, fontSize: 12))),
                            ] else ...[
                              DataColumn(label: Text('IGST', style: TextStyle(
                                  fontWeight: FontWeight.bold, fontSize: 12))),
                            ],
                            // 👆 END OF CONDITIONAL COLUMNS

                            DataColumn(label: Text('Amount', style: TextStyle(
                                fontWeight: FontWeight.bold, fontSize: 12))),
                            DataColumn(label: Text('Actions', style: TextStyle(
                                fontWeight: FontWeight.bold, fontSize: 12))),
                          ],
                          rows: List<DataRow>.generate(
                            _saleItems.length,
                                (index) {
                              final item = _saleItems[index];
                              return DataRow(
                                cells: [
                                  DataCell(Text((index + 1).toString(),
                                      style: const TextStyle(fontSize: 11))),
                                  DataCell(
                                    Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Text(item.description,
                                            style: const TextStyle(fontSize: 11,
                                                fontWeight: FontWeight.w600)),
                                        Text('HSN: ${item.hsnSacCode}',
                                            style: TextStyle(fontSize: 10,
                                                color: Colors.grey.shade600)),
                                      ],
                                    ),
                                  ),
                                  DataCell(Text(
                                      '${item.quantity.toStringAsFixed(1)} ${item.unitOfMeasurement}',
                                      style: const TextStyle(fontSize: 11))),
                                  DataCell(Text('₹${item.sellingPricePerUnit.toStringAsFixed(2)}',
                                      style: const TextStyle(fontSize: 11))),

                                  // 👇 ADD CONDITIONAL TAX CELLS BASED ON SUPPLY TYPE
                                  if (_selectedSupplyType == 'INTRA') ...[
                                    // CGST Cell
                                    DataCell(Text(
                                        '${item.cgstRate.toStringAsFixed(1)}%\n₹${item.centralTaxAmount.toStringAsFixed(2)}',
                                        style: const TextStyle(fontSize: 10))),
                                    // SGST Cell
                                    DataCell(Text(
                                        '${item.sgstRate.toStringAsFixed(1)}%\n₹${item.stateTaxAmount.toStringAsFixed(2)}',
                                        style: const TextStyle(fontSize: 10))),
                                  ] else ...[
                                    // IGST Cell
                                    DataCell(Text(
                                        '${item.igstRate.toStringAsFixed(1)}%\n₹${item.integratedTaxAmount.toStringAsFixed(2)}',
                                        style: const TextStyle(fontSize: 10))),
                                  ],
                                  // 👆 END OF CONDITIONAL TAX CELLS

                                  DataCell(Text(
                                      '₹${item.itemTotal.toStringAsFixed(2)}',
                                      style: const TextStyle(fontSize: 11,
                                          fontWeight: FontWeight.bold))),
                                  DataCell(
                                    Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        IconButton(
                                          icon: const Icon(Icons.edit, size: 18,
                                              color: Colors.orange),
                                          onPressed: () =>
                                              _addItemToSale(existingItem: item,
                                                  index: index),
                                        ),
                                        IconButton(
                                          icon: const Icon(
                                              Icons.delete, size: 18,
                                              color: Colors.red),
                                          onPressed: () =>
                                              _removeItemFromSale(index),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              );
                            },
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Total Section
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade50,
                        border: Border.all(color: Colors.grey.shade300),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                  'Sub Total:', style: TextStyle(fontSize: 14)),
                              Text('₹${(_totalSaleAmount - _calculateTotalTax())
                                  .toStringAsFixed(2)}',
                                  style: const TextStyle(fontSize: 14)),
                            ],
                          ),
                          if (_selectedSupplyType == 'INTRA') ...[
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text('CGST:', style: TextStyle(
                                    fontSize: 12, color: Colors.grey.shade700)),
                                Text('₹${_calculateCGST().toStringAsFixed(2)}',
                                    style: TextStyle(fontSize: 12,
                                        color: Colors.grey.shade700)),
                              ],
                            ),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text('SGST:', style: TextStyle(
                                    fontSize: 12, color: Colors.grey.shade700)),
                                Text('₹${_calculateSGST().toStringAsFixed(2)}',
                                    style: TextStyle(fontSize: 12,
                                        color: Colors.grey.shade700)),
                              ],
                            ),
                          ] else
                            ...[
                              Row(
                                mainAxisAlignment: MainAxisAlignment
                                    .spaceBetween,
                                children: [
                                  Text('IGST:', style: TextStyle(fontSize: 12,
                                      color: Colors.grey.shade700)),
                                  Text(
                                      '₹${_calculateIGST().toStringAsFixed(2)}',
                                      style: TextStyle(fontSize: 12,
                                          color: Colors.grey.shade700)),
                                ],
                              ),
                            ],
                          const Divider(),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text('Total:', style: TextStyle(
                                  fontSize: 16, fontWeight: FontWeight.bold)),
                              Text('₹${_totalSaleAmount.toStringAsFixed(2)}',
                                  style: const TextStyle(fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: Color(0xFF667eea))),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Bank Details
                    _buildBankDetailsSection(),
                    const SizedBox(height: 16),

                    // Signature Section
                    _buildSignatureSection(),
                  ],
                ),
              ),
            ),

            // Save Button
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _saveSale,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF667eea),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: _isLoading
                      ? const SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                      : Text(
                    widget.saleId != null ? 'Update Sale' : 'Save Sale',
                    style: const TextStyle(fontSize: 18),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Tax calculation helper methods
  double _calculateTotalTax() {
    return _saleItems.fold(0.0, (sum, item) =>
    sum + item.centralTaxAmount + item.stateTaxAmount +
        item.integratedTaxAmount + item.cessAmount);
  }

  double _calculateCGST() {
    return _saleItems.fold(0.0, (sum, item) => sum + item.centralTaxAmount);
  }

  double _calculateSGST() {
    return _saleItems.fold(0.0, (sum, item) => sum + item.stateTaxAmount);
  }

  double _calculateIGST() {
    return _saleItems.fold(0.0, (sum, item) => sum + item.integratedTaxAmount);
  }

  // Add the missing methods from the original file
  Future<void> _addItemToSale({SaleItem? existingItem, int? index}) async {
    String? selectedItemId;
    TextEditingController quantityController = TextEditingController(
        text: existingItem?.quantity.toString() ?? '1.0');
    ItemMaster? selectedItemMaster;
    final _itemDialogFormKey = GlobalKey<FormState>();

    // 👇 ADD THESE GST CONTROLLERS HERE (Right after the existing controllers)
    final cgstController = TextEditingController(
        text: existingItem?.cgstRate.toString() ?? '9'
    );
    final sgstController = TextEditingController(
        text: existingItem?.sgstRate.toString() ?? '9'
    );
    final igstController = TextEditingController(
        text: existingItem?.igstRate.toString() ?? '18'
    );
    // 👆 END OF GST CONTROLLERS

    if (existingItem != null) {
      selectedItemId = existingItem.itemId;
      try {
        final itemDoc = await _firestore
            .collection('items')
            .doc(selectedItemId)
            .get();
        if (itemDoc.exists) {
          selectedItemMaster = ItemMaster.fromFirestore(itemDoc);

          // 👇 UPDATE CONTROLLERS WITH ITEM MASTER DATA
          if (existingItem == null) {
            cgstController.text = selectedItemMaster.cgstRate.toString();
            sgstController.text = selectedItemMaster.sgstRate.toString();
            igstController.text = selectedItemMaster.igstRate.toString();
          }
          // 👆 END OF UPDATE
        }
      } catch (e) {
        debugPrint('Error fetching existing item master: $e');
      }
    }

    await showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setStateSB) {
            return AlertDialog(
              title: Text(
                  existingItem == null ? 'Add Item to Sale' : 'Edit Sale Item'),
              content: Form(
                key: _itemDialogFormKey,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Item Dropdown
                      FutureBuilder<QuerySnapshot>(
                        future: _firestore.collection('items').where(
                            'userId', isEqualTo: widget.userId).where(
                            'isActive', isEqualTo: true).get(),
                        builder: (context, snapshot) {
                          if (snapshot.connectionState ==
                              ConnectionState.waiting) {
                            return const CircularProgressIndicator();
                          }
                          if (snapshot.hasError) {
                            debugPrint(
                                'Add Item Dialog: Error loading items: ${snapshot
                                    .error}');
                            return Text(
                                'Error loading items: ${snapshot.error}');
                          }
                          final items = snapshot.data!.docs
                              .map((doc) => ItemMaster.fromFirestore(doc))
                              .toList();

                          if (items.isEmpty) {
                            return const Padding(
                              padding: EdgeInsets.symmetric(vertical: 16.0),
                              child: Text(
                                'No active items available. Please add items in the "Items" tab first.',
                                style: TextStyle(color: Colors.red,
                                    fontStyle: FontStyle.italic),
                                textAlign: TextAlign.center,
                              ),
                            );
                          }

                          return DropdownButtonFormField<String>(
                            value: selectedItemId,
                            decoration: const InputDecoration(
                              labelText: 'Select Item',
                              border: OutlineInputBorder(),
                              filled: true,
                              fillColor: Colors.white,
                            ),
                            items: items.map((item) {
                              return DropdownMenuItem<String>(
                                value: item.id,
                                child: Text(item.description),
                              );
                            }).toList(),
                            onChanged: (value) {
                              setStateSB(() {
                                selectedItemId = value;
                                selectedItemMaster = items.firstWhere((item) =>
                                item.id == value);

                                // 👇 UPDATE GST CONTROLLERS WHEN ITEM CHANGES
                                if (selectedItemMaster != null) {
                                  cgstController.text = selectedItemMaster!.cgstRate.toString();
                                  sgstController.text = selectedItemMaster!.sgstRate.toString();
                                  igstController.text = selectedItemMaster!.igstRate.toString();
                                }
                                // 👆 END OF UPDATE
                              });
                            },
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Please select an item';
                              }
                              return null;
                            },
                          );
                        },
                      ),
                      const SizedBox(height: 16),

                      // Quantity Field
                      TextFormField(
                        controller: quantityController,
                        keyboardType: const TextInputType.numberWithOptions(
                            decimal: true),
                        decoration: const InputDecoration(
                          labelText: 'Quantity',
                          border: OutlineInputBorder(),
                          filled: true,
                          fillColor: Colors.white,
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Please enter quantity';
                          }
                          final parsed = double.tryParse(value);
                          if (parsed == null || parsed <= 0) {
                            return 'Please enter a valid positive number';
                          }
                          return null;
                        },
                      ),

                      // 👇 PASTE THE GST RATE FIELDS HERE
                      const SizedBox(height: 16),

                      // GST Rate Fields
                      const Text(
                        'GST Rates',
                        style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                      ),
                      const SizedBox(height: 8),

                      if (_selectedSupplyType == 'INTRA') ...[
                        Row(
                          children: [
                            Expanded(
                              child: TextFormField(
                                controller: cgstController,
                                decoration: const InputDecoration(
                                  labelText: 'CGST %',
                                  border: OutlineInputBorder(),
                                  filled: true,
                                  fillColor: Colors.white,
                                  isDense: true,
                                ),
                                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                onChanged: (value) {
                                  // Auto-update preview
                                  setStateSB(() {});
                                },
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: TextFormField(
                                controller: sgstController,
                                decoration: const InputDecoration(
                                  labelText: 'SGST %',
                                  border: OutlineInputBorder(),
                                  filled: true,
                                  fillColor: Colors.white,
                                  isDense: true,
                                ),
                                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                onChanged: (value) {
                                  setStateSB(() {});
                                },
                              ),
                            ),
                          ],
                        ),
                      ] else ...[
                        TextFormField(
                          controller: igstController,
                          decoration: const InputDecoration(
                            labelText: 'IGST %',
                            border: OutlineInputBorder(),
                            filled: true,
                            fillColor: Colors.white,
                            isDense: true,
                          ),
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          onChanged: (value) {
                            setStateSB(() {});
                          },
                        ),
                      ],
                      // 👆 END OF GST RATE FIELDS

                      const SizedBox(height: 16),

                      // Preview Info
                      if (selectedItemMaster != null)
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.grey.shade50,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.grey.shade300),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Item Details',
                                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Selling Price: ₹${selectedItemMaster!.sellingPrice.toStringAsFixed(2)}',
                                style: TextStyle(color: Colors.grey.shade700, fontSize: 12),
                              ),
                              Text(
                                'Current CGST: ${cgstController.text}%',
                                style: TextStyle(color: Colors.grey.shade700, fontSize: 12),
                              ),
                              Text(
                                'Current SGST: ${sgstController.text}%',
                                style: TextStyle(color: Colors.grey.shade700, fontSize: 12),
                              ),
                              Text(
                                'Current IGST: ${igstController.text}%',
                                style: TextStyle(color: Colors.grey.shade700, fontSize: 12),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: () {
                    if (_itemDialogFormKey.currentState!.validate()) {
                      if (selectedItemId != null &&
                          quantityController.text.isNotEmpty) {
                        final quantity = double.parse(quantityController.text);

                        // 👇 PARSE GST RATES
                        final cgst = double.tryParse(cgstController.text);
                        final sgst = double.tryParse(sgstController.text);
                        final igst = double.tryParse(igstController.text);
                        // 👆 END PARSE

                        _calculateAndAddSaleItem(
                          selectedItemId!,
                          quantity,
                          existingItem,
                          index,
                          customCgstRate: cgst,
                          customSgstRate: sgst,
                          customIgstRate: igst,
                        );
                        Navigator.of(context).pop();
                      }
                    } else {
                      debugPrint(
                          'Add/Edit Sale Item Dialog: Form validation failed.');
                    }
                  },
                  child: Text(existingItem == null ? 'Add' : 'Update'),
                ),
              ],
            );
          },
        );
      },
    );
  }
  Future<void> _calculateAndAddSaleItem(
      String itemId,
      double quantity,
      SaleItem? existingItem,
      int? index, {
        double? customCgstRate,
        double? customSgstRate,
        double? customIgstRate,
      }) async {
    try {
      final itemDoc = await _firestore.collection('items').doc(itemId).get();
      if (!itemDoc.exists) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Selected item not found'),
                backgroundColor: Colors.red),
          );
        }
        debugPrint('Error: Selected item not found for ID: $itemId');
        return;
      }

      final itemMaster = ItemMaster.fromFirestore(itemDoc);
      final sellingPricePerUnit = itemMaster.sellingPrice;
      final totalTaxableValue = sellingPricePerUnit * quantity;

      // 👇 USE CUSTOM RATES IF PROVIDED, OTHERWISE USE ITEM MASTER RATES
      final cgstRate = customCgstRate ?? itemMaster.cgstRate;
      final sgstRate = customSgstRate ?? itemMaster.sgstRate;
      final igstRate = customIgstRate ?? itemMaster.igstRate;
      // 👆 END

      final cgstAmount = _selectedSupplyType == 'INTRA'
          ? totalTaxableValue * (cgstRate / 100)
          : 0.0;

      final sgstAmount = _selectedSupplyType == 'INTRA'
          ? totalTaxableValue * (sgstRate / 100)
          : 0.0;

      final igstAmount = _selectedSupplyType == 'INTER'
          ? totalTaxableValue * (igstRate / 100)
          : 0.0;

      final cessAmount = totalTaxableValue * (itemMaster.cessRate / 100);

      final itemTotal = totalTaxableValue + cgstAmount + sgstAmount +
          igstAmount + cessAmount;

      final newSaleItem = SaleItem(
        itemId: itemMaster.id,
        itemCode: itemMaster.itemCode,
        description: itemMaster.description,
        hsnSacCode: itemMaster.hsnSacCode,
        unitOfMeasurement: itemMaster.unitOfMeasurement,
        quantity: quantity,
        sellingPricePerUnit: sellingPricePerUnit,
        cgstRate: cgstRate,  // 👈 Use the calculated rate
        sgstRate: sgstRate,  // 👈 Use the calculated rate
        igstRate: igstRate,  // 👈 Use the calculated rate
        cessRate: itemMaster.cessRate,
        totalTaxableValue: totalTaxableValue.toDouble(),
        integratedTaxAmount: igstAmount.toDouble(),
        centralTaxAmount: cgstAmount.toDouble(),
        stateTaxAmount: sgstAmount.toDouble(),
        cessAmount: cessAmount.toDouble(),
        itemTotal: itemTotal.toDouble(),
        supplyType: _selectedSupplyType,
      );

      setState(() {
        if (existingItem != null && index != null) {
          _saleItems[index] = newSaleItem;
          debugPrint('Sale item updated: ${newSaleItem.description}');
        } else {
          _saleItems.add(newSaleItem);
          debugPrint('Sale item added: ${newSaleItem.description}');
        }
        _calculateOverallTotal();
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error adding item: $e'),
              backgroundColor: Colors.red),
        );
      }
      debugPrint('Error calculating and adding sale item: $e');
    }
  }

  void _removeItemFromSale(int index) {
    final removedItemDescription = _saleItems[index].description;
    setState(() {
      _saleItems.removeAt(index);
      _calculateOverallTotal();
    });
    debugPrint('Sale item removed: $removedItemDescription');
  }

  Future<void> _saveSale() async {
    if (!_formKey.currentState!.validate()) {
      debugPrint('Save Sale: Form validation failed.');
      return;
    }
    if (_saleItems.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please add at least one item to the sale'),
            backgroundColor: Colors.orange,
            duration: Duration(seconds: 3),
          ),
        );
      }
      debugPrint('Save Sale: No items added to sale.');
      return;
    }

    setState(() => _isLoading = true);

    // ADD THIS LINE: Save customer details before saving sale
    await _saveCustomerDetails();
    await _loadCustomerNames(); // Refresh the list after saving


    try {
      // ... rest of your existing code
      String gstr1Section = 'B2C_SMALL';
      if (_recipientGSTINController.text
          .trim()
          .isNotEmpty) {
        gstr1Section = 'B2B';
      } else if (_totalSaleAmount > 250000) {
        gstr1Section = 'B2C_LARGE';
      }

      final saleData = SaleMaster(
        id: widget.saleId ?? '',
        userId: widget.userId,
        invoice: _invoiceController.text.trim(),
        customerName: _customerNameController.text.trim(),
        date: _selectedDate,
        total: _totalSaleAmount,
        items: _saleItems,
        recipientGSTIN: _recipientGSTINController.text.trim().toUpperCase(),
        placeOfSupply: _selectedPlaceOfSupply,
        supplyType: _selectedSupplyType,
        saleType: _selectedSaleType,
        gstr1Section: gstr1Section,
        eWayBillNo: _eWayBillController.text
            .trim()
            .isEmpty ? null : _eWayBillController.text.trim(),
        transportMode: _totalSaleAmount > 50000 ? _selectedTransportMode : null,
        distance: _distanceController.text
            .trim()
            .isEmpty ? null : double.tryParse(_distanceController.text.trim()),
        documentType: _selectedDocumentType,
        isReverseCharge: _isReverseCharge,
      ).toFirestore();

      if (widget.saleId != null && widget.saleId!.isNotEmpty) {
        await _firestore.collection('sales').doc(widget.saleId).update(
            saleData);
        debugPrint('Sale updated successfully for ID: ${widget.saleId}');
      } else {
        final docRef = await _firestore.collection('sales').add(saleData);
        debugPrint('Sale added successfully with ID: ${docRef.id}');
      }

      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(widget.saleId != null
                ? 'Sale updated successfully'
                : 'Sale added successfully'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error saving sale: $e'),
              backgroundColor: Colors.red),
        );
      }
      debugPrint('Error saving sale: $e');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  void dispose() {
    // All your existing controller disposals
    _customerNameController.dispose();
    _invoiceController.dispose();
    _termsController.dispose();
    _customerAddressLine1Controller.dispose();
    _customerAddressLine2Controller.dispose();
    _customerCityController.dispose();
    _customerStateController.dispose();
    _customerPincodeController.dispose();
    _shippingAddressLine1Controller.dispose();
    _shippingAddressLine2Controller.dispose();
    _shippingCityController.dispose();
    _shippingStateController.dispose();
    _shippingPincodeController.dispose();
    _recipientGSTINController.dispose();
    _eWayBillController.dispose();
    _distanceController.dispose();

    // Add signature controller disposal
    _signatureController?.dispose();

    super.dispose();
  }
}