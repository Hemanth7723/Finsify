import 'dart:async';

import 'package:flutter/material.dart';

import 'controllers/financial_controller.dart';
import 'controllers/expense_controller.dart';
import 'models/expense.dart';
import 'services/financial_services.dart';
import 'services/xlsx_export_service.dart';
import 'services/file_download_service.dart';
import 'services/voice_recognition_service.dart';
import 'widgets/analytics_bar_chart.dart';
import 'widgets/financial_pages.dart';
import 'widgets/voice_expense_dialog.dart';
import 'theme/finsify_theme.dart';

void main() => runApp(const FinsifyApp());

class FinsifyApp extends StatefulWidget {
  const FinsifyApp({super.key});

  @override
  State<FinsifyApp> createState() => _FinsifyAppState();
}

class _FinsifyAppState extends State<FinsifyApp> {
  bool _darkTheme = false;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Finsify',
      themeMode: _darkTheme ? ThemeMode.dark : ThemeMode.light,
      theme: buildFinsifyTheme(dark: false),
      darkTheme: buildFinsifyTheme(dark: true),
      home: SplashScreen(
        onComplete: (_) => ProfileScreen(
          destination: (profile) => ExpenseDashboard(
            profile: profile,
            onThemeChanged: (enabled) => setState(() => _darkTheme = enabled),
          ),
        ),
      ),
    );
  }
}

class SplashScreen extends StatefulWidget {
  const SplashScreen({required this.onComplete, super.key});

  final WidgetBuilder onComplete;

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _animationController;
  bool _completed = false;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat();
    Future<void>.delayed(const Duration(milliseconds: 2500), _complete);
  }

  void _complete() {
    if (!mounted || _completed) return;

    // Mark the splash as completed without rebuilding it immediately before
    // removing the route. This avoids unnecessary widget-tree churn during
    // route replacement.
    _completed = true;

    Navigator.of(context).pushReplacement(
      PageRouteBuilder<void>(
        // Build the destination with the new route's BuildContext rather than
        // the splash route's context.
        pageBuilder: (routeContext, _, __) => widget.onComplete(routeContext),
        transitionDuration: MediaQuery.disableAnimationsOf(context)
            ? Duration.zero
            : const Duration(milliseconds: 450),
        transitionsBuilder: (_, animation, __, child) => FadeTransition(
          opacity: animation,
          child: SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(0, 0.02),
              end: Offset.zero,
            ).animate(animation),
            child: child,
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF071126),
      body: SafeArea(
        child: AnimatedBuilder(
          animation: _animationController,
          builder: (context, _) => Column(
            children: [
              const Spacer(flex: 3),
              Center(
                child: SizedBox(
                  width: 130,
                  height: 130,
                  child: CustomPaint(
                    painter: SplashLogoPainter(
                      progress: _animationController.value,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 32),
              const Text(
                'COSMIC BUDGET',
                style: TextStyle(
                  color: Color(0xFFF4F7FC),
                  fontSize: 28,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.8,
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                'Secure Personal Expense Tracker',
                style: TextStyle(
                  color: Color(0xFF9BAECD),
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.3,
                ),
              ),
              const SizedBox(height: 64),
              SizedBox(
                width: 220,
                child: Column(
                  children: [
                    SizedBox(
                      width: 180,
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(3),
                        child: LinearProgressIndicator(
                          minHeight: 6,
                          value: 0.68 + (_animationController.value * 0.18),
                          backgroundColor: const Color(0xFF1B3049),
                          valueColor: const AlwaysStoppedAnimation<Color>(
                            Color(0xFF09B8F0),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'Loading Expense Tracker...',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: Color(0xFF8295B3),
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.4,
                      ),
                    ),
                  ],
                ),
              ),
              const Spacer(flex: 3),
            ],
          ),
        ),
      ),
    );
  }
}

class SplashLogoPainter extends CustomPainter {
  const SplashLogoPainter({required this.progress});

  final double progress;

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final ringRadius = size.width * 0.405;
    final coreRadius = size.width * 0.28;
    final rotation = progress * 2 * 3.141592653589793;

    canvas.drawCircle(
      center,
      size.width * 0.49,
      Paint()..color = const Color(0xFF082A45),
    );
    canvas.drawCircle(
      center,
      coreRadius,
      Paint()
        ..color = const Color(0xFF1A2A3E)
        ..style = PaintingStyle.fill,
    );
    canvas.drawCircle(
      center,
      coreRadius,
      Paint()
        ..color = const Color(0xFF31455E)
        ..style = PaintingStyle.stroke
        ..strokeWidth = size.width * (2 / 244),
    );

    final ringPaint = Paint()
      ..color = const Color(0xFF0BB9F2)
      ..style = PaintingStyle.stroke
      ..strokeWidth = size.width * (11 / 244)
      ..strokeCap = StrokeCap.round;
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: ringRadius),
      -1.25 + rotation,
      5.1,
      false,
      ringPaint,
    );

    final iconScale = size.width / 244;
    final diamond = Path()
      ..moveTo(center.dx, center.dy - 27 * iconScale)
      ..lineTo(center.dx + 25 * iconScale, center.dy - 11 * iconScale)
      ..lineTo(center.dx, center.dy + 29 * iconScale)
      ..lineTo(center.dx - 26 * iconScale, center.dy - 11 * iconScale)
      ..close();
    canvas.drawPath(diamond, Paint()..color = const Color(0xFF56CFF2));
    canvas.drawPath(
      Path()
        ..moveTo(center.dx - 26 * iconScale, center.dy - 11 * iconScale)
        ..lineTo(center.dx, center.dy - 4)
        ..lineTo(center.dx + 25 * iconScale, center.dy - 11 * iconScale)
        ..lineTo(center.dx, center.dy - 27 * iconScale)
        ..close(),
      Paint()..color = const Color(0xFF9BEAFF),
    );
    canvas.drawPath(
      Path()
        ..moveTo(center.dx - 26 * iconScale, center.dy - 11 * iconScale)
        ..lineTo(center.dx, center.dy - 4)
        ..lineTo(center.dx, center.dy + 29 * iconScale)
        ..close(),
      Paint()..color = const Color(0xFF2BA7D4),
    );
    canvas.drawPath(
      Path()
        ..moveTo(center.dx, center.dy - 4)
        ..lineTo(center.dx + 25 * iconScale, center.dy - 11 * iconScale)
        ..lineTo(center.dx, center.dy + 29 * iconScale)
        ..close(),
      Paint()..color = const Color(0xFF3ABBE6),
    );
  }

  @override
  bool shouldRepaint(SplashLogoPainter oldDelegate) =>
      oldDelegate.progress != progress;
}

class ProfileData {
  const ProfileData({
    required this.name,
    required this.email,
    required this.bio,
  });

  final String name;
  final String email;
  final String bio;
}

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({required this.destination, super.key});

  final Widget Function(ProfileData profile) destination;

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _bioController = TextEditingController();

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _bioController.dispose();
    super.dispose();
  }

  void _complete() {
    final profile = ProfileData(
      name: _nameController.text.trim(),
      email: _emailController.text.trim(),
      bio: _bioController.text.trim(),
    );

    Navigator.of(context).pushReplacement(
      PageRouteBuilder<void>(
        // Use the new route's context for the destination widget tree.
        pageBuilder: (routeContext, _, __) => widget.destination(profile),
        transitionDuration: MediaQuery.disableAnimationsOf(context)
            ? Duration.zero
            : const Duration(milliseconds: 350),
        transitionsBuilder: (_, animation, __, child) => FadeTransition(
          opacity: animation,
          child: SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(0, 0.02),
              end: Offset.zero,
            ).animate(animation),
            child: child,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.finsifyColors;

    return Scaffold(
      backgroundColor: colors.background,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) => SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(24, 24, 24, 24),
            child: ConstrainedBox(
              constraints: BoxConstraints(
                minHeight: constraints.maxHeight - 48,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'Welcome to Cosmic Budget',
                    style: TextStyle(
                      color: colors.primaryText,
                      fontSize: 26,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Set up a local profile. These optional details personalize this session; no account is required.',
                    style: TextStyle(
                      color: colors.secondaryText,
                      fontSize: 15,
                      height: 1.45,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 24),
                  _ProfileField(
                    controller: _nameController,
                    icon: Icons.person,
                    hintText: 'Display Name (e.g. Alex)',
                    outlineColor: colors.outline,
                    accentColor: colors.accent,
                  ),
                  const SizedBox(height: 16),
                  _ProfileField(
                    controller: _emailController,
                    icon: Icons.mail,
                    hintText: 'Email (Optional)',
                    outlineColor: colors.outline,
                    accentColor: colors.accent,
                    keyboardType: TextInputType.emailAddress,
                  ),
                  const SizedBox(height: 16),
                  _ProfileField(
                    controller: _bioController,
                    icon: Icons.info,
                    hintText: 'Short Bio / Savings Target\n(Optional)',
                    outlineColor: colors.outline,
                    accentColor: colors.accent,
                    maxLines: 3,
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    height: 56,
                    child: FilledButton(
                      onPressed: _complete,
                      style: FilledButton.styleFrom(
                        backgroundColor: colors.accent,
                        foregroundColor: colors.onAccent,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            'Get Started',
                            style: TextStyle(
                              color: colors.onAccent,
                              fontSize: 17,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          SizedBox(width: 10),
                          Icon(Icons.arrow_forward, size: 22),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ProfileField extends StatelessWidget {
  const _ProfileField({
    required this.controller,
    required this.icon,
    required this.hintText,
    required this.outlineColor,
    required this.accentColor,
    this.keyboardType,
    this.maxLines = 1,
  });

  final TextEditingController controller;
  final IconData icon;
  final String hintText;
  final Color outlineColor;
  final Color accentColor;
  final TextInputType? keyboardType;
  final int maxLines;

  @override
  Widget build(BuildContext context) {
    final colors = context.finsifyColors;
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      maxLines: maxLines,
      style: TextStyle(
        color: colors.primaryText,
        fontSize: 15,
        fontWeight: FontWeight.w600,
      ),
      cursorColor: accentColor,
      decoration: InputDecoration(
        hintText: hintText,
        hintStyle: TextStyle(
          color: colors.secondaryText,
          fontSize: 15,
          fontWeight: FontWeight.w600,
          height: 1.7,
        ),
        prefixIcon: Icon(icon, color: accentColor, size: 24),
        prefixIconConstraints: const BoxConstraints(minWidth: 56),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 14,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: outlineColor, width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: accentColor, width: 1),
        ),
      ),
    );
  }
}

class _DashboardCard extends StatelessWidget {
  const _DashboardCard({required this.child, this.padding = EdgeInsets.zero});

  final Widget child;
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) {
    final colors = context.finsifyColors;
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: colors.outline, width: 1),
      ),
      child: child,
    );
  }
}

class ExpenseDashboard extends StatefulWidget {
  const ExpenseDashboard({
    required this.profile,
    required this.onThemeChanged,
    super.key,
  });

  final ProfileData profile;
  final ValueChanged<bool> onThemeChanged;

  @override
  State<ExpenseDashboard> createState() => _ExpenseDashboardState();
}

class _ExpenseDashboardState extends State<ExpenseDashboard> {
  final _controller = ExpenseController();
  final _financialController = FinancialController();
  final _xlsxExportService = XlsxExportService();
  final _fileDownloadService = FileDownloadService();
  final _smsExpenseImporter = SmsExpenseImporter();
  final _billReminderService = BillReminderService();
  final _voiceRecognitionService = VoiceRecognitionService();
  final _financialAddRequests = ValueNotifier<int>(0);
  late ProfileData _profile;
  String _currency = '\u20b9';
  int _analyticsTab = 0;
  int _categoryAnalyticsTab = 0;
  DateTime _analyticsAnchor = DateTime.now();
  int _navigationIndex = 0;
  bool _importingSms = false;
  bool _addActionPressed = false;

  @override
  void initState() {
    super.initState();
    _profile = widget.profile;
    _controller.addListener(_refresh);
    unawaited(_loadFinancialRecords());
  }

  @override
  void dispose() {
    _controller
      ..removeListener(_refresh)
      ..dispose();
    _financialController.dispose();
    _financialAddRequests.dispose();
    super.dispose();
  }

  void _refresh() {
    if (mounted) setState(() {});
  }

  Future<void> _loadFinancialRecords() async {
    try {
      await _financialController.load();
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not load financial records: $error')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final screenWidth = MediaQuery.sizeOf(context).width;
    final compact = screenWidth < 600;
    final colors = context.finsifyColors;
    final pageBackground = colors.background;
    final surface = colors.surface;
    final primaryText = colors.primaryText;
    final secondaryText = colors.secondaryText;
    final accent = colors.accent;
    return Scaffold(
      backgroundColor: pageBackground,
      appBar: PreferredSize(
        preferredSize: Size.fromHeight(compact ? 60 : 72),
        child: AppBar(
          backgroundColor: surface,
          surfaceTintColor: surface,
          elevation: 0,
          scrolledUnderElevation: 0,
          shadowColor: Colors.transparent,
          shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
          titleSpacing: compact ? 12 : 28,
          title: Row(
            children: [
              Container(
                width: compact ? 36 : 42,
                height: compact ? 36 : 42,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(10),
                  gradient: LinearGradient(
                    colors: [accent, accent.withValues(alpha: 0.78)],
                  ),
                ),
                alignment: Alignment.center,
                child: Text(
                  'FS',
                  style: TextStyle(
                    color: colors.onAccent,
                    fontSize: compact ? 14 : 17,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
              SizedBox(width: compact ? 8 : 12),
              Text(
                'Finsify',
                style: TextStyle(
                  color: primaryText,
                  fontSize: compact ? 17 : 20,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
          actions: [
            SizedBox(
              width: 56,
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  isExpanded: true,
                  iconSize: 18,
                  value: _currency,
                  borderRadius: BorderRadius.circular(28),
                  items: const ['\u20b9', '\$', '\u20ac', '\u00a3', '\u00a5']
                      .map(
                        (currency) => DropdownMenuItem(
                          value: currency,
                          child: Text(currency),
                        ),
                      )
                      .toList(),
                  onChanged: (value) =>
                      setState(() => _currency = value ?? _currency),
                  selectedItemBuilder: (_) =>
                      const ['\u20b9', '\$', '\u20ac', '\u00a3', '\u00a5']
                          .map(
                            (currency) => Center(
                              child: Text(
                                currency,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  color: secondaryText,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          )
                          .toList(),
                ),
              ),
            ),
            IconButton(
              tooltip: 'Toggle theme',
              onPressed: () => widget.onThemeChanged(
                Theme.of(context).brightness == Brightness.light,
              ),
              icon: Icon(
                isDark ? Icons.light_mode : Icons.dark_mode,
                color: isDark ? const Color(0xFFFFD45C) : colors.secondaryText,
                size: compact ? 21 : 24,
              ),
            ),
            IconButton(
              tooltip: 'Profile',
              onPressed: _showProfileDialog,
              icon: Icon(
                Icons.account_circle,
                color: isDark ? colors.secondaryText : colors.secondaryText,
                size: compact ? 26 : 28,
              ),
            ),
            SizedBox(width: compact ? 6 : 22),
          ],
        ),
      ),
      body: AnimatedSwitcher(
        duration: MediaQuery.disableAnimationsOf(context)
            ? Duration.zero
            : const Duration(milliseconds: 240),
        switchInCurve: Curves.easeOutCubic,
        switchOutCurve: Curves.easeInCubic,
        transitionBuilder: (child, animation) => FadeTransition(
          opacity: animation,
          child: SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(0.025, 0),
              end: Offset.zero,
            ).animate(animation),
            child: child,
          ),
        ),
        child: KeyedSubtree(
          key: ValueKey(_navigationIndex),
          child: _navigationIndex == 0
              ? _expenseDashboardBody(compact)
              : AnimatedBuilder(
                  animation: _financialController,
                  builder: (context, _) => FinancialPage(
                    section: FinancialSection.values[_navigationIndex - 1],
                    controller: _financialController,
                    currency: _currency,
                    reminders: _billReminderService,
                    addRequests: _financialAddRequests,
                  ),
                ),
        ),
      ),
      bottomNavigationBar: _buildBottomNavigationBar(
        isDark: isDark,
        accent: accent,
        secondaryText: secondaryText,
      ),
    );
  }

  Widget _expenseDashboardBody(bool compact) {
    return ListView(
      padding: EdgeInsets.fromLTRB(
        compact ? 16 : 28,
        compact ? 14 : 22,
        compact ? 16 : 28,
        88,
      ),
      children: [
        _greetingCard(),
        SizedBox(height: compact ? 16 : 20),
        _totalCard(),
        SizedBox(height: compact ? 18 : 22),
        _analyticsTabs(),
        SizedBox(height: compact ? 14 : 18),
        _animatedAnalyticsCard(),
        SizedBox(height: compact ? 22 : 28),
        _ledgerHeader(),
        const SizedBox(height: 8),
        _ledgerControls(),
        const SizedBox(height: 8),
        _expenseInputActions(),
        const SizedBox(height: 10),
        if (_controller.visibleExpenses.isEmpty)
          _emptyLedger()
        else
          ..._controller.visibleExpenses.map(_expenseTile),
      ],
    );
  }

  Widget _buildBottomNavigationBar({
    required bool isDark,
    required Color accent,
    required Color secondaryText,
  }) {
    final surface = context.finsifyColors.surface;
    return SafeArea(
      top: false,
      child: SizedBox(
        height: 80,
        child: LayoutBuilder(
          builder: (context, constraints) => Stack(
            clipBehavior: Clip.none,
            children: [
              Positioned(
                left: constraints.maxWidth < 552
                    ? 16
                    : (constraints.maxWidth - 520) / 2,
                right: constraints.maxWidth < 552
                    ? 16
                    : (constraints.maxWidth - 520) / 2,
                bottom: 4,
                height: 62,
                child: Container(
                  decoration: BoxDecoration(
                    color: surface,
                    borderRadius: BorderRadius.circular(22),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(
                          alpha: isDark ? 0.18 : 0.08,
                        ),
                        blurRadius: 14,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: Row(
                    children: [
                      _navigationItem(
                        index: 0,
                        icon: Icons.receipt_long_outlined,
                        label: 'Expenses',
                        activeColor: accent,
                        inactiveColor: secondaryText,
                      ),
                      _navigationItem(
                        index: 1,
                        icon: Icons.trending_up,
                        label: 'Invest',
                        activeColor: accent,
                        inactiveColor: secondaryText,
                      ),
                      const SizedBox(width: 52),
                      _navigationItem(
                        index: 2,
                        icon: Icons.account_balance_outlined,
                        label: 'Loans',
                        activeColor: accent,
                        inactiveColor: secondaryText,
                      ),
                      _navigationItem(
                        index: 3,
                        icon: Icons.credit_card_outlined,
                        label: 'Bills',
                        activeColor: accent,
                        inactiveColor: secondaryText,
                      ),
                    ],
                  ),
                ),
              ),
              Positioned(
                top: 14,
                left: (constraints.maxWidth - 48) / 2,
                child: Material(
                  color: accent,
                  elevation: 6,
                  shadowColor: accent.withValues(alpha: 0.35),
                  shape: const CircleBorder(),
                  child: Semantics(
                    button: true,
                    label: switch (_navigationIndex) {
                      0 => 'Add expense',
                      1 => 'Add investment',
                      2 => 'Add loan',
                      _ => 'Add bill',
                    },
                    child: InkWell(
                      key: const ValueKey('primary-add-action'),
                      customBorder: const CircleBorder(),
                      onTapDown: (_) =>
                          setState(() => _addActionPressed = true),
                      onTapUp: (_) => setState(() => _addActionPressed = false),
                      onTapCancel: () =>
                          setState(() => _addActionPressed = false),
                      onTap: _handlePrimaryAdd,
                      child: AnimatedScale(
                        scale: _addActionPressed ? 0.92 : 1,
                        duration: MediaQuery.disableAnimationsOf(context)
                            ? Duration.zero
                            : const Duration(milliseconds: 120),
                        curve: Curves.easeOut,
                        child: SizedBox(
                          width: 48,
                          height: 48,
                          child: Icon(
                            Icons.add,
                            color: context.finsifyColors.onAccent,
                            size: 28,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _navigationItem({
    required int index,
    required IconData icon,
    required String label,
    required Color activeColor,
    required Color inactiveColor,
  }) {
    final selected = _navigationIndex == index;
    final color = selected ? activeColor : inactiveColor;
    return Expanded(
      child: Semantics(
        button: true,
        selected: selected,
        label: label,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () => _switchNavigation(index),
          child: AnimatedContainer(
            duration: MediaQuery.disableAnimationsOf(context)
                ? Duration.zero
                : const Duration(milliseconds: 180),
            curve: Curves.easeOutCubic,
            margin: const EdgeInsets.symmetric(vertical: 4),
            decoration: BoxDecoration(
              color: selected
                  ? activeColor.withValues(alpha: 0.1)
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(14),
            ),
            child: SizedBox(
              height: double.infinity,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  AnimatedScale(
                    scale: selected ? 1.08 : 1,
                    duration: MediaQuery.disableAnimationsOf(context)
                        ? Duration.zero
                        : const Duration(milliseconds: 180),
                    curve: Curves.easeOutBack,
                    child: Icon(icon, size: 21, color: color),
                  ),
                  const SizedBox(height: 2),
                  AnimatedDefaultTextStyle(
                    duration: MediaQuery.disableAnimationsOf(context)
                        ? Duration.zero
                        : const Duration(milliseconds: 180),
                    curve: Curves.easeOutCubic,
                    style: TextStyle(
                      color: color,
                      fontSize: 10,
                      fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                    ),
                    child: Text(
                      label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _handlePrimaryAdd() {
    if (_navigationIndex == 0) {
      _showAddExpenseDialog();
    } else {
      _financialAddRequests.value++;
    }
  }

  void _switchNavigation(int index) {
    if (index == _navigationIndex) return;
    setState(() => _navigationIndex = index);
  }

  Widget _greetingCard() {
    final compact = MediaQuery.sizeOf(context).width < 600;
    final colors = context.finsifyColors;
    final name = _profile.name.isEmpty ? 'there' : _profile.name;
    final initials = _profile.name.isEmpty
        ? 'U'
        : _profile.name.trim().substring(0, 1).toUpperCase();
    return _DashboardCard(
      padding: EdgeInsets.all(compact ? 16 : 20),
      child: Row(
        children: [
          CircleAvatar(
            radius: compact ? 27 : 30,
            backgroundColor: colors.accentContainer,
            child: Text(
              initials,
              style: TextStyle(
                color: colors.accent,
                fontSize: compact ? 19 : 21,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          SizedBox(width: compact ? 12 : 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Hello, $name 👋',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: colors.primaryText,
                    fontSize: compact ? 18 : 20,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Budgeting with dynamic currency tracking.',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: colors.secondaryText,
                    fontSize: compact ? 13 : 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _totalCard() {
    final compact = MediaQuery.sizeOf(context).width < 600;
    final colors = context.finsifyColors;
    return Container(
      padding: EdgeInsets.fromLTRB(24, 22, 24, 24),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        gradient: LinearGradient(
          colors: [colors.accent, colors.accent.withValues(alpha: 0.78)],
        ),
        boxShadow: [
          BoxShadow(
            color: colors.accent.withValues(alpha: 0.2),
            blurRadius: 14,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'TOTAL EXPENSES',
            style: TextStyle(
              color: colors.onAccent.withValues(alpha: 0.85),
              fontSize: 13,
              fontWeight: FontWeight.w800,
              letterSpacing: 2,
            ),
          ),
          const SizedBox(height: 12),
          FittedBox(
            alignment: Alignment.centerLeft,
            fit: BoxFit.scaleDown,
            child: Text(
              '$_currency${_controller.totalSpend.toStringAsFixed(2)}',
              style: TextStyle(
                color: colors.onAccent,
                fontSize: compact ? 36 : 40,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _analyticsTabs() {
    final compact = MediaQuery.sizeOf(context).width < 600;
    final colors = context.finsifyColors;

    const tabs = ['Daily', 'Weekly', 'Monthly', 'Yearly', 'Categories'];

    return _DashboardCard(
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 12 : 18,
        vertical: 12,
      ),
      child: Row(
        children: [
          for (var index = 0; index < tabs.length; index++)
            Expanded(
              child: TextButton(
                onPressed: () => setState(() => _analyticsTab = index),
                style: TextButton.styleFrom(
                  padding: EdgeInsets.zero,
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    tabs[index],
                    maxLines: 1,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: index == _analyticsTab
                          ? colors.accent
                          : colors.secondaryText,
                      fontSize: compact ? 12 : 14,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _analyticsCard() {
    final compact = MediaQuery.sizeOf(context).width < 600;
    final colors = context.finsifyColors;
    if (_analyticsTab == 4) return _categoryAnalyticsCard();

    final data = _timeAnalyticsData(_controller.expenses, _analyticsTab);

    return _DashboardCard(
      padding: EdgeInsets.all(compact ? 16 : 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Spending Density Analytics',
            style: TextStyle(
              color: colors.primaryText,
              fontSize: compact ? 17 : 20,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 14),
          if (data.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 34, horizontal: 16),
              child: Center(
                child: Text(
                  'No expense data for this period',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: colors.secondaryText,
                    fontSize: compact ? 16 : 18,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            )
          else
            Container(
              height: compact ? 170 : 180,
              width: double.infinity,
              decoration: BoxDecoration(
                color: colors.surfaceInset,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: colors.outline, width: 2),
              ),
              child: AnalyticsBarChart(data: data, currency: _currency),
            ),
        ],
      ),
    );
  }

  List<AnalyticsDatum> _timeAnalyticsData(List<Expense> expenses, int period) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    late final DateTime rangeStart;
    late final int bucketCount;

    if (period == 0) {
      // Daily: today + previous 6 calendar days.
      rangeStart = today.subtract(const Duration(days: 6));
      bucketCount = 7;
    } else if (period == 1) {
      // Weekly: current Monday-Sunday week + previous 3 weeks.
      final currentWeekStart = today.subtract(
        Duration(days: today.weekday - 1),
      );
      rangeStart = currentWeekStart.subtract(const Duration(days: 21));
      bucketCount = 4;
    } else if (period == 2) {
      // Monthly: current month + previous 3 calendar months.
      rangeStart = DateTime(now.year, now.month - 3);
      bucketCount = 4;
    } else {
      // Yearly: current year + previous 4 calendar years.
      rangeStart = DateTime(now.year - 4);
      bucketCount = 5;
    }

    final totals = List<double>.filled(bucketCount, 0.0);
    final hasExpense = List<bool>.filled(bucketCount, false);

    for (final expense in expenses) {
      final date = expense.timestamp;
      final expenseDay = DateTime(date.year, date.month, date.day);
      int? bucketIndex;

      if (period == 0) {
        final dayOffset = expenseDay.difference(rangeStart).inDays;
        if (dayOffset >= 0 && dayOffset < bucketCount) {
          bucketIndex = dayOffset;
        }
      } else if (period == 1) {
        final expenseWeekStart = expenseDay.subtract(
          Duration(days: expenseDay.weekday - 1),
        );
        final weekOffset = expenseWeekStart.difference(rangeStart).inDays ~/ 7;
        if (weekOffset >= 0 && weekOffset < bucketCount) {
          bucketIndex = weekOffset;
        }
      } else if (period == 2) {
        final monthOffset =
            (date.year - rangeStart.year) * 12 + date.month - rangeStart.month;
        if (monthOffset >= 0 && monthOffset < bucketCount) {
          bucketIndex = monthOffset;
        }
      } else {
        final yearOffset = date.year - rangeStart.year;
        if (yearOffset >= 0 && yearOffset < bucketCount) {
          bucketIndex = yearOffset;
        }
      }

      if (bucketIndex != null) {
        totals[bucketIndex] += expense.amount;
        hasExpense[bucketIndex] = true;
      }
    }

    final data = <AnalyticsDatum>[];

    for (var index = 0; index < bucketCount; index++) {
      // Do not show empty periods on the chart. Only periods containing
      // at least one expense are displayed.
      if (!hasExpense[index]) continue;

      late final DateTime bucketStart;
      late final String label;

      if (period == 0) {
        bucketStart = rangeStart.add(Duration(days: index));
        label = '${bucketStart.month}/${bucketStart.day}';
      } else if (period == 1) {
        bucketStart = rangeStart.add(Duration(days: index * 7));
        final bucketEnd = bucketStart.add(const Duration(days: 6));
        label =
            '${bucketStart.month}/${bucketStart.day}-${bucketEnd.month}/${bucketEnd.day}';
      } else if (period == 2) {
        bucketStart = DateTime(rangeStart.year, rangeStart.month + index);
        label = _monthName(bucketStart.month);
      } else {
        bucketStart = DateTime(rangeStart.year + index);
        label = '${bucketStart.year}';
      }

      data.add(AnalyticsDatum(label: label, value: totals[index]));
    }

    return data;
  }

  Widget _animatedAnalyticsCard() => AnimatedSwitcher(
    duration: MediaQuery.disableAnimationsOf(context)
        ? Duration.zero
        : const Duration(milliseconds: 220),
    switchInCurve: Curves.easeOutCubic,
    switchOutCurve: Curves.easeInCubic,
    transitionBuilder: (child, animation) => FadeTransition(
      opacity: animation,
      child: SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(0, 0.025),
          end: Offset.zero,
        ).animate(animation),
        child: child,
      ),
    ),
    child: KeyedSubtree(
      key: ValueKey(
        'analytics-$_analyticsTab-$_categoryAnalyticsTab-'
        '${_analyticsAnchor.year}-${_analyticsAnchor.month}-'
        '${_analyticsAnchor.day}',
      ),
      child: _analyticsCard(),
    ),
  );

  Widget _categoryAnalyticsCard() {
    final compact = MediaQuery.sizeOf(context).width < 600;
    final colors = context.finsifyColors;
    final periodNames = ['Daily', 'Weekly', 'Monthly', 'Yearly'];
    final categoryTotals = _categoryTotalsForPeriod(
      _controller.expenses,
      _categoryAnalyticsTab,
      _analyticsAnchor,
    );
    final maxValue = categoryTotals.isEmpty
        ? 1.0
        : categoryTotals.values.reduce((a, b) => a > b ? a : b);
    return _DashboardCard(
      padding: EdgeInsets.all(compact ? 16 : 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Spending Density Analytics',
            style: TextStyle(
              color: colors.primaryText,
              fontSize: compact ? 17 : 20,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: colors.surfaceInset,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              children: [
                for (var index = 0; index < periodNames.length; index++)
                  Expanded(
                    child: GestureDetector(
                      onTap: () =>
                          setState(() => _categoryAnalyticsTab = index),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        decoration: BoxDecoration(
                          color: index == _categoryAnalyticsTab
                              ? colors.accent
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Text(
                          periodNames[index],
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: index == _categoryAnalyticsTab
                                ? colors.onAccent
                                : colors.secondaryText,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          _periodNavigator(_categoryAnalyticsTab),
          const SizedBox(height: 24),
          if (categoryTotals.isEmpty)
            SizedBox(
              height: 190,
              child: Center(
                child: Text(
                  'No category ledger records for this period',
                  style: TextStyle(
                    color: colors.secondaryText,
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            )
          else
            ...categoryTotals.entries.map(
              (entry) => _categoryStat(entry.key, entry.value, maxValue),
            ),
        ],
      ),
    );
  }

  Widget _periodNavigator(int period) {
    final colors = context.finsifyColors;
    return Container(
      height: 72,
      decoration: BoxDecoration(
        color: colors.surfaceInset,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: colors.outline, width: 2),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            onPressed: () => setState(
              () =>
                  _analyticsAnchor = _shiftPeriod(_analyticsAnchor, period, -1),
            ),
            icon: Icon(Icons.chevron_left, color: colors.accent, size: 36),
          ),
          Row(
            children: [
              const SizedBox(width: 0),
              Text(
                _periodLabel(_analyticsAnchor, period),
                style: TextStyle(
                  color: colors.primaryText,
                  fontSize: 19,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
          IconButton(
            onPressed: () => setState(
              () =>
                  _analyticsAnchor = _shiftPeriod(_analyticsAnchor, period, 1),
            ),
            icon: Icon(Icons.chevron_right, color: colors.accent, size: 36),
          ),
        ],
      ),
    );
  }

  Widget _categoryStat(String category, double amount, double maxValue) {
    final colors = context.finsifyColors;
    final color = category.toLowerCase() == 'entertainment'
        ? const Color(0xFFED2B9B)
        : const Color(0xFFFFA400);
    return Padding(
      padding: const EdgeInsets.only(bottom: 17),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                _categoryEmoji(category),
                style: const TextStyle(fontSize: 23),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  category,
                  style: TextStyle(
                    color: colors.primaryText,
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              Text(
                '$_currency${amount.toStringAsFixed(2)}',
                style: TextStyle(
                  color: colors.primaryText,
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
          const SizedBox(height: 9),
          ClipRRect(
            borderRadius: BorderRadius.circular(7),
            child: LinearProgressIndicator(
              value: amount / maxValue,
              minHeight: 19,
              backgroundColor: colors.surfaceInset,
              valueColor: AlwaysStoppedAnimation(color),
            ),
          ),
        ],
      ),
    );
  }

  Map<String, double> _categoryTotalsForPeriod(
    List<Expense> expenses,
    int period,
    DateTime anchor,
  ) {
    final totals = <String, double>{};
    final range = _periodRange(anchor, period);
    for (final expense in expenses) {
      if (!expense.timestamp.isBefore(range.$1) &&
          expense.timestamp.isBefore(range.$2)) {
        totals[expense.category] =
            (totals[expense.category] ?? 0) + expense.amount;
      }
    }
    return totals;
  }

  (DateTime, DateTime) _periodRange(DateTime date, int period) {
    if (period == 0)
      return (
        DateTime(date.year, date.month, date.day),
        DateTime(date.year, date.month, date.day + 1),
      );
    if (period == 1) {
      final start = DateTime(
        date.year,
        date.month,
        date.day,
      ).subtract(Duration(days: date.weekday - 1));
      return (start, start.add(const Duration(days: 7)));
    }
    if (period == 2)
      return (
        DateTime(date.year, date.month),
        DateTime(date.year, date.month + 1),
      );
    return (DateTime(date.year), DateTime(date.year + 1));
  }

  DateTime _shiftPeriod(DateTime date, int period, int amount) {
    if (period == 0) return date.add(Duration(days: amount));
    if (period == 1) return date.add(Duration(days: amount * 7));
    if (period == 2) return DateTime(date.year, date.month + amount, date.day);
    return DateTime(date.year + amount, date.month, date.day);
  }

  String _periodLabel(DateTime date, int period) {
    if (period == 0)
      return '${_monthName(date.month).substring(0, 3)} ${date.day}, ${date.year}';
    if (period == 1) {
      final start = date.subtract(Duration(days: date.weekday - 1));
      final end = start.add(const Duration(days: 6));
      return '${_monthName(start.month).substring(0, 3)} ${start.day} - ${_monthName(end.month).substring(0, 3)} ${end.day}, ${end.year}';
    }
    if (period == 2) return '${_monthName(date.month)} ${date.year}';
    return '${date.year}';
  }

  String _monthName(int month) => const [
    'January',
    'February',
    'March',
    'April',
    'May',
    'June',
    'July',
    'August',
    'September',
    'October',
    'November',
    'December',
  ][month - 1];

  Widget _ledgerHeader() {
    final compact = MediaQuery.sizeOf(context).width < 600;
    final colors = context.finsifyColors;
    final heading = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'TRANSACTION LEDGER',
          style: TextStyle(
            color: colors.accent,
            fontSize: 12,
            fontWeight: FontWeight.w800,
            letterSpacing: 2,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          'Showing ${_controller.visibleExpenses.length} sorted entries',
          style: TextStyle(
            color: colors.secondaryText,
            fontSize: 13,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
    final download = OutlinedButton.icon(
      onPressed: _exportXlsx,
      icon: Icon(Icons.download_rounded, color: colors.accent),
      label: Text(
        'Download XLSX',
        style: TextStyle(color: colors.accent, fontWeight: FontWeight.w800),
      ),
      style: OutlinedButton.styleFrom(
        backgroundColor: colors.accentContainer,
        side: BorderSide.none,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
    );
    return compact
        ? Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [heading, const SizedBox(height: 8), download],
          )
        : Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [heading, download],
          );
  }

  Widget _ledgerControls() {
    final colors = context.finsifyColors;
    return SizedBox(
      height: 58,
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: [
          DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: _controller.sortOrder,
              icon: Icon(Icons.keyboard_arrow_down, color: colors.accent),
              items: ['Newest', 'Oldest', 'Amount High', 'Amount Low']
                  .map(
                    (order) => DropdownMenuItem(
                      value: order,
                      child: Text(
                        '☷  Sort: $order',
                        style: TextStyle(
                          color: colors.primaryText,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  )
                  .toList(),
              onChanged: (value) => _controller.setSortOrder(value ?? 'Newest'),
            ),
          ),
          const SizedBox(width: 14),
          for (final category in ['All', ...expenseCategories]) ...[
            ChoiceChip(
              label: Text(category),
              selected: _controller.categoryFilter == category,
              onSelected: (_) => _controller.setCategoryFilter(category),
              selectedColor: colors.accent,
              backgroundColor: colors.surface,
              labelStyle: TextStyle(
                color: _controller.categoryFilter == category
                    ? colors.onAccent
                    : colors.primaryText,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(width: 12),
          ],
        ],
      ),
    );
  }

  Widget _expenseInputActions() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: 8,
          runSpacing: 4,
          children: [
            OutlinedButton.icon(
              onPressed: _showVoiceExpenseDialog,
              icon: const Icon(Icons.mic, size: 18),
              label: const Text('Voice entry'),
              style: OutlinedButton.styleFrom(
                visualDensity: VisualDensity.compact,
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
              ),
            ),
            OutlinedButton.icon(
              onPressed: _importingSms ? null : _importSmsExpenses,
              icon: _importingSms
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.sms_outlined, size: 18),
              label: const Text('Import from SMS'),
              style: OutlinedButton.styleFrom(
                visualDensity: VisualDensity.compact,
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
              ),
            ),
          ],
        ),
        Padding(
          padding: const EdgeInsets.only(left: 4, top: 2),
          child: Text(
            'SMS import is Android-only and reads messages only after you choose import.',
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ),
      ],
    );
  }

  Future<void> _showVoiceExpenseDialog() async {
    await showDialog<void>(
      context: context,
      builder: (context) => VoiceExpenseDialog(
        currency: _currency,
        onSave: _controller.addExpense,
        recognizer: _voiceRecognitionService,
      ),
    );
  }

  Future<void> _importSmsExpenses() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Import expenses from SMS?'),
        content: const Text(
          'On Android, Finsify will read up to 100 recent inbox messages on '
          'this device to find transaction alerts. You review each match before '
          'adding it. Message contents are not uploaded or saved as message text.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Continue'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    setState(() => _importingSms = true);
    try {
      final candidates = await _smsExpenseImporter.fetchRecentExpenses();
      if (!mounted) return;
      final existingIds = _controller.expenses.map((item) => item.id).toSet();
      final available = candidates
          .where((candidate) => !existingIds.contains(candidate.expense.id))
          .toList();
      if (available.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('No new expense-like SMS messages found.'),
          ),
        );
        return;
      }
      final selected = await showDialog<Set<String>>(
        context: context,
        builder: (dialogContext) {
          final selectedIds = available.map((item) => item.id).toSet();
          return StatefulBuilder(
            builder: (context, setDialogState) => AlertDialog(
              title: const Text('Review SMS transactions'),
              content: SizedBox(
                width: MediaQuery.sizeOf(context).width < 560
                    ? MediaQuery.sizeOf(context).width - 80
                    : 460,
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: available.length,
                  itemBuilder: (context, index) {
                    final candidate = available[index];
                    return CheckboxListTile(
                      value: selectedIds.contains(candidate.id),
                      controlAffinity: ListTileControlAffinity.leading,
                      contentPadding: EdgeInsets.zero,
                      title: Text(
                        '${candidate.expense.title} · $_currency'
                        '${candidate.expense.amount.toStringAsFixed(2)}',
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      subtitle: Text(
                        '${candidate.expense.category} · '
                        '${_formatExpenseDate(candidate.expense.timestamp)}\n'
                        '${candidate.preview}',
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                      ),
                      onChanged: (checked) => setDialogState(() {
                        if (checked == true) {
                          selectedIds.add(candidate.id);
                        } else {
                          selectedIds.remove(candidate.id);
                        }
                      }),
                    );
                  },
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogContext),
                  child: const Text('Cancel'),
                ),
                FilledButton(
                  onPressed: () => Navigator.pop(dialogContext, selectedIds),
                  child: const Text('Add selected'),
                ),
              ],
            ),
          );
        },
      );
      if (!mounted || selected == null) return;
      final chosen = available
          .where((candidate) => selected.contains(candidate.id))
          .toList();
      for (final candidate in chosen) {
        _controller.addExpense(candidate.expense);
      }
      if (chosen.isNotEmpty && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${chosen.length} expense(s) imported from SMS.'),
          ),
        );
      }
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not import SMS expenses: $error')),
      );
    } finally {
      if (mounted) setState(() => _importingSms = false);
    }
  }

  Widget _emptyLedger() {
    final colors = context.finsifyColors;
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 54),
      child: Column(
        children: [
          CircleAvatar(
            radius: 64,
            backgroundColor: colors.surface,
            child: const Text('💸', style: TextStyle(fontSize: 48)),
          ),
          SizedBox(height: 28),
          Text(
            'No recorded transactions yet',
            style: TextStyle(
              color: colors.primaryText,
              fontSize: 24,
              fontWeight: FontWeight.w800,
            ),
          ),
          SizedBox(height: 18),
          Text(
            'Use the bottom microphone helper to speak an expense or add one manually to analyze details.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: colors.secondaryText,
              fontSize: 17,
              height: 1.7,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  Widget _expenseTile(Expense expense) {
    final colors = context.finsifyColors;
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      elevation: 0,
      color: colors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: colors.outline, width: 2),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        leading: CircleAvatar(
          radius: 23,
          backgroundColor: colors.accentContainer,
          child: Text(
            _categoryEmoji(expense.category),
            style: const TextStyle(fontSize: 23),
          ),
        ),
        title: Text(
          expense.title,
          style: TextStyle(
            color: colors.primaryText,
            fontSize: 15,
            fontWeight: FontWeight.w800,
          ),
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 8),
          child: Text(
            '${expense.category} · ${_formatExpenseDate(expense.timestamp)}',
            style: TextStyle(
              color: colors.secondaryText,
              fontSize: 13,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        trailing: Text(
          '$_currency${expense.amount.toStringAsFixed(2)}',
          style: TextStyle(
            color: colors.accent,
            fontSize: 16,
            fontWeight: FontWeight.w800,
          ),
        ),
        onTap: () => _showManageTransactionDialog(expense),
      ),
    );
  }

  String _formatExpenseDate(DateTime date) {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return '${months[date.month - 1]} ${date.day.toString().padLeft(2, '0')}, ${date.year}';
  }

  String _categoryEmoji(String category) {
    switch (category.toLowerCase()) {
      case 'food':
        return '🍔';
      case 'transport':
        return '🚗';
      case 'entertainment':
        return '🎬';
      case 'shopping':
        return '🛍️';
      case 'health':
        return '🩺';
      case 'utilities':
        return '💡';
      default:
        return '📝';
    }
  }

  bool _isDark(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark;

  FinsifyColors _dialogColors(BuildContext context, {bool? dark}) =>
      dark == null
      ? context.finsifyColors
      : dark
      ? FinsifyColors.dark
      : FinsifyColors.light;

  Color _dialogText(BuildContext context, {bool? dark}) =>
      _dialogColors(context, dark: dark).primaryText;

  Color _dialogSecondary(BuildContext context, {bool? dark}) =>
      _dialogColors(context, dark: dark).secondaryText;

  Color _dialogAccent(BuildContext context, {bool? dark}) =>
      _dialogColors(context, dark: dark).accent;

  ButtonStyle _dialogOutlinedButton(BuildContext context, {bool? dark}) {
    final colors = _dialogColors(context, dark: dark);
    return OutlinedButton.styleFrom(
      foregroundColor: colors.accent,
      side: BorderSide(color: colors.outline, width: 2),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
    );
  }

  InputDecoration _dialogInputDecoration(
    BuildContext context,
    String label, {
    bool? dark,
  }) {
    final colors = _dialogColors(context, dark: dark);
    return InputDecoration(
      labelText: label,
      labelStyle: TextStyle(
        color: colors.secondaryText,
        fontWeight: FontWeight.w700,
      ),
      filled: true,
      fillColor: colors.surfaceInset,
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(20),
        borderSide: BorderSide(color: colors.outline, width: 2),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(20),
        borderSide: BorderSide(color: colors.accent, width: 2),
      ),
    );
  }

  Future<void> _showProfileDialog() async {
    final nameController = TextEditingController(text: _profile.name);
    final emailController = TextEditingController(text: _profile.email);
    final bioController = TextEditingController(text: _profile.bio);
    var darkMode = _isDark(context);

    final updatedProfile = await showDialog<ProfileData>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) {
          final colors = _dialogColors(context, dark: darkMode);
          return AlertDialog(
            backgroundColor: colors.surfaceRaised,
            title: Text(
              'Secure Identity Controls',
              style: TextStyle(
                color: _dialogText(context, dark: darkMode),
                fontWeight: FontWeight.w800,
              ),
            ),
            content: SingleChildScrollView(
              child: SizedBox(
                width: MediaQuery.sizeOf(context).width > 520
                    ? 420
                    : MediaQuery.sizeOf(context).width - 96,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    TextField(
                      controller: nameController,
                      decoration: _dialogInputDecoration(
                        context,
                        'Name',
                        dark: darkMode,
                      ),
                    ),
                    const SizedBox(height: 20),
                    TextField(
                      controller: emailController,
                      keyboardType: TextInputType.emailAddress,
                      decoration: _dialogInputDecoration(
                        context,
                        'Email (Optional)',
                        dark: darkMode,
                      ),
                    ),
                    const SizedBox(height: 20),
                    TextField(
                      controller: bioController,
                      maxLines: 2,
                      decoration: _dialogInputDecoration(
                        context,
                        'Short Bio Target',
                        dark: darkMode,
                      ),
                    ),
                    const SizedBox(height: 20),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 12,
                      ),
                      decoration: BoxDecoration(
                        color: colors.surfaceInset,
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(color: colors.outline, width: 2),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            darkMode ? Icons.nightlight_round : Icons.wb_sunny,
                            color: colors.accent,
                            size: 28,
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'App Theme',
                                  style: TextStyle(
                                    color: _dialogText(context, dark: darkMode),
                                    fontSize: 17,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                                Text(
                                  darkMode
                                      ? 'Dark Mode Enabled'
                                      : 'Light Mode Enabled',
                                  style: TextStyle(
                                    color: _dialogSecondary(
                                      context,
                                      dark: darkMode,
                                    ),
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Switch.adaptive(
                            value: darkMode,
                            activeThumbColor: colors.accent,
                            onChanged: (value) {
                              // Change the dialog's local state first. The app-level
                              // ThemeMode is applied only after the dialog closes,
                              // preventing MaterialApp/Overlay from being rebuilt
                              // while this dialog is still mounted.
                              setDialogState(() => darkMode = value);
                            },
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                    Row(
                      children: [
                        Icon(
                          Icons.warning_amber_outlined,
                          color: _dialogAccent(context, dark: darkMode),
                          size: 18,
                        ),
                        const SizedBox(width: 5),
                        Expanded(
                          child: Text(
                            'Profile details are stored securely on device.',
                            style: TextStyle(
                              color: _dialogAccent(context, dark: darkMode),
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text(
                  'Cancel',
                  style: TextStyle(
                    color: _dialogAccent(context, dark: darkMode),
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(
                  context,
                  ProfileData(
                    name: nameController.text.trim(),
                    email: emailController.text.trim(),
                    bio: bioController.text.trim(),
                  ),
                ),
                child: const Text('Save Profile'),
              ),
            ],
          );
        },
      ),
    );

    nameController.dispose();
    emailController.dispose();
    bioController.dispose();
    if (mounted && updatedProfile != null) {
      setState(() => _profile = updatedProfile);
      widget.onThemeChanged(darkMode);
    }
  }

  Future<void> _exportXlsx() async {
    final filteredExpenses = _controller.visibleExpenses;

    if (filteredExpenses.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No expenses match the current filters.')),
      );
      return;
    }

    try {
      final bytes = _xlsxExportService.generate(filteredExpenses, _currency);

      final fileName = _buildExportFileName('xlsx');

      final savedName = await _fileDownloadService.saveToDownloads(
        bytes: bytes,
        fileName: fileName,
        mimeType:
            'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            savedName == null
                ? 'XLSX export was not completed.'
                : 'XLSX saved to Downloads: $savedName',
          ),
        ),
      );
    } catch (error) {
      if (!mounted) return;

      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('XLSX export failed: $error')));
    }
  }

  String _buildExportFileName(String extension) {
    final now = DateTime.now();
    String twoDigits(int value) => value.toString().padLeft(2, '0');

    return 'finsify_expenses_'
        '${now.year}-'
        '${twoDigits(now.month)}-'
        '${twoDigits(now.day)}_'
        '${twoDigits(now.hour)}'
        '${twoDigits(now.minute)}'
        '${twoDigits(now.second)}'
        '.$extension';
  }

  Future<void> _showManageTransactionDialog(Expense expense) async {
    final action = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: context.finsifyColors.surfaceRaised,
        title: Text(
          'Manage Transaction Details',
          style: TextStyle(
            color: _dialogText(context),
            fontWeight: FontWeight.w800,
          ),
        ),
        content: Text(
          'Title: ${expense.title}\nCost: $_currency${expense.amount}\nCategory: ${expense.category}',
          style: TextStyle(
            color: _dialogSecondary(context),
            fontSize: 19,
            height: 1.45,
            fontWeight: FontWeight.w700,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, 'delete'),
            child: Text(
              'Delete Item',
              style: TextStyle(
                color: Theme.of(context).colorScheme.error,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Dismiss',
              style: TextStyle(
                color: _dialogAccent(context),
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, 'edit'),
            child: Text(
              'Edit Item',
              style: TextStyle(
                color: _dialogAccent(context),
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
    );

    if (!mounted) return;
    if (action == 'delete') {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          _controller.deleteExpense(expense.id);
        }
      });
    } else if (action == 'edit') {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          _showEditTransactionDialog(expense);
        }
      });
    }
  }

  Future<void> _showEditTransactionDialog(Expense expense) async {
    final amountController = TextEditingController(
      text: expense.amount.toString(),
    );
    final notesController = TextEditingController(text: expense.note);
    var category = expense.category;
    var timestamp = expense.timestamp;

    final updatedExpense = await showDialog<Expense>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          backgroundColor: context.finsifyColors.surfaceRaised,
          title: Text(
            'Edit Transaction',
            style: TextStyle(
              color: _dialogText(context),
              fontWeight: FontWeight.w800,
            ),
          ),
          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: amountController,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  decoration: _dialogInputDecoration(
                    context,
                    'Cost Amount ($_currency)',
                  ),
                ),
                const SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        style: _dialogOutlinedButton(context),
                        onPressed: () async {
                          final selected = await showDatePicker(
                            context: context,
                            initialDate: timestamp,
                            firstDate: DateTime(2000),
                            lastDate: DateTime(2100),
                          );
                          if (selected != null)
                            setDialogState(
                              () => timestamp = DateTime(
                                selected.year,
                                selected.month,
                                selected.day,
                                timestamp.hour,
                                timestamp.minute,
                              ),
                            );
                        },
                        child: Text(_formatEditDate(timestamp)),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: OutlinedButton(
                        style: _dialogOutlinedButton(context),
                        onPressed: () async {
                          final selected = await showTimePicker(
                            context: context,
                            initialTime: TimeOfDay.fromDateTime(timestamp),
                          );
                          if (selected != null)
                            setDialogState(
                              () => timestamp = DateTime(
                                timestamp.year,
                                timestamp.month,
                                timestamp.day,
                                selected.hour,
                                selected.minute,
                              ),
                            );
                        },
                        child: Text(
                          TimeOfDay.fromDateTime(timestamp).format(context),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                Text(
                  'Select Category:',
                  style: TextStyle(
                    color: _dialogSecondary(context),
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: MediaQuery.sizeOf(context).width > 520
                      ? 420
                      : MediaQuery.sizeOf(context).width - 96,
                  height: 52,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    children: expenseCategories
                        .map(
                          (item) => Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: ChoiceChip(
                              label: Text('${_categoryEmoji(item)} $item'),
                              selected: category == item,
                              onSelected: (_) =>
                                  setDialogState(() => category = item),
                              selectedColor: context.finsifyColors.accent,
                              backgroundColor: context.finsifyColors.surface,
                              labelStyle: TextStyle(
                                color: category == item
                                    ? context.finsifyColors.onAccent
                                    : _dialogText(context),
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                        )
                        .toList(),
                  ),
                ),
                const SizedBox(height: 20),
                TextField(
                  controller: notesController,
                  maxLines: 2,
                  decoration: _dialogInputDecoration(
                    context,
                    'Notes (Optional)',
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(
                'Cancel',
                style: TextStyle(
                  color: _dialogAccent(context),
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            FilledButton(
              onPressed: () {
                final amount = double.tryParse(amountController.text.trim());
                if (amount == null) return;
                Navigator.pop(
                  context,
                  expense.copyWith(
                    amount: amount,
                    category: category,
                    timestamp: timestamp,
                    note: notesController.text.trim(),
                  ),
                );
              },
              child: const Text('Save Changes'),
            ),
          ],
        ),
      ),
    );

    amountController.dispose();
    notesController.dispose();

    if (mounted && updatedExpense != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          _controller.updateExpense(updatedExpense);
        }
      });
    }
  }

  String _formatEditDate(DateTime date) {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return '${months[date.month - 1]} ${date.day}, ${date.year}';
  }

  Future<void> _showAddExpenseDialog() async {
    final titleController = TextEditingController();
    final amountController = TextEditingController();
    final noteController = TextEditingController();
    var category = expenseCategories.first;
    final expense = await showDialog<Expense>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          backgroundColor: context.finsifyColors.surfaceRaised,
          insetPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 24,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(32),
          ),
          title: Text(
            'Manual Transaction Ledger',
            style: TextStyle(
              color: _dialogText(context),
              fontWeight: FontWeight.w800,
            ),
          ),
          content: SingleChildScrollView(
            child: SizedBox(
              width: MediaQuery.sizeOf(context).width > 520
                  ? 420
                  : MediaQuery.sizeOf(context).width - 64,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  TextField(
                    controller: titleController,
                    decoration: _dialogInputDecoration(
                      context,
                      'Title (e.g. Electric Bill)',
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: amountController,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    decoration: _dialogInputDecoration(
                      context,
                      'Cost Amount ($_currency)',
                    ),
                  ),
                  const SizedBox(height: 20),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'Select Category:',
                      style: TextStyle(
                        color: _dialogSecondary(context),
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  SizedBox(
                    height: 52,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemCount: expenseCategories.length,
                      separatorBuilder: (_, __) => const SizedBox(width: 8),
                      itemBuilder: (context, index) {
                        final item = expenseCategories[index];
                        final selected = category == item;
                        return ChoiceChip(
                          label: Text(
                            '${_categoryEmoji(item)} $item',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          selected: selected,
                          onSelected: (_) =>
                              setDialogState(() => category = item),
                          selectedColor: context.finsifyColors.accent,
                          backgroundColor: context.finsifyColors.surface,
                          labelStyle: TextStyle(
                            color: selected
                                ? context.finsifyColors.onAccent
                                : _dialogText(context),
                            fontWeight: FontWeight.w800,
                          ),
                          side: BorderSide(
                            color: context.finsifyColors.outline,
                          ),
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 18),
                  TextField(
                    controller: noteController,
                    maxLines: 2,
                    decoration: _dialogInputDecoration(
                      context,
                      'Notes (Optional)',
                    ),
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(
                'Cancel',
                style: TextStyle(
                  color: _dialogAccent(context),
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            FilledButton(
              onPressed: () {
                final amount = double.tryParse(amountController.text.trim());
                if (titleController.text.trim().isEmpty || amount == null)
                  return;
                Navigator.pop(
                  context,
                  Expense(
                    id: DateTime.now().microsecondsSinceEpoch,
                    title: titleController.text.trim(),
                    amount: amount,
                    category: category,
                    timestamp: DateTime.now(),
                    note: noteController.text.trim(),
                  ),
                );
              },
              child: const Text('Save Ledger'),
            ),
          ],
        ),
      ),
    );
    titleController.dispose();
    amountController.dispose();
    noteController.dispose();

    // Wait until the dialog route has finished deactivating before rebuilding
    // the dashboard. Rebuilding immediately after Navigator.pop() can trigger
    // Flutter's InheritedElement '_dependents.isEmpty' assertion in debug mode.
    if (mounted && expense != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          _controller.addExpense(expense);
        }
      });
    }
  }
}
