import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:pdf/pdf.dart';
import 'package:printing/printing.dart';

class PdfInvoiceScreen extends StatefulWidget {
  final DocumentSnapshot saleDoc;
  const PdfInvoiceScreen({super.key, required this.saleDoc});

  @override
  State<PdfInvoiceScreen> createState() => _PdfInvoiceScreenState();
}

class _PdfInvoiceScreenState extends State<PdfInvoiceScreen> {
  final pdf = pw.Document();
  List<Map<String, dynamic>> _items = [];

  @override
  void initState() {
    super.initState();
    _loadItems();
  }

  Future<void> _loadItems() async {
    final itemsSnapshot = await widget.saleDoc.reference.collection('items').get();
    setState(() {
      _items = itemsSnapshot.docs
          .map((doc) => {
        'name': doc['name'],
        'price': (doc['price'] as num).toDouble(),
        'quantity': (doc['quantity'] as num).toInt(),
      })
          .toList();
    });
    _generatePdf();
  }

  void _generatePdf() {
    pdf.addPage(
      pw.Page(
        build: (context) => pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text('Invoice', style: pw.TextStyle(fontSize: 24)),
            pw.SizedBox(height: 20),
            pw.Text('Customer: ${widget.saleDoc['customerName']}'),
            pw.Text('Date: ${widget.saleDoc['date'].toDate()}'),
            pw.SizedBox(height: 20),
            pw.Table.fromTextArray(
              headers: ['Item', 'Price', 'Quantity', 'Total'],
              data: _items
                  .map((item) => [
                item['name'],
                '₹${item['price'].toStringAsFixed(2)}',
                item['quantity'].toString(),
                '₹${(item['price'] * item['quantity']).toStringAsFixed(2)}',
              ])
                  .toList(),
            ),
            pw.SizedBox(height: 20),
            pw.Text(
                'Total: ₹${widget.saleDoc['total'].toDouble().toStringAsFixed(2)}',
                style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold)),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_items.isEmpty) {
      return const Scaffold(
          body: Center(child: CircularProgressIndicator()));
    }
    return Scaffold(
      appBar: AppBar(title: const Text('Invoice PDF')),
      body: PdfPreview(
        build: (format) => pdf.save(),
      ),
    );
  }
}
