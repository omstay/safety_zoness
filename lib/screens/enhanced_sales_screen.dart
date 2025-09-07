import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'package:share_plus/share_plus.dart';
import '../services/auth_service.dart';
import '../utils/gst_utils.dart';

// Enhanced Sales Screen with 5 main sections
class EnhancedSalesScreen extends StatefulWidget {
  const EnhancedSalesScreen({super.key});

  @override
  State<EnhancedSalesScreen> createState() => _EnhancedSalesScreenState();
}

class _EnhancedSalesScreenState extends State<EnhancedSalesScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  String? _currentUserId;
  String? _businessId;
  late AnimationController _fabAnimationController;
  late Animation<double> _fabScaleAnimation;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);
    _getCurrentUser();

    _fabAnimationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _fabScaleAnimation = Tween<double>(begin: 0, end: 1).animate(CurvedAnimation(
      parent: _fabAnimationController,
      curve: Curves.easeInOut,
    ));

    _fabAnimationController.forward();
  }

  void _getCurrentUser() {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      setState(() {
        _currentUserId = user.uid;
        _businessId = user.uid; // Using user ID as business ID for simplicity
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_currentUserId == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        title: const Text(
          'Sales Management',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        bottom: TabBar(
          controller: _tabController,
          labelColor: const Color(0xFF667eea),
          unselectedLabelColor: Colors.grey,
          indicatorColor: const Color(0xFF667eea),
          indicatorWeight: 3,
          isScrollable: true,
          tabs: const [
            Tab(text: 'Invoices', icon: Icon(Icons.receipt_long, size: 20)),
            Tab(text: 'Payment-In', icon: Icon(Icons.payment, size: 20)),
            Tab(text: 'Returns', icon: Icon(Icons.assignment_return, size: 20)),
            Tab(text: 'Estimates', icon: Icon(Icons.description, size: 20)),
            Tab(text: 'Challans', icon: Icon(Icons.local_shipping, size: 20)),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          SaleInvoicesTab(businessId: _businessId!),
          PaymentInTab(businessId: _businessId!),
          SaleReturnTab(businessId: _businessId!),
          EstimateQuotationTab(businessId: _businessId!),
          DeliveryChallanTab(businessId: _businessId!),
        ],
      ),
      floatingActionButton: AnimatedBuilder(
        animation: _fabScaleAnimation,
        builder: (context, child) {
          return Transform.scale(
            scale: _fabScaleAnimation.value,
            child: Container(
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF10B981), Color(0xFF059669)],
                ),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF10B981).withOpacity(0.4),
                    blurRadius: 15,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: FloatingActionButton.extended(
                onPressed: () => _createNewInvoice(),
                backgroundColor: Colors.transparent,
                elevation: 0,
                icon: const Icon(Icons.add_rounded, color: Colors.white, size: 24),
                label: const Text(
                  'Create Invoice',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  void _createNewInvoice() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CreateInvoiceScreen(businessId: _businessId!),
      ),
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    _fabAnimationController.dispose();
    super.dispose();
  }
}

// 1. Sale Invoices Tab
class SaleInvoicesTab extends StatefulWidget {
  final String businessId;

  const SaleInvoicesTab({super.key, required this.businessId});

  @override
  State<SaleInvoicesTab> createState() => _SaleInvoicesTabState();
}

class _SaleInvoicesTabState extends State<SaleInvoicesTab> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  String _statusFilter = 'All';
  DateTime? _fromDate;
  DateTime? _toDate;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Filters Section
        Container(
          padding: const EdgeInsets.all(16),
          color: Colors.white,
          child: Column(
            children: [
              // Search Bar
              TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: 'Search by customer, invoice number...',
                  prefixIcon: const Icon(Icons.search),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                ),
                onChanged: (value) {
                  setState(() {
                    _searchQuery = value.toLowerCase();
                  });
                },
              ),
              const SizedBox(height: 12),
              // Filter Row
              Row(
                children: [
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      value: _statusFilter,
                      decoration: InputDecoration(
                        labelText: 'Status',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      ),
                      items: const [
                        DropdownMenuItem(value: 'All', child: Text('All Status')),
                        DropdownMenuItem(value: 'Paid', child: Text('Paid')),
                        DropdownMenuItem(value: 'Pending', child: Text('Pending')),
                        DropdownMenuItem(value: 'Overdue', child: Text('Overdue')),
                      ],
                      onChanged: (value) {
                        setState(() {
                          _statusFilter = value!;
                        });
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: InkWell(
                      onTap: () => _selectDateRange(),
                      child: InputDecorator(
                        decoration: InputDecoration(
                          labelText: 'Date Range',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        ),
                        child: Text(
                          _fromDate != null && _toDate != null
                              ? '${DateFormat('dd/MM').format(_fromDate!)} - ${DateFormat('dd/MM').format(_toDate!)}'
                              : 'Select Range',
                          style: TextStyle(
                            color: _fromDate != null ? Colors.black : Colors.grey,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        // Invoices List
        Expanded(
          child: StreamBuilder<QuerySnapshot>(
            stream: _getInvoicesStream(),
            builder: (context, snapshot) {
              if (snapshot.hasError) {
                return const Center(child: Text('Error loading invoices'));
              }
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              final invoices = snapshot.data!.docs.where((doc) {
                final data = doc.data() as Map<String, dynamic>;
                final customerName = (data['customerName'] ?? '').toString().toLowerCase();
                final invoiceNumber = (data['invoiceNumber'] ?? '').toString().toLowerCase();

                if (_searchQuery.isNotEmpty) {
                  if (!customerName.contains(_searchQuery) && !invoiceNumber.contains(_searchQuery)) {
                    return false;
                  }
                }

                if (_statusFilter != 'All') {
                  final status = data['status'] ?? 'Pending';
                  if (status != _statusFilter) {
                    return false;
                  }
                }

                return true;
              }).toList();

              if (invoices.isEmpty) {
                return _buildEmptyState();
              }

              return ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: invoices.length,
                itemBuilder: (context, index) {
                  return _buildInvoiceCard(invoices[index]);
                },
              );
            },
          ),
        ),
      ],
    );
  }

  Stream<QuerySnapshot> _getInvoicesStream() {
    Query query = FirebaseFirestore.instance
        .collection('invoices')
        .where('businessId', isEqualTo: widget.businessId)
        .orderBy('createdAt', descending: true);

    if (_fromDate != null && _toDate != null) {
      query = query
          .where('invoiceDate', isGreaterThanOrEqualTo: Timestamp.fromDate(_fromDate!))
          .where('invoiceDate', isLessThanOrEqualTo: Timestamp.fromDate(_toDate!));
    }

    return query.snapshots();
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.receipt_long_outlined,
            size: 80,
            color: Colors.grey.shade400,
          ),
          const SizedBox(height: 16),
          Text(
            'No invoices found',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Create your first invoice to get started',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey.shade500,
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () => _createNewInvoice(),
            icon: const Icon(Icons.add),
            label: const Text('Create Invoice'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF667eea),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInvoiceCard(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    final invoiceDate = (data['invoiceDate'] as Timestamp?)?.toDate() ?? DateTime.now();
    final status = data['status'] ?? 'Pending';
    final totalAmount = (data['totalAmount'] ?? 0.0).toDouble();

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
      child: InkWell(
        onTap: () => _viewInvoiceDetails(doc),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
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
                          'Invoice #${data['invoiceNumber'] ?? 'N/A'}',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          data['customerName'] ?? 'Walk-in Customer',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey.shade600,
                          ),
                        ),
                        Text(
                          DateFormat('dd MMM yyyy').format(invoiceDate),
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade500,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        '₹${totalAmount.toStringAsFixed(2)}',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.green,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: _getStatusColor(status).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          status,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: _getStatusColor(status),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  _buildActionButton(
                    icon: Icons.share,
                    label: 'Share',
                    onTap: () => _shareInvoice(doc),
                  ),
                  _buildActionButton(
                    icon: Icons.picture_as_pdf,
                    label: 'PDF',
                    onTap: () => _exportToPDF(doc),
                  ),
                  _buildActionButton(
                    icon: Icons.print,
                    label: 'Print',
                    onTap: () => _printInvoice(doc),
                  ),
                  _buildActionButton(
                    icon: Icons.edit,
                    label: 'Edit',
                    onTap: () => _editInvoice(doc),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Column(
            children: [
              Icon(icon, size: 20, color: Colors.grey.shade600),
              const SizedBox(height: 4),
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey.shade600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'Paid':
        return Colors.green;
      case 'Pending':
        return Colors.orange;
      case 'Overdue':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  void _selectDateRange() async {
    final DateTimeRange? picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      initialDateRange: _fromDate != null && _toDate != null
          ? DateTimeRange(start: _fromDate!, end: _toDate!)
          : null,
    );

    if (picked != null) {
      setState(() {
        _fromDate = picked.start;
        _toDate = picked.end;
      });
    }
  }

  void _createNewInvoice() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CreateInvoiceScreen(businessId: widget.businessId),
      ),
    );
  }

  void _viewInvoiceDetails(DocumentSnapshot doc) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => InvoiceDetailsScreen(
          businessId: widget.businessId,
          invoiceDoc: doc,
        ),
      ),
    );
  }

  void _shareInvoice(DocumentSnapshot doc) async {
    // Implement share functionality
    final data = doc.data() as Map<String, dynamic>;
    final invoiceText = '''
Invoice #${data['invoiceNumber']}
Customer: ${data['customerName']}
Date: ${DateFormat('dd/MM/yyyy').format((data['invoiceDate'] as Timestamp).toDate())}
Amount: ₹${data['totalAmount']}
Status: ${data['status']}
    ''';

    await Share.share(invoiceText);
  }

  void _exportToPDF(DocumentSnapshot doc) async {
    // Implement PDF export
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('PDF export functionality will be implemented')),
    );
  }

  void _printInvoice(DocumentSnapshot doc) async {
    // Implement print functionality
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Print functionality will be implemented')),
    );
  }

  void _editInvoice(DocumentSnapshot doc) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CreateInvoiceScreen(
          businessId: widget.businessId,
          invoiceDoc: doc,
        ),
      ),
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
}

// 2. Payment-In Tab
class PaymentInTab extends StatefulWidget {
  final String businessId;

  const PaymentInTab({super.key, required this.businessId});

  @override
  State<PaymentInTab> createState() => _PaymentInTabState();
}

class _PaymentInTabState extends State<PaymentInTab> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  String _paymentTypeFilter = 'All';

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Filters
        Container(
          padding: const EdgeInsets.all(16),
          color: Colors.white,
          child: Row(
            children: [
              Expanded(
                flex: 2,
                child: TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'Search payments...',
                    prefixIcon: const Icon(Icons.search),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  ),
                  onChanged: (value) {
                    setState(() {
                      _searchQuery = value.toLowerCase();
                    });
                  },
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: DropdownButtonFormField<String>(
                  value: _paymentTypeFilter,
                  decoration: InputDecoration(
                    labelText: 'Type',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  ),
                  items: const [
                    DropdownMenuItem(value: 'All', child: Text('All Types')),
                    DropdownMenuItem(value: 'Cash', child: Text('Cash')),
                    DropdownMenuItem(value: 'Cheque', child: Text('Cheque')),
                    DropdownMenuItem(value: 'UPI', child: Text('UPI')),
                    DropdownMenuItem(value: 'Online', child: Text('Online')),
                  ],
                  onChanged: (value) {
                    setState(() {
                      _paymentTypeFilter = value!;
                    });
                  },
                ),
              ),
            ],
          ),
        ),
        // Payments List
        Expanded(
          child: StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('payments')
                .where('businessId', isEqualTo: widget.businessId)
                .orderBy('paymentDate', descending: true)
                .snapshots(),
            builder: (context, snapshot) {
              if (snapshot.hasError) {
                return const Center(child: Text('Error loading payments'));
              }
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              final payments = snapshot.data!.docs.where((doc) {
                final data = doc.data() as Map<String, dynamic>;
                final customerName = (data['customerName'] ?? '').toString().toLowerCase();
                final invoiceNumber = (data['invoiceNumber'] ?? '').toString().toLowerCase();

                if (_searchQuery.isNotEmpty) {
                  if (!customerName.contains(_searchQuery) && !invoiceNumber.contains(_searchQuery)) {
                    return false;
                  }
                }

                if (_paymentTypeFilter != 'All') {
                  final paymentType = data['paymentType'] ?? '';
                  if (paymentType != _paymentTypeFilter) {
                    return false;
                  }
                }

                return true;
              }).toList();

              if (payments.isEmpty) {
                return _buildEmptyPaymentsState();
              }

              return ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: payments.length,
                itemBuilder: (context, index) {
                  return _buildPaymentCard(payments[index]);
                },
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyPaymentsState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.payment_outlined,
            size: 80,
            color: Colors.grey.shade400,
          ),
          const SizedBox(height: 16),
          Text(
            'No payments recorded',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Record your first payment to get started',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey.shade500,
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () => _recordNewPayment(),
            icon: const Icon(Icons.add),
            label: const Text('Record Payment'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF4CAF50),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentCard(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    final paymentDate = (data['paymentDate'] as Timestamp?)?.toDate() ?? DateTime.now();
    final amount = (data['amount'] ?? 0.0).toDouble();
    final paymentType = data['paymentType'] ?? 'Cash';

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
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    color: Colors.green.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.payment,
                    color: Colors.green,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        data['customerName'] ?? 'Walk-in Customer',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Invoice #${data['invoiceNumber'] ?? 'N/A'}',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey.shade600,
                        ),
                      ),
                      Text(
                        DateFormat('dd MMM yyyy').format(paymentDate),
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade500,
                        ),
                      ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '₹${amount.toStringAsFixed(2)}',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.green,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: _getPaymentTypeColor(paymentType).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        paymentType,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: _getPaymentTypeColor(paymentType),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
            if (data['notes'] != null && data['notes'].toString().isNotEmpty) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey.shade50,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  'Notes: ${data['notes']}',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey.shade700,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Color _getPaymentTypeColor(String paymentType) {
    switch (paymentType) {
      case 'Cash':
        return Colors.green;
      case 'Cheque':
        return Colors.blue;
      case 'UPI':
        return Colors.purple;
      case 'Online':
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }

  void _recordNewPayment() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => RecordPaymentScreen(businessId: widget.businessId),
      ),
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
}

// 3. Sale Return Tab
class SaleReturnTab extends StatefulWidget {
  final String businessId;

  const SaleReturnTab({super.key, required this.businessId});

  @override
  State<SaleReturnTab> createState() => _SaleReturnTabState();
}

class _SaleReturnTabState extends State<SaleReturnTab> {
  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('sale_returns')
          .where('businessId', isEqualTo: widget.businessId)
          .orderBy('returnDate', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return const Center(child: Text('Error loading returns'));
        }
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final returns = snapshot.data!.docs;

        if (returns.isEmpty) {
          return _buildEmptyReturnsState();
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: returns.length,
          itemBuilder: (context, index) {
            return _buildReturnCard(returns[index]);
          },
        );
      },
    );
  }

  Widget _buildEmptyReturnsState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.assignment_return_outlined,
            size: 80,
            color: Colors.grey.shade400,
          ),
          const SizedBox(height: 16),
          Text(
            'No returns recorded',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Create credit notes for returned items',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey.shade500,
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () => _createSaleReturn(),
            icon: const Icon(Icons.add),
            label: const Text('Create Return'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFFF5722),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReturnCard(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    final returnDate = (data['returnDate'] as Timestamp?)?.toDate() ?? DateTime.now();
    final amount = (data['returnAmount'] ?? 0.0).toDouble();

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
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    color: Colors.red.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.assignment_return,
                    color: Colors.red,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Credit Note #${data['creditNoteNumber'] ?? 'N/A'}',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Original Invoice: ${data['originalInvoiceNumber'] ?? 'N/A'}',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey.shade600,
                        ),
                      ),
                      Text(
                        DateFormat('dd MMM yyyy').format(returnDate),
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade500,
                        ),
                      ),
                    ],
                  ),
                ),
                Text(
                  '₹${amount.toStringAsFixed(2)}',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.red,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              'Reason: ${data['returnReason'] ?? 'Not specified'}',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade700,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _createSaleReturn() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CreateSaleReturnScreen(businessId: widget.businessId),
      ),
    );
  }
}

// 4. Estimate/Quotation Tab
class EstimateQuotationTab extends StatefulWidget {
  final String businessId;

  const EstimateQuotationTab({super.key, required this.businessId});

  @override
  State<EstimateQuotationTab> createState() => _EstimateQuotationTabState();
}

class _EstimateQuotationTabState extends State<EstimateQuotationTab> {
  String _statusFilter = 'All';

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Filter
        Container(
          padding: const EdgeInsets.all(16),
          color: Colors.white,
          child: DropdownButtonFormField<String>(
            value: _statusFilter,
            decoration: InputDecoration(
              labelText: 'Status',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            ),
            items: const [
              DropdownMenuItem(value: 'All', child: Text('All Status')),
              DropdownMenuItem(value: 'Open', child: Text('Open')),
              DropdownMenuItem(value: 'Approved', child: Text('Approved')),
              DropdownMenuItem(value: 'Converted', child: Text('Converted')),
              DropdownMenuItem(value: 'Expired', child: Text('Expired')),
            ],
            onChanged: (value) {
              setState(() {
                _statusFilter = value!;
              });
            },
          ),
        ),
        // Estimates List
        Expanded(
          child: StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('estimates')
                .where('businessId', isEqualTo: widget.businessId)
                .orderBy('createdAt', descending: true)
                .snapshots(),
            builder: (context, snapshot) {
              if (snapshot.hasError) {
                return const Center(child: Text('Error loading estimates'));
              }
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              final estimates = snapshot.data!.docs.where((doc) {
                if (_statusFilter == 'All') return true;
                final data = doc.data() as Map<String, dynamic>;
                return data['status'] == _statusFilter;
              }).toList();

              if (estimates.isEmpty) {
                return _buildEmptyEstimatesState();
              }

              return ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: estimates.length,
                itemBuilder: (context, index) {
                  return _buildEstimateCard(estimates[index]);
                },
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyEstimatesState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.description_outlined,
            size: 80,
            color: Colors.grey.shade400,
          ),
          const SizedBox(height: 16),
          Text(
            'No estimates created',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Create GST-compliant quotes for your customers',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey.shade500,
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () => _createEstimate(),
            icon: const Icon(Icons.add),
            label: const Text('Create Estimate'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF9C27B0),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEstimateCard(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    final estimateDate = (data['estimateDate'] as Timestamp?)?.toDate() ?? DateTime.now();
    final expiryDate = (data['expiryDate'] as Timestamp?)?.toDate();
    final amount = (data['totalAmount'] ?? 0.0).toDouble();
    final status = data['status'] ?? 'Open';

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
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    color: Colors.purple.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.description,
                    color: Colors.purple,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Estimate #${data['estimateNumber'] ?? 'N/A'}',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        data['customerName'] ?? 'Walk-in Customer',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey.shade600,
                        ),
                      ),
                      Text(
                        DateFormat('dd MMM yyyy').format(estimateDate),
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade500,
                        ),
                      ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '₹${amount.toStringAsFixed(2)}',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.purple,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: _getEstimateStatusColor(status).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        status,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: _getEstimateStatusColor(status),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
            if (expiryDate != null) ...[
              const SizedBox(height: 12),
              Row(
                children: [
                  Icon(
                    Icons.schedule,
                    size: 16,
                    color: Colors.grey.shade600,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    'Expires: ${DateFormat('dd MMM yyyy').format(expiryDate)}',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
            ],
            if (status == 'Open' || status == 'Approved') ...[
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => _convertToInvoice(doc),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF4CAF50),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: const Text('Convert to Invoice'),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Color _getEstimateStatusColor(String status) {
    switch (status) {
      case 'Open':
        return Colors.blue;
      case 'Approved':
        return Colors.green;
      case 'Converted':
        return Colors.purple;
      case 'Expired':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  void _createEstimate() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CreateEstimateScreen(businessId: widget.businessId),
      ),
    );
  }

  void _convertToInvoice(DocumentSnapshot doc) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Convert to Invoice'),
        content: const Text('Are you sure you want to convert this estimate to an invoice?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.of(context).pop();
              await _performConversion(doc);
            },
            child: const Text('Convert'),
          ),
        ],
      ),
    );
  }

  Future<void> _performConversion(DocumentSnapshot doc) async {
    try {
      final estimateData = doc.data() as Map<String, dynamic>;

      // Create invoice from estimate data
      final invoiceData = {
        ...estimateData,
        'invoiceNumber': await _generateInvoiceNumber(),
        'invoiceDate': Timestamp.now(),
        'status': 'Pending',
        'convertedFromEstimate': doc.id,
      };

      // Remove estimate-specific fields
      invoiceData.remove('estimateNumber');
      invoiceData.remove('estimateDate');
      invoiceData.remove('expiryDate');

      // Add to invoices collection
      await FirebaseFirestore.instance.collection('invoices').add(invoiceData);

      // Update estimate status
      await doc.reference.update({'status': 'Converted'});

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Estimate converted to invoice successfully'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error converting estimate: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<String> _generateInvoiceNumber() async {
    final snapshot = await FirebaseFirestore.instance
        .collection('invoices')
        .where('businessId', isEqualTo: widget.businessId)
        .orderBy('invoiceNumber', descending: true)
        .limit(1)
        .get();

    int nextNumber = 1;
    if (snapshot.docs.isNotEmpty) {
      final lastInvoice = snapshot.docs.first.data();
      final lastNumber = int.tryParse(lastInvoice['invoiceNumber']?.toString() ?? '0') ?? 0;
      nextNumber = lastNumber + 1;
    }

    return nextNumber.toString().padLeft(4, '0');
  }
}

// 5. Delivery Challan Tab
class DeliveryChallanTab extends StatefulWidget {
  final String businessId;

  const DeliveryChallanTab({super.key, required this.businessId});

  @override
  State<DeliveryChallanTab> createState() => _DeliveryChallanTabState();
}

class _DeliveryChallanTabState extends State<DeliveryChallanTab> {
  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('delivery_challans')
          .where('businessId', isEqualTo: widget.businessId)
          .orderBy('challanDate', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return const Center(child: Text('Error loading challans'));
        }
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final challans = snapshot.data!.docs;

        if (challans.isEmpty) {
          return _buildEmptyChallansState();
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: challans.length,
          itemBuilder: (context, index) {
            return _buildChallanCard(challans[index]);
          },
        );
      },
    );
  }

  Widget _buildEmptyChallansState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.local_shipping_outlined,
            size: 80,
            color: Colors.grey.shade400,
          ),
          const SizedBox(height: 16),
          Text(
            'No delivery challans created',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Create challans for transporting goods',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey.shade500,
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () => _createChallan(),
            icon: const Icon(Icons.add),
            label: const Text('Create Challan'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF2196F3),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChallanCard(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    final challanDate = (data['challanDate'] as Timestamp?)?.toDate() ?? DateTime.now();
    final status = data['status'] ?? 'Pending';

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
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    color: Colors.blue.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.local_shipping,
                    color: Colors.blue,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Challan #${data['challanNumber'] ?? 'N/A'}',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'To: ${data['partyName'] ?? 'N/A'}',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey.shade600,
                        ),
                      ),
                      Text(
                        DateFormat('dd MMM yyyy').format(challanDate),
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade500,
                        ),
                      ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: _getChallanStatusColor(status).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        status,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: _getChallanStatusColor(status),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              'Transport: ${data['transportDetails'] ?? 'Not specified'}',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade700,
              ),
            ),
            if (status == 'Pending') ...[
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => _convertChallanToInvoice(doc),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF4CAF50),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: const Text('Convert to Invoice'),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Color _getChallanStatusColor(String status) {
    switch (status) {
      case 'Pending':
        return Colors.orange;
      case 'Delivered':
        return Colors.green;
      case 'Converted':
        return Colors.purple;
      default:
        return Colors.grey;
    }
  }

  void _createChallan() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CreateChallanScreen(businessId: widget.businessId),
      ),
    );
  }

  void _convertChallanToInvoice(DocumentSnapshot doc) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Convert to Invoice'),
        content: const Text('Are you sure you want to convert this challan to an invoice?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.of(context).pop();
              await _performChallanConversion(doc);
            },
            child: const Text('Convert'),
          ),
        ],
      ),
    );
  }

  Future<void> _performChallanConversion(DocumentSnapshot doc) async {
    try {
      final challanData = doc.data() as Map<String, dynamic>;

      // Create invoice from challan data
      final invoiceData = {
        'businessId': widget.businessId,
        'invoiceNumber': await _generateInvoiceNumber(),
        'invoiceDate': Timestamp.now(),
        'customerName': challanData['partyName'],
        'customerAddress': challanData['partyAddress'],
        'customerGSTIN': challanData['partyGSTIN'],
        'status': 'Pending',
        'convertedFromChallan': doc.id,
        'totalAmount': challanData['totalAmount'] ?? 0.0,
        'createdAt': FieldValue.serverTimestamp(),
      };

      // Add to invoices collection
      await FirebaseFirestore.instance.collection('invoices').add(invoiceData);

      // Update challan status
      await doc.reference.update({'status': 'Converted'});

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Challan converted to invoice successfully'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error converting challan: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<String> _generateInvoiceNumber() async {
    final snapshot = await FirebaseFirestore.instance
        .collection('invoices')
        .where('businessId', isEqualTo: widget.businessId)
        .orderBy('invoiceNumber', descending: true)
        .limit(1)
        .get();

    int nextNumber = 1;
    if (snapshot.docs.isNotEmpty) {
      final lastInvoice = snapshot.docs.first.data();
      final lastNumber = int.tryParse(lastInvoice['invoiceNumber']?.toString() ?? '0') ?? 0;
      nextNumber = lastNumber + 1;
    }

    return nextNumber.toString().padLeft(4, '0');
  }
}

// Placeholder screens for navigation
class CreateInvoiceScreen extends StatelessWidget {
  final String businessId;
  final DocumentSnapshot? invoiceDoc;

  const CreateInvoiceScreen({
    super.key,
    required this.businessId,
    this.invoiceDoc,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(invoiceDoc == null ? 'Create Invoice' : 'Edit Invoice'),
      ),
      body: const Center(
        child: Text('Invoice creation screen will be implemented here'),
      ),
    );
  }
}

class InvoiceDetailsScreen extends StatelessWidget {
  final String businessId;
  final DocumentSnapshot invoiceDoc;

  const InvoiceDetailsScreen({
    super.key,
    required this.businessId,
    required this.invoiceDoc,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Invoice Details'),
      ),
      body: const Center(
        child: Text('Invoice details screen will be implemented here'),
      ),
    );
  }
}

class RecordPaymentScreen extends StatelessWidget {
  final String businessId;

  const RecordPaymentScreen({
    super.key,
    required this.businessId,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Record Payment'),
      ),
      body: const Center(
        child: Text('Payment recording screen will be implemented here'),
      ),
    );
  }
}

class CreateSaleReturnScreen extends StatelessWidget {
  final String businessId;

  const CreateSaleReturnScreen({
    super.key,
    required this.businessId,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Create Sale Return'),
      ),
      body: const Center(
        child: Text('Sale return creation screen will be implemented here'),
      ),
    );
  }
}

class CreateEstimateScreen extends StatelessWidget {
  final String businessId;

  const CreateEstimateScreen({
    super.key,
    required this.businessId,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Create Estimate'),
      ),
      body: const Center(
        child: Text('Estimate creation screen will be implemented here'),
      ),
    );
  }
}

class CreateChallanScreen extends StatelessWidget {
  final String businessId;

  const CreateChallanScreen({
    super.key,
    required this.businessId,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Create Delivery Challan'),
      ),
      body: const Center(
        child: Text('Challan creation screen will be implemented here'),
      ),
    );
  }
}
