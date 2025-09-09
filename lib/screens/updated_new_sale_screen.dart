// import 'package:flutter/material.dart';
// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:intl/intl.dart';
// import '../model/sale_item.dart';
// import '../services/user_service.dart';
// import 'add_item_to_sale_dialog.dart';
//
// class UpdatedNewSaleScreen extends StatefulWidget {
//   final String businessId;
//   final String? saleId;
//
//   const UpdatedNewSaleScreen({
//     super.key,
//     required this.businessId,
//     this.saleId,
//   });
//
//   @override
//   State<UpdatedNewSaleScreen> createState() => _UpdatedNewSaleScreenState();
// }
//
// class _UpdatedNewSaleScreenState extends State<UpdatedNewSaleScreen> {
//   final FirebaseFirestore _firestore = FirebaseFirestore.instance;
//   final _formKey = GlobalKey<FormState>();
//
//   // Form Controllers
//   final _customerNameController = TextEditingController();
//   final _customerAddressController = TextEditingController();
//   final _customerGstinController = TextEditingController();
//   final _invoiceNumberController = TextEditingController();
//   final _remarksController = TextEditingController();
//
//   // Sale Data
//   List<SaleItem> _saleItems = [];
//   DateTime _saleDate = DateTime.now();
//   bool _isLoading = false;
//
//   // Totals
//   double _totalTaxableValue = 0;
//   double _totalCgstAmount = 0;
//   double _totalSgstAmount = 0;
//   double _totalIgstAmount = 0;
//   double _totalCessAmount = 0;
//   double _grandTotal = 0;
//
//   @override
//   void initState() {
//     super.initState();
//     _generateInvoiceNumber();
//     if (widget.saleId != null) {
//       _loadExistingSale();
//     }
//   }
//
//   void _generateInvoiceNumber() {
//     final now = DateTime.now();
//     final invoiceNumber = 'INV${DateFormat('yyyyMMdd').format(now)}${now.millisecondsSinceEpoch.toString().substring(8)}';
//     _invoiceNumberController.text = invoiceNumber;
//   }
//
//   Future<void> _loadExistingSale() async {
//     // Implementation for loading existing sale for editing
//   }
//
//   void _addItemToSale(SaleItem item) {
//     setState(() {
//       _saleItems.add(item);
//       _calculateTotals();
//     });
//   }
//
//   void _removeItemFromSale(int index) {
//     setState(() {
//       _saleItems.removeAt(index);
//       _calculateTotals();
//     });
//   }
//
//   void _calculateTotals() {
//     _totalTaxableValue = 0;
//     _totalCgstAmount = 0;
//     _totalSgstAmount = 0;
//     _totalIgstAmount = 0;
//     _totalCessAmount = 0;
//
//     for (var item in _saleItems) {
//       _totalTaxableValue += item.taxableValue;
//       _totalCgstAmount += item.cgstAmount;
//       _totalSgstAmount += item.sgstAmount;
//       _totalIgstAmount += item.igstAmount;
//       _totalCessAmount += item.cessAmount;
//     }
//
//     _grandTotal = _totalTaxableValue + _totalCgstAmount + _totalSgstAmount + _totalIgstAmount + _totalCessAmount;
//   }
//
//   Future<void> _saveSale() async {
//     if (!_formKey.currentState!.validate() || _saleItems.isEmpty) {
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(
//           content: const Text('Please add at least one item to the sale'),
//           backgroundColor: Colors.red,
//           shape: RoundedRectangleBorder(
//             borderRadius: BorderRadius.circular(10),
//           ),
//         ),
//       );
//       return;
//     }
//
//     setState(() => _isLoading = true);
//
//     try {
//       final saleData = UserService.addUserData({
//         'businessId': widget.businessId,
//         'customerName': _customerNameController.text.trim(),
//         'customerAddress': _customerAddressController.text.trim(),
//         'customerGstin': _customerGstinController.text.trim(),
//         'invoice': _invoiceNumberController.text.trim(),
//         'date': Timestamp.fromDate(_saleDate),
//         'remarks': _remarksController.text.trim(),
//         'items': _saleItems.map((item) => item.toMap()).toList(),
//         'totalTaxableValue': _totalTaxableValue,
//         'totalCgstAmount': _totalCgstAmount,
//         'totalSgstAmount': _totalSgstAmount,
//         'totalIgstAmount': _totalIgstAmount,
//         'totalCessAmount': _totalCessAmount,
//         'total': _grandTotal,
//         'createdAt': FieldValue.serverTimestamp(),
//       });
//
//       if (widget.saleId != null) {
//         await _firestore.collection('sales').doc(widget.saleId).update(saleData);
//       } else {
//         await _firestore.collection('sales').add(saleData);
//       }
//
//       if (mounted) {
//         Navigator.of(context).pop();
//         ScaffoldMessenger.of(context).showSnackBar(
//           SnackBar(
//             content: Text(widget.saleId != null ? 'Sale updated successfully' : 'Sale created successfully'),
//             backgroundColor: const Color(0xFF4CAF50),
//             shape: RoundedRectangleBorder(
//               borderRadius: BorderRadius.circular(10),
//             ),
//           ),
//         );
//       }
//     } catch (e) {
//       if (mounted) {
//         ScaffoldMessenger.of(context).showSnackBar(
//           SnackBar(
//             content: Text('Error: $e'),
//             backgroundColor: Colors.red,
//             shape: RoundedRectangleBorder(
//               borderRadius: BorderRadius.circular(10),
//             ),
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
//       backgroundColor: const Color(0xFFF5F7FA),
//       appBar: AppBar(
//         title: Text(
//           widget.saleId != null ? 'Edit Sale' : 'New Sale',
//           style: const TextStyle(
//             color: Colors.white,
//             fontWeight: FontWeight.bold,
//           ),
//         ),
//         backgroundColor: const Color(0xFF2E3A59),
//         elevation: 0,
//         iconTheme: const IconThemeData(color: Colors.white),
//         actions: [
//           if (_isLoading)
//             const Center(
//               child: Padding(
//                 padding: EdgeInsets.all(16),
//                 child: SizedBox(
//                   width: 20,
//                   height: 20,
//                   child: CircularProgressIndicator(
//                     strokeWidth: 2,
//                     valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
//                   ),
//                 ),
//               ),
//             )
//           else
//             Container(
//               margin: const EdgeInsets.all(8),
//               decoration: BoxDecoration(
//                 color: const Color(0xFF4CAF50),
//                 borderRadius: BorderRadius.circular(10),
//               ),
//               child: TextButton.icon(
//                 onPressed: _saveSale,
//                 icon: const Icon(Icons.save, color: Colors.white),
//                 label: const Text(
//                   'Save',
//                   style: TextStyle(color: Colors.white),
//                 ),
//               ),
//             ),
//         ],
//       ),
//       body: Form(
//         key: _formKey,
//         child: Column(
//           children: [
//             // Customer Details Section
//             Container(
//               margin: const EdgeInsets.all(16),
//               padding: const EdgeInsets.all(20),
//               decoration: BoxDecoration(
//                 color: Colors.white,
//                 borderRadius: BorderRadius.circular(20),
//                 boxShadow: [
//                   BoxShadow(
//                     color: Colors.black.withOpacity(0.08),
//                     blurRadius: 15,
//                     offset: const Offset(0, 5),
//                   ),
//                 ],
//               ),
//               child: Column(
//                 crossAxisAlignment: CrossAxisAlignment.start,
//                 children: [
//                   Row(
//                     children: [
//                       Container(
//                         width: 40,
//                         height: 40,
//                         decoration: BoxDecoration(
//                           gradient: const LinearGradient(
//                             colors: [Color(0xFF4CAF50), Color(0xFF45A049)],
//                           ),
//                           borderRadius: BorderRadius.circular(12),
//                         ),
//                         child: const Icon(Icons.person, color: Colors.white, size: 20),
//                       ),
//                       const SizedBox(width: 12),
//                       const Text(
//                         'Customer Details',
//                         style: TextStyle(
//                           fontSize: 18,
//                           fontWeight: FontWeight.bold,
//                           color: Color(0xFF2E3A59),
//                         ),
//                       ),
//                     ],
//                   ),
//                   const SizedBox(height: 20),
//                   Row(
//                     children: [
//                       Expanded(
//                         flex: 2,
//                         child: _buildTextField(
//                           controller: _customerNameController,
//                           label: 'Customer Name *',
//                           validator: (value) {
//                             if (value == null || value.trim().isEmpty) {
//                               return 'Customer name is required';
//                             }
//                             return null;
//                           },
//                         ),
//                       ),
//                       const SizedBox(width: 16),
//                       Expanded(
//                         child: _buildTextField(
//                           controller: _invoiceNumberController,
//                           label: 'Invoice Number *',
//                           validator: (value) {
//                             if (value == null || value.trim().isEmpty) {
//                               return 'Invoice number is required';
//                             }
//                             return null;
//                           },
//                         ),
//                       ),
//                     ],
//                   ),
//                   const SizedBox(height: 16),
//                   Row(
//                     children: [
//                       Expanded(
//                         child: _buildTextField(
//                           controller: _customerAddressController,
//                           label: 'Customer Address',
//                           maxLines: 2,
//                         ),
//                       ),
//                       const SizedBox(width: 16),
//                       Expanded(
//                         child: Column(
//                           children: [
//                             _buildTextField(
//                               controller: _customerGstinController,
//                               label: 'Customer GSTIN',
//                             ),
//                             const SizedBox(height: 16),
//                             InkWell(
//                               onTap: () async {
//                                 final date = await showDatePicker(
//                                   context: context,
//                                   initialDate: _saleDate,
//                                   firstDate: DateTime(2020),
//                                   lastDate: DateTime.now().add(const Duration(days: 365)),
//                                 );
//                                 if (date != null) {
//                                   setState(() {
//                                     _saleDate = date;
//                                   });
//                                 }
//                               },
//                               child: Container(
//                                 padding: const EdgeInsets.all(16),
//                                 decoration: BoxDecoration(
//                                   border: Border.all(color: Colors.grey.shade300),
//                                   borderRadius: BorderRadius.circular(12),
//                                 ),
//                                 child: Row(
//                                   children: [
//                                     const Icon(Icons.calendar_today, size: 20, color: Color(0xFF2E3A59)),
//                                     const SizedBox(width: 8),
//                                     Text(
//                                       DateFormat('dd/MM/yyyy').format(_saleDate),
//                                       style: const TextStyle(color: Color(0xFF2E3A59)),
//                                     ),
//                                   ],
//                                 ),
//                               ),
//                             ),
//                           ],
//                         ),
//                       ),
//                     ],
//                   ),
//                 ],
//               ),
//             ),
//
//             // Items Section
//             Expanded(
//               child: Container(
//                 margin: const EdgeInsets.symmetric(horizontal: 16),
//                 decoration: BoxDecoration(
//                   color: Colors.white,
//                   borderRadius: BorderRadius.circular(20),
//                   boxShadow: [
//                     BoxShadow(
//                       color: Colors.black.withOpacity(0.08),
//                       blurRadius: 15,
//                       offset: const Offset(0, 5),
//                     ),
//                   ],
//                 ),
//                 child: Column(
//                   children: [
//                     // Items Header
//                     Container(
//                       padding: const EdgeInsets.all(20),
//                       decoration: BoxDecoration(
//                         gradient: LinearGradient(
//                           colors: [Colors.grey.shade50, Colors.grey.shade100],
//                         ),
//                         borderRadius: const BorderRadius.only(
//                           topLeft: Radius.circular(20),
//                           topRight: Radius.circular(20),
//                         ),
//                       ),
//                       child: Row(
//                         mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                         children: [
//                           Row(
//                             children: [
//                               Container(
//                                 width: 40,
//                                 height: 40,
//                                 decoration: BoxDecoration(
//                                   gradient: const LinearGradient(
//                                     colors: [Color(0xFF2196F3), Color(0xFF1976D2)],
//                                   ),
//                                   borderRadius: BorderRadius.circular(12),
//                                 ),
//                                 child: const Icon(Icons.inventory_2, color: Colors.white, size: 20),
//                               ),
//                               const SizedBox(width: 12),
//                               const Text(
//                                 'Items',
//                                 style: TextStyle(
//                                   fontSize: 18,
//                                   fontWeight: FontWeight.bold,
//                                   color: Color(0xFF2E3A59),
//                                 ),
//                               ),
//                             ],
//                           ),
//                           ElevatedButton.icon(
//                             onPressed: () {
//                               showDialog(
//                                 context: context,
//                                 builder: (context) => AddItemToSaleDialog(
//                                   businessId: widget.businessId,
//                                   onItemAdded: _addItemToSale,
//                                 ),
//                               );
//                             },
//                             icon: const Icon(Icons.add),
//                             label: const Text('Add Item'),
//                             style: ElevatedButton.styleFrom(
//                               backgroundColor: const Color(0xFF4CAF50),
//                               foregroundColor: Colors.white,
//                               shape: RoundedRectangleBorder(
//                                 borderRadius: BorderRadius.circular(12),
//                               ),
//                             ),
//                           ),
//                         ],
//                       ),
//                     ),
//
//                     // Items Table or Empty State
//                     if (_saleItems.isEmpty)
//                       Expanded(
//                         child: Center(
//                           child: Column(
//                             mainAxisAlignment: MainAxisAlignment.center,
//                             children: [
//                               Container(
//                                 width: 80,
//                                 height: 80,
//                                 decoration: BoxDecoration(
//                                   color: const Color(0xFF4CAF50).withOpacity(0.1),
//                                   borderRadius: BorderRadius.circular(40),
//                                 ),
//                                 child: const Icon(
//                                   Icons.shopping_cart_outlined,
//                                   size: 40,
//                                   color: Color(0xFF4CAF50),
//                                 ),
//                               ),
//                               const SizedBox(height: 16),
//                               const Text(
//                                 'No items added yet',
//                                 style: TextStyle(
//                                   fontSize: 16,
//                                   fontWeight: FontWeight.w600,
//                                   color: Color(0xFF2E3A59),
//                                 ),
//                               ),
//                               const SizedBox(height: 8),
//                               Text(
//                                 'Tap "Add Item" to get started',
//                                 style: TextStyle(
//                                   fontSize: 14,
//                                   color: Colors.grey.shade600,
//                                 ),
//                               ),
//                             ],
//                           ),
//                         ),
//                       )
//                     else
//                       Expanded(
//                         child: SingleChildScrollView(
//                           scrollDirection: Axis.horizontal,
//                           child: SingleChildScrollView(
//                             child: Container(
//                               padding: const EdgeInsets.all(16),
//                               child: DataTable(
//                                 columnSpacing: 16,
//                                 headingRowColor: MaterialStateProperty.all(
//                                   const Color(0xFF2E3A59).withOpacity(0.1),
//                                 ),
//                                 columns: const [
//                                   DataColumn(
//                                     label: Text(
//                                       'Sr.\nNo.',
//                                       style: TextStyle(
//                                         fontWeight: FontWeight.bold,
//                                         color: Color(0xFF2E3A59),
//                                       ),
//                                     ),
//                                   ),
//                                   DataColumn(
//                                     label: Text(
//                                       'HSN',
//                                       style: TextStyle(
//                                         fontWeight: FontWeight.bold,
//                                         color: Color(0xFF2E3A59),
//                                       ),
//                                     ),
//                                   ),
//                                   DataColumn(
//                                     label: Text(
//                                       'Description',
//                                       style: TextStyle(
//                                         fontWeight: FontWeight.bold,
//                                         color: Color(0xFF2E3A59),
//                                       ),
//                                     ),
//                                   ),
//                                   DataColumn(
//                                     label: Text(
//                                       'UQC',
//                                       style: TextStyle(
//                                         fontWeight: FontWeight.bold,
//                                         color: Color(0xFF2E3A59),
//                                       ),
//                                     ),
//                                   ),
//                                   DataColumn(
//                                     label: Text(
//                                       'Total\nQuantity',
//                                       style: TextStyle(
//                                         fontWeight: FontWeight.bold,
//                                         color: Color(0xFF2E3A59),
//                                       ),
//                                     ),
//                                   ),
//                                   DataColumn(
//                                     label: Text(
//                                       'Total taxable\nvalue (₹)',
//                                       style: TextStyle(
//                                         fontWeight: FontWeight.bold,
//                                         color: Color(0xFF2E3A59),
//                                       ),
//                                     ),
//                                   ),
//                                   DataColumn(
//                                     label: Text(
//                                       'Rate\n(%)',
//                                       style: TextStyle(
//                                         fontWeight: FontWeight.bold,
//                                         color: Color(0xFF2E3A59),
//                                       ),
//                                     ),
//                                   ),
//                                   DataColumn(
//                                     label: Text(
//                                       'Central\ntax (₹)',
//                                       style: TextStyle(
//                                         fontWeight: FontWeight.bold,
//                                         color: Color(0xFF2E3A59),
//                                       ),
//                                     ),
//                                   ),
//                                   DataColumn(
//                                     label: Text(
//                                       'State/UT\ntax (₹)',
//                                       style: TextStyle(
//                                         fontWeight: FontWeight.bold,
//                                         color: Color(0xFF2E3A59),
//                                       ),
//                                     ),
//                                   ),
//                                   DataColumn(
//                                     label: Text(
//                                       'Cess\n(₹)',
//                                       style: TextStyle(
//                                         fontWeight: FontWeight.bold,
//                                         color: Color(0xFF2E3A59),
//                                       ),
//                                     ),
//                                   ),
//                                   DataColumn(
//                                     label: Text(
//                                       'Actions',
//                                       style: TextStyle(
//                                         fontWeight: FontWeight.bold,
//                                         color: Color(0xFF2E3A59),
//                                       ),
//                                     ),
//                                   ),
//                                 ],
//                                 rows: _saleItems.asMap().entries.map((entry) {
//                                   final index = entry.key;
//                                   final item = entry.value;
//                                   return DataRow(
//                                     cells: [
//                                       DataCell(Text('${index + 1}')),
//                                       DataCell(Text(item.hsnCode)),
//                                       DataCell(
//                                         SizedBox(
//                                           width: 150,
//                                           child: Text(
//                                             item.description,
//                                             overflow: TextOverflow.ellipsis,
//                                             maxLines: 2,
//                                           ),
//                                         ),
//                                       ),
//                                       DataCell(Text(item.uqc)),
//                                       DataCell(Text(item.quantity.toString())),
//                                       DataCell(Text(item.taxableValue.toStringAsFixed(2))),
//                                       DataCell(Text('${item.cgstRate + item.sgstRate + item.igstRate}')),
//                                       DataCell(Text(item.cgstAmount.toStringAsFixed(2))),
//                                       DataCell(Text(item.sgstAmount.toStringAsFixed(2))),
//                                       DataCell(Text(item.cessAmount.toStringAsFixed(2))),
//                                       DataCell(
//                                         IconButton(
//                                           icon: const Icon(Icons.delete, color: Colors.red),
//                                           onPressed: () => _removeItemFromSale(index),
//                                         ),
//                                       ),
//                                     ],
//                                   );
//                                 }).toList(),
//                               ),
//                             ),
//                           ),
//                         ),
//                       ),
//
//                     // Totals Section
//                     if (_saleItems.isNotEmpty)
//                       Container(
//                         padding: const EdgeInsets.all(20),
//                         decoration: BoxDecoration(
//                           gradient: LinearGradient(
//                             colors: [
//                               const Color(0xFF4CAF50).withOpacity(0.1),
//                               const Color(0xFF4CAF50).withOpacity(0.05),
//                             ],
//                           ),
//                           borderRadius: const BorderRadius.only(
//                             bottomLeft: Radius.circular(20),
//                             bottomRight: Radius.circular(20),
//                           ),
//                         ),
//                         child: Column(
//                           children: [
//                             _buildTotalRow('Total Taxable Value:', _totalTaxableValue),
//                             if (_totalCgstAmount > 0) _buildTotalRow('Total CGST:', _totalCgstAmount),
//                             if (_totalSgstAmount > 0) _buildTotalRow('Total SGST:', _totalSgstAmount),
//                             if (_totalIgstAmount > 0) _buildTotalRow('Total IGST:', _totalIgstAmount),
//                             if (_totalCessAmount > 0) _buildTotalRow('Total Cess:', _totalCessAmount),
//                             const Divider(thickness: 2),
//                             Row(
//                               mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                               children: [
//                                 const Text(
//                                   'Grand Total:',
//                                   style: TextStyle(
//                                     fontSize: 20,
//                                     fontWeight: FontWeight.bold,
//                                     color: Color(0xFF2E3A59),
//                                   ),
//                                 ),
//                                 Text(
//                                   '₹${_grandTotal.toStringAsFixed(2)}',
//                                   style: const TextStyle(
//                                     fontSize: 20,
//                                     fontWeight: FontWeight.bold,
//                                     color: Color(0xFF4CAF50),
//                                   ),
//                                 ),
//                               ],
//                             ),
//                           ],
//                         ),
//                       ),
//                   ],
//                 ),
//               ),
//             ),
//
//             // Remarks Section
//             Container(
//               margin: const EdgeInsets.all(16),
//               padding: const EdgeInsets.all(20),
//               decoration: BoxDecoration(
//                 color: Colors.white,
//                 borderRadius: BorderRadius.circular(20),
//                 boxShadow: [
//                   BoxShadow(
//                     color: Colors.black.withOpacity(0.08),
//                     blurRadius: 15,
//                     offset: const Offset(0, 5),
//                   ),
//                 ],
//               ),
//               child: _buildTextField(
//                 controller: _remarksController,
//                 label: 'Remarks (Optional)',
//                 maxLines: 2,
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
//
//   Widget _buildTextField({
//     required TextEditingController controller,
//     required String label,
//     String? Function(String?)? validator,
//     int maxLines = 1,
//   }) {
//     return TextFormField(
//       controller: controller,
//       validator: validator,
//       maxLines: maxLines,
//       decoration: InputDecoration(
//         labelText: label,
//         border: OutlineInputBorder(
//           borderRadius: BorderRadius.circular(12),
//           borderSide: BorderSide(color: Colors.grey.shade300),
//         ),
//         enabledBorder: OutlineInputBorder(
//           borderRadius: BorderRadius.circular(12),
//           borderSide: BorderSide(color: Colors.grey.shade300),
//         ),
//         focusedBorder: OutlineInputBorder(
//           borderRadius: BorderRadius.circular(12),
//           borderSide: const BorderSide(color: Color(0xFF4CAF50), width: 2),
//         ),
//         contentPadding: const EdgeInsets.all(16),
//       ),
//     );
//   }
//
//   Widget _buildTotalRow(String label, double amount) {
//     return Padding(
//       padding: const EdgeInsets.symmetric(vertical: 4),
//       child: Row(
//         mainAxisAlignment: MainAxisAlignment.spaceBetween,
//         children: [
//           Text(
//             label,
//             style: const TextStyle(
//               fontWeight: FontWeight.w600,
//               color: Color(0xFF2E3A59),
//             ),
//           ),
//           Text(
//             '₹${amount.toStringAsFixed(2)}',
//             style: const TextStyle(
//               fontWeight: FontWeight.w600,
//               color: Color(0xFF4CAF50),
//             ),
//           ),
//         ],
//       ),
//     );
//   }
//
//   @override
//   void dispose() {
//     _customerNameController.dispose();
//     _customerAddressController.dispose();
//     _customerGstinController.dispose();
//     _invoiceNumberController.dispose();
//     _remarksController.dispose();
//     super.dispose();
//   }
// }
