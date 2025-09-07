import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'package:share_plus/share_plus.dart';

// Comprehensive Reports Screen with 8 categories
class ComprehensiveReportsScreen extends StatefulWidget {
  const ComprehensiveReportsScreen({super.key});

  @override
  State<ComprehensiveReportsScreen> createState() => _ComprehensiveReportsScreenState();
}

class _ComprehensiveReportsScreenState extends State<ComprehensiveReportsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String? _currentUserId;
  String? _businessId;
  DateTime _fromDate = DateTime.now().subtract(const Duration(days: 30));
  DateTime _toDate = DateTime.now();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 8, vsync: this);
    _getCurrentUser();
  }

  void _getCurrentUser() {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      setState(() {
        _currentUserId = user.uid;
        _businessId = user.uid; // Using user ID as business ID
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
          'Reports & Analytics',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            onPressed: () => _selectDateRange(),
            icon: const Icon(Icons.date_range),
            tooltip: 'Select Date Range',
          ),
          IconButton(
            onPressed: () => _exportReports(),
            icon: const Icon(Icons.download),
            tooltip: 'Export Reports',
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          labelColor: const Color(0xFF667eea),
          unselectedLabelColor: Colors.grey,
          indicatorColor: const Color(0xFF667eea),
          indicatorWeight: 3,
          isScrollable: true,
          tabs: const [
            Tab(text: 'Transaction', icon: Icon(Icons.receipt, size: 16)),
            Tab(text: 'Party', icon: Icon(Icons.people, size: 16)),
            Tab(text: 'GST', icon: Icon(Icons.account_balance, size: 16)),
            Tab(text: 'Item/Stock', icon: Icon(Icons.inventory, size: 16)),
            Tab(text: 'Business', icon: Icon(Icons.business, size: 16)),
            Tab(text: 'Expense', icon: Icon(Icons.money_off, size: 16)),
            Tab(text: 'Orders', icon: Icon(Icons.shopping_cart, size: 16)),
            Tab(text: 'Other', icon: Icon(Icons.more_horiz, size: 16)),
          ],
        ),
      ),
      body: Column(
        children: [
          // Date Range Display
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.white,
            child: Row(
              children: [
                Icon(Icons.calendar_today, size: 16, color: Colors.grey.shade600),
                const SizedBox(width: 8),
                Text(
                  'Period: ${DateFormat('dd MMM yyyy').format(_fromDate)} - ${DateFormat('dd MMM yyyy').format(_toDate)}',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey.shade700,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const Spacer(),
                TextButton(
                  onPressed: () => _selectDateRange(),
                  child: const Text('Change'),
                ),
              ],
            ),
          ),
          // Reports Content
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                TransactionReportsTab(businessId: _businessId!, fromDate: _fromDate, toDate: _toDate),
                PartyReportsTab(businessId: _businessId!, fromDate: _fromDate, toDate: _toDate),
                GSTReportsTab(businessId: _businessId!, fromDate: _fromDate, toDate: _toDate),
                ItemStockReportsTab(businessId: _businessId!, fromDate: _fromDate, toDate: _toDate),
                BusinessStatusTab(businessId: _businessId!, fromDate: _fromDate, toDate: _toDate),
                ExpenseReportsTab(businessId: _businessId!, fromDate: _fromDate, toDate: _toDate),
                OrderReportsTab(businessId: _businessId!, fromDate: _fromDate, toDate: _toDate),
                OtherReportsTab(businessId: _businessId!, fromDate: _fromDate, toDate: _toDate),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _selectDateRange() async {
    final DateTimeRange? picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      initialDateRange: DateTimeRange(start: _fromDate, end: _toDate),
    );

    if (picked != null) {
      setState(() {
        _fromDate = picked.start;
        _toDate = picked.end;
      });
    }
  }

  void _exportReports() {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Export Reports',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            ListTile(
              leading: const Icon(Icons.picture_as_pdf, color: Colors.red),
              title: const Text('Export as PDF'),
              onTap: () {
                Navigator.pop(context);
                _exportAsPDF();
              },
            ),
            ListTile(
              leading: const Icon(Icons.table_chart, color: Colors.green),
              title: const Text('Export as Excel'),
              onTap: () {
                Navigator.pop(context);
                _exportAsExcel();
              },
            ),
            ListTile(
              leading: const Icon(Icons.description, color: Colors.blue),
              title: const Text('Export as Word'),
              onTap: () {
                Navigator.pop(context);
                _exportAsWord();
              },
            ),
            ListTile(
              leading: const Icon(Icons.share, color: Colors.orange),
              title: const Text('Share Report'),
              onTap: () {
                Navigator.pop(context);
                _shareReport();
              },
            ),
          ],
        ),
      ),
    );
  }

  void _exportAsPDF() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('PDF export functionality will be implemented')),
    );
  }

  void _exportAsExcel() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Excel export functionality will be implemented')),
    );
  }

  void _exportAsWord() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Word export functionality will be implemented')),
    );
  }

  void _shareReport() {
    Share.share('Report data will be shared here');
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }
}

// 1. Transaction Reports Tab
class TransactionReportsTab extends StatelessWidget {
  final String businessId;
  final DateTime fromDate;
  final DateTime toDate;

  const TransactionReportsTab({
    super.key,
    required this.businessId,
    required this.fromDate,
    required this.toDate,
  });

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _buildReportCard(
          'Sale Report',
          'Detailed sales transactions with GST breakdown',
          Icons.trending_up,
          Colors.green,
              () => _openSaleReport(context),
        ),
        _buildReportCard(
          'Purchase Report',
          'All purchase transactions and vendor payments',
          Icons.shopping_cart,
          Colors.blue,
              () => _openPurchaseReport(context),
        ),
        _buildReportCard(
          'Day Book',
          'Daily transaction summary with cash flow',
          Icons.today,
          Colors.orange,
              () => _openDayBook(context),
        ),
        _buildReportCard(
          'Bill-wise Profit',
          'Profit analysis for each invoice',
          Icons.analytics,
          Colors.purple,
              () => _openBillwiseProfit(context),
        ),
        _buildReportCard(
          'Profit & Loss',
          'Comprehensive P&L statement',
          Icons.account_balance,
          Colors.red,
              () => _openProfitLoss(context),
        ),
        _buildReportCard(
          'Cash Flow',
          'Cash inflow and outflow analysis',
          Icons.water_drop,
          Colors.cyan,
              () => _openCashFlow(context),
        ),
        _buildReportCard(
          'Balance Sheet',
          'Assets, liabilities and equity statement',
          Icons.balance,
          Colors.indigo,
              () => _openBalanceSheet(context),
        ),
        _buildReportCard(
          'All Transactions',
          'Complete transaction history',
          Icons.list_alt,
          Colors.grey,
              () => _openAllTransactions(context),
        ),
      ],
    );
  }

  Widget _buildReportCard(
      String title,
      String description,
      IconData icon,
      Color color,
      VoidCallback onTap,
      ) {
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
        contentPadding: const EdgeInsets.all(16),
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
          description,
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

  void _openSaleReport(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => SaleReportScreen(
          businessId: businessId,
          fromDate: fromDate,
          toDate: toDate,
        ),
      ),
    );
  }

  void _openPurchaseReport(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PurchaseReportScreen(
          businessId: businessId,
          fromDate: fromDate,
          toDate: toDate,
        ),
      ),
    );
  }

  void _openDayBook(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => DayBookScreen(
          businessId: businessId,
          fromDate: fromDate,
          toDate: toDate,
        ),
      ),
    );
  }

  void _openBillwiseProfit(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => BillwiseProfitScreen(
          businessId: businessId,
          fromDate: fromDate,
          toDate: toDate,
        ),
      ),
    );
  }

  void _openProfitLoss(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ProfitLossScreen(
          businessId: businessId,
          fromDate: fromDate,
          toDate: toDate,
        ),
      ),
    );
  }

  void _openCashFlow(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CashFlowScreen(
          businessId: businessId,
          fromDate: fromDate,
          toDate: toDate,
        ),
      ),
    );
  }

  void _openBalanceSheet(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => BalanceSheetScreen(
          businessId: businessId,
          fromDate: fromDate,
          toDate: toDate,
        ),
      ),
    );
  }

  void _openAllTransactions(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AllTransactionsScreen(
          businessId: businessId,
          fromDate: fromDate,
          toDate: toDate,
        ),
      ),
    );
  }
}

// 2. Party Reports Tab
class PartyReportsTab extends StatelessWidget {
  final String businessId;
  final DateTime fromDate;
  final DateTime toDate;

  const PartyReportsTab({
    super.key,
    required this.businessId,
    required this.fromDate,
    required this.toDate,
  });

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _buildReportCard(
          'Party Statement',
          'Individual party transaction history',
          Icons.person,
          Colors.blue,
              () => _openPartyStatement(context),
        ),
        _buildReportCard(
          'Party-wise P&L',
          'Profit and loss analysis by customer',
          Icons.trending_up,
          Colors.green,
              () => _openPartyWisePL(context),
        ),
        _buildReportCard(
          'Outstanding Dues',
          'Pending payments from customers',
          Icons.schedule,
          Colors.orange,
              () => _openOutstandingDues(context),
        ),
        _buildReportCard(
          'Sale by Party',
          'Sales breakdown by customer',
          Icons.group,
          Colors.purple,
              () => _openSaleByParty(context),
        ),
        _buildReportCard(
          'Purchase by Party',
          'Purchase breakdown by vendor',
          Icons.shopping_bag,
          Colors.red,
              () => _openPurchaseByParty(context),
        ),
        _buildReportCard(
          'Party & Item Reports',
          'Combined party and item analysis',
          Icons.analytics,
          Colors.cyan,
              () => _openPartyItemReports(context),
        ),
      ],
    );
  }

  Widget _buildReportCard(
      String title,
      String description,
      IconData icon,
      Color color,
      VoidCallback onTap,
      ) {
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
        contentPadding: const EdgeInsets.all(16),
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
          description,
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

  void _openPartyStatement(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Party Statement report will be implemented')),
    );
  }

  void _openPartyWisePL(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Party-wise P&L report will be implemented')),
    );
  }

  void _openOutstandingDues(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Outstanding Dues report will be implemented')),
    );
  }

  void _openSaleByParty(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Sale by Party report will be implemented')),
    );
  }

  void _openPurchaseByParty(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Purchase by Party report will be implemented')),
    );
  }

  void _openPartyItemReports(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Party & Item reports will be implemented')),
    );
  }
}

// 3. GST Reports Tab (Enhanced from existing code)
// 3. GST Reports Tab (Enhanced from existing code)
class GSTReportsTab extends StatelessWidget {
  final String businessId;
  final DateTime fromDate;
  final DateTime toDate;

  const GSTReportsTab({
    super.key,
    required this.businessId,
    required this.fromDate,
    required this.toDate,
  });

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: <Widget>[
        _buildReportCard(
          context,
          'GSTR-1 (Sales)',
          'Outward supplies for GST filing',
          Icons.upload,
          Colors.green,
              () => _openGSTR1(context),
        ),
        _buildReportCard(
          context,
          'GSTR-2 (Purchases)',
          'Inward supplies for GST filing',
          Icons.download,
          Colors.blue,
              () => _openGSTR2(context),
        ),
        _buildReportCard(
          context,
          'GSTR-3B',
          'Monthly return summary',
          Icons.summarize,
          Colors.orange,
              () => _openGSTR3B(context),
        ),
        _buildReportCard(
          context,
          'GSTR-9',
          'Annual return filing',
          Icons.calendar_month, // Fixed: IconData first
          Colors.purple,        // Fixed: Color second
              () => _openGSTR9(context),
        ),
        _buildReportCard(
          context,
          'GST Detail Report',
          'Comprehensive GST transaction details',
          Icons.receipt_long,
          Colors.red,
              () => _openGSTDetailReport(context),
        ),
        _buildReportCard(
          context,
          'HSN Summary',
          'HSN-wise sales and tax summary',
          Icons.category,
          Colors.cyan,
              () => _openHSNSummary(context),
        ),
      ],
    );
  }

  Widget _buildReportCard(
      BuildContext context,
      String title,
      String description,
      IconData icon,
      Color color,
      VoidCallback onTap,
      ) {
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
        contentPadding: const EdgeInsets.all(16),
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
          description,
          style: TextStyle(
            fontSize: 14,
            color: Colors.grey.shade600,
          ),
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.download, size: 20),
              onPressed: () => _exportGSTReport(context, title),
              tooltip: 'Export',
            ),
            const Icon(Icons.arrow_forward_ios, size: 16),
          ],
        ),
        onTap: onTap,
      ),
    );
  }

  void _openGSTR1(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => GSTR1Screen(
          businessId: businessId,
          fromDate: fromDate,
          toDate: toDate,
        ),
      ),
    );
  }

  void _openGSTR2(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('GSTR-2 report will be implemented')),
    );
  }

  void _openGSTR3B(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('GSTR-3B report will be implemented')),
    );
  }

  void _openGSTR9(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('GSTR-9 report will be implemented')),
    );
  }

  void _openGSTDetailReport(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('GST Detail report will be implemented')),
    );
  }

  void _openHSNSummary(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => HSNSummaryScreen(
          businessId: businessId,
          fromDate: fromDate,
          toDate: toDate,
        ),
      ),
    );
  }

  void _exportGSTReport(BuildContext context, String reportType) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('$reportType export functionality will be implemented')),
    );
  }
}

  void _exportGSTReport(BuildContext context, String reportType) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('$reportType export functionality will be implemented')),
    );
  }



// Continue with remaining tabs...
// 4. Item/Stock Reports Tab
class ItemStockReportsTab extends StatelessWidget {
  final String businessId;
  final DateTime fromDate;
  final DateTime toDate;

  const ItemStockReportsTab({
    super.key,
    required this.businessId,
    required this.fromDate,
    required this.toDate,
  });

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _buildReportCard(
          'Stock Summary',
          'Current stock levels overview',
          Icons.inventory,
          Colors.blue,
              () => _openStockSummary(context),
        ),
        _buildReportCard(
          'Stock Detail',
          'Detailed stock movement report',
          Icons.list_alt,
          Colors.green,
              () => _openStockDetail(context),
        ),
        _buildReportCard(
          'Item-wise Profit/Loss',
          'Profitability analysis by item',
          Icons.trending_up,
          Colors.purple,
              () => _openItemWisePL(context),
        ),
        _buildReportCard(
          'Low Stock Alert',
          'Items below minimum stock level',
          Icons.warning,
          Colors.orange,
              () => _openLowStockAlert(context),
        ),
        _buildReportCard(
          'Sale by Category',
          'Sales breakdown by item category',
          Icons.category,
          Colors.red,
              () => _openSaleByCategory(context),
        ),
        _buildReportCard(
          'Batch/Serial Reports',
          'Batch and serial number tracking',
          Icons.qr_code,
          Colors.cyan,
              () => _openBatchSerialReports(context),
        ),
        _buildReportCard(
          'Item-wise Discounts',
          'Discount analysis by item',
          Icons.local_offer,
          Colors.indigo,
              () => _openItemWiseDiscounts(context),
        ),
      ],
    );
  }

  Widget _buildReportCard(
      String title,
      String description,
      IconData icon,
      Color color,
      VoidCallback onTap,
      ) {
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
        contentPadding: const EdgeInsets.all(16),
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
          description,
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

  void _openStockSummary(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => StockSummaryScreen(
          businessId: businessId,
          fromDate: fromDate,
          toDate: toDate,
        ),
      ),
    );
  }

  void _openStockDetail(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Stock Detail report will be implemented')),
    );
  }

  void _openItemWisePL(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Item-wise P&L report will be implemented')),
    );
  }

  void _openLowStockAlert(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => LowStockAlertScreen(
          businessId: businessId,
        ),
      ),
    );
  }

  void _openSaleByCategory(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Sale by Category report will be implemented')),
    );
  }

  void _openBatchSerialReports(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Batch/Serial reports will be implemented')),
    );
  }

  void _openItemWiseDiscounts(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Item-wise Discounts report will be implemented')),
    );
  }
}

// Placeholder screens for the remaining tabs
class BusinessStatusTab extends StatelessWidget {
  final String businessId;
  final DateTime fromDate;
  final DateTime toDate;

  const BusinessStatusTab({
    super.key,
    required this.businessId,
    required this.fromDate,
    required this.toDate,
  });

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Text('Business Status reports will be implemented here'),
    );
  }
}

class ExpenseReportsTab extends StatelessWidget {
  final String businessId;
  final DateTime fromDate;
  final DateTime toDate;

  const ExpenseReportsTab({
    super.key,
    required this.businessId,
    required this.fromDate,
    required this.toDate,
  });

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Text('Expense reports will be implemented here'),
    );
  }
}

class OrderReportsTab extends StatelessWidget {
  final String businessId;
  final DateTime fromDate;
  final DateTime toDate;

  const OrderReportsTab({
    super.key,
    required this.businessId,
    required this.fromDate,
    required this.toDate,
  });

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Text('Order reports will be implemented here'),
    );
  }
}

class OtherReportsTab extends StatelessWidget {
  final String businessId;
  final DateTime fromDate;
  final DateTime toDate;

  const OtherReportsTab({
    super.key,
    required this.businessId,
    required this.fromDate,
    required this.toDate,
  });

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Text('Other Income & Loans reports will be implemented here'),
    );
  }
}

// Placeholder report screens
class SaleReportScreen extends StatelessWidget {
  final String businessId;
  final DateTime fromDate;
  final DateTime toDate;

  const SaleReportScreen({
    super.key,
    required this.businessId,
    required this.fromDate,
    required this.toDate,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Sale Report')),
      body: const Center(child: Text('Sale Report implementation')),
    );
  }
}

class PurchaseReportScreen extends StatelessWidget {
  final String businessId;
  final DateTime fromDate;
  final DateTime toDate;

  const PurchaseReportScreen({
    super.key,
    required this.businessId,
    required this.fromDate,
    required this.toDate,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Purchase Report')),
      body: const Center(child: Text('Purchase Report implementation')),
    );
  }
}

class DayBookScreen extends StatelessWidget {
  final String businessId;
  final DateTime fromDate;
  final DateTime toDate;

  const DayBookScreen({
    super.key,
    required this.businessId,
    required this.fromDate,
    required this.toDate,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Day Book')),
      body: const Center(child: Text('Day Book implementation')),
    );
  }
}

class BillwiseProfitScreen extends StatelessWidget {
  final String businessId;
  final DateTime fromDate;
  final DateTime toDate;

  const BillwiseProfitScreen({
    super.key,
    required this.businessId,
    required this.fromDate,
    required this.toDate,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Bill-wise Profit')),
      body: const Center(child: Text('Bill-wise Profit implementation')),
    );
  }
}

class ProfitLossScreen extends StatelessWidget {
  final String businessId;
  final DateTime fromDate;
  final DateTime toDate;

  const ProfitLossScreen({
    super.key,
    required this.businessId,
    required this.fromDate,
    required this.toDate,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Profit & Loss')),
      body: const Center(child: Text('Profit & Loss implementation')),
    );
  }
}

class CashFlowScreen extends StatelessWidget {
  final String businessId;
  final DateTime fromDate;
  final DateTime toDate;

  const CashFlowScreen({
    super.key,
    required this.businessId,
    required this.fromDate,
    required this.toDate,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Cash Flow')),
      body: const Center(child: Text('Cash Flow implementation')),
    );
  }
}

class BalanceSheetScreen extends StatelessWidget {
  final String businessId;
  final DateTime fromDate;
  final DateTime toDate;

  const BalanceSheetScreen({
    super.key,
    required this.businessId,
    required this.fromDate,
    required this.toDate,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Balance Sheet')),
      body: const Center(child: Text('Balance Sheet implementation')),
    );
  }
}

class AllTransactionsScreen extends StatelessWidget {
  final String businessId;
  final DateTime fromDate;
  final DateTime toDate;

  const AllTransactionsScreen({
    super.key,
    required this.businessId,
    required this.fromDate,
    required this.toDate,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('All Transactions')),
      body: const Center(child: Text('All Transactions implementation')),
    );
  }
}

class GSTR1Screen extends StatelessWidget {
  final String businessId;
  final DateTime fromDate;
  final DateTime toDate;

  const GSTR1Screen({
    super.key,
    required this.businessId,
    required this.fromDate,
    required this.toDate,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('GSTR-1')),
      body: const Center(child: Text('GSTR-1 implementation')),
    );
  }
}

class HSNSummaryScreen extends StatelessWidget {
  final String businessId;
  final DateTime fromDate;
  final DateTime toDate;

  const HSNSummaryScreen({
    super.key,
    required this.businessId,
    required this.fromDate,
    required this.toDate,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('HSN Summary')),
      body: const Center(child: Text('HSN Summary implementation')),
    );
  }
}

class StockSummaryScreen extends StatelessWidget {
  final String businessId;
  final DateTime fromDate;
  final DateTime toDate;

  const StockSummaryScreen({
    super.key,
    required this.businessId,
    required this.fromDate,
    required this.toDate,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Stock Summary')),
      body: const Center(child: Text('Stock Summary implementation')),
    );
  }
}

class LowStockAlertScreen extends StatelessWidget {
  final String businessId;

  const LowStockAlertScreen({
    super.key,
    required this.businessId,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Low Stock Alert')),
      body: const Center(child: Text('Low Stock Alert implementation')),
    );
  }
}
