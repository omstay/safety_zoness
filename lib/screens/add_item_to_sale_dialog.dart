import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../model/sale_item.dart';

class AddItemToSaleDialog extends StatefulWidget {
  final String businessId;
  final Function(SaleItem) onItemAdded;
  final SaleItem? existingItem; // For editing existing items

  const AddItemToSaleDialog({
    super.key,
    required this.businessId,
    required this.onItemAdded,
    this.existingItem,
  });

  @override
  State<AddItemToSaleDialog> createState() => _AddItemToSaleDialogState();
}

class _AddItemToSaleDialogState extends State<AddItemToSaleDialog> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final _formKey = GlobalKey<FormState>();

  // Controllers
  final _quantityController = TextEditingController();
  final _rateController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _hsnController = TextEditingController();
  final _uqcController = TextEditingController(text: 'NOS');

  // Selected item from dropdown
  String? _selectedItemId;
  List<Map<String, dynamic>> _items = [];
  bool _isLoading = false;

  // Tax calculations
  double _taxableValue = 0.0;
  double _cgstAmount = 0.0;
  double _sgstAmount = 0.0;
  double _igstAmount = 0.0;
  double _cessAmount = 0.0;
  double _totalAmount = 0.0;

  // Tax rates (will be populated from selected item)
  double _cgstRate = 0.0;
  double _sgstRate = 0.0;
  double _igstRate = 0.0;
  double _cessRate = 0.0;

  @override
  void initState() {
    super.initState();
    _loadItems();
    _initializeExistingItem();
  }

  void _initializeExistingItem() {
    if (widget.existingItem != null) {
      final item = widget.existingItem!;
      _quantityController.text = item.quantity.toString();
      _rateController.text = item.rate.toString();
      _descriptionController.text = item.description;
      _hsnController.text = item.hsnCode;
      _uqcController.text = item.uqc;
      _selectedItemId = item.itemId;
      _cgstRate = item.cgstRate;
      _sgstRate = item.sgstRate;
      _igstRate = item.igstRate;
      _cessRate = item.cessRate;
      _calculateTotals();
    }
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
            'description': data['description'] ?? '',
            'hsnSacCode': data['hsnSacCode'] ?? '',
            'sellingPrice': (data['sellingPrice'] ?? 0).toDouble(),
            'cgstRate': (data['cgstRate'] ?? 0).toDouble(),
            'sgstRate': (data['sgstRate'] ?? 0).toDouble(),
            'igstRate': (data['igstRate'] ?? 0).toDouble(),
            'cessRate': (data['cessRate'] ?? 0).toDouble(),
            'unitOfMeasurement': data['unitOfMeasurement'] ?? 'NOS',
          };
        }).toList();
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading items: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _onItemSelected(String? itemId) {
    if (itemId == null) return;

    final selectedItem = _items.firstWhere((item) => item['id'] == itemId);

    setState(() {
      _selectedItemId = itemId;
      _descriptionController.text = selectedItem['description'];
      _hsnController.text = selectedItem['hsnSacCode'];
      _rateController.text = selectedItem['sellingPrice'].toString();
      _uqcController.text = selectedItem['unitOfMeasurement'];
      _cgstRate = selectedItem['cgstRate'];
      _sgstRate = selectedItem['sgstRate'];
      _igstRate = selectedItem['igstRate'];
      _cessRate = selectedItem['cessRate'];
    });

    _calculateTotals();
  }

  void _calculateTotals() {
    final quantity = double.tryParse(_quantityController.text) ?? 0;
    final rate = double.tryParse(_rateController.text) ?? 0;

    setState(() {
      _taxableValue = quantity * rate;
      _cgstAmount = (_taxableValue * _cgstRate) / 100;
      _sgstAmount = (_taxableValue * _sgstRate) / 100;
      _igstAmount = (_taxableValue * _igstRate) / 100;
      _cessAmount = (_taxableValue * _cessRate) / 100;
      _totalAmount = _taxableValue + _cgstAmount + _sgstAmount + _igstAmount + _cessAmount;
    });
  }

  void _saveItem() {
    if (!_formKey.currentState!.validate()) return;

    final saleItem = SaleItem(
      id: widget.existingItem?.id ?? DateTime.now().millisecondsSinceEpoch.toString(),
      itemId: _selectedItemId ?? '',
      hsnCode: _hsnController.text.trim(),
      description: _descriptionController.text.trim(),
      descriptionAsPerHsn: _descriptionController.text.trim(),
      uqc: _uqcController.text.trim(),
      quantity: double.tryParse(_quantityController.text) ?? 0,
      rate: double.tryParse(_rateController.text) ?? 0,
      taxableValue: _taxableValue,
      cgstRate: _cgstRate,
      sgstRate: _sgstRate,
      igstRate: _igstRate,
      cessRate: _cessRate,
      cgstAmount: _cgstAmount,
      sgstAmount: _sgstAmount,
      igstAmount: _igstAmount,
      cessAmount: _cessAmount,
      totalAmount: _totalAmount,
    );

    widget.onItemAdded(saleItem);
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: Container(
        width: MediaQuery.of(context).size.width * 0.9,
        height: MediaQuery.of(context).size.height * 0.8,
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  widget.existingItem != null ? 'Edit Item' : 'Add Item to Sale',
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
            const Divider(),

            // Form
            Expanded(
              child: Form(
                key: _formKey,
                child: SingleChildScrollView(
                  child: Column(
                    children: [
                      // Item Selection Dropdown
                      DropdownButtonFormField<String>(
                        value: _selectedItemId,
                        decoration: const InputDecoration(
                          labelText: 'Select Item',
                          border: OutlineInputBorder(),
                        ),
                        items: _items.map((item) {
                          return DropdownMenuItem<String>(
                            value: item['id'],
                            child: Text(
                              item['description'].isNotEmpty
                                  ? item['description']
                                  : 'Unnamed Item',
                              overflow: TextOverflow.ellipsis,
                            ),
                          );
                        }).toList(),
                        onChanged: _onItemSelected,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please select an item';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),

                      // HSN Code and Description Row
                      Row(
                        children: [
                          Expanded(
                            flex: 1,
                            child: TextFormField(
                              controller: _hsnController,
                              decoration: const InputDecoration(
                                labelText: 'HSN Code',
                                border: OutlineInputBorder(),
                              ),
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
                            flex: 2,
                            child: TextFormField(
                              controller: _descriptionController,
                              decoration: const InputDecoration(
                                labelText: 'Description',
                                border: OutlineInputBorder(),
                              ),
                              validator: (value) {
                                if (value == null || value.trim().isEmpty) {
                                  return 'Required';
                                }
                                return null;
                              },
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // UQC, Quantity, Rate Row
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: _uqcController,
                              decoration: const InputDecoration(
                                labelText: 'UQC',
                                border: OutlineInputBorder(),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: TextFormField(
                              controller: _quantityController,
                              keyboardType: const TextInputType.numberWithOptions(decimal: true),
                              decoration: const InputDecoration(
                                labelText: 'Quantity',
                                border: OutlineInputBorder(),
                              ),
                              onChanged: (value) => _calculateTotals(),
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
                              controller: _rateController,
                              keyboardType: const TextInputType.numberWithOptions(decimal: true),
                              decoration: const InputDecoration(
                                labelText: 'Rate (₹)',
                                border: OutlineInputBorder(),
                              ),
                              onChanged: (value) => _calculateTotals(),
                              validator: (value) {
                                if (value == null || value.trim().isEmpty) {
                                  return 'Required';
                                }
                                final parsed = double.tryParse(value);
                                if (parsed == null || parsed <= 0) {
                                  return 'Invalid rate';
                                }
                                return null;
                              },
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),

                      // Tax Calculation Display
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade50,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.grey.shade300),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Tax Calculation',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 12),
                            _buildTaxRow('Taxable Value', _taxableValue),
                            if (_cgstRate > 0) _buildTaxRow('CGST (${_cgstRate.toStringAsFixed(1)}%)', _cgstAmount),
                            if (_sgstRate > 0) _buildTaxRow('SGST (${_sgstRate.toStringAsFixed(1)}%)', _sgstAmount),
                            if (_igstRate > 0) _buildTaxRow('IGST (${_igstRate.toStringAsFixed(1)}%)', _igstAmount),
                            if (_cessRate > 0) _buildTaxRow('Cess (${_cessRate.toStringAsFixed(1)}%)', _cessAmount),
                            const Divider(),
                            _buildTaxRow('Total Amount', _totalAmount, isTotal: true),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // Action Buttons
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Cancel'),
                ),
                const SizedBox(width: 12),
                ElevatedButton(
                  onPressed: _saveItem,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF667eea),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  ),
                  child: Text(widget.existingItem != null ? 'Update Item' : 'Add Item'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTaxRow(String label, double amount, {bool isTotal = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
              fontSize: isTotal ? 16 : 14,
            ),
          ),
          Text(
            '₹${amount.toStringAsFixed(2)}',
            style: TextStyle(
              fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
              fontSize: isTotal ? 16 : 14,
              color: isTotal ? Colors.green : Colors.black87,
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _quantityController.dispose();
    _rateController.dispose();
    _descriptionController.dispose();
    _hsnController.dispose();
    _uqcController.dispose();
    super.dispose();
  }
}
