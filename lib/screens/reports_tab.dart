import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:safetyzoness/screens/report/sales_by_hsn_report_screen.dart';
import 'package:safetyzoness/screens/sales_register_screen.dart';
import '../model/SaleMaster.dart';
import '../model/item_master.dart';
import '../services/user_service.dart';
import 'gstr1_reports_screen.dart';

// UPDATE: Replace the existing ReportsTab class with this enhanced version

class ReportsTab extends StatefulWidget {
  final String businessId;
  const ReportsTab({super.key, required this.businessId});

  @override
  State<ReportsTab> createState() => _ReportsTabState();
}

class _ReportsTabState extends State<ReportsTab> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Column(
        children: [
          const TabBar(
            labelColor: Color(0xFF667eea),
            unselectedLabelColor: Colors.grey,
            indicatorColor: Color(0xFF667eea),
            tabs: [
              Tab(text: 'GST Reports', icon: Icon(Icons.account_balance)),
              Tab(text: 'Inventory Reports', icon: Icon(Icons.analytics)),
            ],
          ),
          Expanded(
            child: TabBarView(
              children: [
                _buildGSTReportsTab(),
                _buildInventoryReportsTab(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGSTReportsTab() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'GST Compliance Reports',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 20),

          // Quick Stats Row
          Row(
            children: [
              Expanded(child: _buildGSTSummaryCard()),
              const SizedBox(width: 12),
              Expanded(child: _buildTaxCollectedCard()),
            ],
          ),
          const SizedBox(height: 20),

          // GST Reports List
          Expanded(
            child: ListView(
              children: [
                _buildReportCard(
                  'GSTR-1 Filing',
                  'Complete GSTR-1 return preparation',
                  Icons.file_copy,
                  const Color(0xFF4CAF50),
                      () => Navigator.push(context, MaterialPageRoute(
                    builder: (_) => GSTR1ReportsScreen(businessId: widget.businessId),
                  )),
                ),
                _buildReportCard(
                  'Sales Register',
                  'Detailed sales transactions report',
                  Icons.point_of_sale,
                  const Color(0xFF2196F3),
                      () => _showSalesRegisterReport(context),
                ),
                _buildReportCard(
                  'Tax Summary',
                  'Period-wise tax collection summary',
                  Icons.pie_chart,
                  const Color(0xFF9C27B0),
                      () => _showTaxSummaryReport(context),
                ),
                _buildReportCard(
                  'Customer GSTIN Report',
                  'B2B customer GSTIN-wise sales',
                  Icons.business,
                  const Color(0xFFFF9800),
                      () => _showCustomerGSTINReport(context),
                ),
                _buildReportCard(
                  'State-wise Sales',
                  'Place of Supply wise sales analysis',
                  Icons.map,
                  const Color(0xFF607D8B),
                      () => _showStateWiseSalesReport(context),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInventoryReportsTab() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Inventory Reports',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 20),

          // Summary Cards Row
          Row(
            children: [
              Expanded(child: _buildSummaryCard()),
              const SizedBox(width: 12),
              Expanded(child: _buildLowStockCard()),
            ],
          ),
          const SizedBox(height: 20),

          // Inventory Reports List
          Expanded(
            child: ListView(
              children: [
                _buildReportCard(
                  'Stock Summary',
                  'Overview of current stock levels',
                  Icons.analytics,
                  const Color(0xFF4CAF50),
                      () => _showStockSummaryReport(context),
                ),
                _buildReportCard(
                  'Low Stock Alert',
                  'Items running low on stock',
                  Icons.warning,
                  const Color(0xFFFF9800),
                      () => _showLowStockReport(context),
                ),
                _buildReportCard(
                  'Sales Performance (HSN)',
                  'Track sales trends and performance by HSN/SAC code',
                  Icons.trending_up,
                  const Color(0xFF2196F3),
                      () => _showSalesByHsnReport(context),
                ),
                _buildReportCard(
                  'Valuation Report',
                  'Total inventory valuation',
                  Icons.account_balance,
                  const Color(0xFF9C27B0),
                      () => _showValuationReport(context),
                ),
                _buildReportCard(
                  'Profit Analysis',
                  'Analyze profit margins by item',
                  Icons.show_chart,
                  const Color(0xFFE91E63),
                      () => _showProfitAnalysisReport(context),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGSTSummaryCard() {
    return StreamBuilder<QuerySnapshot>(
      stream: _firestore
          .collection('sales')
          .where('businessId', isEqualTo: widget.businessId)
          .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(DateTime.now().subtract(const Duration(days: 30))))
          .snapshots(),
      builder: (context, snapshot) {
        int totalInvoices = 0;
        double totalTax = 0;

        if (snapshot.hasData) {
          for (var doc in snapshot.data!.docs) {
            final sale = SaleMaster.fromFirestore(doc);
            totalInvoices++;
            for (var item in sale.items) {
              totalTax += item.centralTaxAmount + item.stateTaxAmount + item.integratedTaxAmount;
            }
          }
        }

        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.green.shade600, Colors.green.shade400],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.green.withOpacity(0.3),
                blurRadius: 10,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.account_balance, color: Colors.white, size: 24),
                  const SizedBox(width: 8),
                  const Text(
                    'Tax Collected (30d)',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                '₹${totalTax.toStringAsFixed(2)}',
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              Text(
                '$totalInvoices invoices',
                style: const TextStyle(
                  fontSize: 12,
                  color: Colors.white70,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildTaxCollectedCard() {
    return StreamBuilder<QuerySnapshot>(
      stream: _firestore
          .collection('sales')
          .where('businessId', isEqualTo: widget.businessId)
          .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(DateTime.now().subtract(const Duration(days: 30))))
          .snapshots(),
      builder: (context, snapshot) {
        int b2bCount = 0;
        int b2cCount = 0;

        if (snapshot.hasData) {
          for (var doc in snapshot.data!.docs) {
            final sale = SaleMaster.fromFirestore(doc);
            if (sale.gstr1Section == 'B2B') {
              b2bCount++;
            } else {
              b2cCount++;
            }
          }
        }

        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.blue.shade600, Colors.blue.shade400],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.blue.withOpacity(0.3),
                blurRadius: 10,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.business, color: Colors.white, size: 24),
                  const SizedBox(width: 8),
                  const Text(
                    'Sales Mix (30d)',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                'B2B: $b2bCount',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              Text(
                'B2C: $b2cCount',
                style: const TextStyle(
                  fontSize: 12,
                  color: Colors.white70,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // Keep existing methods for inventory reports...
  Widget _buildSummaryCard() {
    return StreamBuilder<QuerySnapshot>(
      stream: _firestore
          .collection('items')
          .where('businessId', isEqualTo: widget.businessId)
          .where('isActive', isEqualTo: true)
          .snapshots(),
      builder: (context, snapshot) {
        int totalItems = snapshot.hasData ? snapshot.data!.docs.length : 0;
        return Container(
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
              Row(
                children: [
                  Icon(Icons.inventory, color: Colors.blue.shade600, size: 24),
                  const SizedBox(width: 8),
                  const Text(
                    'Total Items',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: Colors.black87,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                totalItems.toString(),
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildLowStockCard() {
    return StreamBuilder<QuerySnapshot>(
      stream: _firestore
          .collection('stock_inventory')
          .where('businessId', isEqualTo: widget.businessId)
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return _buildSummaryCardSkeleton();
        }
        int lowStockCount = 0;
        for (var doc in snapshot.data!.docs) {
          try {
            final data = doc.data() as Map<String, dynamic>;
            final currentStock = ItemMaster.getDoubleValue(data, 'currentStock');
            final minStock = ItemMaster.getDoubleValue(data, 'minimumStockLevel');
            if (currentStock <= minStock) {
              lowStockCount++;
            }
          } catch (e) {
            // Handle parsing errors
          }
        }
        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: lowStockCount > 0 ? Border.all(color: Colors.orange, width: 2) : null,
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
              Row(
                children: [
                  Icon(
                    Icons.warning,
                    color: lowStockCount > 0 ? Colors.orange : Colors.green,
                    size: 24,
                  ),
                  const SizedBox(width: 8),
                  const Text(
                    'Low Stock',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: Colors.black87,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                lowStockCount.toString(),
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: lowStockCount > 0 ? Colors.orange : Colors.green,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSummaryCardSkeleton() {
    return Container(
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
          Row(
            children: [
              Icon(Icons.warning, color: Colors.grey.shade400, size: 24),
              const SizedBox(width: 8),
              const Text(
                'Loading...',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: Colors.grey,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          const Text(
            '0',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.grey,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReportCard(String title, String subtitle, IconData icon, Color color, VoidCallback onTap) {
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
        title: Text(
          title,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
        ),
        subtitle: Text(
          subtitle,
          style: TextStyle(
            fontSize: 14,
            color: Colors.grey.shade600,
          ),
        ),
        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
        onTap: onTap,
      ),
    );
  }

  // GST Report Methods
  void _showSalesRegisterReport(BuildContext context) {
    // Navigate to detailed sales register with GST columns
    Navigator.push(context, MaterialPageRoute(
      builder: (_) => SalesRegisterScreen(businessId: widget.businessId),
    ));
  }

  void _showTaxSummaryReport(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Tax Summary Report'),
        content: SizedBox(
          width: double.maxFinite,
          height: 400,
          child: StreamBuilder<QuerySnapshot>(
            stream: _firestore
                .collection('sales')
                .where('businessId', isEqualTo: widget.businessId)
                .snapshots(),
            builder: (context, snapshot) {
              if (!snapshot.hasData) {
                return const Center(child: CircularProgressIndicator());
              }

              Map<String, Map<String, double>> monthlyTax = {};

              for (var doc in snapshot.data!.docs) {
                final sale = SaleMaster.fromFirestore(doc);
                final monthKey = DateFormat('MMM yyyy').format(sale.date);

                if (!monthlyTax.containsKey(monthKey)) {
                  monthlyTax[monthKey] = {'cgst': 0, 'sgst': 0, 'igst': 0, 'total': 0};
                }

                for (var item in sale.items) {
                  monthlyTax[monthKey]!['cgst'] = monthlyTax[monthKey]!['cgst']! + item.centralTaxAmount;
                  monthlyTax[monthKey]!['sgst'] = monthlyTax[monthKey]!['sgst']! + item.stateTaxAmount;
                  monthlyTax[monthKey]!['igst'] = monthlyTax[monthKey]!['igst']! + item.integratedTaxAmount;
                  monthlyTax[monthKey]!['total'] = monthlyTax[monthKey]!['total']! +
                      (item.centralTaxAmount + item.stateTaxAmount + item.integratedTaxAmount);
                }
              }

              return ListView.builder(
                itemCount: monthlyTax.keys.length,
                itemBuilder: (context, index) {
                  final month = monthlyTax.keys.elementAt(index);
                  final taxes = monthlyTax[month]!;

                  return Card(
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(month, style: const TextStyle(fontWeight: FontWeight.bold)),
                          const SizedBox(height: 8),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text('CGST: ₹${taxes['cgst']!.toStringAsFixed(2)}'),
                              Text('SGST: ₹${taxes['sgst']!.toStringAsFixed(2)}'),
                              Text('IGST: ₹${taxes['igst']!.toStringAsFixed(2)}'),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text('Total: ₹${taxes['total']!.toStringAsFixed(2)}',
                              style: const TextStyle(fontWeight: FontWeight.bold)),
                        ],
                      ),
                    ),
                  );
                },
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _showCustomerGSTINReport(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Customer GSTIN Report'),
        content: SizedBox(
          width: double.maxFinite,
          height: 400,
          child: StreamBuilder<QuerySnapshot>(
            stream: _firestore
                .collection('sales')
                .where('businessId', isEqualTo: widget.businessId)
                .where('gstr1Section', isEqualTo: 'B2B')
                .snapshots(),
            builder: (context, snapshot) {
              if (!snapshot.hasData) {
                return const Center(child: CircularProgressIndicator());
              }

              Map<String, Map<String, dynamic>> gstinWiseSales = {};

              for (var doc in snapshot.data!.docs) {
                final sale = SaleMaster.fromFirestore(doc);
                final gstin = sale.recipientGSTIN;

                if (gstin.isNotEmpty) {
                  if (!gstinWiseSales.containsKey(gstin)) {
                    gstinWiseSales[gstin] = {
                      'customerName': sale.customerName,
                      'totalValue': 0.0,
                      'invoiceCount': 0,
                    };
                  }

                  gstinWiseSales[gstin]!['totalValue'] += sale.total;
                  gstinWiseSales[gstin]!['invoiceCount']++;
                }
              }

              if (gstinWiseSales.isEmpty) {
                return const Center(child: Text('No B2B sales found'));
              }

              return ListView.builder(
                itemCount: gstinWiseSales.keys.length,
                itemBuilder: (context, index) {
                  final gstin = gstinWiseSales.keys.elementAt(index);
                  final data = gstinWiseSales[gstin]!;

                  return Card(
                    child: ListTile(
                      title: Text(data['customerName']),
                      subtitle: Text('GSTIN: $gstin'),
                      trailing: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text('₹${data['totalValue'].toStringAsFixed(2)}',
                              style: const TextStyle(fontWeight: FontWeight.bold)),
                          Text('${data['invoiceCount']} invoices',
                              style: const TextStyle(fontSize: 12)),
                        ],
                      ),
                    ),
                  );
                },
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _showStateWiseSalesReport(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('State-wise Sales Report'),
        content: SizedBox(
          width: double.maxFinite,
          height: 400,
          child: StreamBuilder<QuerySnapshot>(
            stream: _firestore
                .collection('sales')
                .where('businessId', isEqualTo: widget.businessId)
                .snapshots(),
            builder: (context, snapshot) {
              if (!snapshot.hasData) {
                return const Center(child: CircularProgressIndicator());
              }

              Map<String, Map<String, dynamic>> stateWiseSales = {};

              for (var doc in snapshot.data!.docs) {
                final sale = SaleMaster.fromFirestore(doc);
                final pos = sale.placeOfSupply;

                if (pos.isNotEmpty) {
                  if (!stateWiseSales.containsKey(pos)) {
                    stateWiseSales[pos] = {
                      'totalValue': 0.0,
                      'invoiceCount': 0,
                      'intraSales': 0.0,
                      'interSales': 0.0,
                    };
                  }

                  stateWiseSales[pos]!['totalValue'] += sale.total;
                  stateWiseSales[pos]!['invoiceCount']++;

                  if (sale.supplyType == 'INTRA') {
                    stateWiseSales[pos]!['intraSales'] += sale.total;
                  } else {
                    stateWiseSales[pos]!['interSales'] += sale.total;
                  }
                }
              }

              if (stateWiseSales.isEmpty) {
                return const Center(child: Text('No sales data found'));
              }

              return ListView.builder(
                itemCount: stateWiseSales.keys.length,
                itemBuilder: (context, index) {
                  final state = stateWiseSales.keys.elementAt(index);
                  final data = stateWiseSales[state]!;

                  return Card(
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('State Code: $state', style: const TextStyle(fontWeight: FontWeight.bold)),
                          const SizedBox(height: 8),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text('Total: ₹${data['totalValue'].toStringAsFixed(2)}'),
                              Text('${data['invoiceCount']} invoices'),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text('Intra: ₹${data['intraSales'].toStringAsFixed(2)}'),
                              Text('Inter: ₹${data['interSales'].toStringAsFixed(2)}'),
                            ],
                          ),
                        ],
                      ),
                    ),
                  );
                },
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  // Keep existing inventory report methods...
  void _showStockSummaryReport(BuildContext context) {
    // [Keep existing implementation]
  }

  void _showLowStockReport(BuildContext context) {
    // [Keep existing implementation]
  }

  void _showSalesByHsnReport(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => SalesByHsnReportScreen(businessId: widget.businessId),
      ),
    );
  }

  void _showValuationReport(BuildContext context) {
    // [Keep existing implementation]
  }

  void _showProfitAnalysisReport(BuildContext context) {
    // [Keep existing implementation]
  }
}