import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import '../utils/gst_utils.dart';
import '../services/stock_service.dart';

class CreateInvoiceScreen extends StatefulWidget {
  final String businessId;
  final DocumentSnapshot? invoiceDoc;

  const CreateInvoiceScreen({
    super.key,
    required this.businessId,
    this.invoiceDoc,
  });

  @override
  State<CreateInvoiceScreen> createState() => _CreateInvoiceScreenState();
}

class _CreateInvoiceScreenState extends State<CreateInvoiceScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final _formKey = GlobalKey<FormState>();

  // Controllers
  final _customerNameController = TextEditingController();
  final _customerGSTINController = TextEditingController();
  final _customerAddressController = TextEditingController();
  final _customerPhoneController = TextEditingController();
  final _customerEmailController = TextEditingController();
  final _poNumberController = TextEditingController();
  final _challanNumberController = TextEditingController();
  final _termsController = TextEditingController();
  final _notesController = TextEditingController();

  // Invoice data
  String _invoiceNumber = '';
  DateTime _invoiceDate = DateTime.now();
  DateTime _dueDate = DateTime.now().add(const Duration(days: 30));
  List<InvoiceItem> _items = [];
  double _subtotal = 0.0;
  double _totalCGST = 0.0;
  double _totalSGST = 0.0;
  double _totalIGST = 0.0;
  double _totalAmount = 0.0;
  double _discountAmount = 0.0;
  double _shippingCharges = 0.0;
  double _otherCharges = 0.0;

  bool _isLoading = false;
  bool _isEditing = false;
  String? _businessGSTIN;

  @override
  void initState() {
    super.initState();
    _isEditing = widget.invoiceDoc != null;
    _loadBusinessSettings();
    _generateInvoiceNumber();
    if (_isEditing) {
      _loadInvoiceData();
    }
  }

  Future<void> _loadBusinessSettings() async {
    try {
      final businessDoc = await _firestore
          .collection('business_profiles')
          .doc(widget.businessId)
          .get();

      if (businessDoc.exists) {
        final data = businessDoc.data()!;
        _businessGSTIN = data['gstin'] ?? '';
      }
    } catch (e) {
      print('Error loading business settings: $e');
    }
  }

  Future<void> _generateInvoiceNumber() async {
    if (_isEditing) return;

    try {
      final snapshot = await _firestore
          .collection('invoices')
          .where('businessId', isEqualTo: widget.businessId)
          .orderBy('invoiceNumber', descending: true)
          .limit(1)
          .get();

      int nextNumber = 1;
      if (snapshot.docs.isNotEmpty) {
        final lastInvoice = snapshot.docs.first.data();
        final lastNumber = int.tryParse(lastInvoice['invoiceNumber']?.toString() ?? '0') ?? 0;
        nextNumber = lastNumber + 1;
      }

      setState(() {
        _invoiceNumber = 'INV${nextNumber.toString().padLeft(4, '0')}';
      });
    } catch (e) {
      setState(() {
        _invoiceNumber = 'INV0001';
      });
    }
  }

  void _loadInvoiceData() {
    if (widget.invoiceDoc == null) return;

    final data = widget.invoiceDoc!.data() as Map<String, dynamic>;

    _customerNameController.text = data['customerName'] ?? '';
    _customerGSTINController.text = data['customerGSTIN'] ?? '';
    _customerAddressController.text = data['customerAddress'] ?? '';
    _customerPhoneController.text = data['customerPhone'] ?? '';
    _customerEmailController.text = data['customerEmail'] ?? '';
    _poNumberController.text = data['poNumber'] ?? '';
    _challanNumberController.text = data['challanNumber'] ?? '';
    _termsController.text = data['terms'] ?? '';
    _notesController.text = data['notes'] ?? '';

    _invoiceNumber = data['invoiceNumber'] ?? '';
    _invoiceDate = (data['invoiceDate'] as Timestamp?)?.toDate() ?? DateTime.now();
    _dueDate = (data['dueDate'] as Timestamp?)?.toDate() ?? DateTime.now().add(const Duration(days: 30));

    // Load items
    final itemsData = data['items'] as List<dynamic>? ?? [];
    _items = itemsData.map((item) => InvoiceItem.fromMap(item)).toList();

    _discountAmount = (data['discountAmount'] ?? 0.0).toDouble();
    _shippingCharges = (data['shippingCharges'] ?? 0.0).toDouble();
    _otherCharges = (data['otherCharges'] ?? 0.0).toDouble();

    _calculateTotals();
  }

  void _calculateTotals() {
    _subtotal = _items.fold(0.0, (sum, item) => sum + item.totalAmount);

    _totalCGST = 0.0;
    _totalSGST = 0.0;
    _totalIGST = 0.0;

    final isInterstate = GSTUtils.isInterstateTransaction(_businessGSTIN ?? '', _customerGSTINController.text);

    for (final item in _items) {
      final gstCalc = GSTUtils.calculateGST(
        item.totalAmount,
        item.cgstRate,
        item.sgstRate,
        item.igstRate,
        isInterstate,
      );

      _totalCGST += gstCalc['cgst']!;
      _totalSGST += gstCalc['sgst']!;
      _totalIGST += gstCalc['igst']!;
    }

    _totalAmount = _subtotal + _totalCGST + _totalSGST + _totalIGST - _discountAmount + _shippingCharges + _otherCharges;

    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        title: Text(_isEditing ? 'Edit Invoice' : 'Create Invoice'),
        backgroundColor: Colors.white,
        elevation: 0,
        actions: [
          if (_isEditing)
            IconButton(
              onPressed: _previewInvoice,
              icon: const Icon(Icons.preview),
              tooltip: 'Preview',
            ),
          IconButton(
            onPressed: _saveInvoice,
            icon: const Icon(Icons.save),
            tooltip: 'Save',
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildInvoiceHeader(),
              const SizedBox(height: 20),
              _buildCustomerDetails(),
              const SizedBox(height: 20),
              _buildItemsSection(),
              const SizedBox(height: 20),
              _buildTotalsSection(),
              const SizedBox(height: 20),
              _buildAdditionalDetails(),
              const SizedBox(height: 30),
              _buildActionButtons(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInvoiceHeader() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Invoice Details',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color(0xFF2D3748),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Invoice Number'),
                    const SizedBox(height: 4),
                    Text(
                      _invoiceNumber,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF667eea),
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Invoice Date'),
                    const SizedBox(height: 4),
                    InkWell(
                      onTap: () => _selectDate(true),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey.shade300),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(DateFormat('dd/MM/yyyy').format(_invoiceDate)),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Due Date'),
              const SizedBox(height: 4),
              InkWell(
                onTap: () => _selectDate(false),
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey.shade300),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      Text(DateFormat('dd/MM/yyyy').format(_dueDate)),
                      const Spacer(),
                      const Icon(Icons.calendar_today, size: 16),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCustomerDetails() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text(
                'Customer Details',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF2D3748),
                ),
              ),
              const Spacer(),
              TextButton.icon(
                onPressed: _selectExistingCustomer,
                icon: const Icon(Icons.person_search),
                label: const Text('Select Customer'),
              ),
            ],
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _customerNameController,
            decoration: const InputDecoration(
              labelText: 'Customer Name *',
              border: OutlineInputBorder(),
            ),
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'Customer name is required';
              }
              return null;
            },
            onChanged: (_) => _calculateTotals(),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: TextFormField(
                  controller: _customerGSTINController,
                  decoration: const InputDecoration(
                    labelText: 'GSTIN',
                    border: OutlineInputBorder(),
                  ),
                  onChanged: (_) => _calculateTotals(),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TextFormField(
                  controller: _customerPhoneController,
                  decoration: const InputDecoration(
                    labelText: 'Phone',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.phone,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _customerEmailController,
            decoration: const InputDecoration(
              labelText: 'Email',
              border: OutlineInputBorder(),
            ),
            keyboardType: TextInputType.emailAddress,
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _customerAddressController,
            decoration: const InputDecoration(
              labelText: 'Billing Address',
              border: OutlineInputBorder(),
            ),
            maxLines: 3,
          ),
        ],
      ),
    );
  }

  Widget _buildItemsSection() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text(
                'Items',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF2D3748),
                ),
              ),
              const Spacer(),
              ElevatedButton.icon(
                onPressed: _addItem,
                icon: const Icon(Icons.add),
                label: const Text('Add Item'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF667eea),
                  foregroundColor: Colors.white,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (_items.isEmpty)
            Container(
              padding: const EdgeInsets.all(40),
              child: Column(
                children: [
                  Icon(
                    Icons.inventory_2_outlined,
                    size: 64,
                    color: Colors.grey.shade400,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No items added yet',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey.shade600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Add items to create your invoice',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey.shade500,
                    ),
                  ),
                ],
              ),
            )
          else
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _items.length,
              itemBuilder: (context, index) {
                return _buildItemCard(_items[index], index);
              },
            ),
        ],
      ),
    );
  }

  Widget _buildItemCard(InvoiceItem item, int index) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade200),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  item.itemName,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              PopupMenuButton<String>(
                onSelected: (value) {
                  switch (value) {
                    case 'edit':
                      _editItem(index);
                      break;
                    case 'delete':
                      _removeItem(index);
                      break;
                  }
                },
                itemBuilder: (context) => [
                  const PopupMenuItem(
                    value: 'edit',
                    child: Row(
                      children: [
                        Icon(Icons.edit, size: 16),
                        SizedBox(width: 8),
                        Text('Edit'),
                      ],
                    ),
                  ),
                  const PopupMenuItem(
                    value: 'delete',
                    child: Row(
                      children: [
                        Icon(Icons.delete, size: 16, color: Colors.red),
                        SizedBox(width: 8),
                        Text('Delete', style: TextStyle(color: Colors.red)),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Text('HSN: ${item.hsnCode}'),
              const SizedBox(width: 16),
              Text('Qty: ${item.quantity}'),
              const SizedBox(width: 16),
              Text('Rate: ₹${item.unitPrice.toStringAsFixed(2)}'),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('GST: ${item.cgstRate + item.sgstRate + item.igstRate}%'),
              Text(
                'Amount: ₹${item.totalAmount.toStringAsFixed(2)}',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF667eea),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTotalsSection() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Invoice Summary',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color(0xFF2D3748),
            ),
          ),
          const SizedBox(height: 16),
          _buildTotalRow('Subtotal', _subtotal),
          if (_totalCGST > 0) _buildTotalRow('CGST', _totalCGST),
          if (_totalSGST > 0) _buildTotalRow('SGST', _totalSGST),
          if (_totalIGST > 0) _buildTotalRow('IGST', _totalIGST),
          _buildEditableRow('Discount', _discountAmount, (value) {
            setState(() {
              _discountAmount = value;
              _calculateTotals();
            });
          }),
          _buildEditableRow('Shipping Charges', _shippingCharges, (value) {
            setState(() {
              _shippingCharges = value;
              _calculateTotals();
            });
          }),
          _buildEditableRow('Other Charges', _otherCharges, (value) {
            setState(() {
              _otherCharges = value;
              _calculateTotals();
            });
          }),
          const Divider(thickness: 2),
          _buildTotalRow('Total Amount', _totalAmount, isTotal: true),
        ],
      ),
    );
  }

  Widget _buildTotalRow(String label, double amount, {bool isTotal = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: isTotal ? 16 : 14,
              fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
              color: isTotal ? const Color(0xFF2D3748) : Colors.grey.shade700,
            ),
          ),
          Text(
            '₹${amount.toStringAsFixed(2)}',
            style: TextStyle(
              fontSize: isTotal ? 16 : 14,
              fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
              color: isTotal ? const Color(0xFF667eea) : Colors.grey.shade700,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEditableRow(String label, double amount, Function(double) onChanged) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey.shade700,
            ),
          ),
          SizedBox(
            width: 100,
            child: TextFormField(
              initialValue: amount.toStringAsFixed(2),
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              textAlign: TextAlign.right,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                prefixText: '₹',
              ),
              onChanged: (value) {
                final parsed = double.tryParse(value) ?? 0.0;
                onChanged(parsed);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAdditionalDetails() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Additional Details',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color(0xFF2D3748),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: TextFormField(
                  controller: _poNumberController,
                  decoration: const InputDecoration(
                    labelText: 'PO Number',
                    border: OutlineInputBorder(),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TextFormField(
                  controller: _challanNumberController,
                  decoration: const InputDecoration(
                    labelText: 'Challan Number',
                    border: OutlineInputBorder(),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _termsController,
            decoration: const InputDecoration(
              labelText: 'Terms & Conditions',
              border: OutlineInputBorder(),
            ),
            maxLines: 3,
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _notesController,
            decoration: const InputDecoration(
              labelText: 'Notes',
              border: OutlineInputBorder(),
            ),
            maxLines: 2,
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons() {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton(
            onPressed: () => Navigator.of(context).pop(),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
              side: const BorderSide(color: Colors.grey),
            ),
            child: const Text('Cancel'),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: ElevatedButton(
            onPressed: _isLoading ? null : _saveInvoice,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF667eea),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
            child: _isLoading
                ? const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
              ),
            )
                : Text(_isEditing ? 'Update Invoice' : 'Save Invoice'),
          ),
        ),
        const SizedBox(width: 12),
        ElevatedButton(
          onPressed: _previewInvoice,
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF10B981),
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
          ),
          child: const Icon(Icons.preview),
        ),
      ],
    );
  }

  Future<void> _selectDate(bool isInvoiceDate) async {
    final date = await showDatePicker(
      context: context,
      initialDate: isInvoiceDate ? _invoiceDate : _dueDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
    );

    if (date != null) {
      setState(() {
        if (isInvoiceDate) {
          _invoiceDate = date;
        } else {
          _dueDate = date;
        }
      });
    }
  }

  void _selectExistingCustomer() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Select Customer'),
        content: SizedBox(
          width: double.maxFinite,
          height: 300,
          child: StreamBuilder<QuerySnapshot>(
            stream: _firestore
                .collection('customers')
                .where('businessId', isEqualTo: widget.businessId)
                .snapshots(),
            builder: (context, snapshot) {
              if (!snapshot.hasData) {
                return const Center(child: CircularProgressIndicator());
              }

              final customers = snapshot.data!.docs;

              if (customers.isEmpty) {
                return const Center(
                  child: Text('No customers found. Add customers first.'),
                );
              }

              return ListView.builder(
                itemCount: customers.length,
                itemBuilder: (context, index) {
                  final customer = customers[index].data() as Map<String, dynamic>;
                  return ListTile(
                    title: Text(customer['name'] ?? ''),
                    subtitle: Text(customer['phone'] ?? ''),
                    onTap: () {
                      _customerNameController.text = customer['name'] ?? '';
                      _customerGSTINController.text = customer['gstin'] ?? '';
                      _customerAddressController.text = customer['address'] ?? '';
                      _customerPhoneController.text = customer['phone'] ?? '';
                      _customerEmailController.text = customer['email'] ?? '';
                      Navigator.of(context).pop();
                      _calculateTotals();
                    },
                  );
                },
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }

  void _addItem() {
    showDialog(
      context: context,
      builder: (context) => AddItemDialog(
        businessId: widget.businessId,
        onItemAdded: (item) {
          setState(() {
            _items.add(item);
            _calculateTotals();
          });
        },
      ),
    );
  }

  void _editItem(int index) {
    showDialog(
      context: context,
      builder: (context) => AddItemDialog(
        businessId: widget.businessId,
        item: _items[index],
        onItemAdded: (item) {
          setState(() {
            _items[index] = item;
            _calculateTotals();
          });
        },
      ),
    );
  }

  void _removeItem(int index) {
    setState(() {
      _items.removeAt(index);
      _calculateTotals();
    });
  }

  Future<void> _saveInvoice() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_items.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please add at least one item'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final invoiceData = {
        'businessId': widget.businessId,
        'invoiceNumber': _invoiceNumber,
        'invoiceDate': Timestamp.fromDate(_invoiceDate),
        'dueDate': Timestamp.fromDate(_dueDate),
        'customerName': _customerNameController.text.trim(),
        'customerGSTIN': _customerGSTINController.text.trim(),
        'customerAddress': _customerAddressController.text.trim(),
        'customerPhone': _customerPhoneController.text.trim(),
        'customerEmail': _customerEmailController.text.trim(),
        'poNumber': _poNumberController.text.trim(),
        'challanNumber': _challanNumberController.text.trim(),
        'terms': _termsController.text.trim(),
        'notes': _notesController.text.trim(),
        'items': _items.map((item) => item.toMap()).toList(),
        'subtotal': _subtotal,
        'totalCGST': _totalCGST,
        'totalSGST': _totalSGST,
        'totalIGST': _totalIGST,
        'discountAmount': _discountAmount,
        'shippingCharges': _shippingCharges,
        'otherCharges': _otherCharges,
        'totalAmount': _totalAmount,
        'status': 'Pending',
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      };

      if (_isEditing && widget.invoiceDoc != null) {
        await widget.invoiceDoc!.reference.update(invoiceData);
      } else {
        await _firestore.collection('invoices').add(invoiceData);
      }

      // Update stock for each item
      for (final item in _items) {
        await StockService.updateStockAfterSale(item.itemId, item.quantity);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_isEditing ? 'Invoice updated successfully' : 'Invoice created successfully'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _previewInvoice() {
    // TODO: Implement invoice preview
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Invoice preview will be implemented')),
    );
  }

  @override
  void dispose() {
    _customerNameController.dispose();
    _customerGSTINController.dispose();
    _customerAddressController.dispose();
    _customerPhoneController.dispose();
    _customerEmailController.dispose();
    _poNumberController.dispose();
    _challanNumberController.dispose();
    _termsController.dispose();
    _notesController.dispose();
    super.dispose();
  }
}

class InvoiceItem {
  final String itemId;
  final String itemName;
  final String hsnCode;
  final double quantity;
  final double unitPrice;
  final double totalAmount;
  final double cgstRate;
  final double sgstRate;
  final double igstRate;
  final String unit;

  InvoiceItem({
    required this.itemId,
    required this.itemName,
    required this.hsnCode,
    required this.quantity,
    required this.unitPrice,
    required this.totalAmount,
    required this.cgstRate,
    required this.sgstRate,
    required this.igstRate,
    required this.unit,
  });

  factory InvoiceItem.fromMap(Map<String, dynamic> map) {
    return InvoiceItem(
      itemId: map['itemId'] ?? '',
      itemName: map['itemName'] ?? '',
      hsnCode: map['hsnCode'] ?? '',
      quantity: (map['quantity'] ?? 0.0).toDouble(),
      unitPrice: (map['unitPrice'] ?? 0.0).toDouble(),
      totalAmount: (map['totalAmount'] ?? 0.0).toDouble(),
      cgstRate: (map['cgstRate'] ?? 0.0).toDouble(),
      sgstRate: (map['sgstRate'] ?? 0.0).toDouble(),
      igstRate: (map['igstRate'] ?? 0.0).toDouble(),
      unit: map['unit'] ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'itemId': itemId,
      'itemName': itemName,
      'hsnCode': hsnCode,
      'quantity': quantity,
      'unitPrice': unitPrice,
      'totalAmount': totalAmount,
      'cgstRate': cgstRate,
      'sgstRate': sgstRate,
      'igstRate': igstRate,
      'unit': unit,
    };
  }
}

class AddItemDialog extends StatefulWidget {
  final String businessId;
  final InvoiceItem? item;
  final Function(InvoiceItem) onItemAdded;

  const AddItemDialog({
    super.key,
    required this.businessId,
    required this.onItemAdded,
    this.item,
  });

  @override
  State<AddItemDialog> createState() => _AddItemDialogState();
}

class _AddItemDialogState extends State<AddItemDialog> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final _formKey = GlobalKey<FormState>();

  String? _selectedItemId;
  final _quantityController = TextEditingController();
  final _unitPriceController = TextEditingController();
  final _discountController = TextEditingController(text: '0');

  String _itemName = '';
  String _hsnCode = '';
  String _unit = '';
  double _cgstRate = 0.0;
  double _sgstRate = 0.0;
  double _igstRate = 0.0;

  List<Map<String, dynamic>> _items = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadItems();
    if (widget.item != null) {
      _loadItemData();
    }
  }

  void _loadItemData() {
    final item = widget.item!;
    _selectedItemId = item.itemId;
    _itemName = item.itemName;
    _hsnCode = item.hsnCode;
    _unit = item.unit;
    _cgstRate = item.cgstRate;
    _sgstRate = item.sgstRate;
    _igstRate = item.igstRate;
    _quantityController.text = item.quantity.toString();
    _unitPriceController.text = item.unitPrice.toString();
  }

  Future<void> _loadItems() async {
    try {
      final snapshot = await _firestore
          .collection('items')
          .where('businessId', isEqualTo: widget.businessId)
          .where('isActive', isEqualTo: true)
          .get();

      setState(() {
        _items = snapshot.docs.map((doc) {
          final data = doc.data();
          return {
            'id': doc.id,
            'name': data['description'] ?? '',
            'hsnCode': data['hsnSacCode'] ?? '',
            'unit': data['unitOfMeasurement'] ?? '',
            'cgstRate': (data['cgstRate'] ?? 0.0).toDouble(),
            'sgstRate': (data['sgstRate'] ?? 0.0).toDouble(),
            'igstRate': (data['igstRate'] ?? 0.0).toDouble(),
            'sellingPrice': (data['sellingPrice'] ?? 0.0).toDouble(),
          };
        }).toList();
      });
    } catch (e) {
      print('Error loading items: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.item == null ? 'Add Item' : 'Edit Item'),
      content: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButtonFormField<String>(
                value: _selectedItemId,
                decoration: const InputDecoration(
                  labelText: 'Select Item',
                  border: OutlineInputBorder(),
                ),
                items: _items.map((item) {
                  return DropdownMenuItem<String>(
                    value: item['id'],
                    child: Text(item['name']),
                  );
                }).toList(),
                onChanged: (value) {
                  if (value != null) {
                    final selectedItem = _items.firstWhere((item) => item['id'] == value);
                    setState(() {
                      _selectedItemId = value;
                      _itemName = selectedItem['name'];
                      _hsnCode = selectedItem['hsnCode'];
                      _unit = selectedItem['unit'];
                      _cgstRate = selectedItem['cgstRate'];
                      _sgstRate = selectedItem['sgstRate'];
                      _igstRate = selectedItem['igstRate'];
                      _unitPriceController.text = selectedItem['sellingPrice'].toString();
                    });
                  }
                },
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please select an item';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _quantityController,
                      decoration: const InputDecoration(
                        labelText: 'Quantity',
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Required';
                        }
                        final parsed = double.tryParse(value);
                        if (parsed == null || parsed <= 0) {
                          return 'Invalid quantity';
                        }
                        return null;
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextFormField(
                      controller: _unitPriceController,
                      decoration: const InputDecoration(
                        labelText: 'Unit Price',
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Required';
                        }
                        final parsed = double.tryParse(value);
                        if (parsed == null || parsed < 0) {
                          return 'Invalid price';
                        }
                        return null;
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _discountController,
                decoration: const InputDecoration(
                  labelText: 'Discount %',
                  border: OutlineInputBorder(),
                ),
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
              ),
              if (_itemName.isNotEmpty) ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('HSN Code: $_hsnCode'),
                      Text('Unit: $_unit'),
                      Text('GST: ${_cgstRate + _sgstRate + _igstRate}%'),
                    ],
                  ),
                ),
              ],
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
          onPressed: _isLoading ? null : _saveItem,
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF667eea),
            foregroundColor: Colors.white,
          ),
          child: _isLoading
              ? const SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
            ),
          )
              : const Text('Add'),
        ),
      ],
    );
  }

  void _saveItem() {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final quantity = double.parse(_quantityController.text);
    final unitPrice = double.parse(_unitPriceController.text);
    final discount = double.tryParse(_discountController.text) ?? 0.0;

    final discountAmount = (unitPrice * quantity * discount) / 100;
    final totalAmount = (unitPrice * quantity) - discountAmount;

    final item = InvoiceItem(
      itemId: _selectedItemId!,
      itemName: _itemName,
      hsnCode: _hsnCode,
      quantity: quantity,
      unitPrice: unitPrice,
      totalAmount: totalAmount,
      cgstRate: _cgstRate,
      sgstRate: _sgstRate,
      igstRate: _igstRate,
      unit: _unit,
    );

    widget.onItemAdded(item);
    Navigator.of(context).pop();
  }

  @override
  void dispose() {
    _quantityController.dispose();
    _unitPriceController.dispose();
    _discountController.dispose();
    super.dispose();
  }
}
