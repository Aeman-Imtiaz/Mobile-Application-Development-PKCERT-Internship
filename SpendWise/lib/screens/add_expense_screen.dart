import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../db/database_helper.dart';
import '../services/categorization_service.dart';
import '../services/user_prefs_service.dart';
import '../services/notification_service.dart';
import 'scan_receipt_screen.dart';
import 'voice_expense_screen.dart';

class AddExpenseScreen extends StatefulWidget {
  final String initialType;
  const AddExpenseScreen({super.key, this.initialType = 'cash_out'});

  @override
  State<AddExpenseScreen> createState() => _AddExpenseScreenState();
}

class _AddExpenseScreenState extends State<AddExpenseScreen> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _contactController = TextEditingController();

  DateTime _selectedDate = DateTime.now();
  TimeOfDay _selectedTime = TimeOfDay.now();
  late String _type; // 'cash_in' or 'cash_out'
  String _paymentMode = 'Cash';
  bool _isSaving = false;

  final List<String> _paymentModes = ['Cash', 'Online', 'Bank', 'Card'];

  @override
  void initState() {
    super.initState();
    _type = widget.initialType;
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2023),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null) setState(() => _selectedDate = picked);
  }

  Future<void> _pickTime() async {
    final picked = await showTimePicker(context: context, initialTime: _selectedTime);
    if (picked != null) setState(() => _selectedTime = picked);
  }

  Future<void> _scanReceipt() async {
    final result = await Navigator.push<Map<String, dynamic>>(
      context,
      MaterialPageRoute(builder: (_) => const ScanReceiptScreen()),
    );

    if (result == null) return;

    final merchant = (result['merchant'] as String?)?.trim() ?? '';
    final note = (result['note'] as String?)?.trim() ?? '';
    final amount = result['amount'] as double?;
    final date = result['date'] as DateTime?;

    setState(() {
      if (amount != null) {
        _amountController.text = amount.toStringAsFixed(0);
      }
      if (note.isNotEmpty && merchant.isNotEmpty) {
        _descriptionController.text = '$merchant - $note';
      } else if (note.isNotEmpty) {
        _descriptionController.text = note;
      } else if (merchant.isNotEmpty) {
        _descriptionController.text = merchant;
      }
      if (merchant.isNotEmpty) {
        _contactController.text = merchant;
      }
      if (date != null) {
        _selectedDate = date;
      }
    });

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Receipt scanned — review the details below'),
          backgroundColor: Colors.indigo,
        ),
      );
    }
  }

  Future<void> _addByVoice() async {
    final result = await Navigator.push<Map<String, dynamic>>(
      context,
      MaterialPageRoute(builder: (_) => const VoiceExpenseScreen()),
    );

    if (result == null) return;

    final amount = result['amount'] as double?;
    final type = result['type'] as String?;
    final description = (result['description'] as String?)?.trim() ?? '';

    setState(() {
      if (type != null) _type = type;
      if (amount != null) _amountController.text = amount.toStringAsFixed(0);
      if (description.isNotEmpty) _descriptionController.text = description;
    });

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Voice se bhar diya — review kar ke save karein'),
          backgroundColor: Colors.indigo,
        ),
      );
    }
  }

  Future<void> _saveExpense() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);

    final description = _descriptionController.text.trim();
    final amount = double.parse(_amountController.text);
    final dateStr = DateFormat('yyyy-MM-dd').format(_selectedDate);

    String category;
    if (_type == 'cash_in') {
      category = 'Income';
    } else {
      category = await CategorizationService.categorize(description);
    }

    await DatabaseHelper.instance.insertExpense({
      'type': _type,
      'amount': amount,
      'description': description,
      'category': category,
      'paymentMode': _paymentMode,
      'contactName': _contactController.text.trim(),
      'date': dateStr,
    });

    // Check budgets only for Cash Out entries
    if (_type == 'cash_out') {
      await _checkBudgetsAndNotify(dateStr);
    }

    setState(() => _isSaving = false);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_type == 'cash_in' ? 'Cash In saved' : 'Saved as "$category"'),
          backgroundColor: _type == 'cash_in' ? Colors.green : Colors.indigo,
        ),
      );
      Navigator.pop(context, true);
    }
  }

  Future<void> _checkBudgetsAndNotify(String dateStr) async {
    // Daily budget check
    final dailyBudget = await UserPrefsService.getDailyBudget();
    if (dailyBudget != null && dailyBudget > 0) {
     final double todaySpent = await DatabaseHelper.instance.getTodaySpent(dateStr);
      if (todaySpent > dailyBudget) {
        await NotificationService.showBudgetAlert(
          title: '⚠️ Daily Budget Exceeded',
            body: 'Aap ne aaj Rs. ${todaySpent.toStringAsFixed(0)} kharch kar liye hain '
              '(budget: Rs. ${dailyBudget.toStringAsFixed(0)}).',
        );
      }
    }

    // Monthly budget check
    final monthlyBudget = await UserPrefsService.getMonthlyBudget();
    if (monthlyBudget != null && monthlyBudget > 0) {
      final totals = await DatabaseHelper.instance.getTotals();
      final monthSpent = totals['cashOut']!;
      if (monthSpent > monthlyBudget) {
        await NotificationService.showBudgetAlert(
          title: '🚨 Monthly Budget Exceeded',
          body: 'Is mahine Rs. ${monthSpent.toStringAsFixed(0)} kharch ho chuka hai '
              '(budget: Rs. ${monthlyBudget.toStringAsFixed(0)}).',
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isCashIn = _type == 'cash_in';
    final themeColor = isCashIn ? Colors.green : Colors.red;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F6FA),
      appBar: AppBar(
        title: Text(isCashIn ? 'Add Cash In Entry' : 'Add Cash Out Entry'),
        backgroundColor: themeColor,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Cash In / Cash Out Toggle
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(30),
                  boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 6)],
                ),
                padding: const EdgeInsets.all(4),
                child: Row(
                  children: [
                    Expanded(
                      child: GestureDetector(
                        onTap: () => setState(() => _type = 'cash_in'),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          decoration: BoxDecoration(
                            color: isCashIn ? Colors.green : Colors.transparent,
                            borderRadius: BorderRadius.circular(26),
                          ),
                          child: Text(
                            'Cash In',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: isCashIn ? Colors.white : Colors.grey.shade700,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                    ),
                    Expanded(
                      child: GestureDetector(
                        onTap: () => setState(() => _type = 'cash_out'),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          decoration: BoxDecoration(
                            color: !isCashIn ? Colors.red : Colors.transparent,
                            borderRadius: BorderRadius.circular(26),
                          ),
                          child: Text(
                            'Cash Out',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: !isCashIn ? Colors.white : Colors.grey.shade700,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

             // Voice Add + Scan Receipt (available for both Cash In and Cash Out)
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _addByVoice,
                      icon: const Icon(Icons.mic_none),
                      label: const Text('Voice Add'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.indigo,
                        side: const BorderSide(color: Colors.indigo),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _scanReceipt,
                      icon: const Icon(Icons.document_scanner_outlined),
                      label: const Text('Scan Receipt'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.indigo,
                        side: const BorderSide(color: Colors.indigo),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Date & Time Row
              Row(
                children: [
                  Expanded(
                    child: ListTile(
                      tileColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      leading: const Icon(Icons.calendar_today, size: 20),
                      title: Text(DateFormat('dd MMM yyyy').format(_selectedDate)),
                      onTap: _pickDate,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: ListTile(
                      tileColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      leading: const Icon(Icons.access_time, size: 20),
                      title: Text(_selectedTime.format(context)),
                      onTap: _pickTime,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Amount
              TextFormField(
                controller: _amountController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                decoration: InputDecoration(
                  labelText: 'Amount',
                  prefixText: 'Rs. ',
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) return 'Enter an amount';
                  if (double.tryParse(value) == null) return 'Enter a valid number';
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Description
              TextFormField(
                controller: _descriptionController,
                decoration: InputDecoration(
                  labelText: 'Description',
                  hintText: isCashIn ? 'e.g. Salary, Refund' : 'e.g. Pizza with friends',
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) return 'Enter a description';
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Contact Name (optional)
              TextFormField(
                controller: _contactController,
                decoration: InputDecoration(
                  labelText: 'Contact Name (optional)',
                  hintText: 'e.g. Ali, Landlord',
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                ),
              ),
              const SizedBox(height: 16),

              // Payment Mode
              DropdownButtonFormField<String>(
                initialValue: _paymentMode,
                decoration: InputDecoration(
                  labelText: 'Payment Mode',
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                ),
                items: _paymentModes
                    .map((mode) => DropdownMenuItem(value: mode, child: Text(mode)))
                    .toList(),
                onChanged: (value) => setState(() => _paymentMode = value!),
              ),
              const SizedBox(height: 28),

              // Save Button
              ElevatedButton(
                onPressed: _isSaving ? null : _saveExpense,
                style: ElevatedButton.styleFrom(
                  backgroundColor: themeColor,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: _isSaving
                    ? const SizedBox(
                        height: 20, width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      )
                    : Text(
                        isCashIn ? 'Save Cash In' : 'Save Cash Out',
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

