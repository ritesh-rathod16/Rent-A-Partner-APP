import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:razorpay_flutter/razorpay_flutter.dart';
import 'package:rent_a_partner/core/api/api_client.dart';
import 'package:rent_a_partner/core/theme/app_theme.dart';
import 'package:rent_a_partner/features/auth/repository/auth_repository.dart';

class WalletScreen extends ConsumerStatefulWidget {
  const WalletScreen({super.key});

  @override
  ConsumerState<WalletScreen> createState() => _WalletScreenState();
}

class _WalletScreenState extends ConsumerState<WalletScreen> {
  late Razorpay _razorpay;
  bool _isLoading = false;
  double _pendingAmount = 0;
  List<Map<String, dynamic>> _transactions = [];

  @override
  void initState() {
    super.initState();
    _razorpay = Razorpay();
    _razorpay.on(Razorpay.EVENT_PAYMENT_SUCCESS, _handlePaymentSuccess);
    _razorpay.on(Razorpay.EVENT_PAYMENT_ERROR, _handlePaymentError);
    _razorpay.on(Razorpay.EVENT_EXTERNAL_WALLET, _handleExternalWallet);
    _loadTransactions();
  }

  void _loadTransactions() async {
    try {
      final res = await ref.read(apiClientProvider).get('/auth/wallet/transactions');
      setState(() => _transactions = List<Map<String, dynamic>>.from(res.data));
    } catch (e) {
      debugPrint('Failed to load transactions: $e');
    }
  }

  void _handlePaymentSuccess(PaymentSuccessResponse response) async {
    setState(() => _isLoading = true);
    try {
      await ref.read(apiClientProvider).post('/auth/wallet/confirm', data: {
        'razorpay_order_id': response.orderId,
        'razorpay_payment_id': response.paymentId,
        'razorpay_signature': response.signature,
        'amount': _pendingAmount,
      });
      
      final updatedUser = await ref.read(authRepositoryProvider).getMe();
      ref.read(currentUserProvider.notifier).state = updatedUser;
      
      setState(() {
        _transactions.insert(0, {
          'title': 'Money Added',
          'amount': '+₹${_pendingAmount.toInt()}',
          'date': 'Just now',
          'isDebit': false
        });
      });
      
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Money added to wallet!')));
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Verification failed: $e')));
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _handlePaymentError(PaymentFailureResponse response) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Payment failed: ${response.message}')));
  }

  void _handleExternalWallet(ExternalWalletResponse response) {}

  void _addMoney() async {
    final amountController = TextEditingController();
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Add Money to Wallet'),
        content: TextField(
          controller: amountController,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(labelText: 'Amount (₹)', prefixText: '₹'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Proceed')),
        ],
      ),
    );

    if (confirm == true && amountController.text.isNotEmpty) {
      final amount = double.parse(amountController.text);
      _pendingAmount = amount;
      
      try {
        final res = await ref.read(apiClientProvider).post('/auth/wallet/add', data: {'amount': amount});
        
        var options = {
          'key': 'rzp_live_S3PqGffrDLRgtX',
          'amount': (amount * 100).toInt(),
          'name': 'Rent A Partner',
          'description': 'Wallet Top-up',
          'order_id': res.data['razorpay_order_id'],
          'prefill': {'contact': '', 'email': ref.read(currentUserProvider)?.email},
        };
        
        _razorpay.open(options);
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to initialize: $e')));
      }
    }
  }

  void _withdrawMoney() async {
    final amountController = TextEditingController();
    final upiController = TextEditingController();
    
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Withdraw Money'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: amountController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Amount (₹)', prefixText: '₹'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: upiController,
              decoration: const InputDecoration(labelText: 'UPI ID or Bank Details'),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Withdraw')),
        ],
      ),
    );

    if (confirm == true && amountController.text.isNotEmpty) {
      final amount = double.parse(amountController.text);
      final user = ref.read(currentUserProvider);
      
      if (amount > (user?.walletBalance ?? 0)) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Insufficient balance')));
        return;
      }

      setState(() => _isLoading = true);
      try {
        await ref.read(apiClientProvider).post('/auth/wallet/withdraw', data: {
          'amount': amount,
          'details': upiController.text,
        });
        
        final updatedUser = await ref.read(authRepositoryProvider).getMe();
        ref.read(currentUserProvider.notifier).state = updatedUser;
        
        setState(() {
          _transactions.insert(0, {
            'title': 'Withdrawal Request',
            'amount': '-₹${amount.toInt()}',
            'date': 'Just now',
            'isDebit': true
          });
        });

        if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Withdrawal request submitted!')));
      } catch (e) {
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Withdrawal failed: $e')));
      } finally {
        setState(() => _isLoading = false);
      }
    }
  }

  void _showStatement() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.7,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
        ),
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2)))),
            const SizedBox(height: 24),
            Text('Transaction History', style: GoogleFonts.poppins(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            Expanded(
              child: ListView.builder(
                itemCount: _transactions.length,
                itemBuilder: (context, index) {
                  final tx = _transactions[index];
                  return _transactionItem(tx['title'], tx['amount'], tx['date'], isDebit: tx['isDebit']);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _razorpay.clear();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(currentUserProvider);
    
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text('My Wallet', style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        foregroundColor: AppColors.darkNavy,
        elevation: 0,
      ),
      body: _isLoading 
        ? const Center(child: CircularProgressIndicator())
        : SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildBalanceCard(user?.walletBalance ?? 0.0),
                const SizedBox(height: 32),
                Text('Quick Actions', style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _actionItem(Icons.add_card, 'Add Money', onTap: _addMoney),
                    _actionItem(Icons.account_balance_wallet, 'Withdraw', onTap: _withdrawMoney),
                    _actionItem(Icons.history, 'Statement', onTap: _showStatement),
                  ],
                ),
                const SizedBox(height: 40),
                Text('Recent Transactions', style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 16),
                ..._transactions.take(3).map((tx) => _transactionItem(tx['title'], tx['amount'], tx['date'], isDebit: tx['isDebit'])),
                if (_transactions.length > 3)
                  Center(
                    child: TextButton(onPressed: _showStatement, child: const Text('View All Transactions', style: TextStyle(color: AppColors.primaryPink))),
                  ),
              ],
            ),
          ),
    );
  }

  Widget _buildBalanceCard(double balance) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF0F172A), Color(0xFF1E293B)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [BoxShadow(color: const Color(0xFF0F172A).withValues(alpha: 0.3), blurRadius: 20, offset: const Offset(0, 10))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Total Balance', style: TextStyle(color: Colors.white70, fontSize: 16)),
          const SizedBox(height: 8),
          Text('₹${balance.toInt()}', style: GoogleFonts.poppins(color: Colors.white, fontSize: 40, fontWeight: FontWeight.bold)),
          const SizedBox(height: 24),
          Row(
            children: [
              const Icon(Icons.verified, color: Colors.greenAccent, size: 16),
              const SizedBox(width: 8),
              Text('Secure Wallet', style: GoogleFonts.inter(color: Colors.white54, fontSize: 12)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _actionItem(IconData icon, String label, {VoidCallback? onTap}) {
    return InkWell(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(color: AppColors.softPink, borderRadius: BorderRadius.circular(16)),
            child: Icon(icon, color: AppColors.primaryPink),
          ),
          const SizedBox(height: 8),
          Text(label, style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  Widget _transactionItem(String title, String amount, String date, {bool isDebit = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: isDebit ? Colors.red.shade50 : Colors.green.shade50,
            child: Icon(isDebit ? Icons.arrow_outward : Icons.arrow_downward, color: isDebit ? Colors.red : Colors.green, size: 18),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: GoogleFonts.inter(fontWeight: FontWeight.bold)),
                Text(date, style: GoogleFonts.inter(fontSize: 12, color: Colors.grey)),
              ],
            ),
          ),
          Text(amount, style: GoogleFonts.poppins(fontWeight: FontWeight.bold, color: isDebit ? Colors.red : Colors.green)),
        ],
      ),
    );
  }
}
