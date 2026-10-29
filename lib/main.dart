import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'notification_service.dart';

const _supabaseUrl = 'https://sofioxoobxwnaeicaaow.supabase.co';
const _supabaseAnonKey = 'sb_publishable_cQS4U6DOuhNXe2OZTMMHMw_sDfITmGd';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  String? startupError;
  try {
    await Supabase.initialize(
      url: _supabaseUrl,
      anonKey: _supabaseAnonKey,
    );
    if (Supabase.instance.client.auth.currentSession == null) {
      await Supabase.instance.client.auth.signInAnonymously();
    }
  } catch (error) {
    startupError = 'Supabase connection failed: $error';
  }
  runApp(LifeAssistantApp(startupError: startupError));
}

class LifeAssistantApp extends StatelessWidget {
  const LifeAssistantApp({super.key, this.startupError});

  final String? startupError;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Dayflow',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.light,
        colorScheme: const ColorScheme.light(
          primary: Color(0xFF4055C8),
          onPrimary: Colors.white,
          secondary: Color(0xFFB36B3C),
          surface: Color(0xFFF7F8FC),
          onSurface: Color(0xFF202638),
        ),
        scaffoldBackgroundColor: const Color(0xFFF7F8FC),
        cardTheme: CardThemeData(
          color: Colors.white,
          elevation: 0,
          margin: EdgeInsets.zero,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(18)),
            side: BorderSide(color: Color(0xFFE6E8F0)),
          ),
        ),
        navigationBarTheme: const NavigationBarThemeData(
          height: 72,
          backgroundColor: Colors.white,
          indicatorColor: Color(0xFFE9ECFF),
          labelTextStyle: WidgetStatePropertyAll(
            TextStyle(fontSize: 11, fontWeight: FontWeight.w700),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: const Color(0xFFF7F8FC),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide.none,
          ),
        ),
        useMaterial3: true,
      ),
      home: _StartupGate(startupError: startupError),
    );
  }
}

class _StartupGate extends StatefulWidget {
  const _StartupGate({this.startupError});

  final String? startupError;

  @override
  State<_StartupGate> createState() => _StartupGateState();
}

class _StartupGateState extends State<_StartupGate>
    with SingleTickerProviderStateMixin {
  late final AnimationController _animationController;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1100),
    )..forward();
    Future<void>.delayed(const Duration(milliseconds: 1500), () {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_animationController.isCompleted) {
      return AppShell(startupError: widget.startupError);
    }
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF5367F5), Color(0xFF7869E9)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Center(
          child: FadeTransition(
            opacity: CurvedAnimation(
              parent: _animationController,
              curve: Curves.easeIn,
            ),
            child: ScaleTransition(
              scale: Tween<double>(begin: .82, end: 1).animate(
                CurvedAnimation(
                  parent: _animationController,
                  curve: Curves.easeOutBack,
                ),
              ),
              child: const Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircleAvatar(
                    radius: 42,
                    backgroundColor: Colors.white,
                    child: Icon(Icons.auto_awesome_rounded,
                        size: 42, color: Color(0xFF5367F5)),
                  ),
                  SizedBox(height: 20),
                  Text('Dayflow',
                      style: TextStyle(
                          color: Colors.white,
                          fontSize: 32,
                          fontWeight: FontWeight.w800)),
                  SizedBox(height: 7),
                  Text('Plan your days. Build better habits.',
                      style: TextStyle(color: Color(0xFFDCE1FF), fontSize: 14)),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class TaskItem {
  TaskItem(this.title, this.area,
      {this.id, this.done = false, this.priority = 'Medium'});

  final String? id;
  final String title;
  final String area;
  bool done;
  final String priority;
}

class GroceryItem {
  GroceryItem(this.name, this.category,
      {this.bought = false,
      this.quantity = 1,
      this.minimumQuantity = 1,
      this.price = 0,
      DateTime? purchasedAt,
      DateTime? expiresAt})
      : purchasedAt = purchasedAt ?? DateTime.now(),
        expiresAt = expiresAt ?? DateTime.now().add(const Duration(days: 7));

  final String name;
  final String category;
  bool bought;
  double quantity;
  double minimumQuantity;
  double price;
  DateTime purchasedAt;
  DateTime expiresAt;

  bool get isLow => quantity <= minimumQuantity;
  bool get isExpired => expiresAt.isBefore(DateTime.now());

  Map<String, dynamic> toJson() => {
        'name': name,
        'category': category,
        'bought': bought,
        'quantity': quantity,
        'minimumQuantity': minimumQuantity,
        'price': price,
        'purchasedAt': purchasedAt.toIso8601String(),
        'expiresAt': expiresAt.toIso8601String(),
      };

  factory GroceryItem.fromJson(Map<String, dynamic> json) => GroceryItem(
        json['name'] as String,
        json['category'] as String,
        bought: json['bought'] as bool? ?? false,
        quantity: (json['quantity'] as num?)?.toDouble() ?? 1,
        minimumQuantity: (json['minimumQuantity'] as num?)?.toDouble() ?? 1,
        price: (json['price'] as num?)?.toDouble() ?? 0,
        purchasedAt: DateTime.tryParse(json['purchasedAt'] as String? ?? ''),
        expiresAt: DateTime.tryParse(json['expiresAt'] as String? ?? ''),
      );
}

class MonthlyItem {
  MonthlyItem(this.name, this.category, this.daysUntilDue,
      {this.quantity = 1, this.price = 0});

  String name;
  String category;
  int daysUntilDue;
  double quantity;
  double price;

  Map<String, dynamic> toJson() => {
        'name': name,
        'category': category,
        'daysUntilDue': daysUntilDue,
        'quantity': quantity,
        'price': price,
      };

  factory MonthlyItem.fromJson(Map<String, dynamic> json) => MonthlyItem(
        json['name'] as String? ?? 'Purchase',
        json['category'] as String? ?? 'Other',
        (json['daysUntilDue'] as num?)?.toInt() ?? 30,
        quantity: (json['quantity'] as num?)?.toDouble() ?? 1,
        price: (json['price'] as num?)?.toDouble() ?? 0,
      );
}

class ChallengeItem {
  ChallengeItem(this.title, this.subtitle, this.color,
      {int totalDays = 30, DateTime? startDate})
      : startDate = _dateOnly(startDate ?? DateTime.now()),
        days = List<bool>.filled(totalDays, false);

  final String title;
  final String subtitle;
  final Color color;
  final DateTime startDate;
  final List<bool> days;
  final Set<int> restDays = <int>{};
  bool expanded = false;
  int get totalDays => days.length;

  Map<String, dynamic> toJson() => {
        'title': title,
        'subtitle': subtitle,
        'color': color.value,
        'startDate': startDate.toIso8601String(),
        'days': days,
        'restDays': restDays.toList(),
      };

  factory ChallengeItem.fromJson(Map<String, dynamic> json) {
    final savedDays = (json['days'] as List<dynamic>? ?? [])
        .map((day) => day as bool)
        .toList();
    final challenge = ChallengeItem(
      json['title'] as String? ?? 'Challenge',
      json['subtitle'] as String? ?? 'Complete it daily',
      Color((json['color'] as num?)?.toInt() ?? 0xFF5367F5),
      totalDays: savedDays.isEmpty ? 1 : savedDays.length,
      startDate: DateTime.tryParse(json['startDate'] as String? ?? ''),
    );
    challenge.days
      ..clear()
      ..addAll(savedDays.isEmpty ? [false] : savedDays);
    challenge.restDays.addAll((json['restDays'] as List<dynamic>? ?? [])
        .map((day) => (day as num).toInt()));
    return challenge;
  }
}

DateTime _dateOnly(DateTime date) => DateTime(date.year, date.month, date.day);

String _dayLabel(DateTime date) {
  const weekdays = [
    'MONDAY',
    'TUESDAY',
    'WEDNESDAY',
    'THURSDAY',
    'FRIDAY',
    'SATURDAY',
    'SUNDAY',
  ];
  const months = [
    'JANUARY',
    'FEBRUARY',
    'MARCH',
    'APRIL',
    'MAY',
    'JUNE',
    'JULY',
    'AUGUST',
    'SEPTEMBER',
    'OCTOBER',
    'NOVEMBER',
    'DECEMBER',
  ];
  return '${weekdays[date.weekday - 1]}, ${months[date.month - 1]} ${date.day}';
}

class WorkoutLog {
  WorkoutLog(this.title, this.date);

  final String title;
  final DateTime date;

  Map<String, dynamic> toJson() => {
        'title': title,
        'date': date.toIso8601String(),
      };

  factory WorkoutLog.fromJson(Map<String, dynamic> json) => WorkoutLog(
        json['title'] as String? ?? 'Workout',
        DateTime.tryParse(json['date'] as String? ?? '') ?? DateTime.now(),
      );
}

class ProfileData {
  ProfileData({
    this.name = 'Harinjiva',
    this.email = '',
    this.goal = 'Build healthy habits',
    this.targetMass = 70,
    this.currency = 'MUR',
  });

  String name;
  String email;
  String goal;
  double targetMass;
  String currency;
  final List<MassEntry> massEntries = [];

  Map<String, dynamic> toJson() => {
        'name': name,
        'email': email,
        'goal': goal,
        'targetMass': targetMass,
        'currency': currency,
        'massEntries': massEntries.map((entry) => entry.toJson()).toList(),
      };

  factory ProfileData.fromJson(Map<String, dynamic> json) {
    final profile = ProfileData(
      name: json['name'] as String? ?? 'Harinjiva',
      email: json['email'] as String? ?? '',
      goal: json['goal'] as String? ?? 'Build healthy habits',
      targetMass: (json['targetMass'] as num?)?.toDouble() ?? 70,
      currency: json['currency'] as String? ?? 'MUR',
    );
    final entries = json['massEntries'] as List<dynamic>? ?? [];
    profile.massEntries.addAll(entries
        .map((entry) => MassEntry.fromJson(entry as Map<String, dynamic>)));
    return profile;
  }
}

class MassEntry {
  MassEntry(this.date, this.mass);

  final DateTime date;
  final double mass;

  Map<String, dynamic> toJson() =>
      {'date': date.toIso8601String(), 'mass': mass};

  factory MassEntry.fromJson(Map<String, dynamic> json) => MassEntry(
        DateTime.tryParse(json['date'] as String? ?? '') ?? DateTime.now(),
        (json['mass'] as num?)?.toDouble() ?? 0,
      );
}

class PlannerDeadline {
  PlannerDeadline(this.title, this.date);

  final String title;
  final DateTime date;

  Map<String, dynamic> toJson() =>
      {'title': title, 'date': date.toIso8601String()};

  factory PlannerDeadline.fromJson(Map<String, dynamic> json) =>
      PlannerDeadline(
        json['title'] as String? ?? 'Untitled deadline',
        DateTime.tryParse(json['date'] as String? ?? '') ?? DateTime.now(),
      );
}

class TimetableEntry {
  TimetableEntry(this.title, this.day, this.start, this.end);

  final String title;
  final int day;
  final TimeOfDay start;
  final TimeOfDay end;

  Map<String, dynamic> toJson() => {
        'title': title,
        'day': day,
        'start': start.hour * 60 + start.minute,
        'end': end.hour * 60 + end.minute,
      };

  factory TimetableEntry.fromJson(Map<String, dynamic> json) {
    final start = json['start'] as int? ?? 540;
    final end = json['end'] as int? ?? 600;
    return TimetableEntry(
      json['title'] as String? ?? 'Class',
      json['day'] as int? ?? 1,
      TimeOfDay(hour: start ~/ 60, minute: start % 60),
      TimeOfDay(hour: end ~/ 60, minute: end % 60),
    );
  }
}

class _ConnectionBanner extends StatelessWidget {
  const _ConnectionBanner({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: const Color(0xFFFFF3E6),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
        child: Row(
          children: [
            const Icon(Icons.cloud_off_rounded,
                color: Color(0xFFB36B3C), size: 18),
            const SizedBox(width: 9),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(
                  color: Color(0xFF754B2F),
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class AppShell extends StatefulWidget {
  const AppShell({super.key, this.startupError});

  final String? startupError;

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  final _taskService = TaskService(Supabase.instance.client);
  int _selectedIndex = 0;
  final List<TaskItem> _tasks = [];
  final List<GroceryItem> _groceries = [
    GroceryItem('Chicken breast', 'Protein'),
    GroceryItem('Eggs', 'Protein'),
    GroceryItem('Rice', 'Pantry'),
    GroceryItem('Broccoli', 'Vegetables', bought: true),
    GroceryItem('Tomatoes', 'Vegetables'),
    GroceryItem('Milk', 'Dairy', bought: true),
  ];
  final List<MonthlyItem> _monthlyItems = [
    MonthlyItem('Toothpaste', 'Household', 5),
    MonthlyItem('Laundry detergent', 'Household', 18),
    MonthlyItem('Swimming goggles', 'Personal', 31),
    MonthlyItem('Supplements', 'Health', 12),
  ];
  final List<ChallengeItem> _challenges = [
    ChallengeItem('30-day push-up challenge', 'Target: 100 push-ups per day',
        const Color(0xFFEF8D59))
      ..days.setRange(0, 12, List<bool>.filled(12, true)),
    ChallengeItem(
        'Read every day', 'Target: 20 pages per day', const Color(0xFF5367F5))
      ..days.setRange(0, 12, List<bool>.filled(12, true)),
  ];
  int _selectedChallengeIndex = 0;
  bool _loadingTasks = true;
  String? _taskError;
  String _grocerySort = 'Name';
  final ProfileData _profile = ProfileData();
  final List<PlannerDeadline> _deadlines = [];
  final List<TimetableEntry> _timetable = [];
  int _movementSteps = 0;

  @override
  void initState() {
    super.initState();
    _loadTasks();
    _loadGroceries();
    _loadMonthlyItems();
    _loadProfile();
    _loadPlanner();
    _loadChallenges();
    _loadDailyMovement();
  }

  int get _completedTasks => _tasks.where((task) => task.done).length;
  ChallengeItem get _selectedChallenge => _challenges[_selectedChallengeIndex];
  int get _completedChallengeDays =>
      _selectedChallenge.days.where((completed) => completed).length;

  Future<void> _loadDailyMovement() async {
    final preferences = await SharedPreferences.getInstance();
    final today = _dateOnly(DateTime.now());
    final storedDate = preferences.getString('movement_date') ?? '';
    if (storedDate == today.toIso8601String()) {
      if (mounted) {
        setState(() {
          _movementSteps = preferences.getInt('movement_steps') ?? 0;
        });
      }
    } else {
      await preferences.setString('movement_date', today.toIso8601String());
      await preferences.setInt('movement_steps', 0);
    }
  }

  Future<void> _editMovement() async {
    final controller = TextEditingController(text: '$_movementSteps');
    final result = await showDialog<int>(
      context: context,
      builder: (context) => _NumberInputDialog(
        title: 'Log today\'s movement',
        label: 'Steps completed today',
        controller: controller,
      ),
    );
    controller.dispose();
    if (result == null || !mounted) return;
    final preferences = await SharedPreferences.getInstance();
    setState(() => _movementSteps = result);
    await preferences.setString(
        'movement_date', _dateOnly(DateTime.now()).toIso8601String());
    await preferences.setInt('movement_steps', result);
  }

  Future<void> _loadTasks() async {
    try {
      final tasks = await _taskService.getTasks();
      if (!mounted) return;
      setState(() {
        _tasks
          ..clear()
          ..addAll(tasks);
        _loadingTasks = false;
        _taskError = null;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _loadingTasks = false;
        _taskError =
            'Could not load tasks. Check your Supabase table and policies.';
      });
    }
  }

  Future<void> _toggleTask(TaskItem task) async {
    if (task.id == null) return;
    final previous = task.done;
    setState(() => task.done = !previous);
    try {
      await _taskService.updateTask(id: task.id!, completed: task.done);
    } catch (error) {
      if (!mounted) return;
      setState(() => task.done = previous);
      _showMessage('Could not update that task.');
    }
  }

  Future<void> _deleteTask(TaskItem task) async {
    if (task.id == null) return;
    setState(() => _tasks.remove(task));
    try {
      await _taskService.deleteTask(task.id!);
    } catch (error) {
      if (!mounted) return;
      await _loadTasks();
      _showMessage('Could not delete that task.');
    }
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  void _toggleGrocery(GroceryItem item) {
    setState(() {
      item.bought = !item.bought;
      if (item.bought) {
        item.purchasedAt = DateTime.now();
      }
    });
    _saveGroceries();
  }

  Future<void> _loadGroceries() async {
    final preferences = await SharedPreferences.getInstance();
    final encoded = preferences.getString('groceries');
    if (encoded == null) return;
    try {
      final decoded = jsonDecode(encoded) as List<dynamic>;
      if (!mounted) return;
      setState(() {
        _groceries
          ..clear()
          ..addAll(decoded.map(
              (item) => GroceryItem.fromJson(item as Map<String, dynamic>)));
      });
    } catch (_) {
      await preferences.remove('groceries');
    }
  }

  Future<void> _saveGroceries() async {
    final preferences = await SharedPreferences.getInstance();
    await preferences.setString(
      'groceries',
      jsonEncode(_groceries.map((item) => item.toJson()).toList()),
    );
  }

  Future<void> _loadMonthlyItems() async {
    final preferences = await SharedPreferences.getInstance();
    final encoded = preferences.getString('monthly_items');
    if (encoded == null) return;
    try {
      final decoded = jsonDecode(encoded) as List<dynamic>;
      if (!mounted) return;
      setState(() {
        _monthlyItems
          ..clear()
          ..addAll(decoded.map(
              (item) => MonthlyItem.fromJson(item as Map<String, dynamic>)));
      });
    } catch (_) {
      await preferences.remove('monthly_items');
    }
  }

  Future<void> _saveMonthlyItems() async {
    final preferences = await SharedPreferences.getInstance();
    await preferences.setString(
      'monthly_items',
      jsonEncode(_monthlyItems.map((item) => item.toJson()).toList()),
    );
  }

  Future<void> _editGrocery(GroceryItem item) async {
    final updated = await showDialog<GroceryItem>(
      context: context,
      builder: (context) => _GroceryEditorDialog(initial: item),
    );
    if (updated == null || !mounted) return;
    final index = _groceries.indexOf(item);
    if (index == -1) return;
    setState(() => _groceries[index] = updated);
    await _saveGroceries();
  }

  Future<void> _deleteGrocery(GroceryItem item) async {
    setState(() => _groceries.remove(item));
    await _saveGroceries();
  }

  Future<void> _addMonthlyItem() async {
    final item = await showDialog<MonthlyItem>(
      context: context,
      builder: (context) => const _MonthlyItemDialog(),
    );
    if (item == null || !mounted) return;
    setState(() => _monthlyItems.add(item));
    await _saveMonthlyItems();
  }

  Future<void> _editMonthlyItem(MonthlyItem item) async {
    final updated = await showDialog<MonthlyItem>(
      context: context,
      builder: (context) => _MonthlyItemDialog(initial: item),
    );
    if (updated == null || !mounted) return;
    final index = _monthlyItems.indexOf(item);
    if (index == -1) return;
    setState(() => _monthlyItems[index] = updated);
    await _saveMonthlyItems();
  }

  Future<void> _deleteMonthlyItem(MonthlyItem item) async {
    setState(() => _monthlyItems.remove(item));
    await _saveMonthlyItems();
  }

  Future<void> _loadProfile() async {
    final preferences = await SharedPreferences.getInstance();
    final encoded = preferences.getString('profile');
    if (encoded == null) return;
    try {
      final loaded =
          ProfileData.fromJson(jsonDecode(encoded) as Map<String, dynamic>);
      if (!mounted) return;
      setState(() {
        _profile
          ..name = loaded.name
          ..email = loaded.email
          ..goal = loaded.goal
          ..targetMass = loaded.targetMass;
        _profile.massEntries
          ..clear()
          ..addAll(loaded.massEntries);
      });
    } catch (_) {
      await preferences.remove('profile');
    }
  }

  Future<void> _saveProfile() async {
    final preferences = await SharedPreferences.getInstance();
    await preferences.setString('profile', jsonEncode(_profile.toJson()));
  }

  String get _currencySymbol {
    switch (_profile.currency) {
      case 'EUR':
        return '€';
      case 'USD':
        return '\$';
      default:
        return 'Rs';
    }
  }

  Future<void> _editProfile() async {
    final updated = await showDialog<ProfileData>(
      context: context,
      builder: (context) => _ProfileEditorDialog(profile: _profile),
    );
    if (updated == null || !mounted) return;
    setState(() {
      _profile
        ..name = updated.name
        ..email = updated.email
        ..goal = updated.goal
        ..targetMass = updated.targetMass
        ..currency = updated.currency;
    });
    await _saveProfile();
  }

  Future<void> _addMassEntry() async {
    final mass = await showDialog<double>(
      context: context,
      builder: (context) => const _MassEntryDialog(),
    );
    if (mass == null || !mounted) return;
    setState(() => _profile.massEntries.add(MassEntry(DateTime.now(), mass)));
    await _saveProfile();
  }

  Future<void> _loadPlanner() async {
    final preferences = await SharedPreferences.getInstance();
    try {
      final deadlines = jsonDecode(preferences.getString('deadlines') ?? '[]')
          as List<dynamic>;
      final timetable = jsonDecode(preferences.getString('timetable') ?? '[]')
          as List<dynamic>;
      if (!mounted) return;
      setState(() {
        _deadlines
          ..clear()
          ..addAll(deadlines.map((item) =>
              PlannerDeadline.fromJson(item as Map<String, dynamic>)));
        _timetable
          ..clear()
          ..addAll(timetable.map(
              (item) => TimetableEntry.fromJson(item as Map<String, dynamic>)));
      });
    } catch (_) {
      await preferences.remove('deadlines');
      await preferences.remove('timetable');
    }
  }

  Future<void> _loadChallenges() async {
    final preferences = await SharedPreferences.getInstance();
    final encoded = preferences.getString('challenges');
    if (encoded == null) return;
    try {
      final decoded = jsonDecode(encoded) as List<dynamic>;
      final loaded = decoded
          .map((item) => ChallengeItem.fromJson(item as Map<String, dynamic>))
          .toList();
      if (!mounted || loaded.isEmpty) return;
      setState(() {
        _challenges
          ..clear()
          ..addAll(loaded);
        _selectedChallengeIndex = 0;
      });
    } catch (_) {
      await preferences.remove('challenges');
    }
  }

  Future<void> _saveChallenges() async {
    final preferences = await SharedPreferences.getInstance();
    await preferences.setString(
      'challenges',
      jsonEncode(_challenges.map((challenge) => challenge.toJson()).toList()),
    );
  }

  Future<void> _savePlanner() async {
    final preferences = await SharedPreferences.getInstance();
    await preferences.setString('deadlines',
        jsonEncode(_deadlines.map((item) => item.toJson()).toList()));
    await preferences.setString('timetable',
        jsonEncode(_timetable.map((item) => item.toJson()).toList()));
  }

  Future<void> _addDeadline() async {
    final result = await showDialog<PlannerDeadline>(
      context: context,
      builder: (context) => const _DeadlineDialog(),
    );
    if (result == null || !mounted) return;
    setState(() => _deadlines.add(result));
    await _savePlanner();
  }

  Future<void> _addTimetableEntry() async {
    final result = await showDialog<TimetableEntry>(
      context: context,
      builder: (context) => const _TimetableDialog(),
    );
    if (result == null || !mounted) return;
    setState(() => _timetable.add(result));
    await _savePlanner();
  }

  Future<void> _deleteDeadline(PlannerDeadline deadline) async {
    setState(() => _deadlines.remove(deadline));
    await _savePlanner();
  }

  Future<void> _deleteTimetableEntry(TimetableEntry entry) async {
    setState(() => _timetable.remove(entry));
    await _savePlanner();
  }

  void _toggleChallengeDay(int index) {
    setState(() {
      _selectedChallenge.days[index] = !_selectedChallenge.days[index];
      _selectedChallenge.restDays.remove(index);
    });
    _saveChallenges();
  }

  void _toggleChallengeRestDay(int index) {
    setState(() {
      _selectedChallenge.days[index] = false;
      if (!_selectedChallenge.restDays.remove(index)) {
        _selectedChallenge.restDays.add(index);
      }
    });
    _saveChallenges();
  }

  void _selectChallenge(int index) {
    setState(() {
      if (_selectedChallengeIndex == index) {
        _challenges[index].expanded = !_challenges[index].expanded;
      } else {
        _selectedChallengeIndex = index;
        _challenges[index].expanded = true;
      }
    });
  }

  Future<void> _deleteChallenge(int index) async {
    if (_challenges.length == 1) {
      _showMessage('Keep at least one challenge.');
      return;
    }
    setState(() {
      _challenges.removeAt(index);
      if (_selectedChallengeIndex >= _challenges.length) {
        _selectedChallengeIndex = _challenges.length - 1;
      } else if (_selectedChallengeIndex > index) {
        _selectedChallengeIndex--;
      }
    });
    await _saveChallenges();
  }

  Future<void> _addChallenge() async {
    final challenge = await showDialog<ChallengeItem>(
      context: context,
      builder: (context) => _ChallengeDialog(
        color: [
          const Color(0xFF62AD7D),
          const Color(0xFFB36B3C),
          const Color(0xFF9B6BD6),
          const Color(0xFF3D9BB5),
        ][_challenges.length % 4],
      ),
    );
    if (challenge == null || !mounted) return;
    setState(() {
      challenge.expanded = true;
      _challenges.add(challenge);
      _selectedChallengeIndex = _challenges.length - 1;
    });
    await _saveChallenges();
  }

  Future<void> _resetChallengeProgress() async {
    setState(() {
      _selectedChallenge.days
          .fillRange(0, _selectedChallenge.days.length, false);
      _selectedChallenge.restDays.clear();
    });
    await _saveChallenges();
  }

  Future<void> _showNotifications() async {
    if (!notificationsSupported) {
      _showMessage('Browser notifications are not supported here.');
      return;
    }
    final enabled = await requestNotificationPermission();
    if (!mounted) return;
    if (!enabled) {
      _showMessage('Allow notifications in your browser to enable reminders.');
      return;
    }
    showNotification(
      'Dayflow reminders enabled',
      'You will receive reminders while Dayflow is open.',
    );
    _showMessage('Notifications enabled for this browser.');
  }

  void _openMoreMenu() {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(18, 8, 18, 22),
          child: Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              _MoreMenuItem(
                icon: Icons.shopping_basket_outlined,
                label: 'Shop',
                onTap: () => _selectMorePage(context, 2),
              ),
              _MoreMenuItem(
                icon: Icons.emoji_events_outlined,
                label: 'Challenges',
                onTap: () => _selectMorePage(context, 4),
              ),
              _MoreMenuItem(
                icon: Icons.person_outline_rounded,
                label: 'Profile',
                onTap: () => _selectMorePage(context, 5),
              ),
              _MoreMenuItem(
                icon: Icons.calendar_month_outlined,
                label: 'Planner',
                onTap: () => _selectMorePage(context, 6),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _selectMorePage(BuildContext sheetContext, int page) {
    Navigator.pop(sheetContext);
    setState(() => _selectedIndex = page);
  }

  Future<void> _addTask() async {
    final controller = TextEditingController();
    final title = await showDialog<String>(
      context: context,
      builder: (context) => _InputDialog(
        title: 'Add to today',
        hint: 'e.g. Call the dentist',
        controller: controller,
      ),
    );
    controller.dispose();
    if (title == null || title.trim().isEmpty || !mounted) return;
    try {
      final task = await _taskService.createTask(title: title.trim());
      if (!mounted) return;
      setState(() => _tasks.insert(0, task));
    } catch (error) {
      _showMessage('Could not save that task.');
    }
  }

  Future<void> _addGrocery() async {
    final grocery = await showDialog<GroceryItem>(
      context: context,
      builder: (context) => const _GroceryEditorDialog(),
    );
    if (grocery == null || !mounted) return;
    setState(() => _groceries.add(grocery));
    await _saveGroceries();
  }

  void _sortGroceries() {
    setState(() {
      if (_grocerySort == 'Name') {
        _grocerySort = 'Status';
        _groceries.sort((a, b) => a.bought == b.bought
            ? a.name.compareTo(b.name)
            : (a.bought ? 1 : -1));
      } else {
        _grocerySort = 'Name';
        _groceries.sort((a, b) => a.name.compareTo(b.name));
      }
    });
  }

  Future<void> _showMealPlan() async {
    final ingredients = _groceries
        .where((item) => item.bought && !item.isExpired)
        .map((item) => item.name.toLowerCase())
        .toSet();
    final meals = [
      (
        'Chicken rice bowl',
        'Chicken, rice, broccoli and tomatoes',
        Icons.rice_bowl
      ),
      ('Veggie omelette', 'Eggs, tomatoes and vegetables', Icons.egg_alt),
      (
        'Creamy tomato pasta',
        'Pasta, tomatoes and a simple sauce',
        Icons.dinner_dining
      ),
      (
        'Chicken stir-fry',
        'Chicken, rice and any vegetables available',
        Icons.outdoor_grill
      ),
    ];
    await showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Today's meal plan"),
        content: SizedBox(
          width: 420,
          child: ListView(
            shrinkWrap: true,
            children: meals
                .map((meal) => ListTile(
                      leading: Icon(meal.$3, color: const Color(0xFFE78D48)),
                      title: Text(meal.$1),
                      subtitle: Text(
                        '${meal.$2}\nAvailable ingredients: ${ingredients.isEmpty ? 'Add items to your pantry' : ingredients.take(3).join(', ')}',
                      ),
                      isThreeLine: true,
                    ))
                .toList(),
          ),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Close')),
        ],
      ),
    );
  }

  Future<void> _showPantryDetails() async {
    await showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Pantry status'),
        content: SizedBox(
          width: 420,
          child: ListView(
            shrinkWrap: true,
            children: _groceries
                .where((item) => item.bought)
                .map((item) => ListTile(
                      leading: Icon(
                        item.isExpired
                            ? Icons.delete_outline
                            : item.isLow
                                ? Icons.warning_amber_rounded
                                : Icons.check_circle_outline,
                        color: item.isExpired
                            ? const Color(0xFFE66B61)
                            : item.isLow
                                ? const Color(0xFFE78D48)
                                : const Color(0xFF62AD7D),
                      ),
                      title: Text(item.name),
                      subtitle: Text(item.isExpired
                          ? 'Should be thrown out'
                          : item.isLow
                              ? 'Running low (${item.quantity} left)'
                              : 'Available until ${item.expiresAt.month}/${item.expiresAt.day}'),
                    ))
                .toList(),
          ),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Close')),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final pages = [
      _DashboardPage(
        tasks: _tasks,
        completedTasks: _completedTasks,
        completedChallengeDays: _completedChallengeDays,
        onTaskToggle: _toggleTask,
        onTaskDelete: _deleteTask,
        onChallengeToggle: _toggleChallengeDay,
        onChallengeRest: _toggleChallengeRestDay,
        challengeDays: _selectedChallenge.days,
        challengeRestDays: _selectedChallenge.restDays,
        challengeColor: _selectedChallenge.color,
        challengeTitle: _selectedChallenge.title,
        challengeSubtitle: _selectedChallenge.subtitle,
        challengeStartDate: _selectedChallenge.startDate,
        movementSteps: _movementSteps,
        onEditMovement: _editMovement,
        onSeeAllTasks: () => setState(() => _selectedIndex = 1),
        onOpenChallenges: () => setState(() => _selectedIndex = 4),
        onOpenProfile: () => setState(() => _selectedIndex = 5),
        onMealPlan: _showMealPlan,
        onNotifications: _showNotifications,
      ),
      _TasksPage(
        tasks: _tasks,
        onToggle: _toggleTask,
        onDelete: _deleteTask,
        onAdd: _addTask,
        loading: _loadingTasks,
        error: _taskError,
        onRetry: _loadTasks,
      ),
      _GroceriesPage(
        groceries: _groceries,
        monthlyItems: _monthlyItems,
        onToggle: _toggleGrocery,
        onAdd: _addGrocery,
        onSort: _sortGroceries,
        sortLabel: _grocerySort,
        onMealPlan: _showMealPlan,
        onManagePantry: _showPantryDetails,
        onEdit: _editGrocery,
        onDelete: _deleteGrocery,
        onAddMonthly: _addMonthlyItem,
        onEditMonthly: _editMonthlyItem,
        onDeleteMonthly: _deleteMonthlyItem,
        currencySymbol: _currencySymbol,
      ),
      _WorkoutPage(),
      _ChallengesPage(
        challenges: _challenges,
        selectedIndex: _selectedChallengeIndex,
        onSelect: _selectChallenge,
        onToggle: _toggleChallengeDay,
        onRest: _toggleChallengeRestDay,
        onAdd: _addChallenge,
        onDelete: _deleteChallenge,
        onResetProgress: _resetChallengeProgress,
      ),
      _ProfilePage(
        profile: _profile,
        groceries: _groceries,
        challenges: _challenges,
        onEdit: _editProfile,
        onAddMass: _addMassEntry,
      ),
      _PlannerPage(
        deadlines: _deadlines,
        timetable: _timetable,
        onAddDeadline: _addDeadline,
        onAddClass: _addTimetableEntry,
        onDeleteDeadline: _deleteDeadline,
        onDeleteClass: _deleteTimetableEntry,
      ),
    ];

    final selectedNavigationIndex = _selectedIndex <= 1
        ? _selectedIndex
        : _selectedIndex == 3
            ? 2
            : 3;
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            if (widget.startupError != null)
              _ConnectionBanner(message: widget.startupError!),
            Expanded(
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 760),
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 280),
                    switchInCurve: Curves.easeOutCubic,
                    switchOutCurve: Curves.easeInCubic,
                    child: KeyedSubtree(
                      key: ValueKey(_selectedIndex),
                      child: pages[_selectedIndex],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: selectedNavigationIndex,
        onDestinationSelected: (index) {
          if (index == 3) {
            _openMoreMenu();
          } else if (index == 2) {
            setState(() => _selectedIndex = 3);
          } else {
            setState(() => _selectedIndex = index);
          }
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home_rounded),
            label: 'Home',
          ),
          NavigationDestination(
            icon: Icon(Icons.checklist_outlined),
            selectedIcon: Icon(Icons.checklist_rounded),
            label: 'Today',
          ),
          NavigationDestination(
            icon: Icon(Icons.fitness_center_outlined),
            selectedIcon: Icon(Icons.fitness_center_rounded),
            label: 'Workout',
          ),
          NavigationDestination(
            icon: Icon(Icons.more_horiz_rounded),
            selectedIcon: Icon(Icons.more_horiz_rounded),
            label: 'More',
          ),
        ],
      ),
    );
  }
}

class _DashboardPage extends StatelessWidget {
  const _DashboardPage({
    required this.tasks,
    required this.completedTasks,
    required this.completedChallengeDays,
    required this.onTaskToggle,
    required this.onTaskDelete,
    required this.onChallengeToggle,
    required this.onChallengeRest,
    required this.challengeDays,
    required this.challengeRestDays,
    required this.challengeColor,
    required this.challengeTitle,
    required this.challengeSubtitle,
    required this.challengeStartDate,
    required this.movementSteps,
    required this.onEditMovement,
    required this.onSeeAllTasks,
    required this.onOpenChallenges,
    required this.onOpenProfile,
    required this.onMealPlan,
    required this.onNotifications,
  });

  final List<TaskItem> tasks;
  final int completedTasks;
  final int completedChallengeDays;
  final ValueChanged<TaskItem> onTaskToggle;
  final ValueChanged<TaskItem> onTaskDelete;
  final ValueChanged<int> onChallengeToggle;
  final ValueChanged<int> onChallengeRest;
  final List<bool> challengeDays;
  final Set<int> challengeRestDays;
  final Color challengeColor;
  final String challengeTitle;
  final String challengeSubtitle;
  final DateTime challengeStartDate;
  final int movementSteps;
  final VoidCallback onEditMovement;
  final VoidCallback onSeeAllTasks;
  final VoidCallback onOpenChallenges;
  final VoidCallback onOpenProfile;
  final VoidCallback onMealPlan;
  final VoidCallback onNotifications;

  @override
  Widget build(BuildContext context) {
    final progress = tasks.isEmpty ? 0.0 : completedTasks / tasks.length;
    return _PageScaffold(
      child: ListView(
        padding: const EdgeInsets.fromLTRB(22, 26, 22, 28),
        children: [
          _TopGreeting(
              onNotifications: onNotifications, onProfile: onOpenProfile),
          const SizedBox(height: 22),
          _FocusCard(
              progress: progress,
              completed: completedTasks,
              total: tasks.length),
          const SizedBox(height: 18),
          _MetricCard(
            icon: Icons.directions_run_rounded,
            color: const Color(0xFFEF8D59),
            title: 'Movement today',
            value: '${movementSteps.toString()} steps',
            subtitle: 'Tap to update your progress',
            onTap: onEditMovement,
          ),
          const SizedBox(height: 24),
          _SectionTitle(
              title: "Today's plan",
              action: 'See all',
              onAction: onSeeAllTasks),
          const SizedBox(height: 10),
          ...tasks.take(3).map(
                (task) => Padding(
                  padding: const EdgeInsets.only(bottom: 9),
                  child: _TaskRow(
                    task: task,
                    onToggle: () => onTaskToggle(task),
                    onDelete: () => onTaskDelete(task),
                  ),
                ),
              ),
          const SizedBox(height: 15),
          _AssistantCard(
            title: 'Your assistant noticed',
            message:
                'You have chicken, eggs, rice and broccoli available. A high-protein lunch is ready to make.',
            icon: Icons.auto_awesome_rounded,
            action: 'View meal ideas',
            onAction: onMealPlan,
          ),
          const SizedBox(height: 22),
          _SectionTitle(
              title: challengeTitle,
              action: 'Open',
              onAction: onOpenChallenges),
          const SizedBox(height: 10),
          _ChallengeCard(
            title: challengeTitle,
            subtitle: challengeSubtitle,
            days: challengeDays,
            total: challengeDays.length,
            onDayToggle: onChallengeToggle,
            onDayRest: onChallengeRest,
            restDays: challengeRestDays,
            color: challengeColor,
            startDate: challengeStartDate,
          ),
        ],
      ),
    );
  }
}

class _TasksPage extends StatelessWidget {
  const _TasksPage({
    required this.tasks,
    required this.onToggle,
    required this.onDelete,
    required this.onAdd,
    required this.loading,
    required this.error,
    required this.onRetry,
  });

  final List<TaskItem> tasks;
  final ValueChanged<TaskItem> onToggle;
  final ValueChanged<TaskItem> onDelete;
  final VoidCallback onAdd;
  final bool loading;
  final String? error;
  final Future<void> Function() onRetry;

  @override
  Widget build(BuildContext context) {
    return _PageScaffold(
      child: ListView(
        padding: const EdgeInsets.fromLTRB(22, 26, 22, 28),
        children: [
          _PageHeader(
            eyebrow: _dayLabel(DateTime.now()),
            title: 'Today',
            subtitle:
                '${tasks.where((task) => !task.done).length} things to focus on',
            action: IconButton.filled(
              onPressed: onAdd,
              icon: const Icon(Icons.add_rounded),
              tooltip: 'Add task',
            ),
          ),
          const SizedBox(height: 22),
          _AssistantCard(
            title: 'Suggested by Dayflow',
            message:
                'Protect 7–9 PM for Flutter practice. You usually focus best during this window.',
            icon: Icons.lightbulb_rounded,
            action: 'Add focus block',
            onAction: onAdd,
          ),
          const SizedBox(height: 24),
          if (loading)
            const Center(child: CircularProgressIndicator())
          else if (error != null)
            _ErrorState(message: error!, onRetry: onRetry)
          else
            ...tasks.map(
              (task) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: _TaskRow(
                  task: task,
                  onToggle: () => onToggle(task),
                  onDelete: () => onDelete(task),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _GroceriesPage extends StatelessWidget {
  const _GroceriesPage({
    required this.groceries,
    required this.monthlyItems,
    required this.onToggle,
    required this.onAdd,
    required this.onSort,
    required this.sortLabel,
    required this.onMealPlan,
    required this.onManagePantry,
    required this.onEdit,
    required this.onDelete,
    required this.onAddMonthly,
    required this.onEditMonthly,
    required this.onDeleteMonthly,
    required this.currencySymbol,
  });

  final List<GroceryItem> groceries;
  final List<MonthlyItem> monthlyItems;
  final ValueChanged<GroceryItem> onToggle;
  final VoidCallback onAdd;
  final VoidCallback onSort;
  final String sortLabel;
  final VoidCallback onMealPlan;
  final VoidCallback onManagePantry;
  final ValueChanged<GroceryItem> onEdit;
  final ValueChanged<GroceryItem> onDelete;
  final VoidCallback onAddMonthly;
  final ValueChanged<MonthlyItem> onEditMonthly;
  final ValueChanged<MonthlyItem> onDeleteMonthly;
  final String currencySymbol;

  @override
  Widget build(BuildContext context) {
    final available =
        groceries.where((item) => item.bought).map((item) => item.name);
    final totalCost = groceries
        .where((item) => !item.bought)
        .fold<double>(0, (sum, item) => sum + item.price);
    final lowStock =
        groceries.where((item) => item.isLow && item.bought).toList();
    final expired =
        groceries.where((item) => item.isExpired && item.bought).toList();
    return _PageScaffold(
      child: ListView(
        padding: const EdgeInsets.fromLTRB(22, 26, 22, 28),
        children: [
          _PageHeader(
            eyebrow: 'SMART SHOPPING',
            title: 'Groceries',
            subtitle:
                '${groceries.where((item) => !item.bought).length} items to buy',
            action: IconButton.filled(
              onPressed: onAdd,
              icon: const Icon(Icons.add_rounded),
              tooltip: 'Add grocery',
            ),
          ),
          const SizedBox(height: 20),
          _MealSuggestion(
              ingredients: available.toList(), onOpenPlan: onMealPlan),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: _PantrySummary(
                    title: 'Shopping total',
                    value: '$currencySymbol ${totalCost.toStringAsFixed(2)}',
                    icon: Icons.receipt_long_rounded,
                    color: const Color(0xFF5367F5)),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _PantrySummary(
                    title: 'Low stock',
                    value: '${lowStock.length}',
                    icon: Icons.warning_amber_rounded,
                    color: const Color(0xFFE78D48)),
              ),
            ],
          ),
          if (lowStock.isNotEmpty || expired.isNotEmpty) ...[
            const SizedBox(height: 12),
            _PantryAlert(lowStock: lowStock, expired: expired),
          ],
          const SizedBox(height: 24),
          _SectionTitle(
              title: 'Weekly groceries',
              action: 'Sort: $sortLabel',
              onAction: onSort),
          const SizedBox(height: 10),
          ...groceries.map(
            (item) => Padding(
              padding: const EdgeInsets.only(bottom: 9),
              child: _GroceryRow(
                  item: item,
                  onToggle: () => onToggle(item),
                  onEdit: () => onEdit(item),
                  onDelete: () => onDelete(item),
                  currencySymbol: currencySymbol),
            ),
          ),
          const SizedBox(height: 20),
          _SectionTitle(
              title: 'Monthly purchases',
              action: 'Add',
              onAction: onAddMonthly),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.all(15),
            decoration: _cardDecoration(),
            child: Column(
              children: monthlyItems
                  .map(
                    (item) => Padding(
                      padding: const EdgeInsets.symmetric(vertical: 7),
                      child: Row(
                        children: [
                          const Icon(Icons.autorenew_rounded,
                              size: 18, color: Color(0xFF8A91A4)),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(item.name,
                                    style: const TextStyle(
                                        fontWeight: FontWeight.w700)),
                                const SizedBox(height: 3),
                                Text(
                                    '${item.category} · quantity ${item.quantity.toStringAsFixed(item.quantity == item.quantity.roundToDouble() ? 0 : 1)}',
                                    style: const TextStyle(
                                        color: Color(0xFF9CA2B1),
                                        fontSize: 11)),
                              ],
                            ),
                          ),
                          Text(
                            item.daysUntilDue == 1
                                ? 'Due tomorrow'
                                : 'In ${item.daysUntilDue} days',
                            style: TextStyle(
                              color: item.daysUntilDue < 7
                                  ? const Color(0xFFE17858)
                                  : const Color(0xFF8A91A4),
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          IconButton(
                            onPressed: () => onEditMonthly(item),
                            icon: const Icon(Icons.edit_outlined, size: 18),
                            tooltip: 'Edit purchase',
                          ),
                          IconButton(
                            onPressed: () => onDeleteMonthly(item),
                            icon: const Icon(Icons.delete_outline_rounded,
                                size: 18),
                            tooltip: 'Delete purchase',
                          ),
                        ],
                      ),
                    ),
                  )
                  .toList(),
            ),
          ),
        ],
      ),
    );
  }
}

class _WorkoutPage extends StatefulWidget {
  @override
  State<_WorkoutPage> createState() => _WorkoutPageState();
}

class _WorkoutPageState extends State<_WorkoutPage> {
  bool _completed = false;
  final Set<int> _completedExercises = {};
  final List<WorkoutLog> _workoutLogs = [];
  bool _loading = true;
  final exercises = const [
    ('Bench press', '4 sets × 8 reps', 'Chest, front delts and triceps'),
    ('Incline dumbbell press', '3 sets × 12 reps', 'Upper chest emphasis'),
    ('Dips', '3 sets × 10 reps', 'Chest and triceps finisher'),
    ('Plank', '3 sets × 45 seconds', 'Core stability and control'),
  ];

  @override
  void initState() {
    super.initState();
    _loadWorkout();
  }

  Future<void> _loadWorkout() async {
    final preferences = await SharedPreferences.getInstance();
    final completed =
        (jsonDecode(preferences.getString('workout_exercises') ?? '[]')
                as List<dynamic>)
            .map((index) => (index as num).toInt())
            .toList();
    final encodedLogs = preferences.getString('workout_logs') ?? '[]';
    try {
      final logs = (jsonDecode(encodedLogs) as List<dynamic>)
          .map((item) => WorkoutLog.fromJson(item as Map<String, dynamic>))
          .toList();
      if (!mounted) return;
      setState(() {
        _completed = preferences.getBool('workout_completed') ?? false;
        _completedExercises.addAll(completed);
        _workoutLogs.addAll(logs);
        _loading = false;
      });
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _saveWorkout() async {
    final preferences = await SharedPreferences.getInstance();
    await preferences.setBool('workout_completed', _completed);
    await preferences.setString(
        'workout_exercises', jsonEncode(_completedExercises.toList()));
    await preferences.setString(
      'workout_logs',
      jsonEncode(_workoutLogs.map((log) => log.toJson()).toList()),
    );
  }

  Future<void> _logManualWorkout() async {
    final controller = TextEditingController();
    final title = await showDialog<String>(
      context: context,
      builder: (context) => _InputDialog(
        title: 'Log a workout',
        hint: 'e.g. 30-minute run',
        controller: controller,
      ),
    );
    controller.dispose();
    if (title == null || title.trim().isEmpty || !mounted) return;
    setState(
        () => _workoutLogs.insert(0, WorkoutLog(title.trim(), DateTime.now())));
    await _saveWorkout();
  }

  Future<void> _resetWorkout() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reset workout progress?'),
        content: const Text(
            'This clears today\'s exercise progress, not your saved workout log.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel')),
          FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Reset')),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    setState(() {
      _completed = false;
      _completedExercises.clear();
    });
    await _saveWorkout();
  }

  @override
  Widget build(BuildContext context) {
    final progress = _completedExercises.length / exercises.length;
    return _PageScaffold(
      child: ListView(
        padding: const EdgeInsets.fromLTRB(22, 26, 22, 28),
        children: [
          const _PageHeader(
            eyebrow: 'AI WORKOUT COACH',
            title: 'Push day',
            subtitle: '55 min · Strength and muscle',
          ),
          const SizedBox(height: 20),
          if (_loading) const LinearProgressIndicator(),
          _CoachCard(
            title: 'Today’s recommendation',
            message:
                'You trained consistently this week. Keep the weight steady and focus on a controlled 3-second lowering phase.',
          ),
          const SizedBox(height: 22),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const _SectionTitle(title: 'Your workout'),
              Text('${_completedExercises.length}/${exercises.length}',
                  style: const TextStyle(
                      color: Color(0xFF5367F5), fontWeight: FontWeight.w800)),
            ],
          ),
          const SizedBox(height: 8),
          LinearProgressIndicator(
            value: progress,
            minHeight: 7,
            borderRadius: BorderRadius.circular(8),
            color: const Color(0xFF5367F5),
            backgroundColor: const Color(0xFFE4E7F5),
          ),
          const SizedBox(height: 14),
          ...exercises.asMap().entries.map(
                (entry) => _ExerciseRow(
                  number: entry.key + 1,
                  exercise: entry.value,
                  done: _completedExercises.contains(entry.key),
                  onToggle: () => setState(() {
                    if (!_completedExercises.add(entry.key)) {
                      _completedExercises.remove(entry.key);
                    }
                    _saveWorkout();
                  }),
                ),
              ),
          const SizedBox(height: 12),
          FilledButton.icon(
            onPressed: () {
              setState(() => _completed = !_completed);
              _saveWorkout();
            },
            icon: Icon(_completed ? Icons.check_rounded : Icons.flag_rounded),
            label: Text(_completed ? 'Workout logged' : 'Log workout complete'),
          ),
          const SizedBox(height: 10),
          OutlinedButton.icon(
            onPressed: _logManualWorkout,
            icon: const Icon(Icons.edit_note_rounded),
            label: const Text('Log a workout I did'),
          ),
          const SizedBox(height: 8),
          TextButton.icon(
            onPressed: _resetWorkout,
            icon: const Icon(Icons.restart_alt_rounded),
            label: const Text('Reset today\'s progress'),
          ),
          if (_workoutLogs.isNotEmpty) ...[
            const SizedBox(height: 18),
            const _SectionTitle(title: 'Workout log'),
            const SizedBox(height: 8),
            ..._workoutLogs.take(8).map((log) => ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.check_circle_outline_rounded,
                      color: Color(0xFF62AD7D)),
                  title: Text(log.title,
                      style: const TextStyle(fontWeight: FontWeight.w700)),
                  subtitle: Text(
                      '${log.date.day}/${log.date.month}/${log.date.year} · ${log.date.hour.toString().padLeft(2, '0')}:${log.date.minute.toString().padLeft(2, '0')}'),
                )),
          ],
        ],
      ),
    );
  }
}

class _ChallengesPage extends StatelessWidget {
  const _ChallengesPage({
    required this.challenges,
    required this.selectedIndex,
    required this.onSelect,
    required this.onToggle,
    required this.onRest,
    required this.onAdd,
    required this.onDelete,
    required this.onResetProgress,
  });

  final List<ChallengeItem> challenges;
  final int selectedIndex;
  final ValueChanged<int> onSelect;
  final ValueChanged<int> onToggle;
  final ValueChanged<int> onRest;
  final VoidCallback onAdd;
  final ValueChanged<int> onDelete;
  final VoidCallback onResetProgress;

  @override
  Widget build(BuildContext context) {
    final selectedChallenge = challenges[selectedIndex];
    final endDate = selectedChallenge.startDate
        .add(Duration(days: selectedChallenge.days.length - 1));
    return _PageScaffold(
      child: ListView(
        padding: const EdgeInsets.fromLTRB(22, 26, 22, 28),
        children: [
          const _PageHeader(
            eyebrow: 'CONSISTENCY BUILDER',
            title: 'Challenges',
            subtitle: 'Small actions, repeated daily',
          ),
          const SizedBox(height: 20),
          const Text(
            'Tap a day to mark it done. Long-press a day to mark it as rest. Tap again to undo it.',
            style: TextStyle(color: Color(0xFF858C9F), fontSize: 12),
          ),
          const SizedBox(height: 6),
          Text(
            'Calendar: ${selectedChallenge.startDate.day}/${selectedChallenge.startDate.month}/${selectedChallenge.startDate.year} – ${endDate.day}/${endDate.month}/${endDate.year}',
            style: const TextStyle(
                color: Color(0xFF5367F5),
                fontSize: 12,
                fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 10),
          _ChallengeCard(
            title: selectedChallenge.title,
            subtitle: selectedChallenge.subtitle,
            days: selectedChallenge.days,
            total: selectedChallenge.days.length,
            color: selectedChallenge.color,
            startDate: selectedChallenge.startDate,
            onDayToggle: onToggle,
            onDayRest: onRest,
            restDays: selectedChallenge.restDays,
            showDays: false,
          ),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton.icon(
              onPressed: onResetProgress,
              icon: const Icon(Icons.restart_alt_rounded, size: 17),
              label: const Text('Reset progress'),
            ),
          ),
          const SizedBox(height: 22),
          _SectionTitle(
            title: 'Your challenges',
            action: 'New',
            onAction: onAdd,
          ),
          const SizedBox(height: 10),
          ...challenges.asMap().entries.map(
                (entry) => Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: _SimpleChallenge(
                    challenge: entry.value,
                    selected: entry.key == selectedIndex,
                    onTap: () => onSelect(entry.key),
                    onDelete: () => onDelete(entry.key),
                  ),
                ),
              ),
          if (selectedChallenge.expanded) ...[
            const SizedBox(height: 22),
            const _SectionTitle(title: 'Challenge calendar'),
            const SizedBox(height: 10),
            const Text(
              '✓ done  ·  ○ rest  ·  × not done  ·  dates are the actual challenge days',
              style: TextStyle(color: Color(0xFF858C9F), fontSize: 12),
            ),
            const SizedBox(height: 10),
            _CalendarGrid(
              days: selectedChallenge.days,
              color: selectedChallenge.color,
              startDate: selectedChallenge.startDate,
              onToggle: onToggle,
              onRest: onRest,
              restDays: selectedChallenge.restDays,
            ),
          ],
        ],
      ),
    );
  }
}

class _ProfilePage extends StatelessWidget {
  const _ProfilePage({
    required this.profile,
    required this.groceries,
    required this.challenges,
    required this.onEdit,
    required this.onAddMass,
  });

  final ProfileData profile;
  final List<GroceryItem> groceries;
  final List<ChallengeItem> challenges;
  final VoidCallback onEdit;
  final VoidCallback onAddMass;

  @override
  Widget build(BuildContext context) {
    final entries = [...profile.massEntries]
      ..sort((a, b) => a.date.compareTo(b.date));
    final latest = entries.isEmpty ? null : entries.last;
    return _PageScaffold(
      child: ListView(
        padding: const EdgeInsets.fromLTRB(22, 26, 22, 28),
        children: [
          _PageHeader(
            eyebrow: 'PERSONAL SPACE',
            title: profile.name,
            subtitle: 'Your information, goals and progress',
            action: IconButton.filled(
              onPressed: onEdit,
              icon: const Icon(Icons.edit_rounded),
              tooltip: 'Edit profile',
            ),
          ),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.all(18),
            decoration: _cardDecoration(),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(profile.email.isEmpty ? 'No email added' : profile.email,
                    style: const TextStyle(color: Color(0xFF858C9F))),
                const SizedBox(height: 8),
                Text('Goal: ${profile.goal}',
                    style: const TextStyle(
                        color: Color(0xFF293044), fontWeight: FontWeight.w700)),
                const SizedBox(height: 4),
                Text('Target mass: ${profile.targetMass.toStringAsFixed(1)} kg',
                    style: const TextStyle(
                        color: Color(0xFF5367F5), fontWeight: FontWeight.w700)),
              ],
            ),
          ),
          const SizedBox(height: 22),
          _RecapCard(
            groceries: groceries,
            challenges: challenges,
            currencySymbol: profile.currency == 'MUR'
                ? 'Rs'
                : profile.currency == 'EUR'
                    ? '€'
                    : '\$',
          ),
          const SizedBox(height: 22),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const _SectionTitle(title: 'Mass progress'),
              TextButton.icon(
                onPressed: onAddMass,
                icon: const Icon(Icons.add, size: 17),
                label: const Text('Log'),
              ),
            ],
          ),
          const SizedBox(height: 8),
          if (entries.isEmpty)
            _EmptyProgressCard(onAddMass: onAddMass)
          else ...[
            Container(
              height: 210,
              padding: const EdgeInsets.fromLTRB(12, 16, 16, 12),
              decoration: _cardDecoration(),
              child: CustomPaint(
                painter: _ProgressPainter(
                    entries: entries, color: const Color(0xFF5367F5)),
                child: const SizedBox.expand(),
              ),
            ),
            const SizedBox(height: 10),
            Text(
                'Latest: ${latest!.mass.toStringAsFixed(1)} kg · Target: ${profile.targetMass.toStringAsFixed(1)} kg',
                style: const TextStyle(
                    color: Color(0xFF858C9F),
                    fontSize: 12,
                    fontWeight: FontWeight.w600)),
          ],
        ],
      ),
    );
  }
}

class _RecapCard extends StatelessWidget {
  const _RecapCard(
      {required this.groceries,
      required this.challenges,
      required this.currencySymbol});

  final List<GroceryItem> groceries;
  final List<ChallengeItem> challenges;
  final String currencySymbol;

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    double spentSince(Duration duration) => groceries
        .where((item) =>
            item.bought && now.difference(item.purchasedAt) <= duration)
        .fold(0, (total, item) => total + item.price);
    final weekly = spentSince(const Duration(days: 7));
    final monthly = spentSince(const Duration(days: 30));
    final completed = challenges.fold<int>(
        0,
        (total, challenge) =>
            total + challenge.days.where((day) => day).length);
    final rest = challenges.fold<int>(
        0, (total, challenge) => total + challenge.restDays.length);
    return Container(
      padding: const EdgeInsets.all(17),
      decoration: _cardDecoration(),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Text('Weekly & monthly recap',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
        const SizedBox(height: 12),
        Row(children: [
          Expanded(
              child: _RecapMetric(
                  label: 'Groceries · 7d',
                  value: '$currencySymbol ${weekly.toStringAsFixed(2)}')),
          Expanded(
              child: _RecapMetric(
                  label: 'Groceries · 30d',
                  value: '$currencySymbol ${monthly.toStringAsFixed(2)}')),
        ]),
        const SizedBox(height: 10),
        Row(children: [
          Expanded(
              child: _RecapMetric(
                  label: 'Challenge days', value: '$completed done')),
          Expanded(
              child: _RecapMetric(label: 'Rest days', value: '$rest logged')),
        ]),
        const SizedBox(height: 8),
        const Text(
            'Takeout can be tracked as a grocery category in the next expense entry.',
            style: TextStyle(color: Color(0xFF858C9F), fontSize: 11)),
      ]),
    );
  }
}

class _RecapMetric extends StatelessWidget {
  const _RecapMetric({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label,
              style: const TextStyle(
                  color: Color(0xFF858C9F),
                  fontSize: 10,
                  fontWeight: FontWeight.w700)),
          const SizedBox(height: 3),
          Text(value,
              style: const TextStyle(
                  color: Color(0xFF293044),
                  fontSize: 14,
                  fontWeight: FontWeight.w800)),
        ],
      );
}

class _PlannerPage extends StatelessWidget {
  const _PlannerPage({
    required this.deadlines,
    required this.timetable,
    required this.onAddDeadline,
    required this.onAddClass,
    required this.onDeleteDeadline,
    required this.onDeleteClass,
  });

  final List<PlannerDeadline> deadlines;
  final List<TimetableEntry> timetable;
  final VoidCallback onAddDeadline;
  final VoidCallback onAddClass;
  final ValueChanged<PlannerDeadline> onDeleteDeadline;
  final ValueChanged<TimetableEntry> onDeleteClass;

  @override
  Widget build(BuildContext context) {
    final sortedDeadlines = [...deadlines]
      ..sort((a, b) => a.date.compareTo(b.date));
    final today = DateTime.now();
    return _PageScaffold(
      child: ListView(
        padding: const EdgeInsets.fromLTRB(22, 26, 22, 28),
        children: [
          _PageHeader(
            eyebrow: 'STUDENT PLANNER',
            title: 'Planner',
            subtitle: 'Deadlines, timetable and study planning',
            action: IconButton.filled(
              onPressed: onAddDeadline,
              icon: const Icon(Icons.add_rounded),
              tooltip: 'Add deadline',
            ),
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const _SectionTitle(title: 'Upcoming deadlines'),
              TextButton.icon(
                onPressed: onAddDeadline,
                icon: const Icon(Icons.event_rounded, size: 17),
                label: const Text('Add'),
              ),
            ],
          ),
          const SizedBox(height: 8),
          if (sortedDeadlines.isEmpty)
            const _PlannerEmpty(text: 'No deadlines added yet.')
          else
            ...sortedDeadlines.map((deadline) {
              final days = deadline.date
                  .difference(DateTime(today.year, today.month, today.day))
                  .inDays;
              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: _PlannerDeadlineRow(
                  deadline: deadline,
                  daysUntil: days,
                  onDelete: () => onDeleteDeadline(deadline),
                ),
              );
            }),
          const SizedBox(height: 22),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const _SectionTitle(title: 'Weekly timetable'),
              TextButton.icon(
                onPressed: onAddClass,
                icon: const Icon(Icons.add, size: 17),
                label: const Text('Add class'),
              ),
            ],
          ),
          const SizedBox(height: 8),
          if (timetable.isEmpty)
            const _PlannerEmpty(text: 'Add your classes and study blocks.')
          else
            ...List.generate(7, (day) {
              final entries = timetable
                  .where((entry) => entry.day == day)
                  .toList()
                ..sort((a, b) =>
                    a.start.hour * 60 +
                    a.start.minute -
                    (b.start.hour * 60 + b.start.minute));
              if (entries.isEmpty) return const SizedBox.shrink();
              return _PlannerDay(
                day: day,
                entries: entries,
                onDelete: onDeleteClass,
              );
            }),
        ],
      ),
    );
  }
}

class _PlannerEmpty extends StatelessWidget {
  const _PlannerEmpty({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(18),
        decoration: _cardDecoration(),
        child: Text(text,
            style: const TextStyle(
                color: Color(0xFF858C9F), fontWeight: FontWeight.w600)),
      );
}

class _PlannerDeadlineRow extends StatelessWidget {
  const _PlannerDeadlineRow(
      {required this.deadline,
      required this.daysUntil,
      required this.onDelete});

  final PlannerDeadline deadline;
  final int daysUntil;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final urgent = daysUntil <= 3;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
      decoration: _cardDecoration(),
      child: Row(children: [
        Icon(Icons.assignment_late_outlined,
            color: urgent ? const Color(0xFFE66B61) : const Color(0xFF5367F5)),
        const SizedBox(width: 11),
        Expanded(
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(deadline.title,
                style: const TextStyle(fontWeight: FontWeight.w800)),
            const SizedBox(height: 3),
            Text(
                '${deadline.date.day}/${deadline.date.month}/${deadline.date.year} · ${daysUntil < 0 ? 'Overdue' : daysUntil == 0 ? 'Today' : '$daysUntil days left'}',
                style: TextStyle(
                    color: urgent
                        ? const Color(0xFFE66B61)
                        : const Color(0xFF858C9F),
                    fontSize: 11,
                    fontWeight: FontWeight.w700)),
          ]),
        ),
        IconButton(
            onPressed: onDelete,
            icon: const Icon(Icons.delete_outline_rounded),
            tooltip: 'Remove deadline'),
      ]),
    );
  }
}

class _PlannerDay extends StatelessWidget {
  const _PlannerDay(
      {required this.day, required this.entries, required this.onDelete});

  final int day;
  final List<TimetableEntry> entries;
  final ValueChanged<TimetableEntry> onDelete;
  static const names = [
    'Monday',
    'Tuesday',
    'Wednesday',
    'Thursday',
    'Friday',
    'Saturday',
    'Sunday'
  ];

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: _cardDecoration(),
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(names[day],
                style: const TextStyle(
                    color: Color(0xFF5367F5), fontWeight: FontWeight.w800)),
            ...entries.map((entry) => ListTile(
                  dense: true,
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.schedule_rounded, size: 19),
                  title: Text(entry.title,
                      style: const TextStyle(fontWeight: FontWeight.w700)),
                  subtitle: Text(
                      '${entry.start.format(context)} - ${entry.end.format(context)}'),
                  trailing: IconButton(
                      onPressed: () => onDelete(entry),
                      icon: const Icon(Icons.close_rounded, size: 18)),
                )),
          ]),
        ),
      );
}

class _DeadlineDialog extends StatefulWidget {
  const _DeadlineDialog();

  @override
  State<_DeadlineDialog> createState() => _DeadlineDialogState();
}

class _DeadlineDialogState extends State<_DeadlineDialog> {
  final title = TextEditingController();
  DateTime date = DateTime.now().add(const Duration(days: 1));

  @override
  void dispose() {
    title.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
        title: const Text('Add deadline'),
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          TextField(
              controller: title,
              autofocus: true,
              decoration:
                  const InputDecoration(labelText: 'Assignment or exam')),
          const SizedBox(height: 10),
          OutlinedButton.icon(
            onPressed: () async {
              final selected = await showDatePicker(
                context: context,
                initialDate: date,
                firstDate: DateTime(2020),
                lastDate: DateTime(2100),
              );
              if (selected != null) setState(() => date = selected);
            },
            icon: const Icon(Icons.calendar_today_rounded),
            label: Text('${date.day}/${date.month}/${date.year}'),
          ),
        ]),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel')),
          FilledButton(
              onPressed: () {
                if (title.text.trim().isNotEmpty) {
                  Navigator.pop(
                      context, PlannerDeadline(title.text.trim(), date));
                }
              },
              child: const Text('Add')),
        ],
      );
}

class _TimetableDialog extends StatefulWidget {
  const _TimetableDialog();

  @override
  State<_TimetableDialog> createState() => _TimetableDialogState();
}

class _TimetableDialogState extends State<_TimetableDialog> {
  final title = TextEditingController();
  int day = 0;
  TimeOfDay start = const TimeOfDay(hour: 9, minute: 0);
  TimeOfDay end = const TimeOfDay(hour: 10, minute: 0);

  @override
  void dispose() {
    title.dispose();
    super.dispose();
  }

  Future<void> pickTime(bool isStart) async {
    final selected = await showTimePicker(
        context: context, initialTime: isStart ? start : end);
    if (selected == null) return;
    setState(() {
      if (isStart) {
        start = selected;
      } else {
        end = selected;
      }
    });
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
        title: const Text('Add timetable entry'),
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          TextField(
              controller: title,
              autofocus: true,
              decoration:
                  const InputDecoration(labelText: 'Class or study block')),
          DropdownButtonFormField<int>(
            value: day,
            decoration: const InputDecoration(labelText: 'Day'),
            items: List.generate(
                7,
                (index) => DropdownMenuItem(
                    value: index, child: Text(_PlannerDay.names[index]))),
            onChanged: (value) => setState(() => day = value ?? 0),
          ),
          Row(children: [
            Expanded(
                child: OutlinedButton(
                    onPressed: () => pickTime(true),
                    child: Text(start.format(context)))),
            const SizedBox(width: 8),
            Expanded(
                child: OutlinedButton(
                    onPressed: () => pickTime(false),
                    child: Text(end.format(context)))),
          ]),
        ]),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel')),
          FilledButton(
              onPressed: () {
                if (title.text.trim().isNotEmpty) {
                  Navigator.pop(context,
                      TimetableEntry(title.text.trim(), day, start, end));
                }
              },
              child: const Text('Add')),
        ],
      );
}

class _EmptyProgressCard extends StatelessWidget {
  const _EmptyProgressCard({required this.onAddMass});

  final VoidCallback onAddMass;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: _cardDecoration(),
      child: Column(children: [
        const Icon(Icons.show_chart_rounded,
            size: 32, color: Color(0xFF5367F5)),
        const SizedBox(height: 8),
        const Text('Start tracking your progress',
            style: TextStyle(fontWeight: FontWeight.w800)),
        const SizedBox(height: 5),
        const Text('Log your first measurement to see your evolution.'),
        const SizedBox(height: 12),
        FilledButton(
            onPressed: onAddMass, child: const Text('Add measurement')),
      ]),
    );
  }
}

class _ProgressPainter extends CustomPainter {
  _ProgressPainter({required this.entries, required this.color});

  final List<MassEntry> entries;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final values = entries.map((entry) => entry.mass).toList();
    final minValue = values.reduce((a, b) => a < b ? a : b);
    final maxValue = values.reduce((a, b) => a > b ? a : b);
    final range = (maxValue - minValue).abs() < 0.1 ? 1.0 : maxValue - minValue;
    final chart = Rect.fromLTWH(8, 8, size.width - 16, size.height - 28);
    final line = Paint()
      ..color = color
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke;
    final dot = Paint()..color = color;
    final path = Path();
    for (var index = 0; index < values.length; index++) {
      final x = values.length == 1
          ? chart.center.dx
          : chart.left + chart.width * index / (values.length - 1);
      final y =
          chart.bottom - (values[index] - minValue) / range * chart.height;
      if (index == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
      canvas.drawCircle(Offset(x, y), 5, dot);
    }
    canvas.drawPath(path, line);
    final label = TextPainter(
      text: TextSpan(
          text:
              '${minValue.toStringAsFixed(1)} - ${maxValue.toStringAsFixed(1)} kg',
          style: const TextStyle(color: Color(0xFF858C9F), fontSize: 11)),
      textDirection: TextDirection.ltr,
    )..layout();
    label.paint(canvas, Offset(8, size.height - 16));
  }

  @override
  bool shouldRepaint(covariant _ProgressPainter oldDelegate) =>
      oldDelegate.entries != entries || oldDelegate.color != color;
}

class _ProfileEditorDialog extends StatefulWidget {
  const _ProfileEditorDialog({required this.profile});

  final ProfileData profile;

  @override
  State<_ProfileEditorDialog> createState() => _ProfileEditorDialogState();
}

class _ProfileEditorDialogState extends State<_ProfileEditorDialog> {
  late final TextEditingController _name;
  late final TextEditingController _email;
  late final TextEditingController _goal;
  late final TextEditingController _target;
  String _currency = 'MUR';

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    _goal.dispose();
    _target.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    _name = TextEditingController(text: widget.profile.name);
    _email = TextEditingController(text: widget.profile.email);
    _goal = TextEditingController(text: widget.profile.goal);
    _target = TextEditingController(text: widget.profile.targetMass.toString());
    _currency = widget.profile.currency;
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Edit profile'),
      content: SingleChildScrollView(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          TextField(
              controller: _name,
              decoration: const InputDecoration(labelText: 'Name')),
          TextField(
              controller: _email,
              decoration: const InputDecoration(labelText: 'Email')),
          TextField(
              controller: _goal,
              decoration: const InputDecoration(labelText: 'Main goal')),
          TextField(
              controller: _target,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(labelText: 'Target mass (kg)')),
          DropdownButtonFormField<String>(
            value: _currency,
            decoration: const InputDecoration(labelText: 'Currency'),
            items: const [
              DropdownMenuItem(
                  value: 'MUR', child: Text('MUR · Mauritian rupee')),
              DropdownMenuItem(value: 'EUR', child: Text('EUR · Euro')),
              DropdownMenuItem(value: 'USD', child: Text('USD · US dollar')),
            ],
            onChanged: (value) => setState(() => _currency = value ?? 'MUR'),
          ),
        ]),
      ),
      actions: [
        TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel')),
        FilledButton(
          onPressed: () => Navigator.pop(
            context,
            ProfileData(
              name: _name.text.trim().isEmpty ? 'Harinjiva' : _name.text.trim(),
              email: _email.text.trim(),
              goal: _goal.text.trim().isEmpty
                  ? 'Build healthy habits'
                  : _goal.text.trim(),
              targetMass: double.tryParse(_target.text) ?? 70,
              currency: _currency,
            ),
          ),
          child: const Text('Save'),
        ),
      ],
    );
  }
}

class _MassEntryDialog extends StatefulWidget {
  const _MassEntryDialog();

  @override
  State<_MassEntryDialog> createState() => _MassEntryDialogState();
}

class _MassEntryDialogState extends State<_MassEntryDialog> {
  final _mass = TextEditingController();

  @override
  void dispose() {
    _mass.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Log mass'),
      content: TextField(
        controller: _mass,
        autofocus: true,
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        decoration: const InputDecoration(labelText: 'Mass in kg'),
      ),
      actions: [
        TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel')),
        FilledButton(
            onPressed: () {
              final value = double.tryParse(_mass.text);
              if (value != null && value > 0) Navigator.pop(context, value);
            },
            child: const Text('Log')),
      ],
    );
  }
}

class _PageScaffold extends StatelessWidget {
  const _PageScaffold({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Material(color: const Color(0xFFF7F8FC), child: child);
  }
}

class _TopGreeting extends StatelessWidget {
  const _TopGreeting({required this.onNotifications, required this.onProfile});

  final VoidCallback onNotifications;
  final VoidCallback onProfile;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(_dayLabel(DateTime.now()),
                  style: TextStyle(
                      color: Color(0xFF858C9F),
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1)),
              SizedBox(height: 8),
              Text('Good morning, Harinjiva',
                  style: TextStyle(
                      color: Color(0xFF202638),
                      fontSize: 25,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.7)),
              SizedBox(height: 5),
              Text('Let’s make today count.',
                  style: TextStyle(color: Color(0xFF858C9F), fontSize: 14)),
            ],
          ),
        ),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton.filledTonal(
              onPressed: onProfile,
              tooltip: 'Edit profile',
              icon: const Icon(Icons.person_outline_rounded),
            ),
            const SizedBox(width: 6),
            IconButton.filledTonal(
              onPressed: onNotifications,
              tooltip: 'Enable notifications',
              icon: const Icon(Icons.notifications_none_rounded),
            ),
          ],
        ),
      ],
    );
  }
}

class _MoreMenuItem extends StatelessWidget {
  const _MoreMenuItem({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => SizedBox(
        width: (MediaQuery.sizeOf(context).width - 56) / 2,
        child: ListTile(
          onTap: onTap,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          tileColor: const Color(0xFFF7F8FC),
          leading: Icon(icon, color: const Color(0xFF5367F5)),
          title:
              Text(label, style: const TextStyle(fontWeight: FontWeight.w700)),
        ),
      );
}

class _PageHeader extends StatelessWidget {
  const _PageHeader({
    required this.eyebrow,
    required this.title,
    required this.subtitle,
    this.action,
  });

  final String eyebrow;
  final String title;
  final String subtitle;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(eyebrow,
                  style: const TextStyle(
                      color: Color(0xFF858C9F),
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1)),
              const SizedBox(height: 7),
              Text(title,
                  style: const TextStyle(
                      color: Color(0xFF202638),
                      fontSize: 28,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.8)),
              const SizedBox(height: 4),
              Text(subtitle,
                  style:
                      const TextStyle(color: Color(0xFF858C9F), fontSize: 14)),
            ],
          ),
        ),
        if (action != null) action!,
      ],
    );
  }
}

class _FocusCard extends StatelessWidget {
  const _FocusCard(
      {required this.progress, required this.completed, required this.total});

  final double progress;
  final int completed;
  final int total;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(21),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
            colors: [Color(0xFF5367F5), Color(0xFF7869E9)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
              color: const Color(0xFF5367F5).withOpacity(0.18),
              blurRadius: 22,
              offset: const Offset(0, 10))
        ],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('TODAY’S FOCUS SCORE',
                style: TextStyle(
                    color: Color(0xFFDCE1FF),
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1)),
            Text('${(progress * 100).round()}%',
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.w800)),
          ],
        ),
        const SizedBox(height: 15),
        Text('$completed of $total tasks completed',
            style: const TextStyle(
                color: Colors.white,
                fontSize: 19,
                fontWeight: FontWeight.w800)),
        const SizedBox(height: 5),
        const Text('You are building a strong day.',
            style: TextStyle(color: Color(0xFFDCE1FF), fontSize: 13)),
        const SizedBox(height: 16),
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: LinearProgressIndicator(
              value: progress,
              minHeight: 8,
              backgroundColor: Colors.white.withOpacity(0.22),
              valueColor: const AlwaysStoppedAnimation(Colors.white)),
        ),
      ]),
    );
  }
}

class _MetricCard extends StatelessWidget {
  const _MetricCard(
      {required this.icon,
      required this.color,
      required this.title,
      required this.value,
      required this.subtitle,
      this.onTap});

  final IconData icon;
  final Color color;
  final String title;
  final String value;
  final String subtitle;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final card = Container(
      padding: const EdgeInsets.all(15),
      decoration: _cardDecoration(),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Icon(icon, color: color, size: 21),
        const SizedBox(height: 10),
        Text(title,
            style: const TextStyle(
                color: Color(0xFF858C9F),
                fontSize: 12,
                fontWeight: FontWeight.w700)),
        const SizedBox(height: 4),
        Text(value,
            style: const TextStyle(
                color: Color(0xFF293044),
                fontSize: 15,
                fontWeight: FontWeight.w800)),
        const SizedBox(height: 3),
        Text(subtitle,
            style: const TextStyle(color: Color(0xFF9BA1B0), fontSize: 11)),
      ]),
    );
    if (onTap == null) return card;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(17),
        child: card,
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.title, this.action, this.onAction});

  final String title;
  final String? action;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(title,
            style: const TextStyle(
                color: Color(0xFF293044),
                fontSize: 17,
                fontWeight: FontWeight.w800)),
        if (action != null)
          TextButton(
            onPressed: onAction,
            style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap),
            child: Text(action!,
                style: const TextStyle(
                    color: Color(0xFF5367F5),
                    fontSize: 12,
                    fontWeight: FontWeight.w800)),
          ),
      ],
    );
  }
}

class _TaskRow extends StatelessWidget {
  const _TaskRow({
    required this.task,
    required this.onToggle,
    this.onDelete,
  });

  final TaskItem task;
  final VoidCallback onToggle;
  final VoidCallback? onDelete;

  @override
  Widget build(BuildContext context) {
    final priorityColor = task.priority == 'High'
        ? const Color(0xFFE66B61)
        : task.priority == 'Low'
            ? const Color(0xFF62AD7D)
            : const Color(0xFFE1A448);
    final content = Container(
      padding: const EdgeInsets.all(14),
      decoration: _cardDecoration(),
      child: Row(children: [
        GestureDetector(
          onTap: onToggle,
          child: Container(
            width: 23,
            height: 23,
            decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: task.done ? const Color(0xFF5367F5) : Colors.transparent,
                border: Border.all(
                    color: task.done
                        ? const Color(0xFF5367F5)
                        : const Color(0xFFB5BAC8),
                    width: 2)),
            child: task.done
                ? const Icon(Icons.check_rounded, size: 16, color: Colors.white)
                : null,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(task.title,
                style: TextStyle(
                    color: task.done
                        ? const Color(0xFF9CA2B1)
                        : const Color(0xFF293044),
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    decoration: task.done ? TextDecoration.lineThrough : null)),
            const SizedBox(height: 4),
            Row(children: [
              Text(task.area,
                  style: const TextStyle(
                      color: Color(0xFF9CA2B1),
                      fontSize: 11,
                      fontWeight: FontWeight.w600)),
              const SizedBox(width: 7),
              Container(
                  width: 5,
                  height: 5,
                  decoration: BoxDecoration(
                      color: priorityColor, shape: BoxShape.circle)),
              const SizedBox(width: 4),
              Text(task.priority,
                  style: TextStyle(
                      color: priorityColor,
                      fontSize: 10,
                      fontWeight: FontWeight.w700)),
            ]),
          ]),
        ),
        const Icon(Icons.chevron_right_rounded, color: Color(0xFFC5C9D3)),
      ]),
    );
    if (onDelete == null) return content;
    return Dismissible(
      key: ValueKey(task.id),
      direction: DismissDirection.endToStart,
      onDismissed: (_) => onDelete!(),
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        decoration: BoxDecoration(
          color: const Color(0xFFE66B61),
          borderRadius: BorderRadius.circular(17),
        ),
        child: const Icon(Icons.delete_outline_rounded, color: Colors.white),
      ),
      child: content,
    );
  }
}

class _AssistantCard extends StatelessWidget {
  const _AssistantCard(
      {required this.title,
      required this.message,
      required this.icon,
      required this.action,
      this.onAction});

  final String title;
  final String message;
  final IconData icon;
  final String action;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
          color: const Color(0xFFEEF0FF),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: const Color(0xFFDCE0FF))),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Container(
            padding: const EdgeInsets.all(9),
            decoration: BoxDecoration(
                color: Colors.white, borderRadius: BorderRadius.circular(12)),
            child: Icon(icon, color: const Color(0xFF5367F5), size: 20)),
        const SizedBox(width: 12),
        Expanded(
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(title,
                style: const TextStyle(
                    color: Color(0xFF3945A0),
                    fontSize: 13,
                    fontWeight: FontWeight.w800)),
            const SizedBox(height: 5),
            Text(message,
                style: const TextStyle(
                    color: Color(0xFF5C6594), fontSize: 12, height: 1.35)),
            const SizedBox(height: 8),
            TextButton(
              onPressed: onAction,
              style: TextButton.styleFrom(
                  padding: EdgeInsets.zero,
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap),
              child: Text(action,
                  style: const TextStyle(
                      color: Color(0xFF5367F5),
                      fontSize: 11,
                      fontWeight: FontWeight.w800)),
            ),
          ]),
        ),
      ]),
    );
  }
}

class _MealSuggestion extends StatelessWidget {
  const _MealSuggestion({required this.ingredients, required this.onOpenPlan});

  final List<String> ingredients;
  final VoidCallback onOpenPlan;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
          gradient: const LinearGradient(
              colors: [Color(0xFFFFF3E9), Color(0xFFFFF9F3)]),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: const Color(0xFFFFE1C6))),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          const Icon(Icons.restaurant_menu_rounded,
              color: Color(0xFFE78D48), size: 20),
          const SizedBox(width: 8),
          const Expanded(
              child: Text('Meal ideas from what you have',
                  style: TextStyle(
                      color: Color(0xFF8A5529),
                      fontSize: 14,
                      fontWeight: FontWeight.w800))),
          Text('${ingredients.length} ingredients',
              style: const TextStyle(
                  color: Color(0xFFB87B4A),
                  fontSize: 11,
                  fontWeight: FontWeight.w700)),
        ]),
        const SizedBox(height: 13),
        const Text('Chicken rice bowl',
            style: TextStyle(
                color: Color(0xFF49392E),
                fontSize: 16,
                fontWeight: FontWeight.w800)),
        const SizedBox(height: 4),
        const Text(
            'Chicken · rice · broccoli · tomatoes  •  620 kcal  •  42g protein',
            style: TextStyle(color: Color(0xFF987A61), fontSize: 11)),
        const SizedBox(height: 13),
        OutlinedButton(
            onPressed: onOpenPlan,
            style: OutlinedButton.styleFrom(
                foregroundColor: const Color(0xFFE78D48),
                side: const BorderSide(color: Color(0xFFF3C99F)),
                visualDensity: VisualDensity.compact),
            child: const Text('See today’s meal plan')),
      ]),
    );
  }
}

class _PantrySummary extends StatelessWidget {
  const _PantrySummary(
      {required this.title,
      required this.value,
      required this.icon,
      required this.color});

  final String title;
  final String value;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: _cardDecoration(),
      child: Row(children: [
        Icon(icon, color: color, size: 20),
        const SizedBox(width: 9),
        Expanded(
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(title,
                style: const TextStyle(
                    color: Color(0xFF858C9F),
                    fontSize: 10,
                    fontWeight: FontWeight.w700)),
            const SizedBox(height: 3),
            Text(value,
                style: const TextStyle(
                    color: Color(0xFF293044),
                    fontSize: 15,
                    fontWeight: FontWeight.w800)),
          ]),
        ),
      ]),
    );
  }
}

class _PantryAlert extends StatelessWidget {
  const _PantryAlert({required this.lowStock, required this.expired});

  final List<GroceryItem> lowStock;
  final List<GroceryItem> expired;

  @override
  Widget build(BuildContext context) {
    final messages = <String>[
      if (lowStock.isNotEmpty)
        'Running low: ${lowStock.map((item) => item.name).join(', ')}',
      if (expired.isNotEmpty)
        'Check expiry: ${expired.map((item) => item.name).join(', ')}',
    ];
    return Container(
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF3E6),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: const Color(0xFFFFDDB8)),
      ),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Icon(Icons.notifications_active_outlined,
            color: Color(0xFFE78D48), size: 19),
        const SizedBox(width: 9),
        Expanded(
          child: Text(messages.join('\n'),
              style: const TextStyle(
                  color: Color(0xFF754B2F),
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  height: 1.4)),
        ),
      ]),
    );
  }
}

class _GroceryEditorDialog extends StatefulWidget {
  const _GroceryEditorDialog({this.initial});

  final GroceryItem? initial;

  @override
  State<_GroceryEditorDialog> createState() => _GroceryEditorDialogState();
}

class _GroceryEditorDialogState extends State<_GroceryEditorDialog> {
  late final TextEditingController _name;
  late final TextEditingController _category;
  late final TextEditingController _quantity;
  late final TextEditingController _minimum;
  late final TextEditingController _price;
  late final TextEditingController _expiryDays;

  @override
  void initState() {
    super.initState();
    final item = widget.initial;
    _name = TextEditingController(text: item?.name ?? '');
    _category = TextEditingController(text: item?.category ?? 'Other');
    _quantity = TextEditingController(text: '${item?.quantity ?? 1}');
    _minimum = TextEditingController(text: '${item?.minimumQuantity ?? 1}');
    _price = TextEditingController(text: '${item?.price ?? 0}');
    _expiryDays = TextEditingController(
        text: '${item?.expiresAt.difference(DateTime.now()).inDays ?? 7}');
  }

  @override
  void dispose() {
    for (final controller in [
      _name,
      _category,
      _quantity,
      _minimum,
      _price,
      _expiryDays,
    ]) {
      controller.dispose();
    }
    super.dispose();
  }

  void _save() {
    final name = _name.text.trim();
    if (name.isEmpty) return;
    final now = DateTime.now();
    Navigator.pop(
      context,
      GroceryItem(
        name,
        _category.text.trim().isEmpty ? 'Other' : _category.text.trim(),
        bought: widget.initial?.bought ?? false,
        quantity: double.tryParse(_quantity.text) ?? 1,
        minimumQuantity: double.tryParse(_minimum.text) ?? 1,
        price: double.tryParse(_price.text) ?? 0,
        purchasedAt: widget.initial?.purchasedAt ?? now,
        expiresAt: now.add(Duration(days: int.tryParse(_expiryDays.text) ?? 7)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(
          widget.initial == null ? 'Add grocery item' : 'Edit grocery item'),
      content: SingleChildScrollView(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          TextField(
              controller: _name,
              autofocus: true,
              decoration: const InputDecoration(labelText: 'Item name')),
          DropdownButtonFormField<String>(
            value: const ['Protein', 'Pantry', 'Vegetables', 'Dairy', 'Other']
                    .contains(_category.text)
                ? _category.text
                : 'Other',
            decoration: const InputDecoration(labelText: 'Category suggestion'),
            items: const ['Protein', 'Pantry', 'Vegetables', 'Dairy', 'Other']
                .map((category) =>
                    DropdownMenuItem(value: category, child: Text(category)))
                .toList(),
            onChanged: (value) {
              if (value != null) setState(() => _category.text = value);
            },
          ),
          TextField(
              controller: _category,
              decoration: const InputDecoration(
                  labelText: 'Category (or type your own)')),
          Row(children: [
            Expanded(
                child: TextField(
                    controller: _quantity,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(labelText: 'Quantity'))),
            const SizedBox(width: 10),
            Expanded(
                child: TextField(
                    controller: _minimum,
                    keyboardType: TextInputType.number,
                    decoration:
                        const InputDecoration(labelText: 'Alert below'))),
          ]),
          Row(children: [
            Expanded(
                child: TextField(
                    controller: _price,
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    decoration: const InputDecoration(labelText: 'Price'))),
            const SizedBox(width: 10),
            Expanded(
                child: TextField(
                    controller: _expiryDays,
                    keyboardType: TextInputType.number,
                    decoration:
                        const InputDecoration(labelText: 'Expires in days'))),
          ]),
        ]),
      ),
      actions: [
        TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel')),
        FilledButton(
            onPressed: _save,
            child: Text(widget.initial == null ? 'Add' : 'Save')),
      ],
    );
  }
}

class _GroceryRow extends StatelessWidget {
  const _GroceryRow(
      {required this.item,
      required this.onToggle,
      required this.onEdit,
      required this.onDelete,
      required this.currencySymbol});

  final GroceryItem item;
  final VoidCallback onToggle;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final String currencySymbol;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 13),
      decoration: _cardDecoration(),
      child: Row(children: [
        GestureDetector(
          onTap: onToggle,
          child: Icon(
              item.bought
                  ? Icons.check_circle_rounded
                  : Icons.radio_button_unchecked_rounded,
              color: item.bought
                  ? const Color(0xFF62AD7D)
                  : const Color(0xFFB5BAC8),
              size: 23),
        ),
        const SizedBox(width: 12),
        Expanded(
            child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(item.name,
                style: TextStyle(
                    color: item.bought
                        ? const Color(0xFF9CA2B1)
                        : const Color(0xFF293044),
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    decoration:
                        item.bought ? TextDecoration.lineThrough : null)),
            const SizedBox(height: 4),
            Text(
                '${item.quantity.toStringAsFixed(item.quantity == item.quantity.roundToDouble() ? 0 : 1)} in stock · ${item.category}',
                style: TextStyle(
                    color: item.isExpired
                        ? const Color(0xFFE66B61)
                        : item.isLow
                            ? const Color(0xFFE78D48)
                            : const Color(0xFF9CA2B1),
                    fontSize: 11)),
          ],
        )),
        Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text('$currencySymbol ${item.price.toStringAsFixed(2)}',
                style: const TextStyle(
                    color: Color(0xFF5367F5),
                    fontSize: 11,
                    fontWeight: FontWeight.w700)),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                    onPressed: onEdit,
                    icon: const Icon(Icons.edit_outlined, size: 17),
                    tooltip: 'Edit grocery'),
                IconButton(
                    onPressed: onDelete,
                    icon: const Icon(Icons.delete_outline_rounded, size: 17),
                    tooltip: 'Delete grocery'),
              ],
            ),
          ],
        ),
      ]),
    );
  }
}

class _MonthlyItemDialog extends StatefulWidget {
  const _MonthlyItemDialog({this.initial});

  final MonthlyItem? initial;

  @override
  State<_MonthlyItemDialog> createState() => _MonthlyItemDialogState();
}

class _MonthlyItemDialogState extends State<_MonthlyItemDialog> {
  late final TextEditingController _name;
  late final TextEditingController _category;
  late final TextEditingController _quantity;
  late final TextEditingController _price;
  late final TextEditingController _due;

  @override
  void initState() {
    super.initState();
    final item = widget.initial;
    _name = TextEditingController(text: item?.name ?? '');
    _category = TextEditingController(text: item?.category ?? 'Other');
    _quantity = TextEditingController(text: '${item?.quantity ?? 1}');
    _price = TextEditingController(text: '${item?.price ?? 0}');
    _due = TextEditingController(text: '${item?.daysUntilDue ?? 30}');
  }

  @override
  void dispose() {
    _name.dispose();
    _category.dispose();
    _quantity.dispose();
    _price.dispose();
    _due.dispose();
    super.dispose();
  }

  void _save() {
    if (_name.text.trim().isEmpty) return;
    Navigator.pop(
      context,
      MonthlyItem(
        _name.text.trim(),
        _category.text.trim().isEmpty ? 'Other' : _category.text.trim(),
        int.tryParse(_due.text) ?? 30,
        quantity: double.tryParse(_quantity.text) ?? 1,
        price: double.tryParse(_price.text) ?? 0,
      ),
    );
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
        title: Text(widget.initial == null
            ? 'Add monthly purchase'
            : 'Edit monthly purchase'),
        content: SingleChildScrollView(
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            TextField(
                controller: _name,
                autofocus: true,
                decoration: const InputDecoration(labelText: 'Item name')),
            DropdownButtonFormField<String>(
              value: const ['Household', 'Personal', 'Health', 'Other']
                      .contains(_category.text)
                  ? _category.text
                  : 'Other',
              decoration:
                  const InputDecoration(labelText: 'Category suggestion'),
              items: const ['Household', 'Personal', 'Health', 'Other']
                  .map((category) =>
                      DropdownMenuItem(value: category, child: Text(category)))
                  .toList(),
              onChanged: (value) {
                if (value != null) setState(() => _category.text = value);
              },
            ),
            TextField(
                controller: _category,
                decoration: const InputDecoration(
                    labelText: 'Category (or type your own)')),
            Row(children: [
              Expanded(
                  child: TextField(
                      controller: _quantity,
                      keyboardType:
                          const TextInputType.numberWithOptions(decimal: true),
                      decoration:
                          const InputDecoration(labelText: 'Quantity'))),
              const SizedBox(width: 10),
              Expanded(
                  child: TextField(
                      controller: _price,
                      keyboardType:
                          const TextInputType.numberWithOptions(decimal: true),
                      decoration: const InputDecoration(labelText: 'Price'))),
            ]),
            TextField(
                controller: _due,
                keyboardType: TextInputType.number,
                decoration:
                    const InputDecoration(labelText: 'Due again in days')),
          ]),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel')),
          FilledButton(onPressed: _save, child: const Text('Save')),
        ],
      );
}

class _CoachCard extends StatelessWidget {
  const _CoachCard({required this.title, required this.message});

  final String title;
  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(17),
      decoration: BoxDecoration(
          color: const Color(0xFFEAF7F1),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: const Color(0xFFD1EEDB))),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Icon(Icons.auto_awesome_rounded, color: Color(0xFF3F9C68)),
        const SizedBox(width: 11),
        Expanded(
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(title,
              style: const TextStyle(
                  color: Color(0xFF2D714A),
                  fontSize: 13,
                  fontWeight: FontWeight.w800)),
          const SizedBox(height: 5),
          Text(message,
              style: const TextStyle(
                  color: Color(0xFF548269), fontSize: 12, height: 1.35)),
        ])),
      ]),
    );
  }
}

class _ExerciseRow extends StatelessWidget {
  const _ExerciseRow(
      {required this.number,
      required this.exercise,
      required this.done,
      required this.onToggle});

  final int number;
  final (String, String, String) exercise;
  final bool done;
  final VoidCallback onToggle;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 9),
      padding: const EdgeInsets.all(14),
      decoration: _cardDecoration(),
      child: Row(children: [
        CircleAvatar(
            radius: 16,
            backgroundColor: const Color(0xFFEEF0FF),
            child: Text('$number',
                style: const TextStyle(
                    color: Color(0xFF5367F5), fontWeight: FontWeight.w800))),
        const SizedBox(width: 12),
        Expanded(
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(exercise.$1,
              style: const TextStyle(
                  color: Color(0xFF293044),
                  fontSize: 14,
                  fontWeight: FontWeight.w800)),
          const SizedBox(height: 3),
          Text(exercise.$2,
              style: const TextStyle(
                  color: Color(0xFF5367F5),
                  fontSize: 11,
                  fontWeight: FontWeight.w700)),
          const SizedBox(height: 3),
          Text(exercise.$3,
              style: const TextStyle(color: Color(0xFF9CA2B1), fontSize: 11)),
        ])),
        IconButton(
            onPressed: onToggle,
            icon: Icon(
                done ? Icons.check_circle_rounded : Icons.circle_outlined,
                color:
                    done ? const Color(0xFF62AD7D) : const Color(0xFFB5BAC8))),
      ]),
    );
  }
}

class _ChallengeCard extends StatelessWidget {
  const _ChallengeCard(
      {required this.title,
      required this.subtitle,
      required this.days,
      required this.total,
      required this.color,
      required this.startDate,
      required this.onDayToggle,
      required this.onDayRest,
      required this.restDays,
      this.showDays = true});

  final List<bool> days;
  final String title;
  final String subtitle;
  final int total;
  final Color color;
  final DateTime startDate;
  final ValueChanged<int> onDayToggle;
  final ValueChanged<int> onDayRest;
  final Set<int> restDays;
  final bool showDays;

  @override
  Widget build(BuildContext context) {
    final completed = days.where((day) => day).length;
    final progress = total == 0 ? 0.0 : completed / total;
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: const Color(0xFFE7E9F0))),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Expanded(
              child: Text(title,
                  style: const TextStyle(
                      color: Color(0xFF293044),
                      fontSize: 15,
                      fontWeight: FontWeight.w800))),
          Text('$completed/$total days',
              style: TextStyle(
                  color: color, fontSize: 12, fontWeight: FontWeight.w800)),
        ]),
        const SizedBox(height: 5),
        Text(subtitle,
            style: const TextStyle(color: Color(0xFF9CA2B1), fontSize: 12)),
        const SizedBox(height: 13),
        LinearProgressIndicator(
            value: progress,
            minHeight: 7,
            borderRadius: BorderRadius.circular(8),
            color: color,
            backgroundColor: color.withOpacity(0.14)),
        if (showDays) ...[
          const SizedBox(height: 15),
          Wrap(
            spacing: 7,
            runSpacing: 7,
            children: List.generate(
              total,
              (index) => _ChallengeDayCell(
                index: index,
                date: startDate.add(Duration(days: index)),
                completed: days[index],
                rest: restDays.contains(index),
                color: color,
                onTap: () => onDayToggle(index),
                onLongPress: () => onDayRest(index),
              ),
            ),
          ),
        ],
      ]),
    );
  }
}

class _SimpleChallenge extends StatelessWidget {
  const _SimpleChallenge(
      {required this.challenge,
      required this.selected,
      required this.onTap,
      required this.onDelete});

  final ChallengeItem challenge;
  final bool selected;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final completed = challenge.days.where((completed) => completed).length;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(15),
        decoration: _cardDecoration(),
        foregroundDecoration: selected
            ? BoxDecoration(
                borderRadius: BorderRadius.circular(17),
                border: Border.all(color: challenge.color, width: 1.5))
            : null,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(challenge.title,
                      style: const TextStyle(
                          color: Color(0xFF293044),
                          fontSize: 14,
                          fontWeight: FontWeight.w800)),
                ),
                Text('$completed/${challenge.days.length}',
                    style: TextStyle(
                        color: challenge.color,
                        fontSize: 11,
                        fontWeight: FontWeight.w800)),
                IconButton(
                    onPressed: onDelete,
                    icon: const Icon(Icons.delete_outline_rounded, size: 19),
                    color: const Color(0xFF9CA2B1),
                    tooltip: 'Remove challenge'),
              ],
            ),
            const SizedBox(height: 4),
            Text(challenge.subtitle,
                style: const TextStyle(color: Color(0xFF9CA2B1), fontSize: 11)),
            const SizedBox(height: 11),
            LinearProgressIndicator(
                value: challenge.days.isEmpty
                    ? 0
                    : completed / challenge.days.length,
                color: challenge.color,
                backgroundColor: challenge.color.withOpacity(0.14),
                minHeight: 6,
                borderRadius: BorderRadius.circular(8)),
          ],
        ),
      ),
    );
  }
}

class _ChallengeDayCell extends StatelessWidget {
  const _ChallengeDayCell({
    required this.index,
    required this.date,
    required this.completed,
    required this.rest,
    required this.color,
    required this.onTap,
    required this.onLongPress,
  });

  final int index;
  final DateTime date;
  final bool completed;
  final bool rest;
  final Color color;
  final VoidCallback onTap;
  final VoidCallback onLongPress;

  @override
  Widget build(BuildContext context) {
    final status = completed
        ? 'Done'
        : rest
            ? 'Rest'
            : 'Not done';
    final icon = completed
        ? Icons.check_rounded
        : rest
            ? Icons.circle_outlined
            : Icons.close_rounded;
    final iconColor = completed
        ? const Color(0xFF62AD7D)
        : rest
            ? const Color(0xFF5367F5)
            : const Color(0xFF9CA2B1);
    return Tooltip(
      message:
          'Day ${index + 1} · ${date.day}/${date.month}/${date.year} · $status',
      child: GestureDetector(
        onTap: onTap,
        onLongPress: onLongPress,
        child: Container(
          width: 42,
          height: 42,
          padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 3),
          decoration: BoxDecoration(
            color: completed
                ? const Color(0xFFEAF7F1)
                : rest
                    ? const Color(0xFFEEF0FF)
                    : const Color(0xFFF4F5F8),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
                color: completed
                    ? const Color(0xFFBDE7CE)
                    : rest
                        ? const Color(0xFFDCE0FF)
                        : const Color(0xFFE7E9F0)),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text('${date.day}/${date.month}',
                  maxLines: 1,
                  style: const TextStyle(
                      fontSize: 8, fontWeight: FontWeight.w800)),
              Icon(icon, size: 16, color: completed ? color : iconColor),
            ],
          ),
        ),
      ),
    );
  }
}

class _CalendarGrid extends StatelessWidget {
  const _CalendarGrid(
      {required this.days,
      required this.color,
      required this.startDate,
      required this.onToggle,
      required this.onRest,
      required this.restDays});

  final List<bool> days;
  final Color color;
  final DateTime startDate;
  final ValueChanged<int> onToggle;
  final ValueChanged<int> onRest;
  final Set<int> restDays;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: _cardDecoration(),
      child: Column(children: [
        const Row(
          children: [
            Icon(Icons.check_rounded, size: 16, color: Color(0xFF62AD7D)),
            SizedBox(width: 4),
            Text('Done'),
            SizedBox(width: 14),
            Icon(Icons.circle_outlined, size: 16, color: Color(0xFF5367F5)),
            SizedBox(width: 4),
            Text('Rest'),
            SizedBox(width: 14),
            Icon(Icons.close_rounded, size: 16, color: Color(0xFF9CA2B1)),
            SizedBox(width: 4),
            Text('Not done'),
          ],
        ),
        const SizedBox(height: 12),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: days.length,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 7, mainAxisSpacing: 8, crossAxisSpacing: 8),
          itemBuilder: (context, index) => GestureDetector(
            onTap: () => onToggle(index),
            onLongPress: () => onRest(index),
            child: _ChallengeDayCell(
              index: index,
              date: startDate.add(Duration(days: index)),
              completed: days[index],
              rest: restDays.contains(index),
              color: color,
              onTap: () => onToggle(index),
              onLongPress: () => onRest(index),
            ),
          ),
        ),
      ]),
    );
  }
}

class _InputDialog extends StatelessWidget {
  const _InputDialog(
      {required this.title, required this.hint, required this.controller});

  final String title;
  final String hint;
  final TextEditingController controller;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(title),
      content: TextField(
        controller: controller,
        autofocus: true,
        textCapitalization: TextCapitalization.sentences,
        decoration: InputDecoration(hintText: hint),
        onSubmitted: (value) => Navigator.pop(context, value.trim()),
      ),
      actions: [
        TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel')),
        FilledButton(
            onPressed: () => Navigator.pop(context, controller.text.trim()),
            child: const Text('Add')),
      ],
    );
  }
}

class _NumberInputDialog extends StatelessWidget {
  const _NumberInputDialog({
    required this.title,
    required this.label,
    required this.controller,
  });

  final String title;
  final String label;
  final TextEditingController controller;

  @override
  Widget build(BuildContext context) => AlertDialog(
        title: Text(title),
        content: TextField(
          controller: controller,
          autofocus: true,
          keyboardType: TextInputType.number,
          decoration: InputDecoration(labelText: label),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel')),
          FilledButton(
            onPressed: () {
              final value = int.tryParse(controller.text.trim());
              if (value != null && value >= 0) Navigator.pop(context, value);
            },
            child: const Text('Save'),
          ),
        ],
      );
}

class _ChallengeDialog extends StatefulWidget {
  const _ChallengeDialog({required this.color});

  final Color color;

  @override
  State<_ChallengeDialog> createState() => _ChallengeDialogState();
}

class _ChallengeDialogState extends State<_ChallengeDialog> {
  final _title = TextEditingController();
  final _target = TextEditingController(text: 'Complete it daily');
  final _days = TextEditingController(text: '30');
  DateTime _startDate = _dateOnly(DateTime.now());

  @override
  void dispose() {
    _title.dispose();
    _target.dispose();
    _days.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
        title: const Text('New challenge'),
        content: SingleChildScrollView(
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            TextField(
                controller: _title,
                autofocus: true,
                decoration: const InputDecoration(labelText: 'Challenge name')),
            TextField(
                controller: _target,
                decoration: const InputDecoration(labelText: 'Daily target')),
            const SizedBox(height: 12),
            TextField(
              controller: _days,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'How many days?',
                hintText: 'Enter any number from 1 to 365',
              ),
            ),
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerLeft,
              child: OutlinedButton.icon(
                onPressed: () async {
                  final picked = await showDatePicker(
                    context: context,
                    initialDate: _startDate,
                    firstDate: DateTime(2020),
                    lastDate: DateTime(2100),
                  );
                  if (picked != null) {
                    setState(() => _startDate = _dateOnly(picked));
                  }
                },
                icon: const Icon(Icons.calendar_today_rounded, size: 17),
                label: Text(
                    'Starts ${_startDate.day}/${_startDate.month}/${_startDate.year}'),
              ),
            ),
          ]),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: widget.color),
            onPressed: () {
              final totalDays = int.tryParse(_days.text.trim());
              if (_title.text.trim().isEmpty ||
                  totalDays == null ||
                  totalDays < 1 ||
                  totalDays > 365) {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                    content: Text('Enter a duration between 1 and 365 days.')));
                return;
              }
              Navigator.pop(
                context,
                ChallengeItem(
                  _title.text.trim(),
                  _target.text.trim().isEmpty
                      ? 'Complete it daily'
                      : _target.text.trim(),
                  widget.color,
                  totalDays: totalDays,
                  startDate: _startDate,
                ),
              );
            },
            child: const Text('Create'),
          ),
        ],
      );
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.message, required this.onRetry});

  final String message;
  final Future<void> Function() onRetry;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 28),
      child: Column(
        children: [
          Text(message, textAlign: TextAlign.center),
          const SizedBox(height: 10),
          OutlinedButton(
            onPressed: onRetry,
            child: const Text('Try again'),
          ),
        ],
      ),
    );
  }
}

class TaskService {
  TaskService(this._client);

  final SupabaseClient _client;

  String get _userId {
    final user = _client.auth.currentUser;
    if (user == null) {
      throw StateError('No authenticated Supabase user.');
    }
    return user.id;
  }

  Future<List<TaskItem>> getTasks() async {
    final rows = await _client
        .from('tasks')
        .select('id, title, area, priority, completed')
        .eq('user_id', _userId)
        .order('created_at', ascending: false);

    return rows
        .map(
          (row) => TaskItem(
            row['title'] as String,
            row['area'] as String,
            id: row['id'] as String,
            done: row['completed'] as bool,
            priority: row['priority'] as String,
          ),
        )
        .toList();
  }

  Future<TaskItem> createTask({
    required String title,
    String area = 'Personal',
    String priority = 'Medium',
  }) async {
    final row = await _client
        .from('tasks')
        .insert({
          'user_id': _userId,
          'title': title,
          'area': area,
          'priority': priority,
        })
        .select('id, title, area, priority, completed')
        .single();

    return TaskItem(
      row['title'] as String,
      row['area'] as String,
      id: row['id'] as String,
      done: row['completed'] as bool,
      priority: row['priority'] as String,
    );
  }

  Future<void> updateTask({
    required String id,
    bool? completed,
    String? title,
    String? area,
    String? priority,
  }) async {
    final changes = <String, dynamic>{};
    if (completed != null) changes['completed'] = completed;
    if (title != null) changes['title'] = title;
    if (area != null) changes['area'] = area;
    if (priority != null) changes['priority'] = priority;
    if (changes.isEmpty) return;

    await _client
        .from('tasks')
        .update(changes)
        .eq('id', id)
        .eq('user_id', _userId);
  }

  Future<void> deleteTask(String id) async {
    await _client.from('tasks').delete().eq('id', id).eq('user_id', _userId);
  }
}

BoxDecoration _cardDecoration() {
  return BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(17),
      border: Border.all(color: const Color(0xFFE7E9F0)),
      boxShadow: [
        BoxShadow(
          color: const Color(0xFF27325D).withOpacity(0.035),
          blurRadius: 18,
          offset: const Offset(0, 6),
        ),
      ]);
}
