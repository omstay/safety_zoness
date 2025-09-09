import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import '../services/stock_service.dart';

class CreateSaleReturnScreen extends StatefulWidget {
  final String businessId;

  const CreateSaleReturnScreen({
    super.key,
    required this.businessId,
  });

  @override
  State<CreateSaleReturnScreen> createState() => _CreateSaleReturnScreenState();
}

class _CreateSaleReturnScreenState extends State<CreateSaleReturnScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final _formKey = GlobalKey<FormState>();

  // Controllers
  final _creditNoteNumberController = TextEditingController();
  final _reasonController = TextEditingController();
  final _notesController = TextEditingController();

  // Form data
  String? _selectedInvoiceId;
  DateTime _returnDate = DateTime.now();
  List<ReturnItem> _returnItems = [];
  double _totalReturnAmount = 0.0;

  List<Map<String, dynamic>> _invoices = [];
  List<Map<String, dynamic>> _invoiceItems = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadInvoices();
    _generateCreditNoteNumber();
  }

  Future<void> _loadInvoices() async {
    try {
      final snapshot = await _firestore
          .collection('invoices')
          .where('businessId', isEqualTo: widget.businessId)
          .where('status', whereIn: ['Paid', 'Partial'])
          .orderBy('invoiceDate', descending: true)
          .get();

      setState(() {
        _invoices = snapshot.docs.map((doc) {
          final data = doc.data();
          return {
            'id': doc.id,
            'invoiceNumber': data['invoiceNumber'] ?? '',
            'customerName': data['customerName'] ?? '',
            'totalAmount': (data['totalAmount'] ?? 0.0).toDouble(),
            'invoiceDate': data['invoiceDate'] as Timestamp?,
            'items': data['items'] as List<dynamic>? ?? [],
          };
        }).toList();
      });
    } catch (e) {
      print('Error loading invoices: $e');
    }
  }

  Future<void> _generateCreditNoteNumber() async {
    try {
      final snapshot = await _firestore
          .collection('sale_returns')
          .where('businessId', isEqualTo: widget.businessId)
          .orderBy('creditNoteNumber', descending: true)
          .limit(1)
          .get();

      int nextNumber = 1;
      if (snapshot.docs.isNotEmpty) {
        final lastReturn = snapshot.docs.first.data();
        final lastNumber = int.tryParse(lastReturn['creditNoteNumber']?.toString().replaceAll('CN', '') ?? '0') ?? 0;
        nextNumber = lastNumber + 1;
      }

      setState(() {
        _creditNoteNumberController.text = 'CN${nextNumber.toString().padLeft(4, '0')}';
      });
    } catch (e) {
      setState(() {
        _creditNoteNumberController.text = 'CN0001';
      });
    }
  }

  void _loadInvoiceItems() {
    if (_selectedInvoiceId == null) return;

    final selectedInvoice = _invoices.firstWhere((inv) => inv['id'] == _selectedInvoiceId);
    final items = selectedInvoice['items'] as List<dynamic>;

    setState(() {
      _invoiceItems = items.map((item) => item as Map<String, dynamic>).toList();
      _returnItems.clear();
      _totalReturnAmount = 0.0;
    });
  }

  void _calculateTotal() {
    _totalReturnAmount = _returnItems.fold(0.0, (sum, item) => sum + item.totalAmount);
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        title: const Text('Create Sale Return'),
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
              _buildReturnHeader(),
              const SizedBox(height: 20),
              _buildInvoiceSelection(),
              const SizedBox(height: 20),
              _buildReturnItems(),
              const SizedBox(height: 20),
              _buildReturnSummary(),
              const SizedBox(height: 30),
              _buildActionButtons(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildReturnHeader() {
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
            'Return Details',
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
                  controller: _creditNoteNumberController,
                  decoration: const InputDecoration(
                    labelText: 'Credit Note Number',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.receipt),
                  ),
                  readOnly: true,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: InkWell(
                  onTap: _selectReturnDate,
                  child: InputDecorator(
                    decoration: const InputDecoration(
                      labelText: 'Return Date',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.calendar_today),
                    ),
                    child: Text(DateFormat('dd/MM/yyyy').format(_returnDate)),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _reasonController,
            decoration: const InputDecoration(
              labelText: 'Return Reason *',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.info_outline),
            ),
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'Return reason is required';
              }
              return null;
            },
          ),
        ],
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
            'Original Invoice',
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
              labelText: 'Select Invoice',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.receipt_long),
            ),
            items: _invoices.map((invoice) {
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
                      '${invoice['customerName']} - ₹${invoice['totalAmount'].toStringAsFixed(2)}',
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
              setState(() {
                _selectedInvoiceId = value;
                _loadInvoiceItems();
              });
            },
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please select an invoice';
              }
              return null;
            },
          ),
        ],
      ),
    );
  }

  Widget _buildReturnItems() {
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
            'Return Items',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color(0xFF2D3748),
            ),
          ),
          const SizedBox(height: 16),
          if (_invoiceItems.isEmpty)
            Container(
              padding: const EdgeInsets.all(40),
              child: Column(
                children: [
                  Icon(
                    Icons.assignment_return_outlined,
                    size: 64,
                    color: Colors.grey.shade400,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Select an invoice to view items',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
            )
          else
            Column(
              children: [
                ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: _invoiceItems.length,
                  itemBuilder: (context, index) {
                    return _buildInvoiceItemCard(_invoiceItems[index], index);
                  },
                ),
                if (_returnItems.isNotEmpty) ...[
                  const SizedBox(height: 20),
                  const Divider(),
                  const SizedBox(height: 10),
                  const Text(
                    'Items to Return',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF2D3748),
                    ),
                  ),
                  const SizedBox(height: 10),
                  ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: _returnItems.length,
                    itemBuilder: (context, index) {
                      return _buildReturnItemCard(_returnItems[index], index);
                    },
                  ),
                ],
              ],
            ),
        ],
      ),
    );
  }

  Widget _buildInvoiceItemCard(Map<String, dynamic> item, int index) {
    final isSelected = _returnItems.any((returnItem) => returnItem.itemId == item['itemId']);

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        border: Border.all(
          color: isSelected ? Colors.red.shade300 : Colors.grey.shade200,
        ),
        borderRadius: BorderRadius.circular(8),
        color: isSelected ? Colors.red.shade50 : null,
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item['itemName'] ?? '',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Qty: ${item['quantity']} | Rate: ₹${(item['unitPrice'] ?? 0.0).toStringAsFixed(2)}',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ),
          ),
          Text(
            '₹${(item['totalAmount'] ?? 0.0).toStringAsFixed(2)}',
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              color: Color(0xFF667eea),
            ),
          ),
          const SizedBox(width: 8),
          IconButton(
            onPressed: isSelected ? null : () => _addReturnItem(item),
            icon: Icon(
              isSelected ? Icons.check_circle : Icons.add_circle_outline,
              color: isSelected ? Colors.red : const Color(0xFF667eea),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReturnItemCard(ReturnItem item, int index) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.red.shade200),
        borderRadius: BorderRadius.circular(8),
        color: Colors.red.shade50,
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.itemName,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Return Qty: ${item.returnQuantity} of ${item.originalQuantity}',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ),
          ),
          Text(
            '₹${item.totalAmount.toStringAsFixed(2)}',
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.red,
            ),
          ),
          const SizedBox(width: 8),
          IconButton(
            onPressed: () => _editReturnItem(index),
            icon: const Icon(Icons.edit, size: 20),
          ),
          IconButton(
            onPressed: () => _removeReturnItem(index),
            icon: const Icon(Icons.remove_circle, color: Colors.red, size: 20),
          ),
        ],
      ),
    );
  }

  Widget _buildReturnSummary() {
    if (_returnItems.isEmpty) return const SizedBox.shrink();

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
            'Return Summary',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color(0xFF2D3748),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Total Return Amount',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                '₹${_totalReturnAmount.toStringAsFixed(2)}',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.red,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _notesController,
            decoration: const InputDecoration(
              labelText: 'Additional Notes',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.note),
            ),
            maxLines: 3,
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
            onPressed: _isLoading || _returnItems.isEmpty ? null : _createSaleReturn,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFFF5722),
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
                : const Text('Create Return'),
          ),
        ),
      ],
    );
  }

  Future<void> _selectReturnDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _returnDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );

    if (date != null) {
      setState(() {
        _returnDate = date;
      });
    }
  }

  void _addReturnItem(Map<String, dynamic> invoiceItem) {
    showDialog(
      context: context,
      builder: (context) => ReturnQuantityDialog(
        invoiceItem: invoiceItem,
        onQuantitySelected: (quantity) {
          final unitPrice = (invoiceItem['unitPrice'] ?? 0.0).toDouble();
          final totalAmount = unitPrice * quantity;

          final returnItem = ReturnItem(
            itemId: invoiceItem['itemId'] ?? '',
            itemName: invoiceItem['itemName'] ?? '',
            originalQuantity: (invoiceItem['quantity'] ?? 0.0).toDouble(),
            returnQuantity: quantity,
            unitPrice: unitPrice,
            totalAmount: totalAmount,
          );

          setState(() {
            _returnItems.add(returnItem);
            _calculateTotal();
          });
        },
      ),
    );
  }

  void _editReturnItem(int index) {
    final returnItem = _returnItems[index];
    final invoiceItem = _invoiceItems.firstWhere(
          (item) => item['itemId'] == returnItem.itemId,
    );

    showDialog(
      context: context,
      builder: (context) => ReturnQuantityDialog(
        invoiceItem: invoiceItem,
        currentQuantity: returnItem.returnQuantity,
        onQuantitySelected: (quantity) {
          final unitPrice = returnItem.unitPrice;
          final totalAmount = unitPrice * quantity;

          setState(() {
            _returnItems[index] = ReturnItem(
              itemId: returnItem.itemId,
              itemName: returnItem.itemName,
              originalQuantity: returnItem.originalQuantity,
              returnQuantity: quantity,
              unitPrice: unitPrice,
              totalAmount: totalAmount,
            );
            _calculateTotal();
          });
        },
      ),
    );
  }

  void _removeReturnItem(int index) {
    setState(() {
      _returnItems.removeAt(index);
      _calculateTotal();
    });
  }

  Future<void> _createSaleReturn() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final selectedInvoice = _invoices.firstWhere((inv) => inv['id'] == _selectedInvoiceId);

      // Create sale return document
      await _firestore.collection('sale_returns').add({
        'businessId': widget.businessId,
        'creditNoteNumber': _creditNoteNumberController.text.trim(),
        'originalInvoiceId': _selectedInvoiceId,
        'originalInvoiceNumber': selectedInvoice['invoiceNumber'],
        'customerName': selectedInvoice['customerName'],
        'returnDate': Timestamp.fromDate(_returnDate),
        'returnReason': _reasonController.text.trim(),
        'notes': _notesController.text.trim(),
        'returnItems': _returnItems.map((item) => item.toMap()).toList(),
        'returnAmount': _totalReturnAmount,
        'status': 'Completed',
        'createdAt': FieldValue.serverTimestamp(),
      });

      // Update stock for returned items
      for (final item in _returnItems) {
        await StockService.addStock(widget.businessId, item.itemId, 'Main Store', item.returnQuantity);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Sale return created successfully'),
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
    _creditNoteNumberController.dispose();
    _reasonController.dispose();
    _notesController.dispose();
    super.dispose();
  }
}

class ReturnItem {
  final String itemId;
  final String itemName;
  final double originalQuantity;
  final double returnQuantity;
  final double unitPrice;
  final double totalAmount;

  ReturnItem({
    required this.itemId,
    required this.itemName,
    required this.originalQuantity,
    required this.returnQuantity,
    required this.unitPrice,
    required this.totalAmount,
  });

  Map<String, dynamic> toMap() {
    return {
      'itemId': itemId,
      'itemName': itemName,
      'originalQuantity': originalQuantity,
      'returnQuantity': returnQuantity,
      'unitPrice': unitPrice,
      'totalAmount': totalAmount,
    };
  }
}

class ReturnQuantityDialog extends StatefulWidget {
  final Map<String, dynamic> invoiceItem;
  final double? currentQuantity;
  final Function(double) onQuantitySelected;

  const ReturnQuantityDialog({
    super.key,
    required this.invoiceItem,
    required this.onQuantitySelected,
    this.currentQuantity,
  });

  @override
  State<ReturnQuantityDialog> createState() => _ReturnQuantityDialogState();
}

class _ReturnQuantityDialogState extends State<ReturnQuantityDialog> {
  final _quantityController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    if (widget.currentQuantity != null) {
      _quantityController.text = widget.currentQuantity.toString();
    }
  }

  @override
  Widget build(BuildContext context) {
    final maxQuantity = (widget.invoiceItem['quantity'] ?? 0.0).toDouble();

    return AlertDialog(
      title: const Text('Return Quantity'),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.invoiceItem['itemName'] ?? '',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Original Quantity: ${maxQuantity.toStringAsFixed(1)}',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade600,
              ),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _quantityController,
              decoration: const InputDecoration(
                labelText: 'Return Quantity',
                border: OutlineInputBorder(),
              ),
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Quantity is required';
                }
                final quantity = double.tryParse(value);
                if (quantity == null || quantity <= 0) {
                  return 'Enter a valid quantity';
                }
                if (quantity > maxQuantity) {
                  return 'Cannot exceed original quantity';
                }
                return null;
              },
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () {
            if (_formKey.currentState!.validate()) {
              final quantity = double.parse(_quantityController.text);
              widget.onQuantitySelected(quantity);
              Navigator.of(context).pop();
            }
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFFFF5722),
            foregroundColor: Colors.white,
          ),
          child: const Text('Add'),
        ),
      ],
    );
  }

  @override
  void dispose() {
    _quantityController.dispose();
    super.dispose();
  }
}
