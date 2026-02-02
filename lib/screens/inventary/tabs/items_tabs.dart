// import 'package:flutter/material.dart';
// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:flutter/foundation.dart';
// import 'package:safetyzoness/screens/pdf_utils.dart';
//
// import '../../../model/item_master.dart';
//
// class ItemsTab extends StatefulWidget {
//   final String userId;
//   const ItemsTab({super.key, required this.userId});
//
//   @override
//   State<ItemsTab> createState() => ItemsTabState();
// }
//
// class ItemsTabState extends State<ItemsTab> {
//   final FirebaseFirestore _firestore = FirebaseFirestore.instance;
//   final TextEditingController _searchController = TextEditingController();
//   String _searchQuery = '';
//
//   void showAddItemDialog() {
//     _showItemDialog(null);
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     return Column(
//       children: [
//         Container(
//           margin: const EdgeInsets.all(16),
//           decoration: BoxDecoration(
//             color: Colors.white,
//             borderRadius: BorderRadius.circular(12),
//             boxShadow: [
//               BoxShadow(
//                 color: Colors.black.withOpacity(0.05),
//                 blurRadius: 10,
//                 offset: const Offset(0, 2),
//               ),
//             ],
//           ),
//           child: TextField(
//             controller: _searchController,
//             decoration: const InputDecoration(
//               hintText: 'Search items...',
//               prefixIcon: Icon(Icons.search, color: Colors.grey),
//               border: InputBorder.none,
//               contentPadding: EdgeInsets.all(16),
//             ),
//             onChanged: (value) {
//               setState(() {
//                 _searchQuery = value.toLowerCase();
//               });
//             },
//           ),
//         ),
//         Expanded(
//           child: StreamBuilder<QuerySnapshot>(
//             stream: _firestore.collection('items')
//                 .where('userId', isEqualTo: widget.userId)
//                 .where('isActive', isEqualTo: true)
//                 .snapshots(),
//             builder: (context, snapshot) {
//               if (snapshot.hasError) {
//                 debugPrint('ItemsTab StreamBuilder Error: ${snapshot.error}');
//                 return Center(
//                   child: Column(
//                     mainAxisAlignment: MainAxisAlignment.center,
//                     children: [
//                       const Icon(Icons.error_outline, size: 64, color: Colors.red),
//                       const SizedBox(height: 16),
//                       Text('Error: ${snapshot.error}'),
//                       const SizedBox(height: 16),
//                       ElevatedButton(
//                         onPressed: () => setState(() {}),
//                         child: const Text('Retry'),
//                       ),
//                     ],
//                   ),
//                 );
//               }
//               if (snapshot.connectionState == ConnectionState.waiting) {
//                 return const Center(child: CircularProgressIndicator());
//               }
//               final items = snapshot.data!.docs
//                   .map((doc) {
//                 try {
//                   return ItemMaster.fromFirestore(doc);
//                 } catch (e) {
//                   debugPrint('Error parsing item ${doc.id}: $e');
//                   return null;
//                 }
//               })
//                   .where((item) => item != null)
//                   .cast<ItemMaster>()
//                   .where((item) =>
//               _searchQuery.isEmpty ||
//                   item.description.toLowerCase().contains(_searchQuery) ||
//                   item.itemCode.toLowerCase().contains(_searchQuery))
//                   .toList();
//
//               if (items.isEmpty) {
//                 return _buildEmptyState();
//               }
//
//               return ListView.builder(
//                 padding: const EdgeInsets.symmetric(horizontal: 16),
//                 itemCount: items.length,
//                 itemBuilder: (context, index) {
//                   return _buildItemCard(items[index]);
//                 },
//               );
//             },
//           ),
//         ),
//         Align(
//           alignment: Alignment.bottomRight,
//           child: Padding(
//             padding: const EdgeInsets.all(16.0),
//             child: FloatingActionButton.extended(
//               heroTag: 'generate_items_report',
//               label: const Text('Generate My Items Report'),
//               icon: const Icon(Icons.document_scanner),
//               backgroundColor: Colors.blue,
//               onPressed: () async {
//                 try {
//                   final snapshot = await _firestore
//                       .collection('items')
//                       .where('userId', isEqualTo: widget.userId)
//                       .where('isActive', isEqualTo: true)
//                       .get();
//                   final items = snapshot.docs
//                       .map((doc) => ItemMaster.fromFirestore(doc))
//                       .toList();
//                   if (items.isEmpty) {
//                     if (mounted) {
//                       ScaffoldMessenger.of(context).showSnackBar(
//                         const SnackBar(content: Text('No items to export.'), backgroundColor: Colors.orange),
//                       );
//                     }
//                     return;
//                   }
//                   showModalBottomSheet(
//                     context: context,
//                     builder: (BuildContext bc) {
//                       return SafeArea(
//                         child: Wrap(
//                           children: <Widget>[
//                             ListTile(
//                               leading: const Icon(Icons.download),
//                               title: const Text('Download PDF'),
//                               onTap: () async {
//                                 Navigator.pop(bc);
//                                 await PDFUtils.generateAndDownloadAllItemsPDF(items);
//                                 if (mounted) {
//                                   ScaffoldMessenger.of(context).showSnackBar(
//                                     const SnackBar(content: Text('All Items Report PDF downloaded!'), backgroundColor: Colors.green),
//                                   );
//                                 }
//                               },
//                             ),
//                             ListTile(
//                               leading: const Icon(Icons.share),
//                               title: const Text('Share PDF'),
//                               onTap: () async {
//                                 Navigator.pop(bc);
//                                 await PDFUtils.shareAllItemsPDF(items);
//                                 if (mounted) {
//                                   ScaffoldMessenger.of(context).showSnackBar(
//                                     const SnackBar(content: Text('All Items Report PDF shared!'), backgroundColor: Colors.green),
//                                   );
//                                 }
//                               },
//                             ),
//                             ListTile(
//                               leading: const Icon(Icons.print),
//                               title: const Text('Print PDF'),
//                               onTap: () async {
//                                 Navigator.pop(bc);
//                                 await PDFUtils.printAllItemsPDF(items);
//                                 if (mounted) {
//                                   ScaffoldMessenger.of(context).showSnackBar(
//                                     const SnackBar(content: Text('All Items Report PDF sent to printer!'), backgroundColor: Colors.green),
//                                   );
//                                 }
//                               },
//                             ),
//                           ],
//                         ),
//                       );
//                     },
//                   );
//                 } catch (e) {
//                   if (mounted) {
//                     ScaffoldMessenger.of(context).showSnackBar(
//                       SnackBar(content: Text('Error generating items report: $e'), backgroundColor: Colors.red),
//                     );
//                   }
//                   debugPrint('Error generating all items report: $e');
//                 }
//               },
//             ),
//           ),
//         ),
//       ],
//     );
//   }
//
//   Widget _buildEmptyState() {
//     return Center(
//       child: Column(
//         mainAxisAlignment: MainAxisAlignment.center,
//         children: [
//           Icon(
//             Icons.inventory_2_outlined,
//             size: 80,
//             color: Colors.grey.shade400,
//           ),
//           const SizedBox(height: 16),
//           Text(
//             _searchQuery.isEmpty ? 'No items found' : 'No items match your search',
//             style: TextStyle(
//               fontSize: 18,
//               fontWeight: FontWeight.w600,
//               color: Colors.grey.shade600,
//             ),
//           ),
//           const SizedBox(height: 8),
//           Text(
//             _searchQuery.isEmpty
//                 ? 'Add your first item to get started'
//                 : 'Try a different search term',
//             style: TextStyle(
//               fontSize: 14,
//               color: Colors.grey.shade500,
//             ),
//           ),
//           if (_searchQuery.isEmpty) ...[
//             const SizedBox(height: 24),
//             ElevatedButton.icon(
//               onPressed: () => showAddItemDialog(),
//               icon: const Icon(Icons.add),
//               label: const Text('Add Item'),
//               style: ElevatedButton.styleFrom(
//                 backgroundColor: const Color(0xFF667eea),
//                 foregroundColor: Colors.white,
//                 padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
//                 shape: RoundedRectangleBorder(
//                   borderRadius: BorderRadius.circular(10),
//                 ),
//               ),
//             ),
//           ],
//         ],
//       ),
//     );
//   }
//
//   Widget _buildItemCard(ItemMaster item) {
//     return Container(
//       margin: const EdgeInsets.only(bottom: 12),
//       decoration: BoxDecoration(
//         color: Colors.white,
//         borderRadius: BorderRadius.circular(12),
//         border: Border.all(color: Colors.grey.shade200, width: 1),
//         boxShadow: [
//           BoxShadow(
//             color: Colors.black.withOpacity(0.05),
//             blurRadius: 10,
//             offset: const Offset(0, 2),
//           ),
//         ],
//       ),
//       child: InkWell(
//         onTap: () => _showItemDetails(item),
//         borderRadius: BorderRadius.circular(12),
//         child: Padding(
//           padding: const EdgeInsets.all(16),
//           child: Column(
//             crossAxisAlignment: CrossAxisAlignment.start,
//             children: [
//               Row(
//                 children: [
//                   Container(
//                     width: 50,
//                     height: 50,
//                     decoration: BoxDecoration(
//                       color: const Color(0xFF667eea).withOpacity(0.1),
//                       borderRadius: BorderRadius.circular(12),
//                     ),
//                     child: const Icon(
//                       Icons.inventory_2,
//                       color: Color(0xFF667eea),
//                       size: 24,
//                     ),
//                   ),
//                   const SizedBox(width: 12),
//                   Expanded(
//                     child: Column(
//                       crossAxisAlignment: CrossAxisAlignment.start,
//                       children: [
//                         Text(
//                           item.description.isNotEmpty ? item.description : 'Unnamed Item',
//                           style: const TextStyle(
//                             fontSize: 16,
//                             fontWeight: FontWeight.w600,
//                             color: Colors.black87,
//                           ),
//                           maxLines: 1,
//                           overflow: TextOverflow.ellipsis,
//                         ),
//                         const SizedBox(height: 4),
//                         Text(
//                           'Code: ${item.itemCode.isNotEmpty ? item.itemCode : 'N/A'}',
//                           style: TextStyle(
//                             fontSize: 12,
//                             color: Colors.grey.shade600,
//                           ),
//                         ),
//                       ],
//                     ),
//                   ),
//                   PopupMenuButton<String>(
//                     onSelected: (value) {
//                       switch (value) {
//                         case 'edit':
//                           _showEditItemDialog(item);
//                           break;
//                         case 'delete':
//                           _showDeleteConfirmation(item);
//                           break;
//                       }
//                     },
//                     itemBuilder: (context) => [
//                       const PopupMenuItem(
//                         value: 'edit',
//                         child: Row(
//                           children: [
//                             Icon(Icons.edit, size: 20),
//                             SizedBox(width: 8),
//                             Text('Edit'),
//                           ],
//                         ),
//                       ),
//                       const PopupMenuItem(
//                         value: 'delete',
//                         child: Row(
//                           children: [
//                             Icon(Icons.delete, size: 20, color: Colors.red),
//                             SizedBox(width: 8),
//                             Text('Delete', style: TextStyle(color: Colors.red)),
//                           ],
//                         ),
//                       ),
//                     ],
//                   ),
//                 ],
//               ),
//               const SizedBox(height: 12),
//               Row(
//                 children: [
//                   _buildInfoChip('HSN: ${item.hsnSacCode.isNotEmpty ? item.hsnSacCode : 'N/A'}', Colors.blue),
//                   const SizedBox(width: 8),
//                   _buildInfoChip('Unit: ${item.unitOfMeasurement.isNotEmpty ? item.unitOfMeasurement : 'N/A'}', Colors.green),
//                 ],
//               ),
//               const SizedBox(height: 8),
//               Row(
//                 mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                 children: [
//                   Column(
//                     crossAxisAlignment: CrossAxisAlignment.start,
//                     children: [
//                       Text(
//                         'Cost Price',
//                         style: TextStyle(
//                           fontSize: 12,
//                           color: Colors.grey.shade600,
//                         ),
//                       ),
//                       Text(
//                         '₹${item.costPrice.toStringAsFixed(2)}',
//                         style: const TextStyle(
//                           fontSize: 14,
//                           fontWeight: FontWeight.w600,
//                           color: Colors.red,
//                         ),
//                       ),
//                     ],
//                   ),
//                   Column(
//                     crossAxisAlignment: CrossAxisAlignment.end,
//                     children: [
//                       Text(
//                         'Selling Price',
//                         style: TextStyle(
//                           fontSize: 12,
//                           color: Colors.grey.shade600,
//                         ),
//                       ),
//                       Text(
//                         '₹${item.sellingPrice.toStringAsFixed(2)}',
//                         style: const TextStyle(
//                           fontSize: 14,
//                           fontWeight: FontWeight.w600,
//                           color: Colors.green,
//                         ),
//                       ),
//                     ],
//                   ),
//                   Column(
//                     crossAxisAlignment: CrossAxisAlignment.end,
//                     children: [
//                       Text(
//                         'Profit Margin',
//                         style: TextStyle(
//                           fontSize: 12,
//                           color: Colors.grey.shade600,
//                         ),
//                       ),
//                       Text(
//                         '${item.profitMargin.toStringAsFixed(1)}%',
//                         style: const TextStyle(
//                           fontSize: 14,
//                           fontWeight: FontWeight.w600,
//                           color: Color(0xFF667eea),
//                         ),
//                       ),
//                     ],
//                   ),
//                 ],
//               ),
//             ],
//           ),
//         ),
//       ),
//     );
//   }
//
//   Widget _buildInfoChip(String label, Color color) {
//     return Container(
//       padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
//       decoration: BoxDecoration(
//         color: color.withOpacity(0.1),
//         borderRadius: BorderRadius.circular(6),
//       ),
//       child: Text(
//         label,
//         style: TextStyle(
//           fontSize: 11,
//           fontWeight: FontWeight.w500,
//           color: color,
//         ),
//       ),
//     );
//   }
//
//   void _showEditItemDialog(ItemMaster item) {
//     _showItemDialog(item);
//   }
//
//   void _showItemDialog(ItemMaster? item) {
//     final isEditing = item != null;
//     final _dialogFormKey = GlobalKey<FormState>();
//     final controllers = {
//       'itemCode': TextEditingController(text: item?.itemCode ?? ''),
//       'description': TextEditingController(text: item?.description ?? ''),
//       'hsnSacCode': TextEditingController(text: item?.hsnSacCode ?? ''),
//       'unitOfMeasurement': TextEditingController(text: item?.unitOfMeasurement ?? ''),
//       'cgstRate': TextEditingController(text: item?.cgstRate.toString() ?? '0.0'),
//       'sgstRate': TextEditingController(text: item?.sgstRate.toString() ?? '0.0'),
//       'igstRate': TextEditingController(text: item?.igstRate.toString() ?? '0.0'),
//       'cessRate': TextEditingController(text: item?.cessRate.toString() ?? '0.0'),
//       'sellingPrice': TextEditingController(text: item?.sellingPrice.toString() ?? '0.0'),
//       'costPrice': TextEditingController(text: item?.costPrice.toString() ?? '0.0'),
//     };
//
//     showDialog(
//       context: context,
//       builder: (context) => AlertDialog(
//         title: Text(isEditing ? 'Edit Item' : 'Add New Item'),
//         content: Form(
//           key: _dialogFormKey,
//           child: SingleChildScrollView(
//             child: Column(
//               mainAxisSize: MainAxisSize.min,
//               children: [
//                 _buildDialogTextField('Item Code', controllers['itemCode']!, validator: (value) {
//                   if (value == null || value.trim().isEmpty) return 'Item Code is required';
//                   return null;
//                 }),
//                 _buildDialogTextField('Description', controllers['description']!, validator: (value) {
//                   if (value == null || value.trim().isEmpty) return 'Description is required';
//                   return null;
//                 }),
//                 _buildDialogTextField('HSN/SAC Code', controllers['hsnSacCode']!),
//                 _buildDialogTextField('Unit of Measurement', controllers['unitOfMeasurement']!),
//                 Row(
//                   children: [
//                     Expanded(child: _buildDialogTextField('CGST Rate %', controllers['cgstRate']!, isNumber: true, validator: (value) {
//                       if (double.tryParse(value ?? '') == null) return 'Valid number required';
//                       return null;
//                     })),
//                     const SizedBox(width: 8),
//                     Expanded(child: _buildDialogTextField('SGST Rate %', controllers['sgstRate']!, isNumber: true, validator: (value) {
//                       if (double.tryParse(value ?? '') == null) return 'Valid number required';
//                       return null;
//                     })),
//                   ],
//                 ),
//                 Row(
//                   children: [
//                     Expanded(child: _buildDialogTextField('IGST Rate %', controllers['igstRate']!, isNumber: true, validator: (value) {
//                       if (double.tryParse(value ?? '') == null) return 'Valid number required';
//                       return null;
//                     })),
//                     const SizedBox(width: 8),
//                     Expanded(child: _buildDialogTextField('Cess Rate %', controllers['cessRate']!, isNumber: true, validator: (value) {
//                       if (double.tryParse(value ?? '') == null) return 'Valid number required';
//                       return null;
//                     })),
//                   ],
//                 ),
//                 Row(
//                   children: [
//                     Expanded(child: _buildDialogTextField('Cost Price', controllers['costPrice']!, isNumber: true, validator: (value) {
//                       if (double.tryParse(value ?? '') == null) return 'Valid number required';
//                       return null;
//                     })),
//                     const SizedBox(width: 8),
//                     Expanded(child: _buildDialogTextField('Selling Price', controllers['sellingPrice']!, isNumber: true, validator: (value) {
//                       if (double.tryParse(value ?? '') == null) return 'Valid number required';
//                       return null;
//                     })),
//                   ],
//                 ),
//               ],
//             ),
//           ),
//         ),
//         actions: [
//           TextButton(
//             onPressed: () => Navigator.of(context).pop(),
//             child: const Text('Cancel'),
//           ),
//           ElevatedButton(
//             onPressed: () {
//               if (_dialogFormKey.currentState!.validate()) {
//                 _saveItem(controllers, isEditing, item?.id);
//               } else {
//                 debugPrint('Add/Edit Item Dialog: Form validation failed.');
//               }
//             },
//             style: ElevatedButton.styleFrom(
//               backgroundColor: const Color(0xFF667eea),
//               foregroundColor: Colors.white,
//             ),
//             child: Text(isEditing ? 'Update' : 'Save'),
//           ),
//         ],
//       ),
//     );
//   }
//
//   Widget _buildDialogTextField(String label, TextEditingController controller, {bool isNumber = false, String? Function(String?)? validator}) {
//     return Padding(
//       padding: const EdgeInsets.only(bottom: 12),
//       child: TextFormField(
//         controller: controller,
//         keyboardType: isNumber ? const TextInputType.numberWithOptions(decimal: true) : TextInputType.text,
//         decoration: InputDecoration(
//           labelText: label,
//           border: const OutlineInputBorder(),
//           contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
//           filled: true,
//           fillColor: Colors.white,
//         ),
//         validator: validator,
//       ),
//     );
//   }
//
//   Future<void> _saveItem(Map<String, TextEditingController> controllers, bool isEditing, String? itemId) async {
//     try {
//       final costPrice = double.tryParse(controllers['costPrice']!.text.trim()) ?? 0;
//       final sellingPrice = double.tryParse(controllers['sellingPrice']!.text.trim()) ?? 0;
//       final profitMargin = costPrice > 0 ? ((sellingPrice - costPrice) / costPrice) * 100 : 0;
//
//       final itemData = {
//         'userId': widget.userId,
//         'itemCode': controllers['itemCode']!.text.trim(),
//         'description': controllers['description']!.text.trim(),
//         'hsnSacCode': controllers['hsnSacCode']!.text.trim(),
//         'unitOfMeasurement': controllers['unitOfMeasurement']!.text.trim(),
//         'cgstRate': double.tryParse(controllers['cgstRate']!.text.trim()) ?? 0,
//         'sgstRate': double.tryParse(controllers['sgstRate']!.text.trim()) ?? 0,
//         'igstRate': double.tryParse(controllers['igstRate']!.text.trim()) ?? 0,
//         'cessRate': double.tryParse(controllers['cessRate']!.text.trim()) ?? 0,
//         'sellingPrice': sellingPrice,
//         'costPrice': costPrice,
//         'profitMargin': profitMargin,
//         'isActive': true,
//         if (!isEditing) 'createdAt': FieldValue.serverTimestamp(),
//       };
//
//       if (isEditing && itemId != null) {
//         await _firestore.collection('items').doc(itemId).update(itemData);
//         debugPrint('Item updated successfully: $itemId');
//       } else {
//         final docRef = await _firestore.collection('items').add(itemData);
//         debugPrint('Item added successfully with ID: ${docRef.id}');
//       }
//
//       if (mounted) {
//         Navigator.of(context).pop();
//         ScaffoldMessenger.of(context).showSnackBar(
//           SnackBar(
//             content: Text(isEditing ? 'Item updated successfully' : 'Item added successfully'),
//             backgroundColor: Colors.green,
//           ),
//         );
//       }
//     } catch (e) {
//       if (mounted) {
//         ScaffoldMessenger.of(context).showSnackBar(
//           SnackBar(
//             content: Text('Error: ${e.toString()}'),
//             backgroundColor: Colors.red,
//           ),
//         );
//       }
//       debugPrint('Error saving item: $e');
//     }
//   }
//
//   void _showItemDetails(ItemMaster item) {
//     showDialog(
//       context: context,
//       builder: (context) => AlertDialog(
//         title: Text(item.description.isNotEmpty ? item.description : 'Item Details'),
//         content: Column(
//           mainAxisSize: MainAxisSize.min,
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             _buildDetailRow('Item Code', item.itemCode.isNotEmpty ? item.itemCode : 'N/A'),
//             _buildDetailRow('HSN/SAC Code', item.hsnSacCode.isNotEmpty ? item.hsnSacCode : 'N/A'),
//             _buildDetailRow('Unit', item.unitOfMeasurement.isNotEmpty ? item.unitOfMeasurement : 'N/A'),
//             _buildDetailRow('CGST Rate', '${item.cgstRate}%'),
//             _buildDetailRow('SGST Rate', '${item.sgstRate}%'),
//             _buildDetailRow('IGST Rate', '${item.igstRate}%'),
//             _buildDetailRow('Cost Price', '₹${item.costPrice.toStringAsFixed(2)}'),
//             _buildDetailRow('Selling Price', '₹${item.sellingPrice.toStringAsFixed(2)}'),
//             _buildDetailRow('Profit Margin', '${item.profitMargin.toStringAsFixed(2)}%'),
//           ],
//         ),
//         actions: [
//           TextButton(
//             onPressed: () => Navigator.of(context).pop(),
//             child: const Text('Close'),
//           ),
//         ],
//       ),
//     );
//   }
//
//   Widget _buildDetailRow(String label, String value) {
//     return Padding(
//       padding: const EdgeInsets.symmetric(vertical: 4),
//       child: Row(
//         mainAxisAlignment: MainAxisAlignment.spaceBetween,
//         children: [
//           Text(
//             label,
//             style: TextStyle(
//               fontWeight: FontWeight.w500,
//               color: Colors.grey.shade600,
//             ),
//           ),
//           Flexible(
//             child: Text(
//               value,
//               style: const TextStyle(
//                 fontWeight: FontWeight.w600,
//                 color: Colors.black87,
//               ),
//               textAlign: TextAlign.right,
//             ),
//           ),
//         ],
//       ),
//     );
//   }
//
//   void _showDeleteConfirmation(ItemMaster item) {
//     showDialog(
//       context: context,
//       builder: (context) => AlertDialog(
//         title: const Text('Delete Item'),
//         content: Text('Are you sure you want to delete "${item.description.isNotEmpty ? item.description : 'this item'}"?'),
//         actions: [
//           TextButton(
//             onPressed: () => Navigator.of(context).pop(),
//             child: const Text('Cancel'),
//           ),
//           ElevatedButton(
//             onPressed: () async {
//               try {
//                 await _firestore.collection('items').doc(item.id).update({'isActive': false});
//                 if (mounted) {
//                   Navigator.of(context).pop();
//                   ScaffoldMessenger.of(context).showSnackBar(
//                     const SnackBar(
//                       content: Text('Item deleted successfully'),
//                       backgroundColor: Colors.green,
//                     ),
//                   );
//                 }
//                 debugPrint('Item deleted successfully: ${item.id}');
//               } catch (e) {
//                 if (mounted) {
//                   ScaffoldMessenger.of(context).showSnackBar(
//                     SnackBar(
//                       content: Text('Error: ${e.toString()}'),
//                       backgroundColor: Colors.red,
//                     ),
//                   );
//                 }
//                 debugPrint('Error deleting item: $e');
//               }
//             },
//             style: ElevatedButton.styleFrom(
//               backgroundColor: Colors.red,
//               foregroundColor: Colors.white,
//             ),
//             child: const Text('Delete'),
//           ),
//         ],
//       ),
//     );
//   }
//
//   @override
//   void dispose() {
//     _searchController.dispose();
//     super.dispose();
//   }
// }