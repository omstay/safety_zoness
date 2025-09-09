// // GSTR-1 Section Screen for B2B, B2C Large, B2C Small, Exports
// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:flutter/material.dart';
// import 'package:intl/intl.dart';
// import 'package:safetyzoness/screens/pdf_utils.dart';
//
// import '../model/SaleMaster.dart';
//
// // Import your models
//
//
// // Import your utility for PDF/Excel/JSON export
//
//
// class GSTR1SectionScreen extends StatefulWidget {
//   final String businessId;
//   final String sectionTitle;
//   final String sectionFilter;
//   final DateTime fromDate;
//   final DateTime toDate;
//
//   const GSTR1SectionScreen({
//     super.key,
//     required this.businessId,
//     required this.sectionTitle,
//     required this.sectionFilter,
//     required this.fromDate,
//     required this.toDate,
//   });
//
//   @override
//   State<GSTR1SectionScreen> createState() => _GSTR1SectionScreenState();
// }
//
// class _GSTR1SectionScreenState extends State<GSTR1SectionScreen> {
//   final FirebaseFirestore _firestore = FirebaseFirestore.instance;
//
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: Text(widget.sectionTitle),
//         backgroundColor: const Color(0xFF667eea),
//         foregroundColor: Colors.white,
//         actions: [
//           IconButton(
//             icon: const Icon(Icons.file_download),
//             onPressed: _exportData,
//           ),
//         ],
//       ),
//       body: StreamBuilder<QuerySnapshot>(
//         stream: _firestore
//             .collection('sales')
//             .where('businessId', isEqualTo: widget.businessId)
//             .where('gstr1Section', isEqualTo: widget.sectionFilter)
//             .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(widget.fromDate))
//             .where('date', isLessThanOrEqualTo: Timestamp.fromDate(widget.toDate))
//             .orderBy('date', descending: true)
//             .snapshots(),
//         builder: (context, snapshot) {
//           if (snapshot.hasError) {
//             return Center(child: Text('Error: ${snapshot.error}'));
//           }
//
//           if (snapshot.connectionState == ConnectionState.waiting) {
//             return const Center(child: CircularProgressIndicator());
//           }
//
//           final sales = snapshot.data!.docs
//               .map((doc) => SaleMaster.fromFirestore(doc))
//               .toList();
//
//           if (sales.isEmpty) {
//             return _buildEmptyState();
//           }
//
//           // Calculate totals
//           double totalTaxableValue = 0;
//           double totalCGST = 0;
//           double totalSGST = 0;
//           double totalIGST = 0;
//           double totalCess = 0;
//           double grandTotal = 0;
//
//           for (var sale in sales) {
//             for (var item in sale.items) {
//               totalTaxableValue += item.totalTaxableValue;
//               totalCGST += item.centralTaxAmount;
//               totalSGST += item.stateTaxAmount;
//               totalIGST += item.integratedTaxAmount;
//               totalCess += item.cessAmount;
//             }
//             grandTotal += sale.total;
//           }
//
//           return Column(
//             children: [
//               // Summary Card
//               Container(
//                 margin: const EdgeInsets.all(16),
//                 padding: const EdgeInsets.all(16),
//                 decoration: BoxDecoration(
//                   gradient: LinearGradient(
//                     colors: [Colors.blue.shade600, Colors.blue.shade400],
//                     begin: Alignment.topLeft,
//                     end: Alignment.bottomRight,
//                   ),
//                   borderRadius: BorderRadius.circular(12),
//                   boxShadow: [
//                     BoxShadow(
//                       color: Colors.blue.withOpacity(0.3),
//                       blurRadius: 10,
//                       offset: const Offset(0, 4),
//                     ),
//                   ],
//                 ),
//                 child: Column(
//                   children: [
//                     Text(
//                       'Period: ${DateFormat('dd/MM/yyyy').format(widget.fromDate)} - ${DateFormat('dd/MM/yyyy').format(widget.toDate)}',
//                       style: const TextStyle(color: Colors.white70, fontSize: 12),
//                     ),
//                     const SizedBox(height: 8),
//                     Text(
//                       '${sales.length} Invoices',
//                       style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600),
//                     ),
//                     const SizedBox(height: 12),
//                     Row(
//                       mainAxisAlignment: MainAxisAlignment.spaceAround,
//                       children: [
//                         _buildSummaryItem('Taxable', '₹${totalTaxableValue.toStringAsFixed(2)}'),
//                         _buildSummaryItem('CGST', '₹${totalCGST.toStringAsFixed(2)}'),
//                         _buildSummaryItem('SGST', '₹${totalSGST.toStringAsFixed(2)}'),
//                         _buildSummaryItem('IGST', '₹${totalIGST.toStringAsFixed(2)}'),
//                       ],
//                     ),
//                     const SizedBox(height: 12),
//                     Text(
//                       'Total: ₹${grandTotal.toStringAsFixed(2)}',
//                       style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
//                     ),
//                   ],
//                 ),
//               ),
//
//               // Sales List
//               Expanded(
//                 child: ListView.builder(
//                   padding: const EdgeInsets.symmetric(horizontal: 16),
//                   itemCount: sales.length,
//                   itemBuilder: (context, index) {
//                     return _buildSaleCard(sales[index]);
//                   },
//                 ),
//               ),
//             ],
//           );
//         },
//       ),
//     );
//   }
//
//   Widget _buildSummaryItem(String label, String value) {
//     return Column(
//       children: [
//         Text(label, style: const TextStyle(color: Colors.white70, fontSize: 11)),
//         const SizedBox(height: 4),
//         Text(value, style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600)),
//       ],
//     );
//   }
//
//   Widget _buildEmptyState() {
//     return Center(
//       child: Column(
//         mainAxisAlignment: MainAxisAlignment.center,
//         children: [
//           const Icon(Icons.inbox, size: 80, color: Colors.grey),
//           const SizedBox(height: 16),
//           Text(
//             'No ${widget.sectionTitle.toLowerCase()} found',
//             style: const TextStyle(fontSize: 18, color: Colors.grey),
//           ),
//           const SizedBox(height: 8),
//           Text(
//             'for the selected period',
//             style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
//           ),
//         ],
//       ),
//     );
//   }
//
//   Widget _buildSaleCard(SaleMaster sale) {
//     return Card(
//       margin: const EdgeInsets.only(bottom: 12),
//       shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
//       elevation: 2,
//       child: Padding(
//         padding: const EdgeInsets.all(16),
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             Row(
//               mainAxisAlignment: MainAxisAlignment.spaceBetween,
//               children: [
//                 Expanded(
//                   child: Column(
//                     crossAxisAlignment: CrossAxisAlignment.start,
//                     children: [
//                       Text(
//                         'Invoice: ${sale.invoice}',
//                         style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
//                       ),
//                       const SizedBox(height: 4),
//                       Text('Customer: ${sale.customerName}'),
//                       if (sale.recipientGSTIN.isNotEmpty)
//                         Text('GSTIN: ${sale.recipientGSTIN}',
//                             style: TextStyle(color: Colors.blue.shade700, fontWeight: FontWeight.w500)),
//                     ],
//                   ),
//                 ),
//                 Column(
//                   crossAxisAlignment: CrossAxisAlignment.end,
//                   children: [
//                     Text(
//                       '₹${sale.total.toStringAsFixed(2)}',
//                       style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.green),
//                     ),
//                     Text(
//                       DateFormat('dd/MM/yyyy').format(sale.date),
//                       style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
//                     ),
//                     Container(
//                       padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
//                       decoration: BoxDecoration(
//                         color: sale.supplyType == 'INTRA' ? Colors.green.shade100 : Colors.orange.shade100,
//                         borderRadius: BorderRadius.circular(4),
//                       ),
//                       child: Text(
//                         sale.supplyType,
//                         style: TextStyle(
//                           fontSize: 10,
//                           fontWeight: FontWeight.w500,
//                           color: sale.supplyType == 'INTRA' ? Colors.green.shade700 : Colors.orange.shade700,
//                         ),
//                       ),
//                     ),
//                   ],
//                 ),
//               ],
//             ),
//
//             if (sale.placeOfSupply.isNotEmpty) ...[
//               const SizedBox(height: 8),
//               Text('POS: ${sale.placeOfSupply}', style: TextStyle(color: Colors.grey.shade600)),
//             ],
//
//             const SizedBox(height: 12),
//             // Items summary
//             Text('Items (${sale.items.length}):', style: const TextStyle(fontWeight: FontWeight.w500)),
//             ...sale.items.take(3).map((item) => Padding(
//               padding: const EdgeInsets.only(left: 12, top: 4),
//               child: Row(
//                 children: [
//                   Expanded(child: Text('• ${item.description}', style: TextStyle(fontSize: 13, color: Colors.grey.shade700))),
//                   Text('₹${item.itemTotal.toStringAsFixed(2)}', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
//                 ],
//               ),
//             )),
//             if (sale.items.length > 3)
//               Padding(
//                 padding: const EdgeInsets.only(left: 12, top: 4),
//                 child: Text('... and ${sale.items.length - 3} more items',
//                     style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
//               ),
//           ],
//         ),
//       ),
//     );
//   }
//
//   Future<void> _exportData() async {
//     try {
//       final salesSnapshot = await _firestore
//           .collection('sales')
//           .where('businessId', isEqualTo: widget.businessId)
//           .where('gstr1Section', isEqualTo: widget.sectionFilter)
//           .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(widget.fromDate))
//           .where('date', isLessThanOrEqualTo: Timestamp.fromDate(widget.toDate))
//           .get();
//
//       final sales = salesSnapshot.docs
//           .map((doc) => SaleMaster.fromFirestore(doc))
//           .toList();
//
//       if (sales.isEmpty) {
//         ScaffoldMessenger.of(context).showSnackBar(
//           const SnackBar(content: Text('No data to export')),
//         );
//         return;
//       }
//
//       showModalBottomSheet(
//         context: context,
//         builder: (BuildContext bc) {
//           return SafeArea(
//             child: Wrap(
//               children: <Widget>[
//                 ListTile(
//                   leading: const Icon(Icons.picture_as_pdf),
//                   title: const Text('Download PDF'),
//                   onTap: () async {
//                     Navigator.pop(bc);
//                     await PDFUtils.generateGSTR1SectionPDF(sales, widget.sectionTitle, widget.fromDate, widget.toDate);
//                     ScaffoldMessenger.of(context).showSnackBar(
//                       SnackBar(content: Text('${widget.sectionTitle} PDF downloaded!')),
//                     );
//                   },
//                 ),
//                 ListTile(
//                   leading: const Icon(Icons.table_chart),
//                   title: const Text('Download Excel'),
//                   onTap: () async {
//                     Navigator.pop(bc);
//                     await PDFUtils.generateGSTR1SectionExcel(sales, widget.sectionTitle, widget.fromDate, widget.toDate);
//                     ScaffoldMessenger.of(context).showSnackBar(
//                       SnackBar(content: Text('${widget.sectionTitle} Excel downloaded!')),
//                     );
//                   },
//                 ),
//                 ListTile(
//                   leading: const Icon(Icons.code),
//                   title: const Text('Download JSON'),
//                   onTap: () async {
//                     Navigator.pop(bc);
//                     await PDFUtils.generateGSTR1SectionJSON(sales, widget.sectionFilter, widget.fromDate, widget.toDate);
//                     ScaffoldMessenger.of(context).showSnackBar(
//                       SnackBar(content: Text('${widget.sectionTitle} JSON downloaded!')),
//                     );
//                   },
//                 ),
//               ],
//             ),
//           );
//         },
//       );
//     } catch (e) {
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
//       );
//     }
//   }
// }
//
// // HSN Summary Screen
// class HSNSummaryScreen extends StatefulWidget {
//   final String businessId;
//   final DateTime fromDate;
//   final DateTime toDate;
//
//   const HSNSummaryScreen({
//     super.key,
//     required this.businessId,
//     required this.fromDate,
//     required this.toDate,
//   });
//
//   @override
//   State<HSNSummaryScreen> createState() => _HSNSummaryScreenState();
// }
//
// class _HSNSummaryScreenState extends State<HSNSummaryScreen> {
//   final FirebaseFirestore _firestore = FirebaseFirestore.instance;
//
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: const Text('HSN Summary'),
//         backgroundColor: const Color(0xFF667eea),
//         foregroundColor: Colors.white,
//         actions: [
//           IconButton(
//             icon: const Icon(Icons.file_download),
//             onPressed: _exportHSNSummary,
//           ),
//         ],
//       ),
//       body: FutureBuilder<List<Map<String, dynamic>>>(
//         future: _generateHSNSummary(),
//         builder: (context, snapshot) {
//           if (snapshot.connectionState == ConnectionState.waiting) {
//             return const Center(child: CircularProgressIndicator());
//           }
//
//           if (snapshot.hasError) {
//             return Center(child: Text('Error: ${snapshot.error}'));
//           }
//
//           final hsnData = snapshot.data ?? [];
//
//           if (hsnData.isEmpty) {
//             return const Center(
//               child: Column(
//                 mainAxisAlignment: MainAxisAlignment.center,
//                 children: [
//                   Icon(Icons.summarize, size: 80, color: Colors.grey),
//                   SizedBox(height: 16),
//                   Text('No HSN data found', style: TextStyle(fontSize: 18, color: Colors.grey)),
//                 ],
//               ),
//             );
//           }
//
//           return Column(
//             children: [
//               // Summary header
//               Container(
//                 padding: const EdgeInsets.all(16),
//                 color: Colors.teal.shade50,
//                 child: Row(
//                   mainAxisAlignment: MainAxisAlignment.spaceAround,
//                   children: [
//                     Column(
//                       children: [
//                         const Text('Total HSN Codes', style: TextStyle(fontSize: 12, color: Colors.grey)),
//                         Text('${hsnData.length}', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
//                       ],
//                     ),
//                     Column(
//                       children: [
//                         const Text('Total Value', style: TextStyle(fontSize: 12, color: Colors.grey)),
//                         Text('₹${hsnData.fold<double>(0, (sum, item) => sum + item['totalValue']).toStringAsFixed(2)}',
//                             style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
//                       ],
//                     ),
//                   ],
//                 ),
//               ),
//
//               // HSN List
//               Expanded(
//                 child: ListView.builder(
//                   padding: const EdgeInsets.all(16),
//                   itemCount: hsnData.length,
//                   itemBuilder: (context, index) {
//                     final hsn = hsnData[index];
//                     return _buildHSNCard(hsn);
//                   },
//                 ),
//               ),
//             ],
//           );
//         },
//       ),
//     );
//   }
//
//   Widget _buildHSNCard(Map<String, dynamic> hsn) {
//     return Card(
//       margin: const EdgeInsets.only(bottom: 12),
//       child: Padding(
//         padding: const EdgeInsets.all(16),
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             Row(
//               mainAxisAlignment: MainAxisAlignment.spaceBetween,
//               children: [
//                 Text(
//                   'HSN: ${hsn['hsnCode']}',
//                   style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
//                 ),
//                 Text(
//                   '₹${hsn['totalValue'].toStringAsFixed(2)}',
//                   style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.green),
//                 ),
//               ],
//             ),
//             const SizedBox(height: 8),
//             Text('Description: ${hsn['description']}'),
//             const SizedBox(height: 8),
//             Row(
//               children: [
//                 Expanded(child: Text('UQC: ${hsn['uqc']}')),
//                 Expanded(child: Text('Qty: ${hsn['totalQuantity'].toStringAsFixed(2)}')),
//               ],
//             ),
//             const SizedBox(height: 8),
//             Row(
//               mainAxisAlignment: MainAxisAlignment.spaceAround,
//               children: [
//                 _buildTaxInfo('Taxable', hsn['taxableValue']),
//                 _buildTaxInfo('CGST', hsn['cgstAmount']),
//                 _buildTaxInfo('SGST', hsn['sgstAmount']),
//                 _buildTaxInfo('IGST', hsn['igstAmount']),
//               ],
//             ),
//           ],
//         ),
//       ),
//     );
//   }
//
//   Widget _buildTaxInfo(String label, double value) {
//     return Column(
//       children: [
//         Text(label, style: const TextStyle(fontSize: 11, color: Colors.grey)),
//         Text('₹${value.toStringAsFixed(2)}', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500)),
//       ],
//     );
//   }
//
//   Future<List<Map<String, dynamic>>> _generateHSNSummary() async {
//     final salesSnapshot = await _firestore
//         .collection('sales')
//         .where('businessId', isEqualTo: widget.businessId)
//         .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(widget.fromDate))
//         .where('date', isLessThanOrEqualTo: Timestamp.fromDate(widget.toDate))
//         .get();
//
//     final Map<String, Map<String, dynamic>> hsnSummary = {};
//
//     for (var doc in salesSnapshot.docs) {
//       final sale = SaleMaster.fromFirestore(doc);
//
//       for (var item in sale.items) {
//         final hsnCode = item.hsnSacCode;
//
//         if (hsnSummary.containsKey(hsnCode)) {
//           hsnSummary[hsnCode]!['totalQuantity'] += item.quantity;
//           hsnSummary[hsnCode]!['taxableValue'] += item.totalTaxableValue;
//           hsnSummary[hsnCode]!['cgstAmount'] += item.centralTaxAmount;
//           hsnSummary[hsnCode]!['sgstAmount'] += item.stateTaxAmount;
//           hsnSummary[hsnCode]!['igstAmount'] += item.integratedTaxAmount;
//           hsnSummary[hsnCode]!['totalValue'] += item.itemTotal;
//         } else {
//           hsnSummary[hsnCode] = {
//             'hsnCode': hsnCode,
//             'description': item.description,
//             'uqc': item.unitOfMeasurement,
//             'totalQuantity': item.quantity,
//             'taxableValue': item.totalTaxableValue,
//             'cgstAmount': item.centralTaxAmount,
//             'sgstAmount': item.stateTaxAmount,
//             'igstAmount': item.integratedTaxAmount,
//             'totalValue': item.itemTotal,
//           };
//         }
//       }
//     }
//
//     return hsnSummary.values.toList()..sort((a, b) => a['hsnCode'].compareTo(b['hsnCode']));
//   }
//
//   Future<void> _exportHSNSummary() async {
//     try {
//       final hsnData = await _generateHSNSummary();
//
//       if (hsnData.isEmpty) {
//         ScaffoldMessenger.of(context).showSnackBar(
//           const SnackBar(content: Text('No HSN data to export')),
//         );
//         return;
//       }
//
//       showModalBottomSheet(
//         context: context,
//         builder: (BuildContext bc) {
//           return SafeArea(
//             child: Wrap(
//               children: <Widget>[
//                 ListTile(
//                   leading: const Icon(Icons.picture_as_pdf),
//                   title: const Text('Download PDF'),
//                   onTap: () async {
//                     Navigator.pop(bc);
//                     await PDFUtils.generateHSNSummaryPDF(hsnData, widget.fromDate, widget.toDate);
//                     ScaffoldMessenger.of(context).showSnackBar(
//                       const SnackBar(content: Text('HSN Summary PDF downloaded!')),
//                     );
//                   },
//                 ),
//                 ListTile(
//                   leading: const Icon(Icons.table_chart),
//                   title: const Text('Download Excel'),
//                   onTap: () async {
//                     Navigator.pop(bc);
//                     await PDFUtils.generateHSNSummaryExcel(hsnData, widget.fromDate, widget.toDate);
//                     ScaffoldMessenger.of(context).showSnackBar(
//                       const SnackBar(content: Text('HSN Summary Excel downloaded!')),
//                     );
//                   },
//                 ),
//               ],
//             ),
//           );
//         },
//       );
//     } catch (e) {
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
//       );
//     }
//   }
// }
//
// // Documents Summary Screen
// class DocumentsSummaryScreen extends StatefulWidget {
//   final String businessId;
//   final DateTime fromDate;
//   final DateTime toDate;
//
//   const DocumentsSummaryScreen({
//     super.key,
//     required this.businessId,
//     required this.fromDate,
//     required this.toDate,
//   });
//
//   @override
//   State<DocumentsSummaryScreen> createState() => _DocumentsSummaryScreenState();
// }
//
// class _DocumentsSummaryScreenState extends State<DocumentsSummaryScreen> {
//   final FirebaseFirestore _firestore = FirebaseFirestore.instance;
//
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: const Text('Documents Summary'),
//         backgroundColor: const Color(0xFF667eea),
//         foregroundColor: Colors.white,
//       ),
//       body: FutureBuilder<Map<String, dynamic>>(
//         future: _generateDocumentsSummary(),
//         builder: (context, snapshot) {
//           if (snapshot.connectionState == ConnectionState.waiting) {
//             return const Center(child: CircularProgressIndicator());
//           }
//
//           if (snapshot.hasError) {
//             return Center(child: Text('Error: ${snapshot.error}'));
//           }
//
//           final docSummary = snapshot.data ?? {};
//
//           return Padding(
//             padding: const EdgeInsets.all(16),
//             child: Column(
//               crossAxisAlignment: CrossAxisAlignment.start,
//               children: [
//                 Text(
//                   'Period: ${DateFormat('dd/MM/yyyy').format(widget.fromDate)} - ${DateFormat('dd/MM/yyyy').format(widget.toDate)}',
//                   style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
//                 ),
//                 const SizedBox(height: 24),
//
//                 _buildDocumentTypeCard('Invoices', docSummary['invoices'] ?? {}),
//                 _buildDocumentTypeCard('Debit Notes', docSummary['debitNotes'] ?? {}),
//                 _buildDocumentTypeCard('Credit Notes', docSummary['creditNotes'] ?? {}),
//
//                 const SizedBox(height: 24),
//                 SizedBox(
//                   width: double.infinity,
//                   child: ElevatedButton.icon(
//                     onPressed: () => _exportDocumentsSummary(docSummary),
//                     icon: const Icon(Icons.file_download),
//                     label: const Text('Export Summary'),
//                     style: ElevatedButton.styleFrom(
//                       backgroundColor: const Color(0xFF667eea),
//                       foregroundColor: Colors.white,
//                       padding: const EdgeInsets.symmetric(vertical: 16),
//                     ),
//                   ),
//                 ),
//               ],
//             ),
//           );
//         },
//       ),
//     );
//   }
//
//   Widget _buildDocumentTypeCard(String title, Map<String, dynamic> data) {
//     final count = data['count'] ?? 0;
//     final fromNo = data['fromNo'] ?? 'N/A';
//     final toNo = data['toNo'] ?? 'N/A';
//     final cancelled = data['cancelled'] ?? 0;
//
//     return Card(
//       margin: const EdgeInsets.only(bottom: 16),
//       child: Padding(
//         padding: const EdgeInsets.all(16),
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             Text(
//               title,
//               style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
//             ),
//             const SizedBox(height: 12),
//             Row(
//               children: [
//                 Expanded(
//                   child: Column(
//                     crossAxisAlignment: CrossAxisAlignment.start,
//                     children: [
//                       Text('Total Issued: $count', style: const TextStyle(fontWeight: FontWeight.w500)),
//                       Text('From: $fromNo'),
//                       Text('To: $toNo'),
//                     ],
//                   ),
//                 ),
//                 if (cancelled > 0)
//                   Container(
//                     padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
//                     decoration: BoxDecoration(
//                       color: Colors.red.shade100,
//                       borderRadius: BorderRadius.circular(4),
//                     ),
//                     child: Text(
//                       '$cancelled Cancelled',
//                       style: TextStyle(color: Colors.red.shade700, fontSize: 12),
//                     ),
//                   ),
//               ],
//             ),
//           ],
//         ),
//       ),
//     );
//   }
//
//   Future<Map<String, dynamic>> _generateDocumentsSummary() async {
//     final salesSnapshot = await _firestore
//         .collection('sales')
//         .where('businessId', isEqualTo: widget.businessId)
//         .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(widget.fromDate))
//         .where('date', isLessThanOrEqualTo: Timestamp.fromDate(widget.toDate))
//         .get();
//
//     final invoices = <String>[];
//     final debitNotes = <String>[];
//     final creditNotes = <String>[];
//
//     for (var doc in salesSnapshot.docs) {
//       final sale = SaleMaster.fromFirestore(doc);
//
//       switch (sale.documentType) {
//         case 'INV':
//           invoices.add(sale.invoice);
//           break;
//         case 'DBN':
//           debitNotes.add(sale.invoice);
//           break;
//         case 'CDN':
//           creditNotes.add(sale.invoice);
//           break;
//       }
//     }
//
//     return {
//       'invoices': _getDocumentSummary(invoices),
//       'debitNotes': _getDocumentSummary(debitNotes),
//       'creditNotes': _getDocumentSummary(creditNotes),
//     };
//   }
//
//   Map<String, dynamic> _getDocumentSummary(List<String> documents) {
//     if (documents.isEmpty) {
//       return {'count': 0, 'fromNo': 'N/A', 'toNo': 'N/A', 'cancelled': 0};
//     }
//
//     documents.sort();
//     return {
//       'count': documents.length,
//       'fromNo': documents.first,
//       'toNo': documents.last,
//       'cancelled': 0, // You can implement cancelled document tracking
//     };
//   }
//
//   Future<void> _exportDocumentsSummary(Map<String, dynamic> summary) async {
//     try {
//       await PDFUtils.generateDocumentsSummaryPDF(summary, widget.fromDate, widget.toDate);
//       ScaffoldMessenger.of(context).showSnackBar(
//         const SnackBar(content: Text('Documents Summary PDF downloaded!')),
//       );
//     } catch (e) {
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
//       );
//     }
//   }
// }
//
// // Nil Rated Supplies Screen
// class NilRatedSuppliesScreen extends StatefulWidget {
//   final String businessId;
//   final DateTime fromDate;
//   final DateTime toDate;
//
//   const NilRatedSuppliesScreen({
//     super.key,
//     required this.businessId,
//     required this.fromDate,
//     required this.toDate,
//   });
//
//   @override
//   State<NilRatedSuppliesScreen> createState() => _NilRatedSuppliesScreenState();
// }
//
// class _NilRatedSuppliesScreenState extends State<NilRatedSuppliesScreen> {
//   final FirebaseFirestore _firestore = FirebaseFirestore.instance;
//
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: const Text('Nil Rated Supplies'),
//         backgroundColor: const Color(0xFF667eea),
//         foregroundColor: Colors.white,
//       ),
//       body: FutureBuilder<Map<String, List<Map<String, dynamic>>>>(
//         future: _generateNilRatedData(),
//         builder: (context, snapshot) {
//           if (snapshot.connectionState == ConnectionState.waiting) {
//             return const Center(child: CircularProgressIndicator());
//           }
//
//           if (snapshot.hasError) {
//             return Center(child: Text('Error: ${snapshot.error}'));
//           }
//
//           final nilRatedData = snapshot.data ?? {};
//
//           return DefaultTabController(
//             length: 4,
//             child: Column(
//               children: [
//                 const TabBar(
//                   labelColor: Color(0xFF667eea),
//                   unselectedLabelColor: Colors.grey,
//                   indicatorColor: Color(0xFF667eea),
//                   tabs: [
//                     Tab(text: 'Nil Rated'),
//                     Tab(text: 'Exempted'),
//                     Tab(text: 'Non-GST'),
//                     Tab(text: 'Composition'),
//                   ],
//                 ),
//                 Expanded(
//                   child: TabBarView(
//                     children: [
//                       _buildNilRatedTab(nilRatedData['nilRated'] ?? []),
//                       _buildNilRatedTab(nilRatedData['exempted'] ?? []),
//                       _buildNilRatedTab(nilRatedData['nonGST'] ?? []),
//                       _buildNilRatedTab(nilRatedData['composition'] ?? []),
//                     ],
//                   ),
//                 ),
//               ],
//             ),
//           );
//         },
//       ),
//     );
//   }
//
//   Widget _buildNilRatedTab(List<Map<String, dynamic>> data) {
//     if (data.isEmpty) {
//       return const Center(
//         child: Column(
//           mainAxisAlignment: MainAxisAlignment.center,
//           children: [
//             Icon(Icons.inbox, size: 80, color: Colors.grey),
//             SizedBox(height: 16),
//             Text('No data found', style: TextStyle(fontSize: 18, color: Colors.grey)),
//           ],
//         ),
//       );
//     }
//
//     double totalValue = data.fold(0, (sum, item) => sum + (item['value'] as double));
//
//     return Column(
//       children: [
//         Container(
//           padding: const EdgeInsets.all(16),
//           color: Colors.grey.shade100,
//           child: Row(
//             mainAxisAlignment: MainAxisAlignment.spaceBetween,
//             children: [
//               Text('Total Items: ${data.length}'),
//               Text('Total Value: ₹${totalValue.toStringAsFixed(2)}',
//                   style: const TextStyle(fontWeight: FontWeight.bold)),
//             ],
//           ),
//         ),
//         Expanded(
//           child: ListView.builder(
//             padding: const EdgeInsets.all(16),
//             itemCount: data.length,
//             itemBuilder: (context, index) {
//               final item = data[index];
//               return Card(
//                 margin: const EdgeInsets.only(bottom: 12),
//                 child: ListTile(
//                   title: Text(item['description']),
//                   subtitle: Text('HSN: ${item['hsnCode']}'),
//                   trailing: Text('₹${item['value'].toStringAsFixed(2)}',
//                       style: const TextStyle(fontWeight: FontWeight.bold)),
//                 ),
//               );
//             },
//           ),
//         ),
//       ],
//     );
//   }
//
//   Future<Map<String, List<Map<String, dynamic>>>> _generateNilRatedData() async {
//     final salesSnapshot = await _firestore
//         .collection('sales')
//         .where('businessId', isEqualTo: widget.businessId)
//         .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(widget.fromDate))
//         .where('date', isLessThanOrEqualTo: Timestamp.fromDate(widget.toDate))
//         .get();
//
//     final Map<String, List<Map<String, dynamic>>> nilRatedData = {
//       'nilRated': [],
//       'exempted': [],
//       'nonGST': [],
//       'composition': [],
//     };
//
//     for (var doc in salesSnapshot.docs) {
//       final sale = SaleMaster.fromFirestore(doc);
//
//       for (var item in sale.items) {
//         if (item.isNilRated) {
//           nilRatedData['nilRated']!.add({
//             'description': item.description,
//             'hsnCode': item.hsnSacCode,
//             'value': item.totalTaxableValue,
//           });
//         } else if (item.isExempt) {
//           nilRatedData['exempted']!.add({
//             'description': item.description,
//             'hsnCode': item.hsnSacCode,
//             'value': item.totalTaxableValue,
//           });
//         } else if (item.isNonGST) {
//           nilRatedData['nonGST']!.add({
//             'description': item.description,
//             'hsnCode': item.hsnSacCode,
//             'value': item.totalTaxableValue,
//           });
//         }
//       }
//     }
//
//     return nilRatedData;
//   }
// }