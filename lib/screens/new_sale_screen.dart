import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

import '../model/sale_item.dart';
import 'add_item_to_sale_dialog.dart';


class NewSaleScreen extends StatefulWidget {
  final String businessId;
  final String? saleId; // For editing existing sales

  const NewSaleScreen({
    super.key,
    required this.businessId,
    this.saleId,
  });

  @override
  State<NewSaleScreen> createState() => _NewSaleScreenState();
}

class _NewSaleScreenState extends State<NewSaleScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final _formKey = GlobalKey<FormState>();

  // Controllers
  final _customerNameController = TextEditingController();
  final _customerAddressController = TextEditingController();
  final _customerGstinController = TextEditingController();
  final _invoiceNumberController = TextEditingController();
  final _searchController = TextEditingController();

  // Sale data
  List<SaleItem> _saleItems = [];
  DateTime _saleDate = DateTime.now();
  bool _isLoading = false;
  String _searchQuery = '';

  // Totals
  double _totalTaxableValue = 0.0;
  double _totalCgstAmount = 0.0;
  double _totalSgstAmount = 0.0;
  double _totalIgstAmount = 0.0;
  double _totalCessAmount = 0.0;
  double _grandTotal = 0.0;

  @override
  void initState() {
    super.initState();
    _generateInvoiceNumber();
    if (widget.saleId != null) {
      _loadExistingSale();
    }
  }

  void _generateInvoiceNumber() {
    final now = DateTime.now();
    final invoiceNumber = 'INV${now.year}${now.month.toString().padLeft(2, '0')}${now.day.toString().padLeft(2, '0')}${now.millisecondsSinceEpoch.toString().substring(8)}';
    _invoiceNumberController.text = invoiceNumber;
  }

  Future<void> _loadExistingSale() async {
    // Implementation for loading existing sale for editing
    // This would load the sale data from Firestore
  }

  void _addItem() {
    showDialog(
      context: context,
      builder: (context) => AddItemToSaleDialog(
        businessId: widget.businessId,
        onItemAdded: (saleItem) {
          setState(() {
            _saleItems.add(saleItem);
          });
          _calculateTotals();
        },
      ),
    );
  }

  void _editItem(int index) {
    showDialog(
      context: context,
      builder: (context) => AddItemToSaleDialog(
        businessId: widget.businessId,
        existingItem: _saleItems[index],
        onItemAdded: (saleItem) {
          setState(() {
            _saleItems[index] = saleItem;
          });
          _calculateTotals();
        },
      ),
    );
  }

  void _removeItem(int index) {
    setState(() {
      _saleItems.removeAt(index);
    });
    _calculateTotals();
  }

  void _calculateTotals() {
    double taxableValue = 0.0;
    double cgstAmount = 0.0;
    double sgstAmount = 0.0;
    double igstAmount = 0.0;
    double cessAmount = 0.0;
    double grandTotal = 0.0;

    for (final item in _saleItems) {
      taxableValue += item.taxableValue;
      cgstAmount += item.cgstAmount;
      sgstAmount += item.sgstAmount;
      igstAmount += item.igstAmount;
      cessAmount += item.cessAmount;
      grandTotal += item.totalAmount;
    }

    setState(() {
      _totalTaxableValue = taxableValue;
      _totalCgstAmount = cgstAmount;
      _totalSgstAmount = sgstAmount;
      _totalIgstAmount = igstAmount;
      _totalCessAmount = cessAmount;
      _grandTotal = grandTotal;
    });
  }

  Future<void> _saveSale() async {
    if (!_formKey.currentState!.validate() || _saleItems.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please add at least one item to the sale'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final saleData = {
        'businessId': widget.businessId,
        'customerName': _customerNameController.text.trim(),
        'customerAddress': _customerAddressController.text.trim(),
        'customerGstin': _customerGstinController.text.trim(),
        'invoice': _invoiceNumberController.text.trim(),
        'date': Timestamp.fromDate(_saleDate),
        'items': _saleItems.map((item) => item.toMap()).toList(),
        'totalTaxableValue': _totalTaxableValue,
        'totalCgstAmount': _totalCgstAmount,
        'totalSgstAmount': _totalSgstAmount,
        'totalIgstAmount': _totalIgstAmount,
        'totalCessAmount': _totalCessAmount,
        'total': _grandTotal,
        'createdAt': FieldValue.serverTimestamp(),
      };

      if (widget.saleId != null) {
        await _firestore.collection('sales').doc(widget.saleId).update(saleData);
      } else {
        await _firestore.collection('sales').add(saleData);
      }

      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(widget.saleId != null ? 'Sale updated successfully' : 'Sale created successfully'),
            backgroundColor: Colors.green,
          ),
        );
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
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        title: Text(widget.saleId != null ? 'Edit Sale' : 'New Sale'),
        backgroundColor: Colors.white,
        elevation: 0,
        actions: [
          if (_isLoading)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(16.0),
                child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ),
            )
          else
            TextButton.icon(
              onPressed: _saveSale,
              icon: const Icon(Icons.save),
              label: const Text('Save Sale'),
              style: TextButton.styleFrom(
                foregroundColor: const Color(0xFF667eea),
              ),
            ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: Column(
          children: [
            // Customer Details Section
            Container(
              margin: const EdgeInsets.all(16),
              padding: const EdgeInsets.all(16),
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
                    'Customer Details',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: _invoiceNumberController,
                          decoration: const InputDecoration(
                            labelText: 'Invoice Number',
                            border: OutlineInputBorder(),
                          ),
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'Invoice number is required';
                            }
                            return null;
                          },
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: InkWell(
                          onTap: () async {
                            final date = await showDatePicker(
                              context: context,
                              initialDate: _saleDate,
                              firstDate: DateTime(2020),
                              lastDate: DateTime.now().add(const Duration(days: 365)),
                            );
                            if (date != null) {
                              setState(() {
                                _saleDate = date;
                              });
                            }
                          },
                          child: Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              border: Border.all(color: Colors.grey),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.calendar_today, size: 20),
                                const SizedBox(width: 8),
                                Text(DateFormat('dd/MM/yyyy').format(_saleDate)),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _customerNameController,
                    decoration: const InputDecoration(
                      labelText: 'Customer Name',
                      border: OutlineInputBorder(),
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Customer name is required';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _customerAddressController,
                    decoration: const InputDecoration(
                      labelText: 'Customer Address',
                      border: OutlineInputBorder(),
                    ),
                    maxLines: 2,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _customerGstinController,
                    decoration: const InputDecoration(
                      labelText: 'Customer GSTIN (Optional)',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ],
              ),
            ),

            // Items Section
            Expanded(
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 16),
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
                  children: [
                    // Items Header
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: const BoxDecoration(
                        border: Border(
                          bottom: BorderSide(color: Colors.grey, width: 0.5),
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Added/Edited Items to be saved',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Row(
                            children: [
                              SizedBox(
                                width: 200,
                                child: TextField(
                                  controller: _searchController,
                                  decoration: const InputDecoration(
                                    hintText: 'Search',
                                    prefixIcon: Icon(Icons.search, size: 20),
                                    border: OutlineInputBorder(),
                                    contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                  ),
                                  onChanged: (value) {
                                    setState(() {
                                      _searchQuery = value.toLowerCase();
                                    });
                                  },
                                ),
                              ),
                              const SizedBox(width: 12),
                              ElevatedButton.icon(
                                onPressed: _addItem,
                                icon: const Icon(Icons.add, size: 20),
                                label: const Text('Add Item'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF667eea),
                                  foregroundColor: Colors.white,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),

                    // Items Table
                    Expanded(
                      child: _saleItems.isEmpty
                          ? const Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.receipt_long_outlined, size: 64, color: Colors.grey),
                            SizedBox(height: 16),
                            Text(
                              'No items added yet',
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.grey,
                              ),
                            ),
                            SizedBox(height: 8),
                            Text(
                              'Click "Add Item" to start building your invoice',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey,
                              ),
                            ),
                          ],
                        ),
                      )
                          : SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: DataTable(
                          columnSpacing: 20,
                          headingRowColor: MaterialStateProperty.all(Colors.grey.shade100),
                          columns: const [
                            DataColumn(label: Text('Sr. No.', style: TextStyle(fontWeight: FontWeight.bold))),
                            DataColumn(label: Text('HSN', style: TextStyle(fontWeight: FontWeight.bold))),
                            DataColumn(label: Text('Description', style: TextStyle(fontWeight: FontWeight.bold))),
                            DataColumn(label: Text('UQC', style: TextStyle(fontWeight: FontWeight.bold))),
                            DataColumn(label: Text('Total Quantity', style: TextStyle(fontWeight: FontWeight.bold))),
                            DataColumn(label: Text('Total taxable value (₹)', style: TextStyle(fontWeight: FontWeight.bold))),
                            DataColumn(label: Text('Rate (%)', style: TextStyle(fontWeight: FontWeight.bold))),
                            DataColumn(label: Text('Integrated tax (₹)', style: TextStyle(fontWeight: FontWeight.bold))),
                            DataColumn(label: Text('Central tax (₹)', style: TextStyle(fontWeight: FontWeight.bold))),
                            DataColumn(label: Text('State/UT tax (₹)', style: TextStyle(fontWeight: FontWeight.bold))),
                            DataColumn(label: Text('Cess (₹)', style: TextStyle(fontWeight: FontWeight.bold))),
                            DataColumn(label: Text('Actions', style: TextStyle(fontWeight: FontWeight.bold))),
                          ],
                          rows: _saleItems
                              .asMap()
                              .entries
                              .where((entry) =>
                          _searchQuery.isEmpty ||
                              entry.value.description.toLowerCase().contains(_searchQuery) ||
                              entry.value.hsnCode.toLowerCase().contains(_searchQuery))
                              .map((entry) {
                            final index = entry.key;
                            final item = entry.value;
                            return DataRow(
                              cells: [
                                DataCell(Text('${index + 1}')),
                                DataCell(Text(item.hsnCode)),
                                DataCell(
                                  SizedBox(
                                    width: 150,
                                    child: Text(
                                      item.description,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ),
                                DataCell(Text(item.uqc)),
                                DataCell(Text(item.quantity.toStringAsFixed(0))),
                                DataCell(Text(item.taxableValue.toStringAsFixed(2))),
                                DataCell(Text('${(item.cgstRate + item.sgstRate + item.igstRate).toStringAsFixed(0)}%')),
                                DataCell(Text(item.igstAmount.toStringAsFixed(2))),
                                DataCell(Text(item.cgstAmount.toStringAsFixed(2))),
                                DataCell(Text(item.sgstAmount.toStringAsFixed(2))),
                                DataCell(Text(item.cessAmount.toStringAsFixed(2))),
                                DataCell(
                                  Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      IconButton(
                                        onPressed: () => _editItem(index),
                                        icon: const Icon(Icons.edit, size: 18),
                                        tooltip: 'Edit',
                                      ),
                                      IconButton(
                                        onPressed: () => _removeItem(index),
                                        icon: const Icon(Icons.delete, size: 18, color: Colors.red),
                                        tooltip: 'Delete',
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            );
                          }).toList(),
                        ),
                      ),
                    ),

                    // Totals Section
                    if (_saleItems.isNotEmpty)
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: const BoxDecoration(
                          border: Border(
                            top: BorderSide(color: Colors.grey, width: 0.5),
                          ),
                        ),
                        child: Column(
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                SizedBox(
                                  width: 300,
                                  child: Column(
                                    children: [
                                      _buildTotalRow('Total Taxable Value:', _totalTaxableValue),
                                      if (_totalCgstAmount > 0) _buildTotalRow('Total CGST:', _totalCgstAmount),
                                      if (_totalSgstAmount > 0) _buildTotalRow('Total SGST:', _totalSgstAmount),
                                      if (_totalIgstAmount > 0) _buildTotalRow('Total IGST:', _totalIgstAmount),
                                      if (_totalCessAmount > 0) _buildTotalRow('Total Cess:', _totalCessAmount),
                                      const Divider(thickness: 2),
                                      _buildTotalRow('Grand Total:', _grandTotal, isGrandTotal: true),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildTotalRow(String label, double amount, {bool isGrandTotal = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontWeight: isGrandTotal ? FontWeight.bold : FontWeight.w500,
              fontSize: isGrandTotal ? 16 : 14,
            ),
          ),
          Text(
            '₹${amount.toStringAsFixed(2)}',
            style: TextStyle(
              fontWeight: isGrandTotal ? FontWeight.bold : FontWeight.w500,
              fontSize: isGrandTotal ? 16 : 14,
              color: isGrandTotal ? Colors.green : Colors.black87,
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _customerNameController.dispose();
    _customerAddressController.dispose();
    _customerGstinController.dispose();
    _invoiceNumberController.dispose();
    _searchController.dispose();
    super.dispose();
  }
}
