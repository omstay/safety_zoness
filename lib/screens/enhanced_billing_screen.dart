// import 'package:flutter/material.dart';
// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:intl/intl.dart';
// import '../model/item_master.dart';
// import '../utils/gst_utils.dart';
// import 'inventory_management.dart' hide ItemMaster;
//
// // Customer/Party Model
// class Party {
//   final String id;
//   final String businessId;
//   final String name;
//   final String address;
//   final String phone;
//   final String email;
//   final String gstin;
//   final String stateCode;
//   final bool isB2B;
//   final DateTime createdAt;
//
//   Party({
//     required this.id,
//     required this.businessId,
//     required this.name,
//     required this.address,
//     required this.phone,
//     required this.email,
//     required this.gstin,
//     required this.stateCode,
//     required this.isB2B,
//     required this.createdAt,
//   });
//
//   factory Party.fromFirestore(DocumentSnapshot doc) {
//     final data = doc.data() as Map<String, dynamic>;
//     return Party(
//       id: doc.id,
//       businessId: data['businessId'] ?? '',
//       name: data['name'] ?? '',
//       address: data['address'] ?? '',
//       phone: data['phone'] ?? '',
//       email: data['email'] ?? '',
//       gstin: data['gstin'] ?? '',
//       stateCode: data['stateCode'] ?? '',
//       isB2B: data['isB2B'] ?? false,
//       createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
//     );
//   }
//
//   Map<String, dynamic> toFirestore() {
//     return {
//       'businessId': businessId,
//       'name': name,
//       'address': address,
//       'phone': phone,
//       'email': email,
//       'gstin': gstin,
//       'stateCode': stateCode,
//       'isB2B': isB2B,
//       'createdAt': Timestamp.fromDate(createdAt),
//     };
//   }
// }
//
// // Invoice Item Model
// class InvoiceItem {
//   final String itemId;
//   final String itemName;
//   final String itemCode;
//   final String hsnCode;
//   final double quantity;
//   final String unit;
//   final double rate;
//   final double taxableValue;
//   final double cgstRate;
//   final double sgstRate;
//   final double igstRate;
//   final double cgstAmount;
//   final double sgstAmount;
//   final double igstAmount;
//   final double totalAmount;
//   final bool isTaxExempt;
//   final String taxCategory;
//
//   InvoiceItem({
//     required this.itemId,
//     required this.itemName,
//     required this.itemCode,
//     required this.hsnCode,
//     required this.quantity,
//     required this.unit,
//     required this.rate,
//     required this.taxableValue,
//     required this.cgstRate,
//     required this.sgstRate,
//     required this.igstRate,
//     required this.cgstAmount,
//     required this.sgstAmount,
//     required this.igstAmount,
//     required this.totalAmount,
//     required this.isTaxExempt,
//     required this.taxCategory,
//   });
//
//   factory InvoiceItem.fromItem(ItemMaster item, double quantity, bool isInterstate) {
//     final taxableValue = quantity * item.sellingPrice;
//     Map<String, double> gstCalculation;
//
//     if (item.isTaxExempt) {
//       gstCalculation = {
//         'cgst': 0.0,
//         'sgst': 0.0,
//         'igst': 0.0,
//         'totalTax': 0.0,
//       };
//     } else {
//       gstCalculation = GSTUtils.calculateGST(
//           taxableValue,
//           item.cgstRate,
//           item.sgstRate,
//           item.igstRate,
//           isInterstate
//       );
//     }
//
//     return InvoiceItem(
//       itemId: item.id,
//       itemName: item.itemName,
//       itemCode: item.itemCode,
//       hsnCode: item.hsnSacCode,
//       quantity: quantity,
//       unit: item.unitOfMeasurement,
//       rate: item.sellingPrice,
//       taxableValue: taxableValue,
//       cgstRate: item.cgstRate,
//       sgstRate: item.sgstRate,
//       igstRate: item.igstRate,
//       cgstAmount: gstCalculation['cgst']!,
//       sgstAmount: gstCalculation['sgst']!,
//       igstAmount: gstCalculation['igst']!,
//       totalAmount: taxableValue + gstCalculation['totalTax']!,
//       isTaxExempt: item.isTaxExempt,
//       taxCategory: item.taxCategory,
//     );
//   }
//
//   Map<String, dynamic> toFirestore() {
//     return {
//       'itemId': itemId,
//       'itemName': itemName,
//       'itemCode': itemCode,
//       'hsnCode': hsnCode,
//       'quantity': quantity,
//       'unit': unit,
//       'rate': rate,
//       'taxableValue': taxableValue,
//       'cgstRate': cgstRate,
//       'sgstRate': sgstRate,
//       'igstRate': igstRate,
//       'cgstAmount': cgstAmount,
//       'sgstAmount': sgstAmount,
//       'igstAmount': igstAmount,
//       'totalAmount': totalAmount,
//       'isTaxExempt': isTaxExempt,
//       'taxCategory': taxCategory,
//     };
//   }
// }
//
// // Enhanced Billing Screen
// class EnhancedBillingScreen extends StatefulWidget {
//   final String businessId;
//   final String? invoiceId;
//
//   const EnhancedBillingScreen({
//     super.key,
//     required this.businessId,
//     this.invoiceId,
//   });
//
//   @override
//   State<EnhancedBillingScreen> createState() => _EnhancedBillingScreenState();
// }
//
// class _EnhancedBillingScreenState extends State<EnhancedBillingScreen> {
//   final FirebaseFirestore _firestore = FirebaseFirestore.instance;
//   final _formKey = GlobalKey<FormState>();
//
//   // Controllers
//   final _invoiceNumberController = TextEditingController();
//   final _searchController = TextEditingController();
//
//   // State variables
//   DateTime _invoiceDate = DateTime.now();
//   Party? _selectedParty;
//   String _paymentType = 'Cash';
//   List<InvoiceItem> _invoiceItems = [];
//   List<ItemMaster> _availableItems = [];
//   List<ItemMaster> _filteredItems = [];
//   bool _isLoading = false;
//
//   // Business GSTIN (should come from business settings)
//   final String _businessGSTIN = '27AABCU9603R1ZM'; // Example GSTIN
//
//   @override
//   void initState() {
//     super.initState();
//     _generateInvoiceNumber();
//     _loadItems();
//   }
//
//   Future<void> _generateInvoiceNumber() async {
//     try {
//       final snapshot = await _firestore
//           .collection('invoices')
//           .where('businessId', isEqualTo: widget.businessId)
//           .orderBy('invoiceNumber', descending: true)
//           .limit(1)
//           .get();
//
//       int nextNumber = 1;
//       if (snapshot.docs.isNotEmpty) {
//         final lastInvoice = snapshot.docs.first.data();
//         final lastNumber = int.tryParse(lastInvoice['invoiceNumber']?.toString() ?? '0') ?? 0;
//         nextNumber = lastNumber + 1;
//       }
//
//       _invoiceNumberController.text = nextNumber.toString().padLeft(4, '0');
//     } catch (e) {
//       _invoiceNumberController.text = '0001';
//     }
//   }
//
//   Future<void> _loadItems() async {
//     try {
//       final snapshot = await _firestore
//           .collection('items')
//           .where('businessId', isEqualTo: widget.businessId)
//           .where('isActive', isEqualTo: true)
//           .get();
//
//       setState(() {
//         _availableItems = snapshot.docs
//             .map((doc) => ItemMaster.fromFirestore(doc))
//             .toList();
//         _filteredItems = _availableItems;
//       });
//     } catch (e) {
//       print('Error loading items: $e');
//     }
//   }
//
//   void _filterItems(String query) {
//     setState(() {
//       if (query.isEmpty) {
//         _filteredItems = _availableItems;
//       } else {
//         _filteredItems = _availableItems.where((item) {
//           return item.itemName.toLowerCase().contains(query.toLowerCase()) ||
//               item.itemCode.toLowerCase().contains(query.toLowerCase()) ||
//               item.hsnSacCode.toLowerCase().contains(query.toLowerCase());
//         }).toList();
//       }
//     });
//   }
//
//   void _addItemToInvoice(ItemMaster item) {
//     showDialog(
//       context: context,
//       builder: (context) => _AddItemDialog(
//         item: item,
//         onAdd: (quantity) {
//           final isInterstate = _selectedParty != null &&
//               GSTUtils.isInterstateTransaction(_businessGSTIN, _selectedParty!.gstin);
//
//           final invoiceItem = InvoiceItem.fromItem(item, quantity, isInterstate);
//
//           setState(() {
//             _invoiceItems.add(invoiceItem);
//             _searchController.clear();
//             _filteredItems = _availableItems;
//           });
//         },
//       ),
//     );
//   }
//
//   void _removeItem(int index) {
//     setState(() {
//       _invoiceItems.removeAt(index);
//     });
//   }
//
//   double get _totalTaxableValue {
//     return _invoiceItems.fold(0.0, (sum, item) => sum + item.taxableValue);
//   }
//
//   double get _totalCGST {
//     return _invoiceItems.fold(0.0, (sum, item) => sum + item.cgstAmount);
//   }
//
//   double get _totalSGST {
//     return _invoiceItems.fold(0.0, (sum, item) => sum + item.sgstAmount);
//   }
//
//   double get _totalIGST {
//     return _invoiceItems.fold(0.0, (sum, item) => sum + item.igstAmount);
//   }
//
//   double get _totalAmount {
//     return _invoiceItems.fold(0.0, (sum, item) => sum + item.totalAmount);
//   }
//
//   Future<void> _saveInvoice() async {
//     if (!_formKey.currentState!.validate() || _invoiceItems.isEmpty) {
//       ScaffoldMessenger.of(context).showSnackBar(
//         const SnackBar(
//           content: Text('Please add at least one item to the invoice'),
//           backgroundColor: Colors.red,
//         ),
//       );
//       return;
//     }
//
//     setState(() => _isLoading = true);
//
//     try {
//       final invoiceData = {
//         'businessId': widget.businessId,
//         'invoiceNumber': _invoiceNumberController.text,
//         'invoiceDate': Timestamp.fromDate(_invoiceDate),
//         'partyId': _selectedParty?.id ?? '',
//         'partyName': _selectedParty?.name ?? 'Walk-in Customer',
//         'partyGSTIN': _selectedParty?.gstin ?? '',
//         'isB2B': _selectedParty?.isB2B ?? false,
//         'paymentType': _paymentType,
//         'totalTaxableValue': _totalTaxableValue,
//         'totalCGST': _totalCGST,
//         'totalSGST': _totalSGST,
//         'totalIGST': _totalIGST,
//         'totalAmount': _totalAmount,
//         'itemCount': _invoiceItems.length,
//         'createdAt': FieldValue.serverTimestamp(),
//       };
//
//       final invoiceRef = await _firestore.collection('invoices').add(invoiceData);
//
//       // Add invoice items
//       for (final item in _invoiceItems) {
//         await invoiceRef.collection('items').add(item.toFirestore());
//       }
//
//       if (mounted) {
//         Navigator.of(context).pop();
//         ScaffoldMessenger.of(context).showSnackBar(
//           const SnackBar(
//             content: Text('Invoice saved successfully'),
//             backgroundColor: Colors.green,
//           ),
//         );
//       }
//     } catch (e) {
//       if (mounted) {
//         ScaffoldMessenger.of(context).showSnackBar(
//           SnackBar(
//             content: Text('Error saving invoice: $e'),
//             backgroundColor: Colors.red,
//           ),
//         );
//       }
//     } finally {
//       if (mounted) {
//         setState(() => _isLoading = false);
//       }
//     }
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: const Text('Create Invoice'),
//         backgroundColor: Colors.white,
//         elevation: 0,
//         actions: [
//           IconButton(
//             onPressed: _isLoading ? null : _saveInvoice,
//             icon: _isLoading
//                 ? const SizedBox(
//               width: 20,
//               height: 20,
//               child: CircularProgressIndicator(strokeWidth: 2),
//             )
//                 : const Icon(Icons.save),
//           ),
//         ],
//       ),
//       body: Form(
//         key: _formKey,
//         child: Column(
//           children: [
//             // Invoice Header
//             Container(
//               padding: const EdgeInsets.all(16),
//               color: Colors.grey.shade50,
//               child: Column(
//                 children: [
//                   Row(
//                     children: [
//                       Expanded(
//                         child: TextFormField(
//                           controller: _invoiceNumberController,
//                           decoration: const InputDecoration(
//                             labelText: 'Invoice Number',
//                             border: OutlineInputBorder(),
//                           ),
//                           validator: (value) {
//                             if (value == null || value.isEmpty) {
//                               return 'Please enter invoice number';
//                             }
//                             return null;
//                           },
//                         ),
//                       ),
//                       const SizedBox(width: 16),
//                       Expanded(
//                         child: InkWell(
//                           onTap: () async {
//                             final date = await showDatePicker(
//                               context: context,
//                               initialDate: _invoiceDate,
//                               firstDate: DateTime(2020),
//                               lastDate: DateTime.now().add(const Duration(days: 365)),
//                             );
//                             if (date != null) {
//                               setState(() => _invoiceDate = date);
//                             }
//                           },
//                           child: InputDecorator(
//                             decoration: const InputDecoration(
//                               labelText: 'Invoice Date',
//                               border: OutlineInputBorder(),
//                             ),
//                             child: Text(DateFormat('dd/MM/yyyy').format(_invoiceDate)),
//                           ),
//                         ),
//                       ),
//                     ],
//                   ),
//                   const SizedBox(height: 16),
//                   Row(
//                     children: [
//                       Expanded(
//                         flex: 2,
//                         child: InkWell(
//                           onTap: () => _showPartySelection(),
//                           child: InputDecorator(
//                             decoration: const InputDecoration(
//                               labelText: 'Select Party',
//                               border: OutlineInputBorder(),
//                             ),
//                             child: Text(
//                               _selectedParty?.name ?? 'Walk-in Customer',
//                               style: TextStyle(
//                                 color: _selectedParty == null ? Colors.grey : Colors.black,
//                               ),
//                             ),
//                           ),
//                         ),
//                       ),
//                       const SizedBox(width: 16),
//                       Expanded(
//                         child: DropdownButtonFormField<String>(
//                           value: _paymentType,
//                           decoration: const InputDecoration(
//                             labelText: 'Payment Type',
//                             border: OutlineInputBorder(),
//                           ),
//                           items: const [
//                             DropdownMenuItem(value: 'Cash', child: Text('Cash')),
//                             DropdownMenuItem(value: 'Credit', child: Text('Credit')),
//                             DropdownMenuItem(value: 'UPI', child: Text('UPI')),
//                             DropdownMenuItem(value: 'Card', child: Text('Card')),
//                           ],
//                           onChanged: (value) {
//                             setState(() => _paymentType = value!);
//                           },
//                         ),
//                       ),
//                     ],
//                   ),
//                 ],
//               ),
//             ),
//
//             // Item Search
//             Container(
//               padding: const EdgeInsets.all(16),
//               child: TextField(
//                 controller: _searchController,
//                 decoration: const InputDecoration(
//                   hintText: 'Search items by name, code, or HSN...',
//                   prefixIcon: Icon(Icons.search),
//                   border: OutlineInputBorder(),
//                 ),
//                 onChanged: _filterItems,
//               ),
//             ),
//
//             // Search Results
//             if (_searchController.text.isNotEmpty)
//               Container(
//                 height: 200,
//                 margin: const EdgeInsets.symmetric(horizontal: 16),
//                 decoration: BoxDecoration(
//                   border: Border.all(color: Colors.grey.shade300),
//                   borderRadius: BorderRadius.circular(8),
//                 ),
//                 child: ListView.builder(
//                   itemCount: _filteredItems.length,
//                   itemBuilder: (context, index) {
//                     final item = _filteredItems[index];
//                     return ListTile(
//                       title: Text(item.itemName),
//                       subtitle: Text('Code: ${item.itemCode} | HSN: ${item.hsnSacCode}'),
//                       trailing: Text('₹${item.sellingPrice.toStringAsFixed(2)}'),
//                       onTap: () => _addItemToInvoice(item),
//                     );
//                   },
//                 ),
//               ),
//
//             // Invoice Items
//             Expanded(
//               child: _invoiceItems.isEmpty
//                   ? const Center(
//                 child: Text(
//                   'No items added\nSearch and tap to add items',
//                   textAlign: TextAlign.center,
//                   style: TextStyle(
//                     fontSize: 16,
//                     color: Colors.grey,
//                   ),
//                 ),
//               )
//                   : ListView.builder(
//                 padding: const EdgeInsets.all(16),
//                 itemCount: _invoiceItems.length,
//                 itemBuilder: (context, index) {
//                   return _buildInvoiceItemCard(_invoiceItems[index], index);
//                 },
//               ),
//             ),
//
//             // Invoice Summary
//             if (_invoiceItems.isNotEmpty)
//               Container(
//                 padding: const EdgeInsets.all(16),
//                 decoration: BoxDecoration(
//                   color: Colors.white,
//                   boxShadow: [
//                     BoxShadow(
//                       color: Colors.black.withOpacity(0.1),
//                       blurRadius: 10,
//                       offset: const Offset(0, -2),
//                     ),
//                   ],
//                 ),
//                 child: Column(
//                   children: [
//                     _buildSummaryRow('Taxable Value', _totalTaxableValue),
//                     if (_totalCGST > 0) _buildSummaryRow('CGST', _totalCGST),
//                     if (_totalSGST > 0) _buildSummaryRow('SGST', _totalSGST),
//                     if (_totalIGST > 0) _buildSummaryRow('IGST', _totalIGST),
//                     const Divider(),
//                     _buildSummaryRow('Total Amount', _totalAmount, isTotal: true),
//                   ],
//                 ),
//               ),
//           ],
//         ),
//       ),
//     );
//   }
//
//   Widget _buildInvoiceItemCard(InvoiceItem item, int index) {
//     return Card(
//       margin: const EdgeInsets.only(bottom: 8),
//       child: Padding(
//         padding: const EdgeInsets.all(12),
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             Row(
//               children: [
//                 Expanded(
//                   child: Column(
//                     crossAxisAlignment: CrossAxisAlignment.start,
//                     children: [
//                       Text(
//                         item.itemName,
//                         style: const TextStyle(
//                           fontWeight: FontWeight.w600,
//                           fontSize: 16,
//                         ),
//                       ),
//                       Text(
//                         'HSN: ${item.hsnCode} | ${item.quantity} ${item.unit} × ₹${item.rate}',
//                         style: TextStyle(
//                           color: Colors.grey.shade600,
//                           fontSize: 12,
//                         ),
//                       ),
//                     ],
//                   ),
//                 ),
//                 IconButton(
//                   onPressed: () => _removeItem(index),
//                   icon: const Icon(Icons.delete, color: Colors.red),
//                 ),
//               ],
//             ),
//             const SizedBox(height: 8),
//             Row(
//               mainAxisAlignment: MainAxisAlignment.spaceBetween,
//               children: [
//                 if (item.isTaxExempt)
//                   Container(
//                     padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
//                     decoration: BoxDecoration(
//                       color: Colors.orange.withOpacity(0.1),
//                       borderRadius: BorderRadius.circular(4),
//                     ),
//                     child: Text(
//                       item.taxCategory == 'exempt' ? 'TAX EXEMPT' : 'ZERO RATED',
//                       style: const TextStyle(
//                         fontSize: 10,
//                         fontWeight: FontWeight.bold,
//                         color: Colors.orange,
//                       ),
//                     ),
//                   )
//                 else
//                   Text(
//                     'Tax: ₹${(item.cgstAmount + item.sgstAmount + item.igstAmount).toStringAsFixed(2)}',
//                     style: TextStyle(
//                       color: Colors.grey.shade600,
//                       fontSize: 12,
//                     ),
//                   ),
//                 Text(
//                   '₹${item.totalAmount.toStringAsFixed(2)}',
//                   style: const TextStyle(
//                     fontWeight: FontWeight.bold,
//                     fontSize: 16,
//                     color: Colors.green,
//                   ),
//                 ),
//               ],
//             ),
//           ],
//         ),
//       ),
//     );
//   }
//
//   Widget _buildSummaryRow(String label, double amount, {bool isTotal = false}) {
//     return Padding(
//       padding: const EdgeInsets.symmetric(vertical: 4),
//       child: Row(
//         mainAxisAlignment: MainAxisAlignment.spaceBetween,
//         children: [
//           Text(
//             label,
//             style: TextStyle(
//               fontSize: isTotal ? 16 : 14,
//               fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
//             ),
//           ),
//           Text(
//             '₹${amount.toStringAsFixed(2)}',
//             style: TextStyle(
//               fontSize: isTotal ? 16 : 14,
//               fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
//               color: isTotal ? Colors.green : Colors.black,
//             ),
//           ),
//         ],
//       ),
//     );
//   }
//
//   void _showPartySelection() {
//     showDialog(
//       context: context,
//       builder: (context) => _PartySelectionDialog(
//         businessId: widget.businessId,
//         onPartySelected: (party) {
//           setState(() => _selectedParty = party);
//         },
//       ),
//     );
//   }
//
//   @override
//   void dispose() {
//     _invoiceNumberController.dispose();
//     _searchController.dispose();
//     super.dispose();
//   }
// }
//
// // Add Item Dialog
// class _AddItemDialog extends StatefulWidget {
//   final ItemMaster item;
//   final Function(double) onAdd;
//
//   const _AddItemDialog({required this.item, required this.onAdd});
//
//   @override
//   State<_AddItemDialog> createState() => _AddItemDialogState();
// }
//
// class _AddItemDialogState extends State<_AddItemDialog> {
//   final _quantityController = TextEditingController(text: '1');
//
//   @override
//   Widget build(BuildContext context) {
//     return AlertDialog(
//       title: Text('Add ${widget.item.itemName}'),
//       content: Column(
//         mainAxisSize: MainAxisSize.min,
//         children: [
//           Text('Rate: ₹${widget.item.sellingPrice.toStringAsFixed(2)}'),
//           const SizedBox(height: 16),
//           TextField(
//             controller: _quantityController,
//             keyboardType: const TextInputType.numberWithOptions(decimal: true),
//             decoration: InputDecoration(
//               labelText: 'Quantity (${widget.item.unitOfMeasurement})',
//               border: const OutlineInputBorder(),
//             ),
//           ),
//         ],
//       ),
//       actions: [
//         TextButton(
//           onPressed: () => Navigator.of(context).pop(),
//           child: const Text('Cancel'),
//         ),
//         ElevatedButton(
//           onPressed: () {
//             final quantity = double.tryParse(_quantityController.text) ?? 0;
//             if (quantity > 0) {
//               widget.onAdd(quantity);
//               Navigator.of(context).pop();
//             }
//           },
//           child: const Text('Add'),
//         ),
//       ],
//     );
//   }
// }
//
// // Party Selection Dialog
// class _PartySelectionDialog extends StatefulWidget {
//   final String businessId;
//   final Function(Party?) onPartySelected;
//
//   const _PartySelectionDialog({
//     required this.businessId,
//     required this.onPartySelected,
//   });
//
//   @override
//   State<_PartySelectionDialog> createState() => _PartySelectionDialogState();
// }
//
// class _PartySelectionDialogState extends State<_PartySelectionDialog> {
//   final FirebaseFirestore _firestore = FirebaseFirestore.instance;
//
//   @override
//   Widget build(BuildContext context) {
//     return AlertDialog(
//       title: const Text('Select Party'),
//       content: SizedBox(
//         width: double.maxFinite,
//         height: 400,
//         child: Column(
//           children: [
//             ListTile(
//               leading: const Icon(Icons.person),
//               title: const Text('Walk-in Customer'),
//               subtitle: const Text('B2C Transaction'),
//               onTap: () {
//                 widget.onPartySelected(null);
//                 Navigator.of(context).pop();
//               },
//             ),
//             const Divider(),
//             Expanded(
//               child: StreamBuilder<QuerySnapshot>(
//                 stream: _firestore
//                     .collection('parties')
//                     .where('businessId', isEqualTo: widget.businessId)
//                     .snapshots(),
//                 builder: (context, snapshot) {
//                   if (snapshot.hasError) {
//                     return const Center(child: Text('Error loading parties'));
//                   }
//                   if (snapshot.connectionState == ConnectionState.waiting) {
//                     return const Center(child: CircularProgressIndicator());
//                   }
//
//                   final parties = snapshot.data!.docs
//                       .map((doc) => Party.fromFirestore(doc))
//                       .toList();
//
//                   return ListView.builder(
//                     itemCount: parties.length,
//                     itemBuilder: (context, index) {
//                       final party = parties[index];
//                       return ListTile(
//                         leading: Icon(
//                           party.isB2B ? Icons.business : Icons.person,
//                           color: party.isB2B ? Colors.blue : Colors.green,
//                         ),
//                         title: Text(party.name),
//                         subtitle: Text(
//                           party.isB2B
//                               ? 'GSTIN: ${party.gstin}'
//                               : 'B2C Customer',
//                         ),
//                         onTap: () {
//                           widget.onPartySelected(party);
//                           Navigator.of(context).pop();
//                         },
//                       );
//                     },
//                   );
//                 },
//               ),
//             ),
//           ],
//         ),
//       ),
//       actions: [
//         TextButton(
//           onPressed: () => Navigator.of(context).pop(),
//           child: const Text('Cancel'),
//         ),
//         ElevatedButton(
//           onPressed: () => _showAddPartyDialog(),
//           child: const Text('Add New Party'),
//         ),
//       ],
//     );
//   }
//
//   void _showAddPartyDialog() {
//     Navigator.of(context).pop();
//     showDialog(
//       context: context,
//       builder: (context) => _AddPartyDialog(
//         businessId: widget.businessId,
//         onPartyAdded: (party) {
//           widget.onPartySelected(party);
//         },
//       ),
//     );
//   }
// }
//
// // Add Party Dialog
// class _AddPartyDialog extends StatefulWidget {
//   final String businessId;
//   final Function(Party) onPartyAdded;
//
//   const _AddPartyDialog({
//     required this.businessId,
//     required this.onPartyAdded,
//   });
//
//   @override
//   State<_AddPartyDialog> createState() => _AddPartyDialogState();
// }
//
// class _AddPartyDialogState extends State<_AddPartyDialog> {
//   final _formKey = GlobalKey<FormState>();
//   final _nameController = TextEditingController();
//   final _addressController = TextEditingController();
//   final _phoneController = TextEditingController();
//   final _emailController = TextEditingController();
//   final _gstinController = TextEditingController();
//
//   bool _isB2B = false;
//   bool _isLoading = false;
//
//   @override
//   Widget build(BuildContext context) {
//     return AlertDialog(
//       title: const Text('Add New Party'),
//       content: Form(
//         key: _formKey,
//         child: SingleChildScrollView(
//           child: Column(
//             mainAxisSize: MainAxisSize.min,
//             children: [
//               TextFormField(
//                 controller: _nameController,
//                 decoration: const InputDecoration(
//                   labelText: 'Party Name',
//                   border: OutlineInputBorder(),
//                 ),
//                 validator: (value) {
//                   if (value == null || value.isEmpty) {
//                     return 'Please enter party name';
//                   }
//                   return null;
//                 },
//               ),
//               const SizedBox(height: 12),
//               TextFormField(
//                 controller: _addressController,
//                 decoration: const InputDecoration(
//                   labelText: 'Address',
//                   border: OutlineInputBorder(),
//                 ),
//                 maxLines: 2,
//               ),
//               const SizedBox(height: 12),
//               TextFormField(
//                 controller: _phoneController,
//                 decoration: const InputDecoration(
//                   labelText: 'Phone',
//                   border: OutlineInputBorder(),
//                 ),
//                 keyboardType: TextInputType.phone,
//               ),
//               const SizedBox(height: 12),
//               TextFormField(
//                 controller: _emailController,
//                 decoration: const InputDecoration(
//                   labelText: 'Email',
//                   border: OutlineInputBorder(),
//                 ),
//                 keyboardType: TextInputType.emailAddress,
//               ),
//               const SizedBox(height: 12),
//               CheckboxListTile(
//                 title: const Text('B2B Customer'),
//                 subtitle: const Text('Has GSTIN for business transactions'),
//                 value: _isB2B,
//                 onChanged: (value) {
//                   setState(() {
//                     _isB2B = value ?? false;
//                     if (!_isB2B) {
//                       _gstinController.clear();
//                     }
//                   });
//                 },
//               ),
//               if (_isB2B) ...[
//                 const SizedBox(height: 12),
//                 TextFormField(
//                   controller: _gstinController,
//                   decoration: const InputDecoration(
//                     labelText: 'GSTIN',
//                     border: OutlineInputBorder(),
//                     hintText: '15-digit GSTIN',
//                   ),
//                   validator: (value) {
//                     if (_isB2B && (value == null || value.isEmpty)) {
//                       return 'Please enter GSTIN for B2B customer';
//                     }
//                     if (_isB2B && !GSTUtils.isValidGSTIN(value!)) {
//                       return 'Please enter valid GSTIN';
//                     }
//                     return null;
//                   },
//                 ),
//               ],
//             ],
//           ),
//         ),
//       ),
//       actions: [
//         TextButton(
//           onPressed: _isLoading ? null : () => Navigator.of(context).pop(),
//           child: const Text('Cancel'),
//         ),
//         ElevatedButton(
//           onPressed: _isLoading ? null : _saveParty,
//           child: _isLoading
//               ? const SizedBox(
//             width: 20,
//             height: 20,
//             child: CircularProgressIndicator(strokeWidth: 2),
//           )
//               : const Text('Save'),
//         ),
//       ],
//     );
//   }
//
//   Future<void> _saveParty() async {
//     if (!_formKey.currentState!.validate()) return;
//
//     setState(() => _isLoading = true);
//
//     try {
//       final party = Party(
//         id: '',
//         businessId: widget.businessId,
//         name: _nameController.text.trim(),
//         address: _addressController.text.trim(),
//         phone: _phoneController.text.trim(),
//         email: _emailController.text.trim(),
//         gstin: _gstinController.text.trim().toUpperCase(),
//         stateCode: _isB2B ? GSTUtils.getStateCodeFromGSTIN(_gstinController.text.trim()) : '',
//         isB2B: _isB2B,
//         createdAt: DateTime.now(),
//       );
//
//       final docRef = await FirebaseFirestore.instance
//           .collection('parties')
//           .add(party.toFirestore());
//
//       final savedParty = Party(
//         id: docRef.id,
//         businessId: party.businessId,
//         name: party.name,
//         address: party.address,
//         phone: party.phone,
//         email: party.email,
//         gstin: party.gstin,
//         stateCode: party.stateCode,
//         isB2B: party.isB2B,
//         createdAt: party.createdAt,
//       );
//
//       widget.onPartyAdded(savedParty);
//
//       if (mounted) {
//         Navigator.of(context).pop();
//         ScaffoldMessenger.of(context).showSnackBar(
//           const SnackBar(
//             content: Text('Party added successfully'),
//             backgroundColor: Colors.green,
//           ),
//         );
//       }
//     } catch (e) {
//       if (mounted) {
//         ScaffoldMessenger.of(context).showSnackBar(
//           SnackBar(
//             content: Text('Error: $e'),
//             backgroundColor: Colors.red,
//           ),
//         );
//       }
//     } finally {
//       if (mounted) {
//         setState(() => _isLoading = false);
//       }
//     }
//   }
//
//   @override
//   void dispose() {
//     _nameController.dispose();
//     _addressController.dispose();
//     _phoneController.dispose();
//     _emailController.dispose();
//     _gstinController.dispose();
//     super.dispose();
//   }
// }
