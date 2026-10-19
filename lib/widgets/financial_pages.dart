import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';

import '../controllers/financial_controller.dart';
import '../models/financial_item.dart';
import '../services/financial_services.dart';

enum FinancialSection { investments, loans, bills }

class FinancialPage extends StatefulWidget {
  const FinancialPage({
    required this.section,
    required this.controller,
    required this.currency,
    required this.reminders,
    required this.addRequests,
    super.key,
  });

  final FinancialSection section;
  final FinancialController controller;
  final String currency;
  final BillReminderService reminders;
  final ValueListenable<int> addRequests;

  @override
  FinancialPageState createState() => FinancialPageState();
}

class FinancialPageState extends State<FinancialPage> {
  @override
  void initState() {
    super.initState();
    widget.addRequests.addListener(_handleAddRequest);
  }

  @override
  void didUpdateWidget(covariant FinancialPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.addRequests != widget.addRequests) {
      oldWidget.addRequests.removeListener(_handleAddRequest);
      widget.addRequests.addListener(_handleAddRequest);
    }
  }

  @override
  void dispose() {
    widget.addRequests.removeListener(_handleAddRequest);
    super.dispose();
  }

  void _handleAddRequest() {
    if (mounted) _showAddForm();
  }

  @override
  Widget build(BuildContext context) {
    final compact = MediaQuery.sizeOf(context).width < 600;
    final children = switch (widget.section) {
      FinancialSection.investments => _investmentRows(),
      FinancialSection.loans => _loanRows(),
      FinancialSection.bills => _billRows(),
    };
    final title = switch (widget.section) {
      FinancialSection.investments => 'Investments',
      FinancialSection.loans => 'Loans & EMI',
      FinancialSection.bills => 'Bills to pay',
    };
    final description = switch (widget.section) {
      FinancialSection.investments => 'Track contributions and estimated returns. Values are projections, not guarantees.',
      FinancialSection.loans =>
        'Review EMI, estimated interest, fees and repayment end dates.',
      FinancialSection.bills => 'Track card bills and due dates. Daily reminders stop after each saved due date.',
    };

    return ListView(
      padding: EdgeInsets.fromLTRB(
        compact ? 16 : 28,
        compact ? 18 : 26,
        compact ? 16 : 28,
        24,
      ),
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                title,
                style: Theme.of(context).textTheme.titleLarge
                    ?.copyWith(fontWeight: FontWeight.w800),
              ),
            ),
            IconButton.filledTonal(
              tooltip: 'Add $title',
              onPressed:
                  widget.controller.isLoaded &&
                      widget.controller.loadError == null
                  ? _showAddForm
                  : null,
              icon: const Icon(Icons.add),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(description, style: Theme.of(context).textTheme.bodyMedium),
        const SizedBox(height: 16),
        if (!widget.controller.isLoaded)
          const Padding(
            padding: EdgeInsets.all(36),
            child: Center(child: CircularProgressIndicator()),
          )
        else if (widget.controller.loadError case final loadError?)
          Column(
            children: [
              Text('Financial data could not be loaded: $loadError'),
              TextButton(
                onPressed: () => _persistOperation(widget.controller.load),
                child: const Text('Retry'),
              ),
            ],
          )
        else if (children.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 36, horizontal: 16),
            child: Column(
              children: [
                Icon(
                  _icon,
                  size: 42,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(height: 12),
                Text('No ${title.toLowerCase()} added yet'),
                const SizedBox(height: 4),
                const Text(
                  'Add an item to see its details here.',
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          )
        else
          AnimatedSize(
            duration: MediaQuery.disableAnimationsOf(context)
                ? Duration.zero
                : const Duration(milliseconds: 220),
            curve: Curves.easeOutCubic,
            alignment: Alignment.topCenter,
            child: Column(
              key: ValueKey('${widget.section.name}-${children.length}'),
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: children,
            ),
          ),
      ],
    );
  }

  IconData get _icon => switch (widget.section) {
    FinancialSection.investments => Icons.trending_up,
    FinancialSection.loans => Icons.account_balance,
    FinancialSection.bills => Icons.credit_card,
  };

  List<Widget> _investmentRows() => widget.controller.investments.map((item) {
    final isSip = item.contributionType == ContributionType.sip;
    return _itemCard(
      item.name,
      '${_investmentType(item.type)} · ${isSip ? 'SIP' : 'One-time'}',
      [
        _line(
          'Invested',
          '${widget.currency}${item.investedAmount.toStringAsFixed(2)}',
        ),
        _line(
          'Estimated value',
          '${widget.currency}${item.estimatedValue.toStringAsFixed(2)}',
        ),
        _line(
          'Expected return / year',
          '${item.annualReturnPercent.toStringAsFixed(2)}%',
        ),
      ],
      Icons.show_chart,
      () =>
          _persistOperation(() => widget.controller.deleteInvestment(item.id)),
    );
  }).toList();

  List<Widget> _loanRows() => widget.controller.loans.map((item) {
    return _itemCard(
      item.name,
      '${_interestLabel(item.interestType)} · ${item.tenureMonths} months',
      [
        _line(
          'Monthly EMI',
          '${widget.currency}${item.monthlyPayment.toStringAsFixed(2)}',
        ),
        _line(
          'Interest payable',
          '${widget.currency}${item.totalInterest.toStringAsFixed(2)}',
        ),
        _line(
          'Fees · total payable',
          '${widget.currency}${item.fees.toStringAsFixed(2)} · '
              '${widget.currency}${item.totalPayable.toStringAsFixed(2)}',
        ),
        _line('Payment ends', _formatDate(item.endDate)),
      ],
      Icons.account_balance,
      () => _persistOperation(() => widget.controller.deleteLoan(item.id)),
    );
  }).toList();

  List<Widget> _billRows() => widget.controller.bills.map((item) {
    final daysLeft = DateTime(
      item.dueDate.year,
      item.dueDate.month,
      item.dueDate.day,
    ).difference(DateTime.now()).inDays;
    final dueStatus = item.isPaid
        ? 'Paid'
        : daysLeft < 0
        ? 'Overdue'
        : daysLeft == 0
        ? 'Due today'
        : 'Due in $daysLeft day${daysLeft == 1 ? '' : 's'}';
    return _itemCard(
      item.name,
      '${_billType(item.type)} · ${_formatDate(item.dueDate)} · $dueStatus',
      [
        _line(
          'Amount due',
          '${widget.currency}${item.amount.toStringAsFixed(2)}',
        ),
        _line('Schedule', item.recurringMonthly ? 'Monthly' : 'One-time'),
        _line(
          'Reminder',
          item.isPaid ? 'Stopped (paid)' : 'Every 24 hours until due date',
        ),
      ],
      Icons.credit_card,
      () => _persistOperation(() async {
        await widget.controller.deleteBill(item.id);
        await widget.reminders.cancel(item.id);
      }),
      footer: item.isPaid
          ? null
          : TextButton.icon(
              onPressed: () => _persistOperation(() => _markBillPaid(item)),
              icon: const Icon(Icons.check_circle_outline),
              label: Text(
                item.recurringMonthly ? 'Paid · next month' : 'Mark paid',
              ),
            ),
    );
  }).toList();

  Widget _itemCard(
    String title,
    String subtitle,
    List<Widget> lines,
    IconData icon,
    VoidCallback onDelete, {
    Widget? footer,
  }) {
    final color = Theme.of(context).colorScheme.primary;
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      elevation: 0,
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: color, size: 22),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      Text(
                        subtitle,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
                IconButton(
                  tooltip: 'Delete $title',
                  visualDensity: VisualDensity.compact,
                  onPressed: onDelete,
                  icon: const Icon(Icons.delete_outline),
                ),
              ],
            ),
            const Divider(height: 20),
            ...lines,
            if (footer != null)
              Align(alignment: Alignment.centerRight, child: footer),
          ],
        ),
      ),
    );
  }

  Future<void> _markBillPaid(Bill bill) async {
    if (bill.recurringMonthly) {
      final nextMonth = DateTime(bill.dueDate.year, bill.dueDate.month + 1);
      final lastDay = DateTime(nextMonth.year, nextMonth.month + 1, 0).day;
      final nextDate = DateTime(
        nextMonth.year,
        nextMonth.month,
        bill.dueDate.day > lastDay ? lastDay : bill.dueDate.day,
      );
      await widget.controller.updateBill(
        bill.copyWith(dueDate: nextDate, isPaid: false),
      );
      await widget.reminders.schedule(bill.copyWith(dueDate: nextDate));
      return;
    }
    await widget.controller.updateBill(bill.copyWith(isPaid: true));
    await widget.reminders.cancel(bill.id);
  }

  Widget _line(String label, String value) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 3),
    child: Row(
      children: [
        Expanded(
          child: Text(label, style: Theme.of(context).textTheme.bodySmall),
        ),
        Flexible(
          child: Text(
            value,
            textAlign: TextAlign.end,
            style: Theme.of(context).textTheme.bodyMedium
                ?.copyWith(fontWeight: FontWeight.w700),
          ),
        ),
      ],
    ),
  );

  Future<void> _showAddForm() async {
    if (!widget.controller.isLoaded || widget.controller.loadError != null) {
      return;
    }
    switch (widget.section) {
      case FinancialSection.investments:
        await _addInvestment();
        break;
      case FinancialSection.loans:
        await _addLoan();
        break;
      case FinancialSection.bills:
        await _addBill();
        break;
    }
  }

  Future<void> _persistOperation(Future<void> Function() operation) async {
    try {
      await operation();
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not save financial changes: $error')),
      );
    }
  }

  Future<void> _addInvestment() async {
    final name = TextEditingController();
    final amount = TextEditingController();
    final monthly = TextEditingController(text: '0');
    final rate = TextEditingController(text: '0');
    var type = InvestmentType.stocks;
    var contribution = ContributionType.oneTime;
    var startDate = DateTime.now();
    final result = await showDialog<Investment>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => _formDialog(
          context,
          title: 'Add investment',
          children: [
            _textField(name, 'Investment name'),
            _dropdown<InvestmentType>(
              'Investment type',
              type,
              InvestmentType.values,
              _investmentType,
              (value) => setDialogState(() => type = value),
            ),
            _dropdown<ContributionType>(
              'Contribution',
              contribution,
              ContributionType.values,
              (value) => value == ContributionType.sip ? 'SIP' : 'One-time',
              (value) => setDialogState(() => contribution = value),
            ),
            _textField(
              amount,
              contribution == ContributionType.sip
                  ? 'Initial amount (${widget.currency})'
                  : 'Amount (${widget.currency})',
              decimal: true,
            ),
            if (contribution == ContributionType.sip)
              _textField(
                monthly,
                'Monthly contribution (${widget.currency})',
                decimal: true,
              ),
            _textField(rate, 'Expected annual return (%)', decimal: true),
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Started'),
              subtitle: Text(_formatDate(startDate)),
              trailing: const Icon(Icons.calendar_month),
              onTap: () async {
                final selected = await _pickDate(startDate);
                if (selected != null) {
                  setDialogState(() => startDate = selected);
                }
              },
            ),
          ],
          onSave: () {
            final invested = double.tryParse(amount.text.trim());
            final monthlyAmount = double.tryParse(monthly.text.trim()) ?? 0;
            final annualRate = double.tryParse(rate.text.trim());
            if (name.text.trim().isEmpty ||
                invested == null ||
                invested <= 0 ||
                !invested.isFinite ||
                annualRate == null ||
                annualRate < 0 ||
                annualRate > 1000 ||
                !annualRate.isFinite ||
                monthlyAmount < 0 ||
                !monthlyAmount.isFinite) {
              _showInputError();
              return;
            }
            Navigator.pop(
              context,
              Investment(
                id: DateTime.now().microsecondsSinceEpoch,
                name: name.text.trim(),
                type: type,
                contributionType: contribution,
                amount: invested,
                monthlyContribution: monthlyAmount,
                annualReturnPercent: annualRate,
                startDate: startDate,
              ),
            );
          },
        ),
      ),
    );
    name.dispose();
    amount.dispose();
    monthly.dispose();
    rate.dispose();
    if (result != null) {
      await _persistOperation(() => widget.controller.addInvestment(result));
    }
  }

  Future<void> _addLoan() async {
    final name = TextEditingController();
    final principal = TextEditingController();
    final rate = TextEditingController();
    final tenure = TextEditingController();
    final fees = TextEditingController(text: '0');
    var type = LoanInterestType.reducingBalance;
    var startDate = DateTime.now();
    final result = await showDialog<Loan>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => _formDialog(
          context,
          title: 'Add loan',
          children: [
            _textField(name, 'Loan name'),
            _textField(
              principal,
              'Principal (${widget.currency})',
              decimal: true,
            ),
            _textField(rate, 'Annual interest rate (%)', decimal: true),
            _dropdown<LoanInterestType>(
              'Interest type',
              type,
              LoanInterestType.values,
              _interestLabel,
              (value) => setDialogState(() => type = value),
            ),
            _textField(tenure, 'Tenure (months)', integer: true),
            _textField(
              fees,
              'Applicable fees (${widget.currency})',
              decimal: true,
            ),
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('First payment date'),
              subtitle: Text(_formatDate(startDate)),
              trailing: const Icon(Icons.calendar_month),
              onTap: () async {
                final selected = await _pickDate(startDate);
                if (selected != null) {
                  setDialogState(() => startDate = selected);
                }
              },
            ),
          ],
          onSave: () {
            final principalAmount = double.tryParse(principal.text.trim());
            final annualRate = double.tryParse(rate.text.trim());
            final months = int.tryParse(tenure.text.trim());
            final feeAmount = double.tryParse(fees.text.trim());
            if (name.text.trim().isEmpty ||
                principalAmount == null ||
                principalAmount <= 0 ||
                !principalAmount.isFinite ||
                annualRate == null ||
                annualRate < 0 ||
                annualRate > 1000 ||
                !annualRate.isFinite ||
                months == null ||
                months <= 0 ||
                months > 1200 ||
                feeAmount == null ||
                feeAmount < 0 ||
                !feeAmount.isFinite) {
              _showInputError();
              return;
            }
            Navigator.pop(
              context,
              Loan(
                id: DateTime.now().microsecondsSinceEpoch,
                name: name.text.trim(),
                principal: principalAmount,
                annualInterestPercent: annualRate,
                interestType: type,
                tenureMonths: months,
                fees: feeAmount,
                startDate: startDate,
              ),
            );
          },
        ),
      ),
    );
    name.dispose();
    principal.dispose();
    rate.dispose();
    tenure.dispose();
    fees.dispose();
    if (result != null) {
      await _persistOperation(() => widget.controller.addLoan(result));
    }
  }

  Future<void> _addBill() async {
    final name = TextEditingController();
    final amount = TextEditingController();
    var type = BillType.creditCard;
    var dueDate = DateTime.now().add(const Duration(days: 7));
    var recurring = false;
    final result = await showDialog<Bill>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => _formDialog(
          context,
          title: 'Add bill',
          children: [
            _textField(name, 'Bill or card name'),
            _dropdown<BillType>(
              'Bill type',
              type,
              BillType.values,
              _billType,
              (value) => setDialogState(() => type = value),
            ),
            _textField(
              amount,
              'Amount due (${widget.currency})',
              decimal: true,
            ),
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Due date'),
              subtitle: Text(_formatDate(dueDate)),
              trailing: const Icon(Icons.calendar_month),
              onTap: () async {
                final selected = await _pickDate(dueDate);
                if (selected != null) {
                  setDialogState(() => dueDate = selected);
                }
              },
            ),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Repeats monthly'),
              value: recurring,
              onChanged: (value) => setDialogState(() => recurring = value),
            ),
          ],
          onSave: () {
            final billAmount = double.tryParse(amount.text.trim());
            if (name.text.trim().isEmpty ||
                billAmount == null ||
                billAmount <= 0 ||
                !billAmount.isFinite) {
              _showInputError();
              return;
            }
            Navigator.pop(
              context,
              Bill(
                id: DateTime.now().microsecondsSinceEpoch,
                name: name.text.trim(),
                type: type,
                amount: billAmount,
                dueDate: dueDate,
                recurringMonthly: recurring,
              ),
            );
          },
        ),
      ),
    );
    name.dispose();
    amount.dispose();
    if (result == null) return;
    try {
      await widget.controller.addBill(result);
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Bill could not be saved: $error')),
        );
      }
      return;
    }
    try {
      await widget.reminders.schedule(result);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Daily bill reminders are scheduled.')),
        );
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Bill saved, but reminder setup failed: $error'),
          ),
        );
      }
    }
  }

  Widget _formDialog(
    BuildContext context, {
    required String title,
    required List<Widget> children,
    required VoidCallback onSave,
  }) {
    return AlertDialog(
      title: Text(title),
      content: SizedBox(
        width: MediaQuery.sizeOf(context).width < 560
            ? MediaQuery.sizeOf(context).width - 80
            : 440,
        child: SingleChildScrollView(
          child: Column(mainAxisSize: MainAxisSize.min, children: children),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        FilledButton(onPressed: onSave, child: const Text('Save')),
      ],
    );
  }

  void _showInputError() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Complete the required fields with valid values.'),
      ),
    );
  }

  Widget _textField(
    TextEditingController controller,
    String label, {
    bool decimal = false,
    bool integer = false,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: TextField(
        controller: controller,
        keyboardType: decimal
            ? const TextInputType.numberWithOptions(decimal: true)
            : integer
            ? TextInputType.number
            : TextInputType.text,
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
          isDense: true,
        ),
      ),
    );
  }

  Widget _dropdown<T>(
    String label,
    T value,
    List<T> values,
    String Function(T) text,
    ValueChanged<T> onChanged,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: DropdownButtonFormField<T>(
        initialValue: value,
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
          isDense: true,
        ),
        items: values
            .map(
              (item) => DropdownMenuItem(value: item, child: Text(text(item))),
            )
            .toList(),
        onChanged: (selected) {
          if (selected != null) onChanged(selected);
        },
      ),
    );
  }

  Future<DateTime?> _pickDate(DateTime initial) => showDatePicker(
    context: context,
    initialDate: initial,
    firstDate: DateTime(2000),
    lastDate: DateTime(2100),
  );

  String _formatDate(DateTime date) =>
      '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';

  String _investmentType(InvestmentType type) => switch (type) {
    InvestmentType.stocks => 'Stocks',
    InvestmentType.mutualFunds => 'Mutual funds',
    InvestmentType.bonds => 'Bonds',
    InvestmentType.debt => 'Debt',
    InvestmentType.other => 'Other',
  };

  String _interestLabel(LoanInterestType type) =>
      type == LoanInterestType.flat ? 'Flat interest' : 'Reducing balance';

  String _billType(BillType type) => switch (type) {
    BillType.creditCard => 'Credit card',
    BillType.debitCard => 'Debit card',
    BillType.other => 'Other bill',
  };
}
