import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import '../model/SaleMaster.dart'; // Import the updated SaleMaster and SaleItem
import 'inventory_management.dart'; // To access ItemMaster and its static helpers
import 'package:flutter/foundation.dart'; // Import for debugPrint

/// A screen for adding a new sale or editing an existing one.
class AddEditSaleScreen extends StatefulWidget {
  final String businessId;
  final String? saleId; // Null for new sale, ID for editing
  final DocumentSnapshot? saleDoc; // Optional: pass doc directly for editing

  const AddEditSaleScreen({
    super.key,
    required this.businessId,
    this.saleId,
    this.saleDoc,
  });

  @override
  State<AddEditSaleScreen> createState() => _AddEditSaleScreenState();
}

class _AddEditSaleScreenState extends State<AddEditSaleScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final _formKey = GlobalKey<FormState>();

  // Existing controllers
  final TextEditingController _customerNameController = TextEditingController();
  final TextEditingController _invoiceController = TextEditingController();
  DateTime _selectedDate = DateTime.now();
  List<SaleItem> _saleItems = []; // List to hold items in the current sale
  double _totalSaleAmount = 0.0;
  bool _isLoading = false;

  // NEW GST CONTROLLERS
  final TextEditingController _recipientGSTINController = TextEditingController();
  final TextEditingController _eWayBillController = TextEditingController();
  final TextEditingController _distanceController = TextEditingController();

  // NEW GST DROPDOWNS
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
    if (widget.saleId != null && widget.saleId!.isNotEmpty) {
      _loadSaleData(); // Load data if editing an existing sale
    }
  }

  /// Loads existing sale data for editing.
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
        _saleItems = List.from(sale.items); // Create a mutable copy of items

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

        _calculateOverallTotal(); // Recalculate total based on loaded items
        debugPrint('Sale data loaded for ID: ${widget.saleId}'); // Debug print
      } else {
        debugPrint('Sale document not found for ID: ${widget.saleId}'); // Debug print
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading sale: $e'), backgroundColor: Colors.red),
        );
      }
      debugPrint('Error loading sale: $e'); // Debug print
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  /// GST validation method
  String? _validateGSTIN(String? value) {
    if (value == null || value.trim().isEmpty) return null; // Optional field

    final gstin = value.trim().toUpperCase();
    if (gstin.length != 15) {
      return 'GSTIN must be 15 characters';
    }

    // Basic GSTIN format validation
    final gstinRegex = RegExp(r'^[0-9]{2}[A-Z]{5}[0-9]{4}[A-Z]{1}[1-9A-Z]{1}[Z]{1}[0-9A-Z]{1}$');
    if (!gstinRegex.hasMatch(gstin)) {
      return 'Invalid GSTIN format';
    }

    return null;
  }

  /// Auto-determine supply type based on GSTIN
  void _updateSupplyType() {
    if (_recipientGSTINController.text.length >= 2 && _selectedPlaceOfSupply.isNotEmpty) {
      final recipientStateCode = _recipientGSTINController.text.substring(0, 2);
      final posStateCode = _selectedPlaceOfSupply;

      setState(() {
        _selectedSupplyType = (recipientStateCode == posStateCode) ? 'INTRA' : 'INTER';
      });

      // Auto-update tax structure for all items
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

  /// Calculates the total amount of the sale based on all added items.
  void _calculateOverallTotal() {
    double total = 0.0;
    for (var item in _saleItems) {
      total += item.itemTotal;
    }
    setState(() {
      _totalSaleAmount = total;
    });
  }

  /// Opens a date picker to select the sale date.
  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
      builder: (context, child) {
        return Theme(
          data: ThemeData.light().copyWith(
            colorScheme: const ColorScheme.light(
              primary: Color(0xFF667eea), // Header background color
              onPrimary: Colors.white, // Header text color
              surface: Colors.white, // Dialog background color
              onSurface: Colors.black87, // Text color
            ),
            textButtonTheme: TextButtonThemeData(
              style: TextButton.styleFrom(
                foregroundColor: const Color(0xFF667eea), // Button text color
              ),
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  /// Shows a dialog to add a new item or edit an existing item in the sale.
  Future<void> _addItemToSale({SaleItem? existingItem, int? index}) async {
    String? selectedItemId;
    TextEditingController quantityController = TextEditingController(text: existingItem?.quantity.toString() ?? '1.0');
    ItemMaster? selectedItemMaster;
    final _itemDialogFormKey = GlobalKey<FormState>(); // New form key for item dialog

    if (existingItem != null) {
      selectedItemId = existingItem.itemId;
      // Fetch the ItemMaster for the existing item to pre-populate details
      try {
        final itemDoc = await _firestore.collection('items').doc(selectedItemId).get();
        if (itemDoc.exists) {
          selectedItemMaster = ItemMaster.fromFirestore(itemDoc);
        }
      } catch (e) {
        debugPrint('Error fetching existing item master: $e'); // Debug print
      }
    }

    await showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setStateSB) {
            return AlertDialog(
              title: Text(existingItem == null ? 'Add Item to Sale' : 'Edit Sale Item'),
              content: Form( // Wrap content in a Form
                key: _itemDialogFormKey,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      FutureBuilder<QuerySnapshot>(
                        future: _firestore.collection('items').where('businessId', isEqualTo: widget.businessId).where('isActive', isEqualTo: true).get(),
                        builder: (context, snapshot) {
                          if (snapshot.connectionState == ConnectionState.waiting) {
                            return const CircularProgressIndicator();
                          }
                          if (snapshot.hasError) {
                            debugPrint('Add Item Dialog: Error loading items: ${snapshot.error}'); // Debug print
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
                    if (_itemDialogFormKey.currentState!.validate()) { // Validate before adding/updating
                      if (selectedItemId != null && quantityController.text.isNotEmpty) {
                        final quantity = double.parse(quantityController.text);
                        _calculateAndAddSaleItem(selectedItemId!, quantity, existingItem, index);
                        Navigator.of(context).pop();
                      }
                    } else {
                      debugPrint('Add/Edit Sale Item Dialog: Form validation failed.'); // Debug print
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

  /// Calculates taxes and total for a sale item and adds/updates it in the list.
  Future<void> _calculateAndAddSaleItem(String itemId, double quantity, SaleItem? existingItem, int? index) async {
    try {
      final itemDoc = await _firestore.collection('items').doc(itemId).get();
      if (!itemDoc.exists) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Selected item not found'), backgroundColor: Colors.red),
          );
        }
        debugPrint('Error: Selected item not found for ID: $itemId'); // Debug print
        return;
      }

      final itemMaster = ItemMaster.fromFirestore(itemDoc);
      final sellingPricePerUnit = itemMaster.sellingPrice;
      final totalTaxableValue = sellingPricePerUnit * quantity;

      // Calculate tax amounts based on supply type
      final cgstAmount = _selectedSupplyType == 'INTRA'
          ? totalTaxableValue * (itemMaster.cgstRate / 100)
          : 0.0; // <-- use 0.0 instead of 0

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
          _saleItems[index] = newSaleItem; // Update existing item
          debugPrint('Sale item updated: ${newSaleItem.description}'); // Debug print
        } else {
          _saleItems.add(newSaleItem); // Add new item
          debugPrint('Sale item added: ${newSaleItem.description}'); // Debug print
        }
        _calculateOverallTotal(); // Recalculate total after item change
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error adding item: $e'), backgroundColor: Colors.red),
        );
      }
      debugPrint('Error calculating and adding sale item: $e'); // Debug print
    }
  }

  /// Removes an item from the sale.
  void _removeItemFromSale(int index) {
    final removedItemDescription = _saleItems[index].description;
    setState(() {
      _saleItems.removeAt(index);
      _calculateOverallTotal(); // Recalculate total after item removal
    });
    debugPrint('Sale item removed: $removedItemDescription'); // Debug print
  }

  /// Build GST form fields
  Widget _buildGSTFormFields() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'GST Details',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),

        // Recipient GSTIN
        TextFormField(
          controller: _recipientGSTINController,
          decoration: const InputDecoration(
            labelText: 'Recipient GSTIN (Optional)',
            hintText: 'Enter 15-digit GSTIN',
            border: OutlineInputBorder(),
            filled: true,
            fillColor: Colors.white,
          ),
          textCapitalization: TextCapitalization.characters,
          maxLength: 15,
          validator: _validateGSTIN,
          onChanged: (value) {
            _updateSupplyType();
          },
        ),
        const SizedBox(height: 16),

        // Place of Supply
        DropdownButtonFormField<String>(
          value: _selectedPlaceOfSupply.isEmpty ? null : _selectedPlaceOfSupply,
          decoration: const InputDecoration(
            labelText: 'Place of Supply (POS)',
            border: OutlineInputBorder(),
            filled: true,
            fillColor: Colors.white,
          ),
          items: _stateCodes.map((state) {
            return DropdownMenuItem<String>(
              value: state['code'],
              child: Text('${state['code']} - ${state['name']}'),
            );
          }).toList(),
          onChanged: (value) {
            setState(() {
              _selectedPlaceOfSupply = value ?? '';
            });
            _updateSupplyType();
          },
          validator: (value) => value == null ? 'Please select Place of Supply' : null,
        ),
        const SizedBox(height: 16),

        // Supply Type and Sale Type Row
        Row(
          children: [
            Expanded(
              child: DropdownButtonFormField<String>(
                value: _selectedSupplyType,
                decoration: const InputDecoration(
                  labelText: 'Supply Type',
                  border: OutlineInputBorder(),
                  filled: true,
                  fillColor: Colors.white,
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
            const SizedBox(width: 12),
            Expanded(
              child: DropdownButtonFormField<String>(
                value: _selectedSaleType,
                decoration: const InputDecoration(
                  labelText: 'Sale Type',
                  border: OutlineInputBorder(),
                  filled: true,
                  fillColor: Colors.white,
                ),
                items: const [
                  DropdownMenuItem(value: 'CASH', child: Text('Cash Sale')),
                  DropdownMenuItem(value: 'CREDIT', child: Text('Credit Sale')),
                ],
                onChanged: (value) {
                  setState(() {
                    _selectedSaleType = value ?? 'CASH';
                  });
                },
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),

        // Document Type and Reverse Charge
        Row(
          children: [
            Expanded(
              child: DropdownButtonFormField<String>(
                value: _selectedDocumentType,
                decoration: const InputDecoration(
                  labelText: 'Document Type',
                  border: OutlineInputBorder(),
                  filled: true,
                  fillColor: Colors.white,
                ),
                items: const [
                  DropdownMenuItem(value: 'INV', child: Text('Invoice')),
                  DropdownMenuItem(value: 'DBN', child: Text('Debit Note')),
                  DropdownMenuItem(value: 'CDN', child: Text('Credit Note')),
                ],
                onChanged: (value) {
                  setState(() {
                    _selectedDocumentType = value ?? 'INV';
                  });
                },
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: CheckboxListTile(
                title: const Text('Reverse Charge'),
                value: _isReverseCharge,
                onChanged: (value) {
                  setState(() {
                    _isReverseCharge = value ?? false;
                  });
                },
                contentPadding: EdgeInsets.zero,
                controlAffinity: ListTileControlAffinity.leading,
              ),
            ),
          ],
        ),

        // E-Way Bill Section (show only for goods > 50k value)
        if (_totalSaleAmount > 50000) ...[
          const SizedBox(height: 16),
          const Text(
            'E-Way Bill Details (Required for sales > ₹50,000)',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _eWayBillController,
            decoration: const InputDecoration(
              labelText: 'E-Way Bill Number',
              border: OutlineInputBorder(),
              filled: true,
              fillColor: Colors.white,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: DropdownButtonFormField<String>(
                  value: _selectedTransportMode,
                  decoration: const InputDecoration(
                    labelText: 'Transport Mode',
                    border: OutlineInputBorder(),
                    filled: true,
                    fillColor: Colors.white,
                  ),
                  items: const [
                    DropdownMenuItem(value: 'Road', child: Text('Road')),
                    DropdownMenuItem(value: 'Rail', child: Text('Rail')),
                    DropdownMenuItem(value: 'Air', child: Text('Air')),
                    DropdownMenuItem(value: 'Ship', child: Text('Ship')),
                  ],
                  onChanged: (value) {
                    setState(() {
                      _selectedTransportMode = value ?? 'Road';
                    });
                  },
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TextFormField(
                  controller: _distanceController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Distance (km)',
                    border: OutlineInputBorder(),
                    filled: true,
                    fillColor: Colors.white,
                  ),
                ),
              ),
            ],
          ),
        ],
        const SizedBox(height: 24),
      ],
    );
  }

  /// Saves or updates the sale in Firestore.
  Future<void> _saveSale() async {
    if (!_formKey.currentState!.validate()) {
      debugPrint('Save Sale: Form validation failed.'); // Debug print
      return;
    }
    if (_saleItems.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please add at least one item to the sale'),
            backgroundColor: Colors.orange,
            duration: Duration(seconds: 3), // Increased duration
          ),
        );
      }
      debugPrint('Save Sale: No items added to sale.'); // Debug print
      return;
    }

    setState(() => _isLoading = true);

    try {
      // Determine GSTR-1 section
      String gstr1Section = 'B2C_SMALL';
      if (_recipientGSTINController.text.trim().isNotEmpty) {
        gstr1Section = 'B2B';
      } else if (_totalSaleAmount > 250000) {
        gstr1Section = 'B2C_LARGE';
      }

      final saleData = SaleMaster(
        id: widget.saleId ?? '', // ID will be set by Firestore for new sales
        businessId: widget.businessId,
        invoice: _invoiceController.text.trim(),
        customerName: _customerNameController.text.trim(),
        date: _selectedDate,
        total: _totalSaleAmount,
        items: _saleItems, // Save the list of sale items
        // GST FIELDS
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
        debugPrint('Sale updated successfully for ID: ${widget.saleId}'); // Debug print
      } else {
        final docRef = await _firestore.collection('sales').add(saleData);
        debugPrint('Sale added successfully with ID: ${docRef.id}'); // Debug print
      }

      if (mounted) {
        Navigator.of(context).pop(); // Go back to previous screen
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
      debugPrint('Error saving sale: $e'); // Debug print
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
    _recipientGSTINController.dispose();
    _eWayBillController.dispose();
    _distanceController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.saleId != null ? 'Edit Sale' : 'New Sale'),
        backgroundColor: const Color(0xFF667eea),
        foregroundColor: Colors.white,
      ),
      body: _isLoading && widget.saleId != null
          ? const Center(child: CircularProgressIndicator()) // Show loading for existing sale
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
                    TextFormField(
                      controller: _customerNameController,
                      decoration: const InputDecoration(
                        labelText: 'Customer Name',
                        border: OutlineInputBorder(),
                        filled: true,
                        fillColor: Colors.white,
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Please enter customer name';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _invoiceController,
                      decoration: const InputDecoration(
                        labelText: 'Invoice Number',
                        border: OutlineInputBorder(),
                        filled: true,
                        fillColor: Colors.white,
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Please enter invoice number';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    GestureDetector(
                      onTap: () => _selectDate(context),
                      child: AbsorbPointer(
                        child: TextFormField(
                          decoration: InputDecoration(
                            labelText: 'Date',
                            border: const OutlineInputBorder(),
                            suffixIcon: const Icon(Icons.calendar_today),
                            hintText: DateFormat('dd/MM/yyyy').format(_selectedDate),
                            filled: true,
                            fillColor: Colors.white,
                          ),
                          controller: TextEditingController(
                            text: DateFormat('dd/MM/yyyy').format(_selectedDate),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // GST FORM FIELDS
                    _buildGSTFormFields(),

                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Items in Sale',
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
                    const SizedBox(height: 16),
                    _saleItems.isEmpty
                        ? const Center(
                      child: Padding(
                        padding: EdgeInsets.all(24.0),
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
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          clipBehavior: Clip.hardEdge,
                          child: ConstrainedBox(
                            constraints: BoxConstraints(minWidth: MediaQuery.of(context).size.width - 32),
                            child: DataTable(
                              columnSpacing: 12,
                              horizontalMargin: 12,
                              headingRowColor: MaterialStateProperty.resolveWith((states) => const Color(0xFF667eea).withOpacity(0.1)),
                              dataRowColor: MaterialStateProperty.resolveWith((states) {
                                if (states.contains(MaterialState.selected)) {
                                  return Theme.of(context).colorScheme.primary.withOpacity(0.08);
                                }
                                return null;
                              }),
                              decoration: BoxDecoration(
                                border: Border.all(color: Colors.grey.shade200),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              columns: [
                                DataColumn(label: Text('Sr No.', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey.shade700))),
                                DataColumn(label: Text('HSN', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey.shade700))),
                                DataColumn(label: Text('Description', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey.shade700))),
                                DataColumn(label: Text('UQC', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey.shade700))),
                                DataColumn(label: Text('Qty', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey.shade700))),
                                DataColumn(label: Text('Taxable Value (₹)', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey.shade700))),
                                DataColumn(label: Text('Rate (%)', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey.shade700))),
                                DataColumn(label: Text('IGST (₹)', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey.shade700))),
                                DataColumn(label: Text('CGST (₹)', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey.shade700))),
                                DataColumn(label: Text('SGST (₹)', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey.shade700))),
                                DataColumn(label: Text('Cess (₹)', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey.shade700))),
                                DataColumn(label: Text('Total (₹)', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black87))),
                                DataColumn(label: Text('Actions', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey.shade700))),
                              ],
                              rows: List<DataRow>.generate(
                                _saleItems.length,
                                    (index) {
                                  final item = _saleItems[index];
                                  // Determine the applicable tax rate for display
                                  final totalTaxRate = item.igstRate > 0 ? item.igstRate : (item.cgstRate + item.sgstRate);
                                  return DataRow(
                                    cells: [
                                      DataCell(Text((index + 1).toString(), style: TextStyle(color: Colors.grey.shade800))),
                                      DataCell(Text(item.hsnSacCode, style: TextStyle(color: Colors.grey.shade800))),
                                      DataCell(Text(item.description, style: TextStyle(color: Colors.grey.shade800))),
                                      DataCell(Text(item.unitOfMeasurement, style: TextStyle(color: Colors.grey.shade800))),
                                      DataCell(Text(item.quantity.toStringAsFixed(1), style: TextStyle(color: Colors.grey.shade800))),
                                      DataCell(Text(item.totalTaxableValue.toStringAsFixed(2), style: TextStyle(color: Colors.grey.shade800))),
                                      DataCell(Text('${totalTaxRate.toStringAsFixed(1)}%', style: TextStyle(color: Colors.grey.shade800))),
                                      DataCell(Text(item.integratedTaxAmount.toStringAsFixed(2), style: TextStyle(color: Colors.grey.shade800))),
                                      DataCell(Text(item.centralTaxAmount.toStringAsFixed(2), style: TextStyle(color: Colors.grey.shade800))),
                                      DataCell(Text(item.stateTaxAmount.toStringAsFixed(2), style: TextStyle(color: Colors.grey.shade800))),
                                      DataCell(Text(item.cessAmount.toStringAsFixed(2), style: TextStyle(color: Colors.grey.shade800))),
                                      DataCell(Text(item.itemTotal.toStringAsFixed(2), style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black87))),
                                      DataCell(
                                        Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            IconButton(
                                              icon: const Icon(Icons.edit, size: 20, color: Colors.orange),
                                              onPressed: () => _addItemToSale(existingItem: item, index: index),
                                            ),
                                            IconButton(
                                              icon: const Icon(Icons.delete, size: 20, color: Colors.red),
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
                      ),
                    ),
                    const SizedBox(height: 24),
                    Align(
                      alignment: Alignment.centerRight,
                      child: Text(
                        'Total Sale Amount: ₹${_totalSaleAmount.toStringAsFixed(2)}',
                        style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF667eea)),
                      ),
                    ),
                  ],
                ),
              ),
            ),
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
}