import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

// GST Reports Screen
class GSTReportsScreen extends StatefulWidget {
  final String businessId;

  const GSTReportsScreen({super.key, required this.businessId});

  @override
  State<GSTReportsScreen> createState() => _GSTReportsScreenState();
}

class _GSTReportsScreenState extends State<GSTReportsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  DateTime _fromDate = DateTime.now().subtract(const Duration(days: 30));
  DateTime _toDate = DateTime.now();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('GST Reports'),
        backgroundColor: Colors.white,
        elevation: 0,
        bottom: TabBar(
          controller: _tabController,
          labelColor: const Color(0xFF667eea),
          unselectedLabelColor: Colors.grey,
          indicatorColor: const Color(0xFF667eea),
          tabs: const [
            Tab(text: 'B2B'),
            Tab(text: 'B2C'),
            Tab(text: 'HSN Summary'),
            Tab(text: 'Tax Summary'),
          ],
        ),
      ),
      body: Column(
        children: [
          // Date Range Selector
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.grey.shade50,
            child: Row(
              children: [
                Expanded(
                  child: InkWell(
                    onTap: () => _selectDate(true),
                    child: InputDecorator(
                      decoration: const InputDecoration(
                        labelText: 'From Date',
                        border: OutlineInputBorder(),
                      ),
                      child: Text(DateFormat('dd/MM/yyyy').format(_fromDate)),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: InkWell(
                    onTap: () => _selectDate(false),
                    child: InputDecorator(
                      decoration: const InputDecoration(
                        labelText: 'To Date',
                        border: OutlineInputBorder(),
                      ),
                      child: Text(DateFormat('dd/MM/yyyy').format(_toDate)),
                    ),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                B2BReportTab(
                  businessId: widget.businessId,
                  fromDate: _fromDate,
                  toDate: _toDate,
                ),
                B2CReportTab(
                  businessId: widget.businessId,
                  fromDate: _fromDate,
                  toDate: _toDate,
                ),
                HSNSummaryTab(
                  businessId: widget.businessId,
                  fromDate: _fromDate,
                  toDate: _toDate,
                ),
                TaxSummaryTab(
                  businessId: widget.businessId,
                  fromDate: _fromDate,
                  toDate: _toDate,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _selectDate(bool isFromDate) async {
    final date = await showDatePicker(
      context: context,
      initialDate: isFromDate ? _fromDate : _toDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );

    if (date != null) {
      setState(() {
        if (isFromDate) {
          _fromDate = date;
        } else {
          _toDate = date;
        }
      });
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }
}

// B2B Report Tab
class B2BReportTab extends StatelessWidget {
  final String businessId;
  final DateTime fromDate;
  final DateTime toDate;

  const B2BReportTab({
    super.key,
    required this.businessId,
    required this.fromDate,
    required this.toDate,
  });

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('invoices')
          .where('businessId', isEqualTo: businessId)
          .where('isB2B', isEqualTo: true)
          .where('invoiceDate', isGreaterThanOrEqualTo: Timestamp.fromDate(fromDate))
          .where('invoiceDate', isLessThanOrEqualTo: Timestamp.fromDate(toDate))
          .orderBy('invoiceDate', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return const Center(child: Text('Error loading B2B data'));
        }
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final invoices = snapshot.data!.docs;

        if (invoices.isEmpty) {
          return const Center(
            child: Text('No B2B transactions found for selected period'),
          );
        }

        double totalTaxableValue = 0;
        double totalTax = 0;

        return Column(
          children: [
            // Summary Cards
            Container(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Expanded(
                    child: Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          children: [
                            const Text('Total Invoices', style: TextStyle(fontSize: 12)),
                            Text(
                              '${invoices.length}',
                              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  Expanded(
                    child: Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          children: [
                            const Text('Taxable Value', style: TextStyle(fontSize: 12)),
                            Text(
                              '₹${invoices.fold<double>(0, (sum, doc) => sum + (doc.data() as Map)['totalTaxableValue']).toStringAsFixed(2)}',
                              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.blue),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  Expanded(
                    child: Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          children: [
                            const Text('Total Tax', style: TextStyle(fontSize: 12)),
                            Text(
                              '₹${invoices.fold<double>(0, (sum, doc) {
                                final data = doc.data() as Map;
                                return sum + (data['totalCGST'] ?? 0) + (data['totalSGST'] ?? 0) + (data['totalIGST'] ?? 0);
                              }).toStringAsFixed(2)}',
                              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.green),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            // Invoice List
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: invoices.length,
                itemBuilder: (context, index) {
                  final invoice = invoices[index].data() as Map<String, dynamic>;
                  final invoiceDate = (invoice['invoiceDate'] as Timestamp).toDate();

                  return Card(
                    margin: const EdgeInsets.only(bottom: 8),
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Invoice: ${invoice['invoiceNumber']}',
                                      style: const TextStyle(fontWeight: FontWeight.w600),
                                    ),
                                    Text(
                                      'Date: ${DateFormat('dd/MM/yyyy').format(invoiceDate)}',
                                      style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                                    ),
                                    Text(
                                      'Party: ${invoice['partyName']}',
                                      style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                                    ),
                                    Text(
                                      'GSTIN: ${invoice['partyGSTIN']}',
                                      style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                                    ),
                                  ],
                                ),
                              ),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Text(
                                    '₹${(invoice['totalAmount'] ?? 0).toStringAsFixed(2)}',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                      color: Colors.green,
                                    ),
                                  ),
                                  Text(
                                    'Tax: ₹${((invoice['totalCGST'] ?? 0) + (invoice['totalSGST'] ?? 0) + (invoice['totalIGST'] ?? 0)).toStringAsFixed(2)}',
                                    style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                                  ),
                                ],
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Taxable: ₹${(invoice['totalTaxableValue'] ?? 0).toStringAsFixed(2)}',
                                style: const TextStyle(fontSize: 12),
                              ),
                              if ((invoice['totalCGST'] ?? 0) > 0)
                                Text(
                                  'CGST: ₹${(invoice['totalCGST'] ?? 0).toStringAsFixed(2)}',
                                  style: const TextStyle(fontSize: 12),
                                ),
                              if ((invoice['totalSGST'] ?? 0) > 0)
                                Text(
                                  'SGST: ₹${(invoice['totalSGST'] ?? 0).toStringAsFixed(2)}',
                                  style: const TextStyle(fontSize: 12),
                                ),
                              if ((invoice['totalIGST'] ?? 0) > 0)
                                Text(
                                  'IGST: ₹${(invoice['totalIGST'] ?? 0).toStringAsFixed(2)}',
                                  style: const TextStyle(fontSize: 12),
                                ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }
}

// B2C Report Tab
class B2CReportTab extends StatelessWidget {
  final String businessId;
  final DateTime fromDate;
  final DateTime toDate;

  const B2CReportTab({
    super.key,
    required this.businessId,
    required this.fromDate,
    required this.toDate,
  });

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('invoices')
          .where('businessId', isEqualTo: businessId)
          .where('isB2B', isEqualTo: false)
          .where('invoiceDate', isGreaterThanOrEqualTo: Timestamp.fromDate(fromDate))
          .where('invoiceDate', isLessThanOrEqualTo: Timestamp.fromDate(toDate))
          .orderBy('invoiceDate', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return const Center(child: Text('Error loading B2C data'));
        }
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final invoices = snapshot.data!.docs;

        if (invoices.isEmpty) {
          return const Center(
            child: Text('No B2C transactions found for selected period'),
          );
        }

        return Column(
          children: [
            // Summary Cards
            Container(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Expanded(
                    child: Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          children: [
                            const Text('Total Invoices', style: TextStyle(fontSize: 12)),
                            Text(
                              '${invoices.length}',
                              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  Expanded(
                    child: Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          children: [
                            const Text('Taxable Value', style: TextStyle(fontSize: 12)),
                            Text(
                              '₹${invoices.fold<double>(0, (sum, doc) => sum + (doc.data() as Map)['totalTaxableValue']).toStringAsFixed(2)}',
                              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.blue),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  Expanded(
                    child: Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          children: [
                            const Text('Total Tax', style: TextStyle(fontSize: 12)),
                            Text(
                              '₹${invoices.fold<double>(0, (sum, doc) {
                                final data = doc.data() as Map;
                                return sum + (data['totalCGST'] ?? 0) + (data['totalSGST'] ?? 0) + (data['totalIGST'] ?? 0);
                              }).toStringAsFixed(2)}',
                              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.green),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            // Invoice List
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: invoices.length,
                itemBuilder: (context, index) {
                  final invoice = invoices[index].data() as Map<String, dynamic>;
                  final invoiceDate = (invoice['invoiceDate'] as Timestamp).toDate();

                  return Card(
                    margin: const EdgeInsets.only(bottom: 8),
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Invoice: ${invoice['invoiceNumber']}',
                                      style: const TextStyle(fontWeight: FontWeight.w600),
                                    ),
                                    Text(
                                      'Date: ${DateFormat('dd/MM/yyyy').format(invoiceDate)}',
                                      style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                                    ),
                                    Text(
                                      'Customer: ${invoice['partyName'] ?? 'Walk-in Customer'}',
                                      style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                                    ),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: Colors.green.withOpacity(0.1),
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                      child: const Text(
                                        'B2C',
                                        style: TextStyle(
                                          fontSize: 10,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.green,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Text(
                                    '₹${(invoice['totalAmount'] ?? 0).toStringAsFixed(2)}',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                      color: Colors.green,
                                    ),
                                  ),
                                  Text(
                                    'Tax: ₹${((invoice['totalCGST'] ?? 0) + (invoice['totalSGST'] ?? 0) + (invoice['totalIGST'] ?? 0)).toStringAsFixed(2)}',
                                    style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                                  ),
                                ],
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Taxable: ₹${(invoice['totalTaxableValue'] ?? 0).toStringAsFixed(2)}',
                                style: const TextStyle(fontSize: 12),
                              ),
                              Text(
                                'Payment: ${invoice['paymentType'] ?? 'Cash'}',
                                style: const TextStyle(fontSize: 12),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }
}

// HSN Summary Tab
class HSNSummaryTab extends StatelessWidget {
  final String businessId;
  final DateTime fromDate;
  final DateTime toDate;

  const HSNSummaryTab({
    super.key,
    required this.businessId,
    required this.fromDate,
    required this.toDate,
  });

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Map<String, Map<String, dynamic>>>(
      future: _getHSNSummary(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return const Center(child: Text('Error loading HSN summary'));
        }
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final hsnSummary = snapshot.data!;

        if (hsnSummary.isEmpty) {
          return const Center(
            child: Text('No HSN data found for selected period'),
          );
        }

        final hsnList = hsnSummary.entries.toList();
        final totalTaxableValue = hsnList.fold<double>(0, (sum, entry) => sum + entry.value['taxableValue']);
        final totalTax = hsnList.fold<double>(0, (sum, entry) => sum + entry.value['totalTax']);

        return Column(
          children: [
            // Summary Cards
            Container(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Expanded(
                    child: Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          children: [
                            const Text('Total HSN Codes', style: TextStyle(fontSize: 12)),
                            Text(
                              '${hsnList.length}',
                              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  Expanded(
                    child: Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          children: [
                            const Text('Total Taxable Value', style: TextStyle(fontSize: 12)),
                            Text(
                              '₹${totalTaxableValue.toStringAsFixed(2)}',
                              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.blue),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  Expanded(
                    child: Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          children: [
                            const Text('Total Tax', style: TextStyle(fontSize: 12)),
                            Text(
                              '₹${totalTax.toStringAsFixed(2)}',
                              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.green),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            // HSN List
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: hsnList.length,
                itemBuilder: (context, index) {
                  final hsnCode = hsnList[index].key;
                  final hsnData = hsnList[index].value;

                  return Card(
                    margin: const EdgeInsets.only(bottom: 8),
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'HSN Code: $hsnCode',
                                      style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
                                    ),
                                    Text(
                                      'Description: ${hsnData['description'] ?? 'N/A'}',
                                      style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                                    ),
                                  ],
                                ),
                              ),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Text(
                                    '${hsnData['gstRate']}%',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                      color: Colors.orange,
                                    ),
                                  ),
                                  Text(
                                    'GST Rate',
                                    style: TextStyle(color: Colors.grey.shade600, fontSize: 10),
                                  ),
                                ],
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Quantity',
                                    style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                                  ),
                                  Text(
                                    '${hsnData['totalQuantity'].toStringAsFixed(2)} ${hsnData['unit']}',
                                    style: const TextStyle(fontWeight: FontWeight.w600),
                                  ),
                                ],
                              ),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  Text(
                                    'Taxable Value',
                                    style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                                  ),
                                  Text(
                                    '₹${hsnData['taxableValue'].toStringAsFixed(2)}',
                                    style: const TextStyle(fontWeight: FontWeight.w600, color: Colors.blue),
                                  ),
                                ],
                              ),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Text(
                                    'Total Tax',
                                    style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                                  ),
                                  Text(
                                    '₹${hsnData['totalTax'].toStringAsFixed(2)}',
                                    style: const TextStyle(fontWeight: FontWeight.w600, color: Colors.green),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }

  Future<Map<String, Map<String, dynamic>>> _getHSNSummary() async {
    final Map<String, Map<String, dynamic>> hsnSummary = {};

    try {
      // Get all invoices in date range
      final invoicesSnapshot = await FirebaseFirestore.instance
          .collection('invoices')
          .where('businessId', isEqualTo: businessId)
          .where('invoiceDate', isGreaterThanOrEqualTo: Timestamp.fromDate(fromDate))
          .where('invoiceDate', isLessThanOrEqualTo: Timestamp.fromDate(toDate))
          .get();

      // Process each invoice
      for (final invoiceDoc in invoicesSnapshot.docs) {
        // Get invoice items
        final itemsSnapshot = await invoiceDoc.reference.collection('items').get();

        for (final itemDoc in itemsSnapshot.docs) {
          final itemData = itemDoc.data();
          final hsnCode = itemData['hsnCode'] ?? 'N/A';

          if (!hsnSummary.containsKey(hsnCode)) {
            hsnSummary[hsnCode] = {
              'description': itemData['itemName'] ?? 'N/A',
              'totalQuantity': 0.0,
              'unit': itemData['unit'] ?? '',
              'taxableValue': 0.0,
              'totalTax': 0.0,
              'gstRate': (itemData['cgstRate'] ?? 0) + (itemData['sgstRate'] ?? 0) + (itemData['igstRate'] ?? 0),
            };
          }

          hsnSummary[hsnCode]!['totalQuantity'] += itemData['quantity'] ?? 0.0;
          hsnSummary[hsnCode]!['taxableValue'] += itemData['taxableValue'] ?? 0.0;
          hsnSummary[hsnCode]!['totalTax'] += (itemData['cgstAmount'] ?? 0.0) +
              (itemData['sgstAmount'] ?? 0.0) +
              (itemData['igstAmount'] ?? 0.0);
        }
      }
    } catch (e) {
      print('Error getting HSN summary: $e');
    }

    return hsnSummary;
  }
}

// Tax Summary Tab
class TaxSummaryTab extends StatelessWidget {
  final String businessId;
  final DateTime fromDate;
  final DateTime toDate;

  const TaxSummaryTab({
    super.key,
    required this.businessId,
    required this.fromDate,
    required this.toDate,
  });

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('invoices')
          .where('businessId', isEqualTo: businessId)
          .where('invoiceDate', isGreaterThanOrEqualTo: Timestamp.fromDate(fromDate))
          .where('invoiceDate', isLessThanOrEqualTo: Timestamp.fromDate(toDate))
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return const Center(child: Text('Error loading tax summary'));
        }
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final invoices = snapshot.data!.docs;

        if (invoices.isEmpty) {
          return const Center(
            child: Text('No transactions found for selected period'),
          );
        }

        // Calculate totals
        double totalTaxableValue = 0;
        double totalCGST = 0;
        double totalSGST = 0;
        double totalIGST = 0;
        double totalTax = 0;
        double totalAmount = 0;
        int b2bCount = 0;
        int b2cCount = 0;

        for (final doc in invoices) {
          final data = doc.data() as Map<String, dynamic>;
          totalTaxableValue += data['totalTaxableValue'] ?? 0;
          totalCGST += data['totalCGST'] ?? 0;
          totalSGST += data['totalSGST'] ?? 0;
          totalIGST += data['totalIGST'] ?? 0;
          totalAmount += data['totalAmount'] ?? 0;

          if (data['isB2B'] == true) {
            b2bCount++;
          } else {
            b2cCount++;
          }
        }

        totalTax = totalCGST + totalSGST + totalIGST;

        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              // Overview Cards
              Row(
                children: [
                  Expanded(
                    child: Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          children: [
                            const Text('Total Invoices', style: TextStyle(fontSize: 12)),
                            Text(
                              '${invoices.length}',
                              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  Expanded(
                    child: Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          children: [
                            const Text('B2B Invoices', style: TextStyle(fontSize: 12)),
                            Text(
                              '$b2bCount',
                              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.blue),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  Expanded(
                    child: Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          children: [
                            const Text('B2C Invoices', style: TextStyle(fontSize: 12)),
                            Text(
                              '$b2cCount',
                              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.green),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Tax Breakdown
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Tax Breakdown',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 16),
                      _buildTaxRow('Total Taxable Value', totalTaxableValue, Colors.blue),
                      _buildTaxRow('CGST Collected', totalCGST, Colors.orange),
                      _buildTaxRow('SGST Collected', totalSGST, Colors.purple),
                      _buildTaxRow('IGST Collected', totalIGST, Colors.red),
                      const Divider(),
                      _buildTaxRow('Total Tax Collected', totalTax, Colors.green, isTotal: true),
                      _buildTaxRow('Total Invoice Value', totalAmount, Colors.black, isTotal: true),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Tax Rate Analysis
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Tax Analysis',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Effective Tax Rate'),
                          Text(
                            '${totalTaxableValue > 0 ? ((totalTax / totalTaxableValue) * 100).toStringAsFixed(2) : '0.00'}%',
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Average Invoice Value'),
                          Text(
                            '₹${invoices.isNotEmpty ? (totalAmount / invoices.length).toStringAsFixed(2) : '0.00'}',
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Interstate vs Intrastate'),
                          Text(
                            'IGST: ${totalIGST > 0 ? ((totalIGST / totalTax) * 100).toStringAsFixed(1) : '0'}% | CGST+SGST: ${(totalCGST + totalSGST) > 0 ? (((totalCGST + totalSGST) / totalTax) * 100).toStringAsFixed(1) : '0'}%',
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildTaxRow(String label, double amount, Color color, {bool isTotal = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: isTotal ? 16 : 14,
              fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
            ),
          ),
          Text(
            '₹${amount.toStringAsFixed(2)}',
            style: TextStyle(
              fontSize: isTotal ? 16 : 14,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}
