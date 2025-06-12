import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'package:flutter/services.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:printing/printing.dart';
import 'dart:io';

class PartyManagementScreen extends StatefulWidget {
  const PartyManagementScreen({super.key});

  @override
  State<PartyManagementScreen> createState() => _PartyManagementScreenState();
}

class _PartyManagementScreenState extends State<PartyManagementScreen>
    with TickerProviderStateMixin {
  late TabController _tabController;
  late AnimationController _animationController;
  late AnimationController _fabAnimationController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;
  late Animation<double> _fabScaleAnimation;

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Search and Filter functionality
  final TextEditingController _searchController = TextEditingController();
  bool _isSearching = false;
  String _searchQuery = '';
  String _selectedFilter = 'All';
  final List<String> _filterOptions = ['All', 'To Pay', 'To Receive', 'Recent', 'High Balance'];

  // Statistics
  double _totalReceivable = 0.0;
  double _totalPayable = 0.0;
  int _totalParties = 0;
  int _totalTransactions = 0;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );
    _fabAnimationController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.elasticOut),
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
    _fabScaleAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fabAnimationController, curve: Curves.elasticOut),
    );

    // Start animations
    _animationController.forward();
    Future.delayed(const Duration(milliseconds: 800), () {
      _fabAnimationController.forward();
    });

    _loadStatistics();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _animationController.dispose();
    _fabAnimationController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadStatistics() async {
    try {
      // Load parties statistics
      final partiesSnapshot = await _firestore.collection('parties').get();
      double receivable = 0.0;
      double payable = 0.0;

      for (var doc in partiesSnapshot.docs) {
        final data = doc.data();
        final balance = (data['openingBalance'] ?? 0.0).toDouble();
        final balanceType = data['balanceType'] ?? 'To Pay';

        if (balanceType == 'To Receive') {
          receivable += balance;
        } else {
          payable += balance;
        }
      }

      // Load transactions statistics
      final transactionsSnapshot = await _firestore.collection('transactions').get();

      setState(() {
        _totalReceivable = receivable;
        _totalPayable = payable;
        _totalParties = partiesSnapshot.docs.length;
        _totalTransactions = transactionsSnapshot.docs.length;
      });
    } catch (e) {
      print('Error loading statistics: $e');
    }
  }

  void _addNewTransaction() {
    _showAddTransactionDialog();
  }

  void _showAddTransactionDialog() {
    final TextEditingController amountController = TextEditingController();
    final TextEditingController descriptionController = TextEditingController();
    final TextEditingController invoiceController = TextEditingController();
    String? selectedPartyId;
    String selectedPartyName = '';
    String transactionType = 'SALE';
    DateTime selectedDate = DateTime.now();
    bool isLoading = false;

    showGeneralDialog(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.black.withOpacity(0.7),
      transitionDuration: const Duration(milliseconds: 400),
      pageBuilder: (context, animation, secondaryAnimation) {
        return StatefulBuilder(
          builder: (context, setDialogState) => AnimatedBuilder(
            animation: animation,
            builder: (context, child) {
              return Transform.scale(
                scale: animation.value,
                child: Dialog(
                  backgroundColor: Colors.transparent,
                  insetPadding: const EdgeInsets.all(16),
                  child: Container(
                    constraints: const BoxConstraints(maxHeight: 600),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          Color(0xFFFFFFFF),
                          Color(0xFFF8FAFC),
                          Color(0xFFEDF2F7),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(32),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.25),
                          blurRadius: 40,
                          offset: const Offset(0, 20),
                        ),
                        BoxShadow(
                          color: const Color(0xFF667EEA).withOpacity(0.1),
                          blurRadius: 60,
                          offset: const Offset(0, -10),
                        ),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(32),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // Header with gradient background
                          Container(
                            padding: const EdgeInsets.all(20),
                            decoration: const BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                colors: [
                                  Color(0xFF667EEA),
                                  Color(0xFF764BA2),
                                  Color(0xFF667EEA),
                                ],
                              ),
                            ),
                            child: Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withOpacity(0.2),
                                    borderRadius: BorderRadius.circular(16),
                                    border: Border.all(
                                      color: Colors.white.withOpacity(0.3),
                                      width: 2,
                                    ),
                                  ),
                                  child: const Icon(
                                    Icons.receipt_long_rounded,
                                    color: Colors.white,
                                    size: 24,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                const Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'New Transaction',
                                        style: TextStyle(
                                          fontSize: 20,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.white,
                                        ),
                                      ),
                                      Text(
                                        'Create a new sale or purchase entry',
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: Colors.white70,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                GestureDetector(
                                  onTap: () => Navigator.pop(context),
                                  child: Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: Colors.white.withOpacity(0.2),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: const Icon(
                                      Icons.close_rounded,
                                      color: Colors.white,
                                      size: 20,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),

                          // Scrollable Form Content
                          Flexible(
                            child: SingleChildScrollView(
                              padding: const EdgeInsets.all(20),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // Transaction Type Selection
                                  const Text(
                                    'Transaction Type',
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.bold,
                                      color: Color(0xFF2D3748),
                                    ),
                                  ),
                                  const SizedBox(height: 12),
                                  Row(
                                    children: [
                                      Expanded(
                                        child: GestureDetector(
                                          onTap: () => setDialogState(() => transactionType = 'SALE'),
                                          child: AnimatedContainer(
                                            duration: const Duration(milliseconds: 300),
                                            padding: const EdgeInsets.all(16),
                                            decoration: BoxDecoration(
                                              gradient: transactionType == 'SALE'
                                                  ? const LinearGradient(
                                                colors: [Color(0xFF10B981), Color(0xFF059669)],
                                              )
                                                  : null,
                                              color: transactionType != 'SALE'
                                                  ? const Color(0xFFF7FAFC)
                                                  : null,
                                              borderRadius: BorderRadius.circular(16),
                                              border: Border.all(
                                                color: transactionType == 'SALE'
                                                    ? Colors.transparent
                                                    : const Color(0xFFE2E8F0),
                                                width: 2,
                                              ),
                                              boxShadow: transactionType == 'SALE' ? [
                                                BoxShadow(
                                                  color: const Color(0xFF10B981).withOpacity(0.4),
                                                  blurRadius: 15,
                                                  offset: const Offset(0, 8),
                                                ),
                                              ] : null,
                                            ),
                                            child: Column(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                Icon(
                                                  Icons.trending_up_rounded,
                                                  color: transactionType == 'SALE'
                                                      ? Colors.white
                                                      : const Color(0xFF718096),
                                                  size: 24,
                                                ),
                                                const SizedBox(height: 6),
                                                Text(
                                                  'SALE',
                                                  style: TextStyle(
                                                    color: transactionType == 'SALE'
                                                        ? Colors.white
                                                        : const Color(0xFF718096),
                                                    fontWeight: FontWeight.bold,
                                                    fontSize: 14,
                                                  ),
                                                ),
                                                Text(
                                                  'Money In',
                                                  style: TextStyle(
                                                    color: transactionType == 'SALE'
                                                        ? Colors.white70
                                                        : const Color(0xFF9CA3AF),
                                                    fontSize: 10,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: GestureDetector(
                                          onTap: () => setDialogState(() => transactionType = 'PURCHASE'),
                                          child: AnimatedContainer(
                                            duration: const Duration(milliseconds: 300),
                                            padding: const EdgeInsets.all(16),
                                            decoration: BoxDecoration(
                                              gradient: transactionType == 'PURCHASE'
                                                  ? const LinearGradient(
                                                colors: [Color(0xFFF59E0B), Color(0xFFD97706)],
                                              )
                                                  : null,
                                              color: transactionType != 'PURCHASE'
                                                  ? const Color(0xFFF7FAFC)
                                                  : null,
                                              borderRadius: BorderRadius.circular(16),
                                              border: Border.all(
                                                color: transactionType == 'PURCHASE'
                                                    ? Colors.transparent
                                                    : const Color(0xFFE2E8F0),
                                                width: 2,
                                              ),
                                              boxShadow: transactionType == 'PURCHASE' ? [
                                                BoxShadow(
                                                  color: const Color(0xFFF59E0B).withOpacity(0.4),
                                                  blurRadius: 15,
                                                  offset: const Offset(0, 8),
                                                ),
                                              ] : null,
                                            ),
                                            child: Column(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                Icon(
                                                  Icons.trending_down_rounded,
                                                  color: transactionType == 'PURCHASE'
                                                      ? Colors.white
                                                      : const Color(0xFF718096),
                                                  size: 24,
                                                ),
                                                const SizedBox(height: 6),
                                                Text(
                                                  'PURCHASE',
                                                  style: TextStyle(
                                                    color: transactionType == 'PURCHASE'
                                                        ? Colors.white
                                                        : const Color(0xFF718096),
                                                    fontWeight: FontWeight.bold,
                                                    fontSize: 14,
                                                  ),
                                                ),
                                                Text(
                                                  'Money Out',
                                                  style: TextStyle(
                                                    color: transactionType == 'PURCHASE'
                                                        ? Colors.white70
                                                        : const Color(0xFF9CA3AF),
                                                    fontSize: 10,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 16),

                                  // Party Selection
                                  _buildFormField(
                                    label: 'Select Party',
                                    isRequired: true,
                                    child: StreamBuilder<QuerySnapshot>(
                                      stream: _firestore.collection('parties').snapshots(),
                                      builder: (context, snapshot) {
                                        if (!snapshot.hasData) {
                                          return Container(
                                            padding: const EdgeInsets.all(16),
                                            decoration: BoxDecoration(
                                              color: Colors.white,
                                              borderRadius: BorderRadius.circular(12),
                                              border: Border.all(color: const Color(0xFFE2E8F0), width: 2),
                                            ),
                                            child: const Row(
                                              children: [
                                                SizedBox(
                                                  width: 16,
                                                  height: 16,
                                                  child: CircularProgressIndicator(strokeWidth: 2),
                                                ),
                                                SizedBox(width: 12),
                                                Text('Loading parties...'),
                                              ],
                                            ),
                                          );
                                        }

                                        return Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 16),
                                          decoration: BoxDecoration(
                                            color: Colors.white,
                                            borderRadius: BorderRadius.circular(12),
                                            border: Border.all(color: const Color(0xFFE2E8F0), width: 2),
                                            boxShadow: [
                                              BoxShadow(
                                                color: Colors.black.withOpacity(0.05),
                                                blurRadius: 8,
                                                offset: const Offset(0, 2),
                                              ),
                                            ],
                                          ),
                                          child: DropdownButton<String>(
                                            isExpanded: true,
                                            underline: Container(),
                                            hint: const Row(
                                              children: [
                                                Icon(Icons.person_outline, color: Color(0xFF667EEA), size: 20),
                                                SizedBox(width: 8),
                                                Text('Choose a party', style: TextStyle(fontSize: 14)),
                                              ],
                                            ),
                                            value: selectedPartyId,
                                            items: snapshot.data!.docs.map((doc) {
                                              final data = doc.data() as Map<String, dynamic>;
                                              return DropdownMenuItem<String>(
                                                value: doc.id,
                                                child: Row(
                                                  children: [
                                                    Container(
                                                      width: 8,
                                                      height: 8,
                                                      decoration: const BoxDecoration(
                                                        gradient: LinearGradient(
                                                          colors: [Color(0xFF667EEA), Color(0xFF764BA2)],
                                                        ),
                                                        shape: BoxShape.circle,
                                                      ),
                                                    ),
                                                    const SizedBox(width: 8),
                                                    Expanded(
                                                      child: Text(
                                                        data['partyName'] ?? 'Unknown',
                                                        style: const TextStyle(fontSize: 14),
                                                        overflow: TextOverflow.ellipsis,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              );
                                            }).toList(),
                                            onChanged: (value) {
                                              setDialogState(() {
                                                selectedPartyId = value;
                                                final selectedDoc = snapshot.data!.docs.firstWhere((doc) => doc.id == value);
                                                final data = selectedDoc.data() as Map<String, dynamic>;
                                                selectedPartyName = data['partyName'] ?? 'Unknown';
                                              });
                                            },
                                          ),
                                        );
                                      },
                                    ),
                                  ),

                                  // Amount and Invoice Number Row
                                  Row(
                                    children: [
                                      Expanded(
                                        flex: 2,
                                        child: _buildFormField(
                                          label: 'Amount',
                                          isRequired: true,
                                          child: _buildTextField(
                                            controller: amountController,
                                            hintText: '0.00',
                                            keyboardType: TextInputType.number,
                                            prefixIcon: Icons.currency_rupee_rounded,
                                            prefixIconColor: const Color(0xFF10B981),
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: _buildFormField(
                                          label: 'Invoice #',
                                          child: _buildTextField(
                                            controller: invoiceController,
                                            hintText: 'INV001',
                                            prefixIcon: Icons.receipt_outlined,
                                            prefixIconColor: const Color(0xFF667EEA),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),

                                  // Description
                                  _buildFormField(
                                    label: 'Description',
                                    child: _buildTextField(
                                      controller: descriptionController,
                                      hintText: 'Add transaction details...',
                                      maxLines: 2,
                                      prefixIcon: Icons.description_outlined,
                                      prefixIconColor: const Color(0xFF8B5CF6),
                                    ),
                                  ),

                                  // Date Selection
                                  _buildFormField(
                                    label: 'Transaction Date',
                                    child: GestureDetector(
                                      onTap: () async {
                                        final date = await showDatePicker(
                                          context: context,
                                          initialDate: selectedDate,
                                          firstDate: DateTime(2020),
                                          lastDate: DateTime(2030),
                                          builder: (context, child) {
                                            return Theme(
                                              data: Theme.of(context).copyWith(
                                                colorScheme: const ColorScheme.light(
                                                  primary: Color(0xFF667EEA),
                                                  onPrimary: Colors.white,
                                                ),
                                              ),
                                              child: child!,
                                            );
                                          },
                                        );
                                        if (date != null) {
                                          setDialogState(() => selectedDate = date);
                                        }
                                      },
                                      child: Container(
                                        padding: const EdgeInsets.all(16),
                                        decoration: BoxDecoration(
                                          color: Colors.white,
                                          borderRadius: BorderRadius.circular(12),
                                          border: Border.all(color: const Color(0xFFE2E8F0), width: 2),
                                          boxShadow: [
                                            BoxShadow(
                                              color: Colors.black.withOpacity(0.05),
                                              blurRadius: 8,
                                              offset: const Offset(0, 2),
                                            ),
                                          ],
                                        ),
                                        child: Row(
                                          children: [
                                            const Icon(Icons.calendar_today_rounded, color: Color(0xFF667EEA), size: 20),
                                            const SizedBox(width: 12),
                                            Text(
                                              DateFormat('dd MMM, yyyy').format(selectedDate),
                                              style: const TextStyle(
                                                fontSize: 14,
                                                fontWeight: FontWeight.w600,
                                              ),
                                            ),
                                            const Spacer(),
                                            const Icon(Icons.arrow_drop_down_rounded, color: Color(0xFF9CA3AF), size: 20),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),

                                  const SizedBox(height: 20),

                                  // Action Buttons
                                  Row(
                                    children: [
                                      Expanded(
                                        child: OutlinedButton(
                                          onPressed: isLoading ? null : () => Navigator.pop(context),
                                          style: OutlinedButton.styleFrom(
                                            padding: const EdgeInsets.symmetric(vertical: 16),
                                            side: const BorderSide(color: Color(0xFFE2E8F0), width: 2),
                                            shape: RoundedRectangleBorder(
                                              borderRadius: BorderRadius.circular(12),
                                            ),
                                          ),
                                          child: const Text(
                                            'Cancel',
                                            style: TextStyle(
                                              color: Color(0xFF718096),
                                              fontWeight: FontWeight.bold,
                                              fontSize: 14,
                                            ),
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Container(
                                          decoration: BoxDecoration(
                                            gradient: const LinearGradient(
                                              colors: [Color(0xFF667EEA), Color(0xFF764BA2)],
                                            ),
                                            borderRadius: BorderRadius.circular(12),
                                            boxShadow: [
                                              BoxShadow(
                                                color: const Color(0xFF667EEA).withOpacity(0.5),
                                                blurRadius: 15,
                                                offset: const Offset(0, 8),
                                              ),
                                            ],
                                          ),
                                          child: ElevatedButton(
                                            onPressed: isLoading ? null : () async {
                                              if (selectedPartyId == null || amountController.text.isEmpty) {
                                                _showSnackBar(
                                                  'Please fill all required fields',
                                                  Colors.red,
                                                  Icons.error_outline,
                                                );
                                                return;
                                              }

                                              setDialogState(() => isLoading = true);

                                              try {
                                                final user = _auth.currentUser;
                                                String userId = user?.uid ?? 'anonymous_user_${DateTime.now().millisecondsSinceEpoch}';
                                                final amount = double.parse(amountController.text);
                                                double balance = transactionType == 'PURCHASE' ? -amount : amount;

                                                await _firestore.collection('transactions').add({
                                                  'partyId': selectedPartyId,
                                                  'partyName': selectedPartyName,
                                                  'type': transactionType,
                                                  'amount': amount,
                                                  'balance': balance,
                                                  'description': descriptionController.text.trim(),
                                                  'invoiceNumber': invoiceController.text.trim(),
                                                  'date': Timestamp.fromDate(selectedDate),
                                                  'userId': userId,
                                                  'createdAt': Timestamp.now(),
                                                  'updatedAt': Timestamp.now(),
                                                });

                                                Navigator.pop(context);
                                                _showSnackBar(
                                                  '$transactionType added successfully!',
                                                  const Color(0xFF10B981),
                                                  Icons.check_circle,
                                                );
                                                _loadStatistics(); // Refresh statistics
                                              } catch (e) {
                                                _showSnackBar(
                                                  'Error: $e',
                                                  Colors.red,
                                                  Icons.error_outline,
                                                );
                                              } finally {
                                                setDialogState(() => isLoading = false);
                                              }
                                            },
                                            style: ElevatedButton.styleFrom(
                                              backgroundColor: Colors.transparent,
                                              shadowColor: Colors.transparent,
                                              padding: const EdgeInsets.symmetric(vertical: 16),
                                              shape: RoundedRectangleBorder(
                                                borderRadius: BorderRadius.circular(12),
                                              ),
                                            ),
                                            child: isLoading
                                                ? const SizedBox(
                                              width: 20,
                                              height: 20,
                                              child: CircularProgressIndicator(
                                                strokeWidth: 2,
                                                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                              ),
                                            )
                                                : const Text(
                                              'Save Transaction',
                                              style: TextStyle(
                                                color: Colors.white,
                                                fontWeight: FontWeight.bold,
                                                fontSize: 14,
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
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildFormField({
    required String label,
    required Widget child,
    bool isRequired = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Row(
            children: [
              Text(
                label,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF2D3748),
                ),
              ),
              if (isRequired) ...[
                const SizedBox(width: 4),
                const Text(
                  '*',
                  style: TextStyle(
                    color: Color(0xFFEF4444),
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ],
          ),
        ),
        child,
        const SizedBox(height: 16),
      ],
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hintText,
    TextInputType keyboardType = TextInputType.text,
    int maxLines = 1,
    IconData? prefixIcon,
    Color? prefixIconColor,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0), width: 2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: TextFormField(
        controller: controller,
        keyboardType: keyboardType,
        maxLines: maxLines,
        style: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
        ),
        decoration: InputDecoration(
          border: InputBorder.none,
          contentPadding: const EdgeInsets.all(16),
          hintText: hintText,
          hintStyle: const TextStyle(
            color: Color(0xFF9CA3AF),
            fontWeight: FontWeight.normal,
            fontSize: 14,
          ),
          prefixIcon: prefixIcon != null
              ? Padding(
            padding: const EdgeInsets.all(12),
            child: Icon(
              prefixIcon,
              color: prefixIconColor ?? const Color(0xFF667EEA),
              size: 20,
            ),
          )
              : null,
        ),
      ),
    );
  }

  void _showSnackBar(String message, Color color, IconData icon) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(icon, color: Colors.white, size: 20),
            const SizedBox(width: 12),
            Expanded(child: Text(message, style: const TextStyle(fontSize: 14))),
          ],
        ),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        margin: const EdgeInsets.all(16),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  void _showShareOptions(Map<String, dynamic> transactionData) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Colors.white, Color(0xFFF8FAFC)],
          ),
          borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
          boxShadow: [
            BoxShadow(
              color: Color(0x3F000000),
              blurRadius: 20,
              offset: Offset(0, -4),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 50,
              height: 5,
              decoration: BoxDecoration(
                color: const Color(0xFFE2E8F0),
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'Share Transaction',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Color(0xFF2D3748),
              ),
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildShareOption(
                  icon: Icons.picture_as_pdf_rounded,
                  label: 'PDF',
                  color: const Color(0xFFEF4444),
                  onTap: () => _generateTransactionPDF(transactionData),
                ),
                _buildShareOption(
                  icon: Icons.print_rounded,
                  label: 'Print',
                  color: const Color(0xFF667EEA),
                  onTap: () => _printTransaction(transactionData),
                ),
                _buildShareOption(
                  icon: Icons.message_rounded,
                  label: 'WhatsApp',
                  color: const Color(0xFF25D366),
                  onTap: () => _shareToWhatsApp(transactionData),
                ),
                _buildShareOption(
                  icon: Icons.share_rounded,
                  label: 'More',
                  color: const Color(0xFF8B5CF6),
                  onTap: () => _shareToOthers(transactionData),
                ),
              ],
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildShareOption({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [color, color.withOpacity(0.8)],
              ),
              borderRadius: BorderRadius.circular(18),
              boxShadow: [
                BoxShadow(
                  color: color.withOpacity(0.3),
                  blurRadius: 12,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Icon(icon, color: Colors.white, size: 28),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: Color(0xFF4A5568),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _generateTransactionPDF(Map<String, dynamic> data) async {
    final pdf = pw.Document();

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Header(
                level: 0,
                child: pw.Text('Transaction Receipt', style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold)),
              ),
              pw.SizedBox(height: 20),
              _buildPdfRow('Transaction Type', data['type'] ?? 'N/A'),
              _buildPdfRow('Party Name', data['partyName'] ?? 'N/A'),
              _buildPdfRow('Amount', '₹${data['amount']?.toString() ?? '0.0'}'),
              _buildPdfRow('Date', DateFormat('dd/MM/yyyy').format((data['date'] as Timestamp).toDate())),
              _buildPdfRow('Invoice Number', data['invoiceNumber'] ?? 'N/A'),
              _buildPdfRow('Description', data['description'] ?? 'N/A'),
              pw.SizedBox(height: 40),
              pw.Text('Generated on ${DateFormat('dd/MM/yyyy HH:mm').format(DateTime.now())}',
                  style: const pw.TextStyle(fontSize: 12, color: PdfColors.grey)),
            ],
          );
        },
      ),
    );

    try {
      final directory = await getApplicationDocumentsDirectory();
      final file = File('${directory.path}/transaction_${data['partyName']}_${DateTime.now().millisecondsSinceEpoch}.pdf');
      await file.writeAsBytes(await pdf.save());

      Navigator.pop(context);
      _showSnackBar('PDF saved successfully!', Colors.green, Icons.check_circle);

      // Share the PDF
      Share.shareXFiles([XFile(file.path)], text: 'Transaction Receipt for ${data['partyName']}');
    } catch (e) {
      _showSnackBar('Error generating PDF: $e', Colors.red, Icons.error_outline);
    }
  }

  pw.Widget _buildPdfRow(String label, String value) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 8),
      child: pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.SizedBox(
            width: 150,
            child: pw.Text(
              label,
              style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
            ),
          ),
          pw.SizedBox(width: 20),
          pw.Expanded(
            child: pw.Text(value),
          ),
        ],
      ),
    );
  }

  Future<void> _printTransaction(Map<String, dynamic> data) async {
    final pdf = pw.Document();

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Header(
                level: 0,
                child: pw.Text('Transaction Receipt', style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold)),
              ),
              pw.SizedBox(height: 20),
              _buildPdfRow('Transaction Type', data['type'] ?? 'N/A'),
              _buildPdfRow('Party Name', data['partyName'] ?? 'N/A'),
              _buildPdfRow('Amount', '₹${data['amount']?.toString() ?? '0.0'}'),
              _buildPdfRow('Date', DateFormat('dd/MM/yyyy').format((data['date'] as Timestamp).toDate())),
              _buildPdfRow('Invoice Number', data['invoiceNumber'] ?? 'N/A'),
              _buildPdfRow('Description', data['description'] ?? 'N/A'),
              pw.SizedBox(height: 40),
              pw.Text('Generated on ${DateFormat('dd/MM/yyyy HH:mm').format(DateTime.now())}',
                  style: const pw.TextStyle(fontSize: 12, color: PdfColors.grey)),
            ],
          );
        },
      ),
    );

    try {
      Navigator.pop(context);
      await Printing.layoutPdf(
        onLayout: (PdfPageFormat format) async => pdf.save(),
        name: 'transaction_${data['partyName']}_${DateTime.now().millisecondsSinceEpoch}.pdf',
      );
    } catch (e) {
      _showSnackBar('Error printing: $e', Colors.red, Icons.error_outline);
    }
  }

  void _shareToWhatsApp(Map<String, dynamic> data) {
    Navigator.pop(context);
    final message = '''
🧾 *Transaction Receipt*

📋 Type: ${data['type']}
👤 Party: ${data['partyName']}
💰 Amount: ₹${data['amount']}
📅 Date: ${DateFormat('dd MMM, yyyy').format((data['date'] as Timestamp).toDate())}
🧾 Invoice: ${data['invoiceNumber'] ?? 'N/A'}
${data['description'].isNotEmpty ? '📝 Description: ${data['description']}' : ''}

Generated by Business Management System
    ''';

    Clipboard.setData(ClipboardData(text: message));
    _showSnackBar(
      'Transaction details copied! Open WhatsApp to share',
      const Color(0xFF25D366),
      Icons.message,
    );
  }

  void _shareToOthers(Map<String, dynamic> data) {
    Navigator.pop(context);
    final message = '''
Transaction Receipt:
Type: ${data['type']}
Party: ${data['partyName']}
Amount: ₹${data['amount']}
Date: ${DateFormat('dd MMM, yyyy').format((data['date'] as Timestamp).toDate())}
Invoice: ${data['invoiceNumber'] ?? 'N/A'}
${data['description'].isNotEmpty ? 'Description: ${data['description']}' : ''}
    ''';

    Share.share(message, subject: 'Transaction Receipt for ${data['partyName']}');
  }

  void _showFilterOptions() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Colors.white, Color(0xFFF8FAFC)],
          ),
          borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 50,
              height: 5,
              decoration: BoxDecoration(
                color: const Color(0xFFE2E8F0),
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'Filter Options',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Color(0xFF2D3748),
              ),
            ),
            const SizedBox(height: 24),
            ..._filterOptions.map((option) => ListTile(
              leading: Radio<String>(
                value: option,
                groupValue: _selectedFilter,
                onChanged: (value) {
                  setState(() {
                    _selectedFilter = value!;
                  });
                  Navigator.pop(context);
                },
                activeColor: const Color(0xFF667EEA),
              ),
              title: Text(
                option,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              onTap: () {
                setState(() {
                  _selectedFilter = option;
                });
                Navigator.pop(context);
              },
            )),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF0F4F8),
      body: NestedScrollView(
        headerSliverBuilder: (context, innerBoxIsScrolled) {
          return [
            SliverAppBar(
              expandedHeight: _isSearching ? 200 : 160,
              floating: false,
              pinned: true,
              backgroundColor: Colors.white,
              elevation: 0,
              automaticallyImplyLeading: false,
              flexibleSpace: FlexibleSpaceBar(
                background: Column(
                  children: [
                    // App Bar Content
                    SafeArea(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        child: Row(
                          children: [
                            AnimatedBuilder(
                              animation: _fadeAnimation,
                              builder: (context, child) {
                                return Opacity(
                                  opacity: _fadeAnimation.value,
                                  child: ShaderMask(
                                    shaderCallback: (bounds) => const LinearGradient(
                                      colors: [Color(0xFF667EEA), Color(0xFF764BA2)],
                                    ).createShader(bounds),
                                    child: const Text(
                                      'Business Manager',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 24,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ),
                                );
                              },
                            ),
                            const Spacer(),
                            IconButton(
                              icon: Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFF1F5F9),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Icon(
                                  _isSearching ? Icons.close : Icons.search,
                                  color: const Color(0xFF4A5568),
                                  size: 20,
                                ),
                              ),
                              onPressed: () {
                                setState(() {
                                  _isSearching = !_isSearching;
                                  if (!_isSearching) {
                                    _searchController.clear();
                                    _searchQuery = '';
                                  }
                                });
                              },
                            ),
                            IconButton(
                              icon: Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFF1F5F9),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: const Icon(Icons.filter_list, color: Color(0xFF4A5568), size: 20),
                              ),
                              onPressed: _showFilterOptions,
                            ),
                            IconButton(
                              icon: Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFF1F5F9),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: const Icon(Icons.settings_outlined, color: Color(0xFF4A5568), size: 20),
                              ),
                              onPressed: () {
                                _showSnackBar('Settings will be available soon', Colors.blue, Icons.info);
                              },
                            ),
                          ],
                        ),
                      ),
                    ),

                    // Search Bar
                    if (_isSearching)
                      Container(
                        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.1),
                              blurRadius: 10,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: TextField(
                          controller: _searchController,
                          decoration: const InputDecoration(
                            hintText: 'Search parties or transactions...',
                            prefixIcon: Icon(Icons.search, color: Color(0xFF667EEA)),
                            border: InputBorder.none,
                            contentPadding: EdgeInsets.all(16),
                          ),
                          onChanged: (value) {
                            setState(() {
                              _searchQuery = value;
                            });
                          },
                        ),
                      ),

                    // Tab Bar
                    Container(
                      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 15,
                            offset: const Offset(0, 5),
                          ),
                        ],
                      ),
                      child: TabBar(
                        controller: _tabController,
                        tabs: const [
                          Tab(
                            child: Padding(
                              padding: EdgeInsets.symmetric(vertical: 12),
                              child: Text('Transactions'),
                            ),
                          ),
                          Tab(
                            child: Padding(
                              padding: EdgeInsets.symmetric(vertical: 12),
                              child: Text('Parties'),
                            ),
                          ),
                        ],
                        indicator: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFF667EEA), Color(0xFF764BA2)],
                          ),
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF667EEA).withOpacity(0.4),
                              blurRadius: 12,
                              offset: const Offset(0, 6),
                            ),
                          ],
                        ),
                        indicatorSize: TabBarIndicatorSize.tab,
                        labelColor: Colors.white,
                        unselectedLabelColor: const Color(0xFF718096),
                        labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                        dividerColor: Colors.transparent,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ];
        },
        body: Column(
          children: [
            // Statistics Dashboard
            AnimatedBuilder(
              animation: _scaleAnimation,
              builder: (context, child) {
                return Transform.scale(
                  scale: _scaleAnimation.value,
                  child: Container(
                    margin: const EdgeInsets.all(16),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [Color(0xFF667EEA), Color(0xFF764BA2)],
                      ),
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF667EEA).withOpacity(0.3),
                          blurRadius: 15,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        const Text(
                          'Business Overview',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Expanded(
                              child: _buildStatCard(
                                'To Receive',
                                '₹${_totalReceivable.toStringAsFixed(0)}',
                                Icons.trending_up_rounded,
                                const Color(0xFF10B981),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _buildStatCard(
                                'To Pay',
                                '₹${_totalPayable.toStringAsFixed(0)}',
                                Icons.trending_down_rounded,
                                const Color(0xFFF59E0B),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: _buildStatCard(
                                'Total Parties',
                                _totalParties.toString(),
                                Icons.people_rounded,
                                const Color(0xFF8B5CF6),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _buildStatCard(
                                'Transactions',
                                _totalTransactions.toString(),
                                Icons.receipt_long_rounded,
                                const Color(0xFF3B82F6),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),

            // Tab Content
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildTransactionTab(),
                  _buildPartyTab(),
                ],
              ),
            ),
          ],
        ),
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
                onPressed: _addNewTransaction,
                backgroundColor: Colors.transparent,
                elevation: 0,
                icon: const Icon(Icons.add_rounded, color: Colors.white, size: 24),
                label: const Text(
                  'New Transaction',
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

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.2),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.white.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: Colors.white, size: 24),
          const SizedBox(height: 6),
          Text(
            value,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          Text(
            title,
            style: const TextStyle(
              fontSize: 10,
              color: Colors.white70,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildTransactionTab() {
    return Column(
      children: [
        // Quick Actions
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Colors.white, Color(0xFFF8FAFC)],
            ),
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 15,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Quick Actions',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF2D3748),
                ),
              ),
              const SizedBox(height: 12),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    _buildQuickAction(
                      icon: Icons.add_circle_rounded,
                      label: 'Add',
                      gradient: const LinearGradient(colors: [Color(0xFF667EEA), Color(0xFF764BA2)]),
                      onTap: _addNewTransaction,
                    ),
                    const SizedBox(width: 12),
                    _buildQuickAction(
                      icon: Icons.analytics_rounded,
                      label: 'Reports',
                      gradient: const LinearGradient(colors: [Color(0xFF10B981), Color(0xFF059669)]),
                      onTap: () => _showSnackBar('Reports feature coming soon', Colors.blue, Icons.info),
                    ),
                    const SizedBox(width: 12),
                    _buildQuickAction(
                      icon: Icons.file_download_rounded,
                      label: 'Export',
                      gradient: const LinearGradient(colors: [Color(0xFFF59E0B), Color(0xFFD97706)]),
                      onTap: () => _showSnackBar('Export feature coming soon', Colors.blue, Icons.info),
                    ),
                    const SizedBox(width: 12),
                    _buildQuickAction(
                      icon: Icons.backup_rounded,
                      label: 'Backup',
                      gradient: const LinearGradient(colors: [Color(0xFF8B5CF6), Color(0xFF7C3AED)]),
                      onTap: () => _showSnackBar('Backup feature coming soon', Colors.blue, Icons.info),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),

        // Transactions List
        Expanded(
          child: StreamBuilder<QuerySnapshot>(
            stream: _firestore
                .collection('transactions')
                .orderBy('createdAt', descending: true)
                .snapshots(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(
                  child: CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF667EEA)),
                    strokeWidth: 3,
                  ),
                );
              }

              if (snapshot.hasError) {
                return _buildErrorState('Error loading transactions');
              }

              if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                return _buildEmptyState(
                  icon: Icons.receipt_long_rounded,
                  title: 'No transactions yet',
                  subtitle: 'Start by adding your first transaction',
                  buttonText: 'Add Transaction',
                  onButtonPressed: _addNewTransaction,
                );
              }

              var docs = snapshot.data!.docs;

              // Apply search filter
              if (_searchQuery.isNotEmpty) {
                docs = docs.where((doc) {
                  final data = doc.data() as Map<String, dynamic>;
                  final partyName = (data['partyName'] ?? '').toString().toLowerCase();
                  final description = (data['description'] ?? '').toString().toLowerCase();
                  final type = (data['type'] ?? '').toString().toLowerCase();
                  return partyName.contains(_searchQuery.toLowerCase()) ||
                      description.contains(_searchQuery.toLowerCase()) ||
                      type.contains(_searchQuery.toLowerCase());
                }).toList();
              }

              // Apply filter
              if (_selectedFilter != 'All') {
                docs = docs.where((doc) {
                  final data = doc.data() as Map<String, dynamic>;
                  switch (_selectedFilter) {
                    case 'Recent':
                      final createdAt = data['createdAt'] as Timestamp?;
                      if (createdAt != null) {
                        final daysDiff = DateTime.now().difference(createdAt.toDate()).inDays;
                        return daysDiff <= 7;
                      }
                      return false;
                    default:
                      return true;
                  }
                }).toList();
              }

              return ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: docs.length,
                itemBuilder: (context, index) {
                  final doc = docs[index];
                  final data = doc.data() as Map<String, dynamic>;
                  return _buildTransactionCard(data, index + 1);
                },
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildPartyTab() {
    return Column(
      children: [
        // Quick Actions
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Colors.white, Color(0xFFF8FAFC)],
            ),
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 15,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Party Management',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF2D3748),
                ),
              ),
              const SizedBox(height: 12),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    _buildQuickAction(
                      icon: Icons.person_add_rounded,
                      label: 'Add Party',
                      gradient: const LinearGradient(colors: [Color(0xFF667EEA), Color(0xFF764BA2)]),
                      onTap: () => Navigator.pushNamed(context, '/add_party'),
                    ),
                    const SizedBox(width: 12),
                    _buildQuickAction(
                      icon: Icons.receipt_rounded,
                      label: 'Statements',
                      gradient: const LinearGradient(colors: [Color(0xFF10B981), Color(0xFF059669)]),
                      onTap: () => _showSnackBar('Statements feature coming soon', Colors.blue, Icons.info),
                    ),
                    const SizedBox(width: 12),
                    _buildQuickAction(
                      icon: Icons.import_export_rounded,
                      label: 'Import',
                      gradient: const LinearGradient(colors: [Color(0xFFF59E0B), Color(0xFFD97706)]),
                      onTap: () => _showSnackBar('Import feature coming soon', Colors.blue, Icons.info),
                    ),
                    const SizedBox(width: 12),
                    _buildQuickAction(
                      icon: Icons.sync_rounded,
                      label: 'Sync',
                      gradient: const LinearGradient(colors: [Color(0xFF8B5CF6), Color(0xFF7C3AED)]),
                      onTap: () => _showSnackBar('Sync feature coming soon', Colors.blue, Icons.info),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),

        // Parties List
        Expanded(
          child: StreamBuilder<QuerySnapshot>(
            stream: _firestore
                .collection('parties')
                .orderBy('createdAt', descending: true)
                .snapshots(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(
                  child: CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF667EEA)),
                    strokeWidth: 3,
                  ),
                );
              }

              if (snapshot.hasError) {
                return _buildErrorState('Error loading parties');
              }

              if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                return _buildEmptyState(
                  icon: Icons.people_outline,
                  title: 'No parties found',
                  subtitle: 'Add your first party to get started',
                  buttonText: 'Add Party',
                  onButtonPressed: () => Navigator.pushNamed(context, '/add_party'),
                );
              }

              var docs = snapshot.data!.docs;

              // Apply search filter
              if (_searchQuery.isNotEmpty) {
                docs = docs.where((doc) {
                  final data = doc.data() as Map<String, dynamic>;
                  final partyName = (data['partyName'] ?? '').toString().toLowerCase();
                  final contactNumber = (data['contactNumber'] ?? '').toString().toLowerCase();
                  final emailAddress = (data['emailAddress'] ?? '').toString().toLowerCase();
                  return partyName.contains(_searchQuery.toLowerCase()) ||
                      contactNumber.contains(_searchQuery.toLowerCase()) ||
                      emailAddress.contains(_searchQuery.toLowerCase());
                }).toList();
              }

              // Apply filter
              if (_selectedFilter != 'All') {
                docs = docs.where((doc) {
                  final data = doc.data() as Map<String, dynamic>;
                  switch (_selectedFilter) {
                    case 'To Pay':
                      return data['balanceType'] == 'To Pay';
                    case 'To Receive':
                      return data['balanceType'] == 'To Receive';
                    case 'High Balance':
                      final balance = (data['openingBalance'] ?? 0.0).toDouble();
                      return balance > 10000;
                    case 'Recent':
                      final createdAt = data['createdAt'] as Timestamp?;
                      if (createdAt != null) {
                        final daysDiff = DateTime.now().difference(createdAt.toDate()).inDays;
                        return daysDiff <= 7;
                      }
                      return false;
                    default:
                      return true;
                  }
                }).toList();
              }

              return ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: docs.length,
                itemBuilder: (context, index) {
                  final doc = docs[index];
                  final data = doc.data() as Map<String, dynamic>;
                  return _buildPartyCard(data, doc.id);
                },
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildQuickAction({
    required IconData icon,
    required String label,
    required LinearGradient gradient,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: SizedBox(
        width: 70,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                gradient: gradient,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: gradient.colors.first.withOpacity(0.3),
                    blurRadius: 12,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Icon(icon, color: Colors.white, size: 24),
            ),
            const SizedBox(height: 6),
            Text(
              label,
              style: const TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w600,
                color: Color(0xFF4A5568),
              ),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTransactionCard(Map<String, dynamic> data, int index) {
    final type = data['type'] ?? 'SALE';
    final isIncome = type == 'SALE';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Colors.white, Color(0xFFF8FAFC)],
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () => _showShareOptions(data),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: isIncome
                              ? [const Color(0xFF10B981), const Color(0xFF059669)]
                              : [const Color(0xFFF59E0B), const Color(0xFFD97706)],
                        ),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        isIncome ? Icons.trending_up_rounded : Icons.trending_down_rounded,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            data['partyName'] ?? 'Unknown',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF2D3748),
                            ),
                          ),
                          Text(
                            DateFormat('dd MMM, yyyy').format(
                              (data['date'] as Timestamp).toDate(),
                            ),
                            style: const TextStyle(
                              fontSize: 12,
                              color: Color(0xFF718096),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Text(
                      '#$index',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF718096),
                      ),
                    ),
                  ],
                ),
                if (data['description'] != null && data['description'].isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Text(
                    data['description'],
                    style: const TextStyle(
                      fontSize: 12,
                      color: Color(0xFF4A5568),
                      fontStyle: FontStyle.italic,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
                const SizedBox(height: 12),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: isIncome
                              ? [const Color(0xFF10B981).withOpacity(0.2), const Color(0xFF059669).withOpacity(0.2)]
                              : [const Color(0xFFF59E0B).withOpacity(0.2), const Color(0xFFD97706).withOpacity(0.2)],
                        ),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Text(
                        type,
                        style: TextStyle(
                          color: isIncome ? const Color(0xFF10B981) : const Color(0xFFF59E0B),
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const Spacer(),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          '₹ ${(data['amount'] ?? 0.0).toStringAsFixed(2)}',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: isIncome ? const Color(0xFF10B981) : const Color(0xFFF59E0B),
                          ),
                        ),
                        Text(
                          isIncome ? 'Money In' : 'Money Out',
                          style: const TextStyle(
                            fontSize: 10,
                            color: Color(0xFF718096),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    _buildActionButton(
                      Icons.picture_as_pdf_rounded,
                      const Color(0xFFEF4444),
                          () => _generateTransactionPDF(data),
                    ),
                    const SizedBox(width: 8),
                    _buildActionButton(
                      Icons.print_rounded,
                      const Color(0xFF667EEA),
                          () => _printTransaction(data),
                    ),
                    const SizedBox(width: 8),
                    _buildActionButton(
                      Icons.share_rounded,
                      const Color(0xFF10B981),
                          () => _showShareOptions(data),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPartyCard(Map<String, dynamic> data, String partyId) {
    final balance = (data['openingBalance'] ?? 0.0).toDouble();
    final balanceType = data['balanceType'] ?? 'To Pay';
    final isReceivable = balanceType == 'To Receive';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Colors.white, Color(0xFFF8FAFC)],
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () => _showPartyOptions(data, partyId),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: isReceivable
                          ? [const Color(0xFF10B981), const Color(0xFF059669)]
                          : [const Color(0xFFF59E0B), const Color(0xFFD97706)],
                    ),
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        data['partyName'] ?? 'Unknown',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF2D3748),
                        ),
                      ),
                      const SizedBox(height: 2),
                      if (data['contactNumber'] != null && data['contactNumber'].isNotEmpty)
                        Text(
                          data['contactNumber'],
                          style: const TextStyle(
                            fontSize: 12,
                            color: Color(0xFF718096),
                          ),
                        ),
                      Text(
                        DateFormat('dd MMM, yyyy').format(
                          (data['asOfDate'] as Timestamp).toDate(),
                        ),
                        style: const TextStyle(
                          fontSize: 10,
                          color: Color(0xFF9CA3AF),
                        ),
                      ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '₹ ${balance.toStringAsFixed(0)}',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: isReceivable ? const Color(0xFF10B981) : const Color(0xFFF59E0B),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      isReceivable ? "You'll Get" : "You'll Pay",
                      style: const TextStyle(
                        fontSize: 10,
                        color: Color(0xFF718096),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showPartyOptions(Map<String, dynamic> partyData, String partyId) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Colors.white, Color(0xFFF8FAFC)],
          ),
          borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
          boxShadow: [
            BoxShadow(
              color: Color(0x3F000000),
              blurRadius: 20,
              offset: Offset(0, -4),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 50,
              height: 5,
              decoration: BoxDecoration(
                color: const Color(0xFFE2E8F0),
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              partyData['partyName'] ?? 'Party Options',
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Color(0xFF2D3748),
              ),
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildShareOption(
                  icon: Icons.picture_as_pdf_rounded,
                  label: 'PDF',
                  color: const Color(0xFFEF4444),
                  onTap: () => _generatePartyPDF(partyData),
                ),
                _buildShareOption(
                  icon: Icons.print_rounded,
                  label: 'Print',
                  color: const Color(0xFF667EEA),
                  onTap: () => _printPartyDetails(partyData),
                ),
                _buildShareOption(
                  icon: Icons.share_rounded,
                  label: 'Share',
                  color: const Color(0xFF10B981),
                  onTap: () => _sharePartyDetails(partyData),
                ),
                _buildShareOption(
                  icon: Icons.edit_rounded,
                  label: 'Edit',
                  color: const Color(0xFF8B5CF6),
                  onTap: () => _editParty(partyData, partyId),
                ),
              ],
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Future<void> _generatePartyPDF(Map<String, dynamic> partyData) async {
    final pdf = pw.Document();

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Header(
                level: 0,
                child: pw.Text('Party Details', style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold)),
              ),
              pw.SizedBox(height: 20),
              _buildPdfRow('Party Name', partyData['partyName'] ?? 'N/A'),
              _buildPdfRow('Contact Number', partyData['contactNumber'] ?? 'N/A'),
              _buildPdfRow('Opening Balance', '₹${partyData['openingBalance']?.toString() ?? '0.0'}'),
              _buildPdfRow('Balance Type', partyData['balanceType'] ?? 'N/A'),
              _buildPdfRow('As of Date', DateFormat('dd/MM/yyyy').format((partyData['asOfDate'] as Timestamp).toDate())),
              _buildPdfRow('Billing Address', partyData['billingAddress'] ?? 'N/A'),
              _buildPdfRow('Email Address', partyData['emailAddress'] ?? 'N/A'),
              _buildPdfRow('GST Number', partyData['gstNumber'] ?? 'N/A'),
              _buildPdfRow('Credit Limit', '₹${partyData['creditLimit']?.toString() ?? '0.0'}'),
              pw.SizedBox(height: 40),
              pw.Text('Generated on ${DateFormat('dd/MM/yyyy HH:mm').format(DateTime.now())}',
                  style: const pw.TextStyle(fontSize: 12, color: PdfColors.grey)),
            ],
          );
        },
      ),
    );

    try {
      final directory = await getApplicationDocumentsDirectory();
      final file = File('${directory.path}/${partyData['partyName']}_details.pdf');
      await file.writeAsBytes(await pdf.save());

      Navigator.pop(context);
      _showSnackBar('PDF saved successfully!', Colors.green, Icons.check_circle);

      // Share the PDF
      Share.shareXFiles([XFile(file.path)], text: 'Party Details for ${partyData['partyName']}');
    } catch (e) {
      _showSnackBar('Error generating PDF: $e', Colors.red, Icons.error_outline);
    }
  }

  Future<void> _printPartyDetails(Map<String, dynamic> partyData) async {
    final pdf = pw.Document();

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Header(
                level: 0,
                child: pw.Text('Party Details', style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold)),
              ),
              pw.SizedBox(height: 20),
              _buildPdfRow('Party Name', partyData['partyName'] ?? 'N/A'),
              _buildPdfRow('Contact Number', partyData['contactNumber'] ?? 'N/A'),
              _buildPdfRow('Opening Balance', '₹${partyData['openingBalance']?.toString() ?? '0.0'}'),
              _buildPdfRow('Balance Type', partyData['balanceType'] ?? 'N/A'),
              _buildPdfRow('As of Date', DateFormat('dd/MM/yyyy').format((partyData['asOfDate'] as Timestamp).toDate())),
              _buildPdfRow('Billing Address', partyData['billingAddress'] ?? 'N/A'),
              _buildPdfRow('Email Address', partyData['emailAddress'] ?? 'N/A'),
              _buildPdfRow('GST Number', partyData['gstNumber'] ?? 'N/A'),
              _buildPdfRow('Credit Limit', '₹${partyData['creditLimit']?.toString() ?? '0.0'}'),
              pw.SizedBox(height: 40),
              pw.Text('Generated on ${DateFormat('dd/MM/yyyy HH:mm').format(DateTime.now())}',
                  style: const pw.TextStyle(fontSize: 12, color: PdfColors.grey)),
            ],
          );
        },
      ),
    );

    try {
      Navigator.pop(context);
      await Printing.layoutPdf(
        onLayout: (PdfPageFormat format) async => pdf.save(),
        name: '${partyData['partyName']}_details.pdf',
      );
    } catch (e) {
      _showSnackBar('Error printing: $e', Colors.red, Icons.error_outline);
    }
  }

  void _sharePartyDetails(Map<String, dynamic> partyData) {
    Navigator.pop(context);
    final message = '''
🏢 *Party Details*

👤 Name: ${partyData['partyName']}
📞 Contact: ${partyData['contactNumber']}
💰 Opening Balance: ₹${partyData['openingBalance']}
⚖️ Balance Type: ${partyData['balanceType']}
📅 As of Date: ${DateFormat('dd/MM/yyyy').format((partyData['asOfDate'] as Timestamp).toDate())}
📧 Email: ${partyData['emailAddress']}
🏛️ GST Number: ${partyData['gstNumber']}
💳 Credit Limit: ₹${partyData['creditLimit']}

Generated by Business Management App
    ''';

    Share.share(message, subject: 'Party Details for ${partyData['partyName']}');
  }

  void _editParty(Map<String, dynamic> partyData, String partyId) {
    Navigator.pop(context);
    _showSnackBar('Edit party feature coming soon', Colors.blue, Icons.info);
  }

  Widget _buildActionButton(IconData icon, Color color, VoidCallback onPressed) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: [color, color.withOpacity(0.8)]),
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.3),
            blurRadius: 6,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: IconButton(
        icon: Icon(icon, color: Colors.white, size: 16),
        onPressed: onPressed,
        padding: const EdgeInsets.all(8),
        constraints: const BoxConstraints(),
      ),
    );
  }

  Widget _buildEmptyState({
    required IconData icon,
    required String title,
    required String subtitle,
    required String buttonText,
    required VoidCallback onButtonPressed,
  }) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: const LinearGradient(colors: [Color(0xFF667EEA), Color(0xFF764BA2)]),
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF667EEA).withOpacity(0.3),
                    blurRadius: 15,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Icon(icon, size: 48, color: Colors.white),
            ),
            const SizedBox(height: 20),
            Text(
              title,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Color(0xFF2D3748),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              subtitle,
              style: const TextStyle(
                fontSize: 14,
                color: Color(0xFF718096),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            Container(
              decoration: BoxDecoration(
                gradient: const LinearGradient(colors: [Color(0xFF667EEA), Color(0xFF764BA2)]),
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF667EEA).withOpacity(0.4),
                    blurRadius: 12,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: ElevatedButton(
                onPressed: onButtonPressed,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.transparent,
                  shadowColor: Colors.transparent,
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text(
                  buttonText,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState(String message) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: const LinearGradient(colors: [Color(0xFFEF4444), Color(0xFFDC2626)]),
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Icon(Icons.error_outline, size: 40, color: Colors.white),
          ),
          const SizedBox(height: 16),
          Text(
            message,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Color(0xFF4A5568),
            ),
          ),
        ],
      ),
    );
  }
}