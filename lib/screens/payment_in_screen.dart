import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class RecordPaymentScreen extends StatefulWidget {
  final String businessId;

  const RecordPaymentScreen({
    super.key,
    required this.businessId,
  });

  @override
  State<RecordPaymentScreen> createState() => _RecordPaymentScreenState();
}

class _RecordPaymentScreenState extends State<RecordPaymentScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final _formKey = GlobalKey<FormState>();

  // Controllers
  final _amountController = TextEditingController();
  final _notesController = TextEditingController();
  final _referenceController = TextEditingController();

  // Form data
  String? _selectedInvoiceId;
  String _selectedPaymentType = 'Cash';
  DateTime _paymentDate = DateTime.now();
  String _customerName = '';
  double _invoiceAmount = 0.0;
  double _paidAmount = 0.0;
  double _balanceAmount = 0.0;

  List<Map<String, dynamic>> _pendingInvoices = [];
  bool _isLoading = false;

  final List<String> _paymentTypes = [
    'Cash',
    'Cheque',
    'UPI',
    'Online Transfer',
    'Card',
    'Other',
  ];

  @override
  void initState() {
    super.initState();
    _loadPendingInvoices();
  }

  Future<void> _loadPendingInvoices() async {
    try {
      final snapshot = await _firestore
          .collection('invoices')
          .where('businessId', isEqualTo: widget.businessId)
          .where('status', whereIn: ['Pending', 'Partial'])
          .orderBy('invoiceDate', descending: true)
          .get();

      setState(() {
        _pendingInvoices = snapshot.docs.map((doc) {
          final data = doc.data();
          return {
            'id': doc.id,
            'invoiceNumber': data['invoiceNumber'] ?? '',
            'customerName': data['customerName'] ?? '',
            'totalAmount': (data['totalAmount'] ?? 0.0).toDouble(),
            'paidAmount': (data['paidAmount'] ?? 0.0).toDouble(),
            'balanceAmount': (data['totalAmount'] ?? 0.0).toDouble() - (data['paidAmount'] ?? 0.0).toDouble(),
            'invoiceDate': data['invoiceDate'] as Timestamp?,
          };
        }).where((invoice) => invoice['balanceAmount'] > 0).toList();
      });
    } catch (e) {
      print('Error loading pending invoices: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        title: const Text('Record Payment'),
        backgroundColor: Colors.white,
        elevation: 0,
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildInvoiceSelection(),
              const SizedBox(height: 20),
              _buildPaymentDetails(),
              const SizedBox(height: 20),
              _buildPaymentSummary(),
              const SizedBox(height: 30),
              _buildActionButtons(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInvoiceSelection() {
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
            'Select Invoice',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color(0xFF2D3748),
            ),
          ),
          const SizedBox(height: 16),
          DropdownButtonFormField<String>(
            value: _selectedInvoiceId,
            decoration: const InputDecoration(
              labelText: 'Pending Invoice',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.receipt_long),
            ),
            items: _pendingInvoices.map((invoice) {
              return DropdownMenuItem<String>(
                value: invoice['id'],
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Invoice #${invoice['invoiceNumber']}',
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                    Text(
                      '${invoice['customerName']} - ₹${invoice['balanceAmount'].toStringAsFixed(2)} pending',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
            onChanged: (value) {
              if (value != null) {
                final selectedInvoice = _pendingInvoices.firstWhere((inv) => inv['id'] == value);
                setState(() {
                  _selectedInvoiceId = value;
                  _customerName = selectedInvoice['customerName'];
                  _invoiceAmount = selectedInvoice['totalAmount'];
                  _paidAmount = selectedInvoice['paidAmount'];
                  _balanceAmount = selectedInvoice['balanceAmount'];
                  _amountController.text = _balanceAmount.toStringAsFixed(2);
                });
              }
            },
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please select an invoice';
              }
              return null;
            },
          ),
          if (_selectedInvoiceId != null) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.blue.shade200),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Invoice Amount:'),
                      Text(
                        '₹${_invoiceAmount.toStringAsFixed(2)}',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Already Paid:'),
                      Text(
                        '₹${_paidAmount.toStringAsFixed(2)}',
                        style: const TextStyle(color: Colors.green),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Balance Due:'),
                      Text(
                        '₹${_balanceAmount.toStringAsFixed(2)}',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.red,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildPaymentDetails() {
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
            'Payment Details',
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
                  controller: _amountController,
                  decoration: const InputDecoration(
                    labelText: 'Payment Amount *',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.currency_rupee),
                  ),
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Payment amount is required';
                    }
                    final amount = double.tryParse(value);
                    if (amount == null || amount <= 0) {
                      return 'Enter a valid amount';
                    }
                    if (amount > _balanceAmount) {
                      return 'Amount cannot exceed balance due';
                    }
                    return null;
                  },
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: DropdownButtonFormField<String>(
                  value: _selectedPaymentType,
                  decoration: const InputDecoration(
                    labelText: 'Payment Type',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.payment),
                  ),
                  items: _paymentTypes.map((type) {
                    return DropdownMenuItem<String>(
                      value: type,
                      child: Text(type),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setState(() {
                      _selectedPaymentType = value!;
                    });
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          InkWell(
            onTap: _selectPaymentDate,
            child: InputDecorator(
              decoration: const InputDecoration(
                labelText: 'Payment Date',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.calendar_today),
              ),
              child: Text(DateFormat('dd/MM/yyyy').format(_paymentDate)),
            ),
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _referenceController,
            decoration: const InputDecoration(
              labelText: 'Reference Number',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.confirmation_number),
              hintText: 'Cheque/Transaction ID',
            ),
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _notesController,
            decoration: const InputDecoration(
              labelText: 'Notes',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.note),
            ),
            maxLines: 3,
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentSummary() {
    if (_selectedInvoiceId == null) return const SizedBox.shrink();

    final paymentAmount = double.tryParse(_amountController.text) ?? 0.0;
    final remainingBalance = _balanceAmount - paymentAmount;
    final isFullPayment = remainingBalance <= 0;

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
            'Payment Summary',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color(0xFF2D3748),
            ),
          ),
          const SizedBox(height: 16),
          _buildSummaryRow('Customer', _customerName),
          _buildSummaryRow('Payment Amount', '₹${paymentAmount.toStringAsFixed(2)}'),
          _buildSummaryRow('Payment Type', _selectedPaymentType),
          _buildSummaryRow('Payment Date', DateFormat('dd MMM yyyy').format(_paymentDate)),
          const Divider(),
          _buildSummaryRow(
            'Remaining Balance',
            '₹${remainingBalance.toStringAsFixed(2)}',
            valueColor: remainingBalance > 0 ? Colors.red : Colors.green,
          ),
          _buildSummaryRow(
            'Invoice Status',
            isFullPayment ? 'Paid' : 'Partial',
            valueColor: isFullPayment ? Colors.green : Colors.orange,
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryRow(String label, String value, {Color? valueColor}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              color: Colors.grey.shade700,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontWeight: FontWeight.w600,
              color: valueColor ?? Colors.black87,
            ),
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
            onPressed: _isLoading ? null : _recordPayment,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF4CAF50),
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
                : const Text('Record Payment'),
          ),
        ),
      ],
    );
  }

  Future<void> _selectPaymentDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _paymentDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );

    if (date != null) {
      setState(() {
        _paymentDate = date;
      });
    }
  }

  Future<void> _recordPayment() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final paymentAmount = double.parse(_amountController.text);
      final newPaidAmount = _paidAmount + paymentAmount;
      final remainingBalance = _invoiceAmount - newPaidAmount;
      final newStatus = remainingBalance <= 0 ? 'Paid' : 'Partial';

      // Record the payment
      await _firestore.collection('payments').add({
        'businessId': widget.businessId,
        'invoiceId': _selectedInvoiceId,
        'invoiceNumber': _pendingInvoices.firstWhere((inv) => inv['id'] == _selectedInvoiceId)['invoiceNumber'],
        'customerName': _customerName,
        'amount': paymentAmount,
        'paymentType': _selectedPaymentType,
        'paymentDate': Timestamp.fromDate(_paymentDate),
        'referenceNumber': _referenceController.text.trim(),
        'notes': _notesController.text.trim(),
        'createdAt': FieldValue.serverTimestamp(),
      });

      // Update invoice payment status
      await _firestore.collection('invoices').doc(_selectedInvoiceId).update({
        'paidAmount': newPaidAmount,
        'status': newStatus,
        'lastPaymentDate': Timestamp.fromDate(_paymentDate),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Payment recorded successfully'),
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

  @override
  void dispose() {
    _amountController.dispose();
    _notesController.dispose();
    _referenceController.dispose();
    super.dispose();
  }
}
