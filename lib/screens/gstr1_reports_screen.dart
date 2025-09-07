// NEW FILE: gstr1_reports_screen.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import '../model/SaleMaster.dart';
import 'gst_indivial.dart';
import 'inventory_management.dart';
import 'pdf_utils.dart';

class GSTR1ReportsScreen extends StatefulWidget {
  final String businessId;
  const GSTR1ReportsScreen({super.key, required this.businessId});

  @override
  State<GSTR1ReportsScreen> createState() => _GSTR1ReportsScreenState();
}

class _GSTR1ReportsScreenState extends State<GSTR1ReportsScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  DateTime _fromDate = DateTime.now().subtract(const Duration(days: 30));
  DateTime _toDate = DateTime.now();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('GSTR-1 Reports'),
        backgroundColor: const Color(0xFF667eea),
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          // Date Range Selector
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.white,
            child: Row(
              children: [
                Expanded(
                  child: InkWell(
                    onTap: () => _selectFromDate(context),
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('From Date', style: TextStyle(fontSize: 12, color: Colors.grey)),
                          Text(DateFormat('dd/MM/yyyy').format(_fromDate)),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: InkWell(
                    onTap: () => _selectToDate(context),
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('To Date', style: TextStyle(fontSize: 12, color: Colors.grey)),
                          Text(DateFormat('dd/MM/yyyy').format(_toDate)),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // GSTR-1 Sections List
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                _buildSectionCard(
                  'B2B Supplies',
                  'Sections 4A, 4B, 6B, 6C',
                  'Business to Business transactions',
                  Icons.business,
                  Colors.blue,
                      () => _showB2BReport(),
                ),
                _buildSectionCard(
                  'B2C Large Supplies',
                  'Section 5',
                  'B2C supplies > ₹2.5 lakhs',
                  Icons.store,
                  Colors.green,
                      () => _showB2CLargeReport(),
                ),
                _buildSectionCard(
                  'B2C Small Supplies',
                  'Section 7',
                  'B2C supplies ≤ ₹2.5 lakhs',
                  Icons.shopping_cart,
                  Colors.orange,
                      () => _showB2CSmallReport(),
                ),
                _buildSectionCard(
                  'Exports',
                  'Section 6A',
                  'Export transactions',
                  Icons.flight_takeoff,
                  Colors.purple,
                      () => _showExportsReport(),
                ),
                _buildSectionCard(
                  'Nil Rated Supplies',
                  'Sections 8A, 8B, 8C, 8D',
                  'Nil rated, exempted, non-GST supplies',
                  Icons.block,
                  Colors.grey,
                      () => _showNilRatedReport(),
                ),
                _buildSectionCard(
                  'HSN Summary',
                  'Section 12',
                  'HSN-wise summary of supplies',
                  Icons.summarize,
                  Colors.teal,
                      () => _showHSNSummaryReport(),
                ),
                _buildSectionCard(
                  'Documents Issued',
                  'Section 13',
                  'Summary of documents issued',
                  Icons.receipt_long,
                  Colors.indigo,
                      () => _showDocumentsSummary(),
                ),
              ],
            ),
          ),

          // Generate Complete GSTR-1 Button
          Padding(
            padding: const EdgeInsets.all(16),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _generateCompleteGSTR1,
                icon: const Icon(Icons.file_download),
                label: const Text('Generate Complete GSTR-1'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF667eea),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionCard(String title, String section, String description,
      IconData icon, Color color, VoidCallback onTap) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
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
      child: ListTile(
        leading: Container(
          width: 50,
          height: 50,
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: color, size: 24),
        ),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(section, style: TextStyle(color: color, fontSize: 12)),
            Text(description, style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
          ],
        ),
        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
        onTap: onTap,
      ),
    );
  }

  Future<void> _selectFromDate(BuildContext context) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _fromDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      setState(() => _fromDate = picked);
    }
  }

  Future<void> _selectToDate(BuildContext context) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _toDate,
      firstDate: _fromDate,
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      setState(() => _toDate = picked);
    }
  }

  void _showB2BReport() {
    Navigator.push(context, MaterialPageRoute(
      builder: (_) => GSTR1SectionScreen(
        businessId: widget.businessId,
        sectionTitle: 'B2B Supplies',
        sectionFilter: 'B2B',
        fromDate: _fromDate,
        toDate: _toDate,
      ),
    ));
  }

  void _showB2CLargeReport() {
    Navigator.push(context, MaterialPageRoute(
      builder: (_) => GSTR1SectionScreen(
        businessId: widget.businessId,
        sectionTitle: 'B2C Large Supplies',
        sectionFilter: 'B2C_LARGE',
        fromDate: _fromDate,
        toDate: _toDate,
      ),
    ));
  }

  void _showB2CSmallReport() {
    Navigator.push(context, MaterialPageRoute(
      builder: (_) => GSTR1SectionScreen(
        businessId: widget.businessId,
        sectionTitle: 'B2C Small Supplies',
        sectionFilter: 'B2C_SMALL',
        fromDate: _fromDate,
        toDate: _toDate,
      ),
    ));
  }

  void _showExportsReport() {
    Navigator.push(context, MaterialPageRoute(
      builder: (_) => GSTR1SectionScreen(
        businessId: widget.businessId,
        sectionTitle: 'Export Supplies',
        sectionFilter: 'EXPORT',
        fromDate: _fromDate,
        toDate: _toDate,
      ),
    ));
  }

  void _showNilRatedReport() {
    Navigator.push(context, MaterialPageRoute(
      builder: (_) => NilRatedSuppliesScreen(
        businessId: widget.businessId,
        fromDate: _fromDate,
        toDate: _toDate,
      ),
    ));
  }

  void _showHSNSummaryReport() {
    Navigator.push(context, MaterialPageRoute(
      builder: (_) => HSNSummaryScreen(
        businessId: widget.businessId,
        fromDate: _fromDate,
        toDate: _toDate,
      ),
    ));
  }

  void _showDocumentsSummary() {
    Navigator.push(context, MaterialPageRoute(
      builder: (_) => DocumentsSummaryScreen(
        businessId: widget.businessId,
        fromDate: _fromDate,
        toDate: _toDate,
      ),
    ));
  }

  Future<void> _generateCompleteGSTR1() async {
    try {
      // Get all sales data for the period
      final salesSnapshot = await _firestore
          .collection('sales')
          .where('businessId', isEqualTo: widget.businessId)
          .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(_fromDate))
          .where('date', isLessThanOrEqualTo: Timestamp.fromDate(_toDate))
          .get();

      final sales = salesSnapshot.docs
          .map((doc) => SaleMaster.fromFirestore(doc))
          .toList();

      if (sales.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No data found for the selected period')),
        );
        return;
      }

      // Show options to download, share, or print
      showModalBottomSheet(
        context: context,
        builder: (BuildContext bc) {
          return SafeArea(
            child: Wrap(
              children: <Widget>[
                ListTile(
                  leading: const Icon(Icons.download),
                  title: const Text('Download JSON (for GST Portal)'),
                  onTap: () async {
                    Navigator.pop(bc);
                    await PDFUtils.generateGSTR1JSON(
                        sales.map((sale) => sale.toFirestore()).toList(),
                        _fromDate,
                        _toDate
                    );
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('GSTR-1 JSON downloaded!')),
                    );
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.picture_as_pdf),
                  title: const Text('Download PDF Report'),
                  onTap: () async {
                    Navigator.pop(bc);
                    await PDFUtils.generateGSTR1PDF(
                        sales.map((sale) => sale.toFirestore()).toList(),
                        _fromDate,
                        _toDate
                    );
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('GSTR-1 PDF downloaded!')),
                    );
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.table_chart),
                  title: const Text('Download Excel'),
                  onTap: () async {
                    Navigator.pop(bc);
                    await PDFUtils.generateGSTR1Excel(
                        sales.map((sale) => sale.toFirestore()).toList(),
                        _fromDate,
                        _toDate
                    );
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('GSTR-1 Excel downloaded!')),
                    );
                  },
                ),
              ],
            ),
          );
        },
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
      );
    }
  }
}
