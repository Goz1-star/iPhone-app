import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'models/app_settings.dart';
import 'models/savings_goal.dart';
import 'services/app_storage.dart';
import 'services/goal_notification_service.dart';
import 'services/income_calculator.dart';
import 'ui/falling_money_animation.dart';
import 'ui/fortune_penguin.dart';
import 'ui/gradient_theme_system.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const FacaiApp());
}

class FacaiApp extends StatelessWidget {
  const FacaiApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '发财',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: GradientThemeSystem.rose,
          brightness: Brightness.light,
        ),
        fontFamily: 'Roboto',
        useMaterial3: true,
      ),
      home: const FacaiHomePage(),
    );
  }
}

class FacaiHomePage extends StatefulWidget {
  const FacaiHomePage({super.key});

  @override
  State<FacaiHomePage> createState() => _FacaiHomePageState();
}

class _FacaiHomePageState extends State<FacaiHomePage>
    with WidgetsBindingObserver {
  final _storage = AppStorage();
  final _notificationService = GoalNotificationService.create();
  Timer? _timer;
  AppSettings? _settings;
  SavingsGoal? _goal;
  IncomeSnapshot? _snapshot;
  DateTime _now = DateTime.now();
  bool _notificationReady = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _bootstrap();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _timer?.cancel();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused || state == AppLifecycleState.inactive) {
      final goal = _goal;
      final settings = _settings;
      if (goal != null) {
        _storage.saveSavingsGoal(goal);
      }
      if (settings != null) {
        _storage.saveSettings(settings);
      }
    }
  }

  Future<void> _bootstrap() async {
    final loadedSettings = await _storage.loadSettings();
    final loadedGoal = await _storage.loadSavingsGoal();
    try {
      await _notificationService.initialize();
      _notificationReady = true;
    } catch (_) {
      _notificationReady = false;
    }
    if (!mounted) {
      return;
    }
    setState(() {
      _settings = loadedSettings;
      _goal = loadedGoal;
      _snapshot = IncomeCalculator.snapshot(loadedSettings, _now);
    });
    _timer = Timer.periodic(const Duration(seconds: 1), (_) => _tick());
  }

  void _tick() {
    final settings = _settings;
    final goal = _goal;
    if (settings == null || goal == null) {
      return;
    }

    final now = DateTime.now();
    final snapshot = IncomeCalculator.snapshot(settings, now);
    final updatedGoal = _goalWithIncome(goal, snapshot, now);

    setState(() {
      _now = now;
      _snapshot = snapshot;
      _goal = updatedGoal;
    });

    if (updatedGoal != goal) {
      _storage.saveSavingsGoal(updatedGoal);
    }
  }

  SavingsGoal _goalWithIncome(
    SavingsGoal goal,
    IncomeSnapshot snapshot,
    DateTime now,
  ) {
    if (!snapshot.isWorkday) {
      return goal;
    }

    final key = _dateKey(now);
    final previousTodayIncome =
        goal.lastIncomeDateKey == key ? goal.lastIncomeForDate : 0.0;
    final incomeDelta = math.max(0.0, snapshot.todayIncome - previousTodayIncome);
    var nextGoal = goal;

    if (incomeDelta >= 0.01) {
      nextGoal = goal.copyWith(
        automaticSavedAmount: goal.automaticSavedAmount + incomeDelta,
        lastIncomeDateKey: key,
        lastIncomeForDate: snapshot.todayIncome,
      );
    }

    if (nextGoal.isReached && !nextGoal.reachedNotificationSent) {
      if (_notificationReady) {
        _notificationService.showGoalReached(nextGoal.name);
      }
      nextGoal = nextGoal.copyWith(reachedNotificationSent: true);
    }

    return nextGoal;
  }

  String _dateKey(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-'
        '${date.day.toString().padLeft(2, '0')}';
  }

  Future<void> _saveSettings(AppSettings settings) async {
    setState(() {
      _settings = settings;
      _snapshot = IncomeCalculator.snapshot(settings, DateTime.now());
    });
    await _storage.saveSettings(settings);
  }

  Future<void> _saveGoal(SavingsGoal goal) async {
    setState(() => _goal = goal);
    await _storage.saveSavingsGoal(goal);
  }

  @override
  Widget build(BuildContext context) {
    final settings = _settings;
    final goal = _goal;
    final snapshot = _snapshot;

    if (settings == null || goal == null || snapshot == null) {
      return const Scaffold(
        body: DecoratedBox(
          decoration: BoxDecoration(gradient: GradientThemeSystem.background),
          child: Center(child: CircularProgressIndicator(color: Colors.white)),
        ),
      );
    }

    if (!settings.onboardingCompleted) {
      return OnboardingFlow(
        settings: settings,
        goal: goal,
        onFinish: (nextSettings, nextGoal) async {
          await _saveSettings(nextSettings.copyWith(onboardingCompleted: true));
          await _saveGoal(nextGoal);
        },
      );
    }

    return Scaffold(
      body: Stack(
        children: [
          const _GradientStage(),
          FallingMoneyAnimation(enabled: settings.moneyRainEnabled),
          SafeArea(
            child: CustomScrollView(
              slivers: [
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
                  sliver: SliverList(
                    delegate: SliverChildListDelegate([
                      _TopBar(
                        moneyRainEnabled: settings.moneyRainEnabled,
                        onSettings: () => _openSettings(settings, goal),
                        onToggleMoneyRain: () => _saveSettings(
                          settings.copyWith(
                            moneyRainEnabled: !settings.moneyRainEnabled,
                          ),
                        ),
                      ),
                      const SizedBox(height: 22),
                      _HeroIncomeCard(
                        snapshot: snapshot,
                        now: _now,
                        isTodayWorkday: settings.isWorkday(_now),
                        onToggleWorkday: (value) => _saveSettings(
                          settings.copyWith(todayWorkOverride: value),
                        ),
                      ),
                      const SizedBox(height: 16),
                      _SavingsGoalCard(
                        goal: goal,
                        onEdit: () => _openGoalEditor(goal),
                      ),
                      const SizedBox(height: 16),
                      _PayModeCard(
                        settings: settings,
                        onChanged: _saveSettings,
                      ),
                      const SizedBox(height: 18),
                      Center(
                        child: Text(
                          '老板正在给你打钱，企鹅财神已上线护航。',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.86),
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ]),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _openSettings(AppSettings settings, SavingsGoal goal) async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => SettingsSheet(
        settings: settings,
        onSave: (next) async {
          Navigator.of(context).pop();
          await _saveSettings(next);
        },
      ),
    );
  }

  Future<void> _openGoalEditor(SavingsGoal goal) async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => GoalEditorSheet(
        goal: goal,
        onSave: (next) async {
          Navigator.of(context).pop();
          await _saveGoal(next);
        },
      ),
    );
  }
}

class _GradientStage extends StatelessWidget {
  const _GradientStage();

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: DecoratedBox(
        decoration: const BoxDecoration(gradient: GradientThemeSystem.background),
        child: Stack(
          children: [
            Positioned(
              top: -90,
              right: -70,
              child: _Glow(size: 230, color: Colors.white.withOpacity(0.36)),
            ),
            Positioned(
              bottom: 120,
              left: -100,
              child: _Glow(
                size: 260,
                color: const Color(0xFFFFEC80).withOpacity(0.24),
              ),
            ),
            const _NoiseOverlay(),
          ],
        ),
      ),
    );
  }
}

class _Glow extends StatelessWidget {
  const _Glow({required this.size, required this.color});

  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(
          colors: [color, color.withOpacity(0)],
        ),
      ),
    );
  }
}

class _NoiseOverlay extends StatelessWidget {
  const _NoiseOverlay();

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: IgnorePointer(
        child: Opacity(
          opacity: 0.055,
          child: CustomPaint(
            painter: _NoisePainter(),
          ),
        ),
      ),
    );
  }
}

class _NoisePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = Colors.white;
    for (var x = 0.0; x < size.width; x += 8) {
      for (var y = 0.0; y < size.height; y += 8) {
        if (((x * 31 + y * 17).round() % 5) == 0) {
          canvas.drawCircle(Offset(x, y), 0.7, paint);
        }
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _TopBar extends StatelessWidget {
  const _TopBar({
    required this.moneyRainEnabled,
    required this.onSettings,
    required this.onToggleMoneyRain,
  });

  final bool moneyRainEnabled;
  final VoidCallback onSettings;
  final VoidCallback onToggleMoneyRain;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '发财',
                style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                      color: Colors.white,
                      fontSize: 36,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 0,
                    ),
              ),
              Text(
                '打工人的实时暴富仪表盘',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.82),
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
        IconButton.filledTonal(
          tooltip: moneyRainEnabled ? '关闭金币雨' : '开启金币雨',
          onPressed: onToggleMoneyRain,
          icon: Icon(moneyRainEnabled ? Icons.motion_photos_on : Icons.motion_photos_off),
        ),
        const SizedBox(width: 8),
        IconButton.filled(
          tooltip: '设置',
          onPressed: onSettings,
          icon: const Icon(Icons.tune),
        ),
      ],
    );
  }
}

class _HeroIncomeCard extends StatelessWidget {
  const _HeroIncomeCard({
    required this.snapshot,
    required this.now,
    required this.isTodayWorkday,
    required this.onToggleWorkday,
  });

  final IncomeSnapshot snapshot;
  final DateTime now;
  final bool isTodayWorkday;
  final ValueChanged<bool> onToggleWorkday;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: GradientThemeSystem.glassCard(radius: 32),
      padding: const EdgeInsets.fromLTRB(22, 18, 22, 22),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Expanded(
                child: Text(
                  '今日已入账',
                  style: TextStyle(
                    color: GradientThemeSystem.ink,
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              const FortunePenguin(size: 118),
            ],
          ),
          FittedBox(
            alignment: Alignment.centerLeft,
            fit: BoxFit.scaleDown,
            child: Text(
              _currency(snapshot.todayIncome),
              style: const TextStyle(
                color: GradientThemeSystem.ink,
                fontSize: 58,
                fontWeight: FontWeight.w900,
                letterSpacing: 0,
              ),
            ),
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.74),
              borderRadius: BorderRadius.circular(18),
            ),
            child: Row(
              children: [
                const Icon(Icons.timer_rounded, color: GradientThemeSystem.rose),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    snapshot.isWorkday ? '距离下班 ${snapshot.countdownLabel}' : snapshot.countdownLabel,
                    style: const TextStyle(
                      color: GradientThemeSystem.ink,
                      fontSize: 17,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: _MiniStat(
                  label: '今日日薪',
                  value: _currency(snapshot.dailySalary),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _MiniStat(
                  label: '打钱状态',
                  value: snapshot.isWorkingNow ? '正在暴富' : '暂未开工',
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text(
              '今天上班',
              style: TextStyle(fontWeight: FontWeight.w900),
            ),
            subtitle: Text(
              '${now.month}月${now.day}日可临时切换，企鹅财神会记住',
            ),
            value: isTodayWorkday,
            onChanged: onToggleWorkday,
          ),
        ],
      ),
    );
  }
}

class _MiniStat extends StatelessWidget {
  const _MiniStat({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.66),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: TextStyle(color: Colors.black.withOpacity(0.55))),
          const SizedBox(height: 6),
          FittedBox(
            alignment: Alignment.centerLeft,
            fit: BoxFit.scaleDown,
            child: Text(
              value,
              style: const TextStyle(
                color: GradientThemeSystem.ink,
                fontSize: 18,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SavingsGoalCard extends StatelessWidget {
  const _SavingsGoalCard({required this.goal, required this.onEdit});

  final SavingsGoal goal;
  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: GradientThemeSystem.glassCard(radius: 26),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.savings_rounded, color: GradientThemeSystem.rose),
              const SizedBox(width: 8),
              const Expanded(
                child: Text(
                  '当前存钱目标',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                    color: GradientThemeSystem.ink,
                  ),
                ),
              ),
              TextButton.icon(
                onPressed: onEdit,
                icon: const Icon(Icons.edit_rounded),
                label: const Text('编辑'),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            goal.name,
            style: const TextStyle(
              color: GradientThemeSystem.ink,
              fontSize: 26,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              minHeight: 14,
              value: goal.progress,
              backgroundColor: const Color(0xFFFFDFBE),
              valueColor: const AlwaysStoppedAnimation(GradientThemeSystem.rose),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            '已攒 ${_currency(goal.savedAmount)} / 目标 ${_currency(goal.targetAmount)}，还差 ${_currency(goal.remainingAmount)}',
            style: TextStyle(
              color: GradientThemeSystem.ink.withOpacity(0.72),
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _PayModeCard extends StatelessWidget {
  const _PayModeCard({required this.settings, required this.onChanged});

  final AppSettings settings;
  final ValueChanged<AppSettings> onChanged;

  @override
  Widget build(BuildContext context) {
    final daily = IncomeCalculator.dailySalary(settings);
    final monthly = IncomeCalculator.monthlySalary(settings);
    return Container(
      decoration: GradientThemeSystem.glassCard(radius: 26),
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '薪资切换栏',
            style: TextStyle(
              color: GradientThemeSystem.ink,
              fontSize: 18,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 12),
          SegmentedButton<SalaryMode>(
            segments: const [
              ButtonSegment(
                value: SalaryMode.monthly,
                icon: Icon(Icons.calendar_month_rounded),
                label: Text('月薪'),
              ),
              ButtonSegment(
                value: SalaryMode.daily,
                icon: Icon(Icons.today_rounded),
                label: Text('日薪'),
              ),
            ],
            selected: {settings.salaryMode},
            onSelectionChanged: (selection) {
              onChanged(settings.copyWith(salaryMode: selection.first));
            },
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(child: _MiniStat(label: '月薪估算', value: _currency(monthly))),
              const SizedBox(width: 10),
              Expanded(child: _MiniStat(label: '日薪估算', value: _currency(daily))),
            ],
          ),
        ],
      ),
    );
  }
}

class SettingsSheet extends StatefulWidget {
  const SettingsSheet({
    super.key,
    required this.settings,
    required this.onSave,
  });

  final AppSettings settings;
  final ValueChanged<AppSettings> onSave;

  @override
  State<SettingsSheet> createState() => _SettingsSheetState();
}

class _SettingsSheetState extends State<SettingsSheet> {
  late AppSettings _draft;
  late final TextEditingController _monthly;
  late final TextEditingController _daily;
  late final TextEditingController _workdays;

  @override
  void initState() {
    super.initState();
    _draft = widget.settings;
    _monthly = TextEditingController(text: _draft.monthlySalary.toStringAsFixed(0));
    _daily = TextEditingController(text: _draft.dailySalary.toStringAsFixed(0));
    _workdays = TextEditingController(text: _draft.monthlyWorkdays.toString());
  }

  @override
  void dispose() {
    _monthly.dispose();
    _daily.dispose();
    _workdays.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.of(context).viewInsets.bottom;
    return Padding(
      padding: EdgeInsets.only(bottom: bottom),
      child: Container(
        decoration: const BoxDecoration(
          color: Color(0xFFFFFCF5),
          borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
        ),
        padding: const EdgeInsets.fromLTRB(20, 18, 20, 24),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const _SheetHandle(),
              const Text(
                '发财设置',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900),
              ),
              const SizedBox(height: 16),
              SegmentedButton<SalaryMode>(
                selected: {_draft.salaryMode},
                segments: const [
                  ButtonSegment(value: SalaryMode.monthly, label: Text('月薪')),
                  ButtonSegment(value: SalaryMode.daily, label: Text('日薪')),
                ],
                onSelectionChanged: (selection) {
                  setState(() => _draft = _draft.copyWith(salaryMode: selection.first));
                },
              ),
              const SizedBox(height: 14),
              _MoneyField(label: '月薪', controller: _monthly),
              const SizedBox(height: 10),
              _MoneyField(label: '日薪', controller: _daily),
              const SizedBox(height: 10),
              TextField(
                controller: _workdays,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: '每月工作日',
                  prefixIcon: Icon(Icons.work_history_rounded),
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 18),
              Row(
                children: [
                  Expanded(
                    child: _TimeButton(
                      label: '上班',
                      hour: _draft.workStartHour,
                      minute: _draft.workStartMinute,
                      onPick: (time) {
                        setState(() {
                          _draft = _draft.copyWith(
                            workStartHour: time.hour,
                            workStartMinute: time.minute,
                          );
                        });
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _TimeButton(
                      label: '下班',
                      hour: _draft.workEndHour,
                      minute: _draft.workEndMinute,
                      onPick: (time) {
                        setState(() {
                          _draft = _draft.copyWith(
                            workEndHour: time.hour,
                            workEndMinute: time.minute,
                          );
                        });
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              const Text('常规上班日', style: TextStyle(fontWeight: FontWeight.w900)),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                children: [
                  for (final day in const [
                    DateTime.monday,
                    DateTime.tuesday,
                    DateTime.wednesday,
                    DateTime.thursday,
                    DateTime.friday,
                    DateTime.saturday,
                    DateTime.sunday,
                  ])
                    FilterChip(
                      label: Text(_weekdayLabel(day)),
                      selected: _draft.regularWorkdays.contains(day),
                      onSelected: (selected) {
                        final next = {..._draft.regularWorkdays};
                        selected ? next.add(day) : next.remove(day);
                        setState(() => _draft = _draft.copyWith(regularWorkdays: next));
                      },
                    ),
                ],
              ),
              const SizedBox(height: 20),
              _GradientButton(
                label: '保存发财配置',
                icon: Icons.save_rounded,
                onPressed: () {
                  widget.onSave(
                    _draft.copyWith(
                      monthlySalary: _doubleFrom(_monthly, _draft.monthlySalary),
                      dailySalary: _doubleFrom(_daily, _draft.dailySalary),
                      monthlyWorkdays: _intFrom(_workdays, _draft.monthlyWorkdays),
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class GoalEditorSheet extends StatefulWidget {
  const GoalEditorSheet({
    super.key,
    required this.goal,
    required this.onSave,
  });

  final SavingsGoal goal;
  final ValueChanged<SavingsGoal> onSave;

  @override
  State<GoalEditorSheet> createState() => _GoalEditorSheetState();
}

class _GoalEditorSheetState extends State<GoalEditorSheet> {
  late final TextEditingController _name;
  late final TextEditingController _target;
  late final TextEditingController _manual;

  @override
  void initState() {
    super.initState();
    _name = TextEditingController(text: widget.goal.name);
    _target = TextEditingController(text: widget.goal.targetAmount.toStringAsFixed(0));
    _manual = TextEditingController(
      text: widget.goal.manualAdjustmentAmount.toStringAsFixed(0),
    );
  }

  @override
  void dispose() {
    _name.dispose();
    _target.dispose();
    _manual.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.of(context).viewInsets.bottom;
    return Padding(
      padding: EdgeInsets.only(bottom: bottom),
      child: Container(
        decoration: const BoxDecoration(
          color: Color(0xFFFFFCF5),
          borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
        ),
        padding: const EdgeInsets.fromLTRB(20, 18, 20, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const _SheetHandle(),
            const Align(
              alignment: Alignment.centerLeft,
              child: Text(
                '目标存钱',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _name,
              decoration: const InputDecoration(
                labelText: '目标名称',
                prefixIcon: Icon(Icons.flag_rounded),
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 10),
            _MoneyField(label: '目标金额', controller: _target),
            const SizedBox(height: 10),
            _MoneyField(label: '手动修正金额', controller: _manual),
            const SizedBox(height: 18),
            _GradientButton(
              label: '保存目标',
              icon: Icons.savings_rounded,
              onPressed: () {
                widget.onSave(
                  widget.goal.copyWith(
                    name: _name.text.trim().isEmpty ? '发财基金' : _name.text.trim(),
                    targetAmount: _doubleFrom(_target, widget.goal.targetAmount),
                    manualAdjustmentAmount:
                        _doubleFrom(_manual, widget.goal.manualAdjustmentAmount),
                    reachedNotificationSent: false,
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class OnboardingFlow extends StatefulWidget {
  const OnboardingFlow({
    super.key,
    required this.settings,
    required this.goal,
    required this.onFinish,
  });

  final AppSettings settings;
  final SavingsGoal goal;
  final void Function(AppSettings settings, SavingsGoal goal) onFinish;

  @override
  State<OnboardingFlow> createState() => _OnboardingFlowState();
}

class _OnboardingFlowState extends State<OnboardingFlow> {
  final _page = PageController();
  late AppSettings _settings;
  late SavingsGoal _goal;
  late final TextEditingController _salary;
  late final TextEditingController _workdays;
  late final TextEditingController _goalName;
  late final TextEditingController _goalTarget;
  int _index = 0;

  @override
  void initState() {
    super.initState();
    _settings = widget.settings;
    _goal = widget.goal;
    _salary = TextEditingController(text: _settings.monthlySalary.toStringAsFixed(0));
    _workdays = TextEditingController(text: _settings.monthlyWorkdays.toString());
    _goalName = TextEditingController(text: _goal.name);
    _goalTarget = TextEditingController(text: _goal.targetAmount.toStringAsFixed(0));
  }

  @override
  void dispose() {
    _page.dispose();
    _salary.dispose();
    _workdays.dispose();
    _goalName.dispose();
    _goalTarget.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          const _GradientStage(),
          FallingMoneyAnimation(enabled: true),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Text(
                        '发财启动',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 32,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const Spacer(),
                      TextButton(
                        onPressed: _finish,
                        child: const Text(
                          '跳过',
                          style: TextStyle(color: Colors.white),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),
                  Expanded(
                    child: Container(
                      decoration: GradientThemeSystem.glassCard(radius: 32),
                      padding: const EdgeInsets.all(22),
                      child: PageView(
                        controller: _page,
                        onPageChanged: (value) => setState(() => _index = value),
                        children: [
                          _OnboardingPage(
                            title: '先告诉企鹅财神你的薪资',
                            child: Column(
                              children: [
                                SegmentedButton<SalaryMode>(
                                  selected: {_settings.salaryMode},
                                  segments: const [
                                    ButtonSegment(
                                      value: SalaryMode.monthly,
                                      label: Text('月薪'),
                                    ),
                                    ButtonSegment(
                                      value: SalaryMode.daily,
                                      label: Text('日薪'),
                                    ),
                                  ],
                                  onSelectionChanged: (selection) {
                                    setState(() {
                                      _settings = _settings.copyWith(
                                        salaryMode: selection.first,
                                      );
                                    });
                                  },
                                ),
                                const SizedBox(height: 16),
                                _MoneyField(label: '薪资金额', controller: _salary),
                              ],
                            ),
                          ),
                          _OnboardingPage(
                            title: '设置你的打工时间',
                            child: Column(
                              children: [
                                TextField(
                                  controller: _workdays,
                                  keyboardType: TextInputType.number,
                                  decoration: const InputDecoration(
                                    labelText: '每月工作日',
                                    border: OutlineInputBorder(),
                                  ),
                                ),
                                const SizedBox(height: 16),
                                Row(
                                  children: [
                                    Expanded(
                                      child: _TimeButton(
                                        label: '上班',
                                        hour: _settings.workStartHour,
                                        minute: _settings.workStartMinute,
                                        onPick: (time) {
                                          setState(() {
                                            _settings = _settings.copyWith(
                                              workStartHour: time.hour,
                                              workStartMinute: time.minute,
                                            );
                                          });
                                        },
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: _TimeButton(
                                        label: '下班',
                                        hour: _settings.workEndHour,
                                        minute: _settings.workEndMinute,
                                        onPick: (time) {
                                          setState(() {
                                            _settings = _settings.copyWith(
                                              workEndHour: time.hour,
                                              workEndMinute: time.minute,
                                            );
                                          });
                                        },
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          _OnboardingPage(
                            title: '再设一个暴富目标',
                            child: Column(
                              children: [
                                TextField(
                                  controller: _goalName,
                                  decoration: const InputDecoration(
                                    labelText: '目标名称',
                                    border: OutlineInputBorder(),
                                  ),
                                ),
                                const SizedBox(height: 12),
                                _MoneyField(label: '目标金额', controller: _goalTarget),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 18),
                  Row(
                    children: [
                      Text(
                        '${_index + 1}/3',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const Spacer(),
                      _GradientButton(
                        label: _index == 2 ? '开始发财' : '下一步',
                        icon: _index == 2
                            ? Icons.rocket_launch_rounded
                            : Icons.arrow_forward_rounded,
                        onPressed: () {
                          _persistDraft();
                          if (_index == 2) {
                            _finish();
                          } else {
                            _page.nextPage(
                              duration: const Duration(milliseconds: 260),
                              curve: Curves.easeOutCubic,
                            );
                          }
                        },
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
  }

  void _persistDraft() {
    final salary = _doubleFrom(_salary, _settings.monthlySalary);
    final workdays = _intFrom(_workdays, _settings.monthlyWorkdays);
    _settings = _settings.copyWith(
      monthlyWorkdays: workdays,
      monthlySalary:
          _settings.salaryMode == SalaryMode.monthly ? salary : _settings.monthlySalary,
      dailySalary:
          _settings.salaryMode == SalaryMode.daily ? salary : _settings.dailySalary,
    );
    _goal = _goal.copyWith(
      name: _goalName.text.trim().isEmpty ? _goal.name : _goalName.text.trim(),
      targetAmount: _doubleFrom(_goalTarget, _goal.targetAmount),
    );
  }

  void _finish() {
    _persistDraft();
    widget.onFinish(_settings, _goal);
  }
}

class _OnboardingPage extends StatelessWidget {
  const _OnboardingPage({required this.title, required this.child});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Center(child: FortunePenguin(size: 132)),
        const SizedBox(height: 16),
        Text(
          title,
          style: const TextStyle(
            color: GradientThemeSystem.ink,
            fontSize: 25,
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: 20),
        child,
      ],
    );
  }
}

class _TimeButton extends StatelessWidget {
  const _TimeButton({
    required this.label,
    required this.hour,
    required this.minute,
    required this.onPick,
  });

  final String label;
  final int hour;
  final int minute;
  final ValueChanged<TimeOfDay> onPick;

  @override
  Widget build(BuildContext context) {
    return OutlinedButton.icon(
      onPressed: () async {
        final picked = await showTimePicker(
          context: context,
          initialTime: TimeOfDay(hour: hour, minute: minute),
        );
        if (picked != null) {
          onPick(picked);
        }
      },
      icon: const Icon(Icons.schedule_rounded),
      label: Text('$label ${hour.toString().padLeft(2, '0')}:'
          '${minute.toString().padLeft(2, '0')}'),
    );
  }
}

class _MoneyField extends StatelessWidget {
  const _MoneyField({required this.label, required this.controller});

  final String label;
  final TextEditingController controller;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: const Icon(Icons.payments_rounded),
        prefixText: '¥ ',
        border: const OutlineInputBorder(),
      ),
    );
  }
}

class _GradientButton extends StatelessWidget {
  const _GradientButton({
    required this.label,
    required this.icon,
    required this.onPressed,
  });

  final String label;
  final IconData icon;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: GradientThemeSystem.actionGradient,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: GradientThemeSystem.rose.withOpacity(0.24),
            blurRadius: 18,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: ElevatedButton.icon(
        style: ElevatedButton.styleFrom(
          elevation: 0,
          foregroundColor: Colors.white,
          backgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        ),
        onPressed: onPressed,
        icon: Icon(icon),
        label: Text(label, style: const TextStyle(fontWeight: FontWeight.w900)),
      ),
    );
  }
}

class _SheetHandle extends StatelessWidget {
  const _SheetHandle();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        width: 44,
        height: 5,
        margin: const EdgeInsets.only(bottom: 18),
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.18),
          borderRadius: BorderRadius.circular(999),
        ),
      ),
    );
  }
}

double _doubleFrom(TextEditingController controller, double fallback) {
  return double.tryParse(controller.text.replaceAll(',', '').trim()) ?? fallback;
}

int _intFrom(TextEditingController controller, int fallback) {
  return int.tryParse(controller.text.trim()) ?? fallback;
}

String _currency(double value) {
  return '¥${value.toStringAsFixed(2)}';
}

String _weekdayLabel(int day) {
  return const {
        DateTime.monday: '周一',
        DateTime.tuesday: '周二',
        DateTime.wednesday: '周三',
        DateTime.thursday: '周四',
        DateTime.friday: '周五',
        DateTime.saturday: '周六',
        DateTime.sunday: '周日',
      }[day] ??
      '未知';
}
