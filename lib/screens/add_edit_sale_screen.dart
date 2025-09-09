import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
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
  final TextEditingController _termsController = TextEditingController(text: 'Net 30');
  DateTime _selectedDate = DateTime.now();
  DateTime _dueDate = DateTime.now().add(Duration(days: 30));
  List<SaleItem> _saleItems = [];
  double _totalSaleAmount = 0.0;
  bool _isLoading = false;

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

  // GST dropdowns
  String _selectedPlaceOfSupply = '';
  String _selectedSupplyType = 'INTRA';
  String _selectedSaleType = 'CASH';
  String _selectedDocumentType = 'INV';
  String _selectedTransportMode = 'Road';
  bool _isReverseCharge = false;

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
    if (widget.saleId != null && widget.saleId!.isNotEmpty) {
      _loadSaleData();
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
            _businessAddress = '${userData['businessAddress'] ?? 'Your Business Address'}';
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
          SnackBar(content: Text('Error loading sale: $e'), backgroundColor: Colors.red),
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
          // Business Info and Tax Invoice Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Business Details (Left Side)
              Expanded(
                flex: 2,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _businessName.isNotEmpty ? _businessName : 'Your Business Name',
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _businessAddress,
                      style: TextStyle(color: Colors.grey.shade700, fontSize: 12),
                    ),
                    Text(
                      'GSTIN: $_businessGSTIN',
                      style: TextStyle(color: Colors.grey.shade700, fontSize: 12),
                    ),
                    Text(
                      _businessPhone,
                      style: TextStyle(color: Colors.grey.shade700, fontSize: 12),
                    ),
                    Text(
                      _businessEmail,
                      style: TextStyle(color: Colors.grey.shade700, fontSize: 12),
                    ),
                  ],
                ),
              ),

              // Tax Invoice Title (Right Side)
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey.shade400),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: const Text(
                  'TAX INVOICE',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 2,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Invoice Details Row
          Row(
            children: [
              // Left Column - Invoice Details
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildDetailRow('Invoice #', _invoiceController.text.isEmpty ? 'INV-001' : _invoiceController.text),
                    _buildDetailRow('Invoice Date', DateFormat('dd/MM/yyyy').format(_selectedDate)),
                    _buildDetailRow('Terms', _termsController.text),
                    _buildDetailRow('Due Date', DateFormat('dd/MM/yyyy').format(_dueDate)),
                  ],
                ),
              ),

              // Right Column - Place of Supply
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildDetailRow('Place of Supply',
                        _selectedPlaceOfSupply.isNotEmpty
                            ? '${_stateCodes.firstWhere((state) => state['code'] == _selectedPlaceOfSupply, orElse: () => {'name': 'Select State'})['name']} ($_selectedPlaceOfSupply)'
                            : 'Select Place of Supply'
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
                      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: const Text(
                        'Bill To',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Customer Name
                    TextFormField(
                      controller: _customerNameController,
                      decoration: const InputDecoration(
                        labelText: 'Customer Name *',
                        border: OutlineInputBorder(),
                        isDense: true,
                        contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      ),
                      validator: (value) => value?.trim().isEmpty == true ? 'Required' : null,
                    ),
                    const SizedBox(height: 8),

                    // Customer GSTIN
                    TextFormField(
                      controller: _recipientGSTINController,
                      decoration: const InputDecoration(
                        labelText: 'GSTIN (Optional)',
                        border: OutlineInputBorder(),
                        isDense: true,
                        contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
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
                        contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
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
                              contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
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
                              contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
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
                      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: const Text(
                        'Ship To',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Same as Billing Checkbox
                    CheckboxListTile(
                      title: const Text('Same as Bill To', style: TextStyle(fontSize: 13)),
                      value: _sameAsBilling,
                      onChanged: (value) {
                        setState(() {
                          _sameAsBilling = value ?? false;
                          if (_sameAsBilling) {
                            _shippingAddressLine1Controller.text = _customerAddressLine1Controller.text;
                            _shippingCityController.text = _customerCityController.text;
                            _shippingStateController.text = _customerStateController.text;
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
                          contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
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
                                contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
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
                                contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ] else ...[
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
                            Text(_customerAddressLine1Controller.text.isEmpty ? 'Same as billing address' : _customerAddressLine1Controller.text),
                            if (_customerCityController.text.isNotEmpty || _customerStateController.text.isNotEmpty)
                              Text('${_customerCityController.text}, ${_customerStateController.text}'),
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
  }

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

          Row(
            children: [
              // Place of Supply
              Expanded(
                child: DropdownButtonFormField<String>(
                  value: _selectedPlaceOfSupply.isEmpty ? null : _selectedPlaceOfSupply,
                  decoration: const InputDecoration(
                    labelText: 'Place of Supply *',
                    border: OutlineInputBorder(),
                    isDense: true,
                    contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  ),
                  items: _stateCodes.map((state) {
                    return DropdownMenuItem<String>(
                      value: state['code'],
                      child: Text('${state['code']} - ${state['name']}', style: const TextStyle(fontSize: 12)),
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

              // Supply Type
              Expanded(
                child: DropdownButtonFormField<String>(
                  value: _selectedSupplyType,
                  decoration: const InputDecoration(
                    labelText: 'Supply Type',
                    border: OutlineInputBorder(),
                    isDense: true,
                    contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  ),
                  items: const [
                    DropdownMenuItem(value: 'INTRA', child: Text('Intra State')),
                    DropdownMenuItem(value: 'INTER', child: Text('Inter State')),
                  ],
                  onChanged: (value) {
                    setState(() {
                      _selectedSupplyType = value ?? 'INTRA';
                    });
                    _updateAllItemsTaxStructure();
                  },
                ),
              ),
            ],
          ),
        ],
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
              Text('A/C No: $_accountNumber', style: const TextStyle(fontSize: 12)),
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
      height: 80,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          const Spacer(),
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

  /// Auto-determine supply type based on GSTIN
  void _updateSupplyType() {
    if (_recipientGSTINController.text.length >= 2 && _selectedPlaceOfSupply.isNotEmpty) {
      final recipientStateCode = _recipientGSTINController.text.substring(0, 2);
      final posStateCode = _selectedPlaceOfSupply;

      setState(() {
        _selectedSupplyType = (recipientStateCode == posStateCode) ? 'INTRA' : 'INTER';
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

      final itemTotal = item.totalTaxableValue + cgstAmount + sgstAmount + igstAmount + cessAmount;

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

                    // Basic Invoice Fields
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
                            validator: (value) => value?.trim().isEmpty == true ? 'Required' : null,
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
                                  text: DateFormat('dd/MM/yyyy').format(_selectedDate),
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
                                  text: DateFormat('dd/MM/yyyy').format(_dueDate),
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
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
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
                            DataColumn(label: Text('Sr', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
                            DataColumn(label: Text('Item & Description', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
                            DataColumn(label: Text('Qty', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
                            DataColumn(label: Text('Rate', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
                            DataColumn(label: Text('CGST', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
                            DataColumn(label: Text('SGST', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
                            DataColumn(label: Text('Amount', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
                            DataColumn(label: Text('Actions', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
                          ],
                          rows: List<DataRow>.generate(
                            _saleItems.length,
                                (index) {
                              final item = _saleItems[index];
                              return DataRow(
                                cells: [
                                  DataCell(Text((index + 1).toString(), style: const TextStyle(fontSize: 11))),
                                  DataCell(
                                    Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Text(item.description, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600)),
                                        Text('HSN: ${item.hsnSacCode}', style: TextStyle(fontSize: 10, color: Colors.grey.shade600)),
                                      ],
                                    ),
                                  ),
                                  DataCell(Text('${item.quantity.toStringAsFixed(1)} ${item.unitOfMeasurement}', style: const TextStyle(fontSize: 11))),
                                  DataCell(Text('₹${item.sellingPricePerUnit.toStringAsFixed(2)}', style: const TextStyle(fontSize: 11))),
                                  DataCell(Text('${item.cgstRate.toStringAsFixed(1)}%\n₹${item.centralTaxAmount.toStringAsFixed(2)}', style: const TextStyle(fontSize: 10))),
                                  DataCell(Text('${item.sgstRate.toStringAsFixed(1)}%\n₹${item.stateTaxAmount.toStringAsFixed(2)}', style: const TextStyle(fontSize: 10))),
                                  DataCell(Text('₹${item.itemTotal.toStringAsFixed(2)}', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold))),
                                  DataCell(
                                    Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        IconButton(
                                          icon: const Icon(Icons.edit, size: 18, color: Colors.orange),
                                          onPressed: () => _addItemToSale(existingItem: item, index: index),
                                        ),
                                        IconButton(
                                          icon: const Icon(Icons.delete, size: 18, color: Colors.red),
                                          onPressed: () => _removeItemFromSale(index),
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
                              const Text('Sub Total:', style: TextStyle(fontSize: 14)),
                              Text('₹${(_totalSaleAmount - _calculateTotalTax()).toStringAsFixed(2)}', style: const TextStyle(fontSize: 14)),
                            ],
                          ),
                          if (_selectedSupplyType == 'INTRA') ...[
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text('CGST:', style: TextStyle(fontSize: 12, color: Colors.grey.shade700)),
                                Text('₹${_calculateCGST().toStringAsFixed(2)}', style: TextStyle(fontSize: 12, color: Colors.grey.shade700)),
                              ],
                            ),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text('SGST:', style: TextStyle(fontSize: 12, color: Colors.grey.shade700)),
                                Text('₹${_calculateSGST().toStringAsFixed(2)}', style: TextStyle(fontSize: 12, color: Colors.grey.shade700)),
                              ],
                            ),
                          ] else ...[
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text('IGST:', style: TextStyle(fontSize: 12, color: Colors.grey.shade700)),
                                Text('₹${_calculateIGST().toStringAsFixed(2)}', style: TextStyle(fontSize: 12, color: Colors.grey.shade700)),
                              ],
                            ),
                          ],
                          const Divider(),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text('Total:', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                              Text('₹${_totalSaleAmount.toStringAsFixed(2)}', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF667eea))),
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
    sum + item.centralTaxAmount + item.stateTaxAmount + item.integratedTaxAmount + item.cessAmount);
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
    TextEditingController quantityController = TextEditingController(text: existingItem?.quantity.toString() ?? '1.0');
    ItemMaster? selectedItemMaster;
    final _itemDialogFormKey = GlobalKey<FormState>();

    if (existingItem != null) {
      selectedItemId = existingItem.itemId;
      try {
        final itemDoc = await _firestore.collection('items').doc(selectedItemId).get();
        if (itemDoc.exists) {
          selectedItemMaster = ItemMaster.fromFirestore(itemDoc);
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
              title: Text(existingItem == null ? 'Add Item to Sale' : 'Edit Sale Item'),
              content: Form(
                key: _itemDialogFormKey,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      FutureBuilder<QuerySnapshot>(
                        future: _firestore.collection('items').where('userId', isEqualTo: widget.userId).where('isActive', isEqualTo: true).get(),
                        builder: (context, snapshot) {
                          if (snapshot.connectionState == ConnectionState.waiting) {
                            return const CircularProgressIndicator();
                          }
                          if (snapshot.hasError) {
                            debugPrint('Add Item Dialog: Error loading items: ${snapshot.error}');
                            return Text('Error loading items: ${snapshot.error}');
                          }
                          final items = snapshot.data!.docs
                              .map((doc) => ItemMaster.fromFirestore(doc))
                              .toList();

                          if (items.isEmpty) {
                            return const Padding(
                              padding: EdgeInsets.symmetric(vertical: 16.0),
                              child: Text(
                                'No active items available. Please add items in the "Items" tab first.',
                                style: TextStyle(color: Colors.red, fontStyle: FontStyle.italic),
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
                                selectedItemMaster = items.firstWhere((item) => item.id == value);
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
                      TextFormField(
                        controller: quantityController,
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
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
                      const SizedBox(height: 16),
                      if (selectedItemMaster != null)
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Selling Price: ₹${selectedItemMaster!.sellingPrice.toStringAsFixed(2)}', style: TextStyle(color: Colors.grey.shade700)),
                            Text('CGST: ${selectedItemMaster!.cgstRate}%', style: TextStyle(color: Colors.grey.shade700)),
                            Text('SGST: ${selectedItemMaster!.sgstRate}%', style: TextStyle(color: Colors.grey.shade700)),
                            Text('IGST: ${selectedItemMaster!.igstRate}%', style: TextStyle(color: Colors.grey.shade700)),
                            Text('Cess: ${selectedItemMaster!.cessRate}%', style: TextStyle(color: Colors.grey.shade700)),
                          ],
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
                      if (selectedItemId != null && quantityController.text.isNotEmpty) {
                        final quantity = double.parse(quantityController.text);
                        _calculateAndAddSaleItem(selectedItemId!, quantity, existingItem, index);
                        Navigator.of(context).pop();
                      }
                    } else {
                      debugPrint('Add/Edit Sale Item Dialog: Form validation failed.');
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

  Future<void> _calculateAndAddSaleItem(String itemId, double quantity, SaleItem? existingItem, int? index) async {
    try {
      final itemDoc = await _firestore.collection('items').doc(itemId).get();
      if (!itemDoc.exists) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Selected item not found'), backgroundColor: Colors.red),
          );
        }
        debugPrint('Error: Selected item not found for ID: $itemId');
        return;
      }

      final itemMaster = ItemMaster.fromFirestore(itemDoc);
      final sellingPricePerUnit = itemMaster.sellingPrice;
      final totalTaxableValue = sellingPricePerUnit * quantity;

      final cgstAmount = _selectedSupplyType == 'INTRA'
          ? totalTaxableValue * (itemMaster.cgstRate / 100)
          : 0.0;

      final sgstAmount = _selectedSupplyType == 'INTRA'
          ? totalTaxableValue * (itemMaster.sgstRate / 100)
          : 0.0;

      final igstAmount = _selectedSupplyType == 'INTER'
          ? totalTaxableValue * (itemMaster.igstRate / 100)
          : 0.0;

      final cessAmount = totalTaxableValue * (itemMaster.cessRate / 100);

      final itemTotal = totalTaxableValue + cgstAmount + sgstAmount + igstAmount + cessAmount;

      final newSaleItem = SaleItem(
        itemId: itemMaster.id,
        itemCode: itemMaster.itemCode,
        description: itemMaster.description,
        hsnSacCode: itemMaster.hsnSacCode,
        unitOfMeasurement: itemMaster.unitOfMeasurement,
        quantity: quantity,
        sellingPricePerUnit: sellingPricePerUnit,
        cgstRate: itemMaster.cgstRate,
        sgstRate: itemMaster.sgstRate,
        igstRate: itemMaster.igstRate,
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
          SnackBar(content: Text('Error adding item: $e'), backgroundColor: Colors.red),
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

    try {
      String gstr1Section = 'B2C_SMALL';
      if (_recipientGSTINController.text.trim().isNotEmpty) {
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
        eWayBillNo: _eWayBillController.text.trim().isEmpty ? null : _eWayBillController.text.trim(),
        transportMode: _totalSaleAmount > 50000 ? _selectedTransportMode : null,
        distance: _distanceController.text.trim().isEmpty ? null : double.tryParse(_distanceController.text.trim()),
        documentType: _selectedDocumentType,
        isReverseCharge: _isReverseCharge,
      ).toFirestore();

      if (widget.saleId != null && widget.saleId!.isNotEmpty) {
        await _firestore.collection('sales').doc(widget.saleId).update(saleData);
        debugPrint('Sale updated successfully for ID: ${widget.saleId}');
      } else {
        final docRef = await _firestore.collection('sales').add(saleData);
        debugPrint('Sale added successfully with ID: ${docRef.id}');
      }

      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(widget.saleId != null ? 'Sale updated successfully' : 'Sale added successfully'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error saving sale: $e'), backgroundColor: Colors.red),
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
    super.dispose();
  }
}