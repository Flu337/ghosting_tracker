import 'dart:math';

import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  runApp(const GhostingApp());
}

// ================= THEME =================
class AppTheme {
  static const Color background = Color(0xFFFFFFFF);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color border = Color(0xFFE5E7EB);
  static const Color textMain = Color(0xFF111827);
  static const Color textMuted = Color(0xFF6B7280);
  static const Color accent = Color(0xFF000000);
  static const Color danger = Color(0xFFEF4444);
  static const Color success = Color(0xFF10B981);

  static ThemeData get light {
    return ThemeData(
      scaffoldBackgroundColor: background,
      primaryColor: accent,
      textTheme: GoogleFonts.interTextTheme(),
      appBarTheme: const AppBarTheme(
        backgroundColor: background,
        elevation: 0,
        scrolledUnderElevation: 0,
        iconTheme: IconThemeData(color: textMain),
        titleTextStyle: TextStyle(
          color: textMain,
          fontSize: 18,
          fontWeight: FontWeight.w600,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: accent,
          foregroundColor: Colors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          textStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: const Color(0xFFF9FAFB),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 16,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: accent, width: 2),
        ),
      ),
    );
  }
}

class GhostingApp extends StatelessWidget {
  const GhostingApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Ghosting Tracker',
      theme: AppTheme.light,
      debugShowCheckedModeBanner: false,
      home: const AuthScreen(),
    );
  }
}

// ================= 1. AUTH SCREEN =================
class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final TextEditingController _nameController = TextEditingController();
  bool _isLoading = true;
  List<String> _recentLobbies = [];
  String? _uid;

  @override
  void initState() {
    super.initState();
    _checkExistingSession();
  }

  Future<void> _checkExistingSession() async {
    final prefs = await SharedPreferences.getInstance();
    final name = prefs.getString('name');
    final uid = prefs.getString('uid');
    final recentLobbies = prefs.getStringList('recentLobbies') ?? [];

    if (!mounted) return;

    if (name != null) _nameController.text = name;
    _uid = uid;
    _recentLobbies = recentLobbies;

    setState(() => _isLoading = false);
  }

  Future<void> _saveNameAndProceed() async {
    final name = _nameController.text.trim();
    if (name.isEmpty) return;

    final prefs = await SharedPreferences.getInstance();
    final userId = _uid ?? DateTime.now().millisecondsSinceEpoch.toString();
    await prefs.setString('uid', userId);
    await prefs.setString('name', name);

    if (!mounted) return;
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => LobbySelectionScreen(userId: userId, userName: name),
      ),
    );
  }

  void _joinRecentLobby(String code) {
    if (_uid == null || _nameController.text.trim().isEmpty) return;
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => DashboardScreen(lobbyCode: code, currentUserId: _uid!),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator(color: AppTheme.accent)),
      );
    }

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'Ghosting.Tracker',
                style: TextStyle(fontSize: 28, fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 8),
              const Text(
                'Представься, чтобы начать',
                style: TextStyle(color: AppTheme.textMuted),
              ),
              const SizedBox(height: 32),
              TextField(
                controller: _nameController,
                decoration: const InputDecoration(
                  hintText: 'Твое имя (например, Лёха)',
                ),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _saveNameAndProceed,
                child: const Text('Продолжить'),
              ),
              if (_recentLobbies.isNotEmpty) ...[
                const SizedBox(height: 48),
                const Text(
                  'ТЕКУЩИЕ СЕССИИ',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textMuted,
                  ),
                ),
                const SizedBox(height: 16),
                ..._recentLobbies.map(
                  (code) => Padding(
                    padding: const EdgeInsets.only(bottom: 8.0),
                    child: OutlinedButton(
                      onPressed: () => _joinRecentLobby(code),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.all(16),
                        side: const BorderSide(color: AppTheme.border),
                      ),
                      child: Text(
                        'Лобби: $code',
                        style: const TextStyle(
                          color: AppTheme.textMain,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

// ================= 2. LOBBY SELECTION =================
class LobbySelectionScreen extends StatefulWidget {
  final String userId;
  final String userName;
  const LobbySelectionScreen({
    super.key,
    required this.userId,
    required this.userName,
  });

  @override
  State<LobbySelectionScreen> createState() => _LobbySelectionScreenState();
}

class _LobbySelectionScreenState extends State<LobbySelectionScreen> {
  final TextEditingController _codeController = TextEditingController();
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  String _generateCode() {
    const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    return String.fromCharCodes(
      Iterable.generate(
        6,
        (_) => chars.codeUnitAt(Random().nextInt(chars.length)),
      ),
    );
  }

  Future<void> _createLobby() async {
    final code = _generateCode();
    final userMap = {
      'id': widget.userId,
      'name': widget.userName,
      'score': 100,
      'fails': 0,
      'history': [100],
    };

    await _db.collection('lobbies').doc(code).set({
      'createdAt': FieldValue.serverTimestamp(),
      'users': [userMap],
    });

    _goToDashboard(code);
  }

  Future<void> _joinLobby() async {
    final code = _codeController.text.trim().toUpperCase();
    if (code.length != 6) return;

    final docRef = _db.collection('lobbies').doc(code);
    final doc = await docRef.get();

    if (doc.exists) {
      List users = doc.data()?['users'] ?? [];
      bool exists = users.any((u) => u['id'] == widget.userId);

      if (!exists) {
        users.add({
          'id': widget.userId,
          'name': widget.userName,
          'score': 100,
          'fails': 0,
          'history': [100],
        });
        await docRef.update({'users': users});
      }

      if (!mounted) return;
      _goToDashboard(code);
    } else {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Лобби не найдено')));
    }
  }

  Future<void> _goToDashboard(String code) async {
    final prefs = await SharedPreferences.getInstance();
    List<String> recent = prefs.getStringList('recentLobbies') ?? [];
    if (!recent.contains(code)) {
      recent.add(code);
      await prefs.setStringList('recentLobbies', recent);
    }

    if (!mounted) return;
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) =>
            DashboardScreen(lobbyCode: code, currentUserId: widget.userId),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Вход в лобби')),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.background,
                foregroundColor: AppTheme.accent,
                side: const BorderSide(color: AppTheme.border),
              ),
              onPressed: _createLobby,
              child: const Text('Создать новое лобби'),
            ),
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 24),
              child: Center(
                child: Text('ИЛИ', style: TextStyle(color: AppTheme.textMuted)),
              ),
            ),
            TextField(
              controller: _codeController,
              textCapitalization: TextCapitalization.characters,
              maxLength: 6,
              textAlign: TextAlign.center,
              style: const TextStyle(
                letterSpacing: 4,
                fontWeight: FontWeight.w600,
              ),
              decoration: const InputDecoration(hintText: 'КОД ЛОББИ'),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _joinLobby,
              child: const Text('Войти по коду'),
            ),
          ],
        ),
      ),
    );
  }
}

// ================= 3. DASHBOARD =================
class DashboardScreen extends StatelessWidget {
  final String lobbyCode;
  final String currentUserId;

  const DashboardScreen({
    super.key,
    required this.lobbyCode,
    required this.currentUserId,
  });

  void _showExitOptions(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Выход из лобби'),
          content: const Text('Как вы хотите выйти?'),
          actions: [
            TextButton(
              child: const Text(
                'Выйти с сохранением',
                style: TextStyle(color: AppTheme.textMain),
              ),
              onPressed: () {
                Navigator.of(context).pop();
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (_) => const AuthScreen()),
                );
              },
            ),
            TextButton(
              child: const Text(
                'Покинуть навсегда',
                style: TextStyle(color: AppTheme.danger),
              ),
              onPressed: () async {
                Navigator.of(context).pop();

                // Удаляем лобби из недавних
                final prefs = await SharedPreferences.getInstance();
                List<String> recent =
                    prefs.getStringList('recentLobbies') ?? [];
                recent.remove(lobbyCode);
                await prefs.setStringList('recentLobbies', recent);

                // Удаляем пользователя из лобби в БД
                final docRef = FirebaseFirestore.instance
                    .collection('lobbies')
                    .doc(lobbyCode);
                final doc = await docRef.get();
                if (doc.exists) {
                  List users = doc.data()?['users'] ?? [];
                  users.removeWhere((u) => u['id'] == currentUserId);
                  await docRef.update({'users': users});
                }

                if (!context.mounted) return;
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (_) => const AuthScreen()),
                );
              },
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Лобби: $lobbyCode',
          style: const TextStyle(letterSpacing: 1),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.exit_to_app),
            onPressed: () => _showExitOptions(context),
          ),
        ],
      ),
      body: StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance
            .collection('lobbies')
            .doc(lobbyCode)
            .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData || !snapshot.data!.exists) {
            return const Center(
              child: CircularProgressIndicator(color: AppTheme.accent),
            );
          }

          var data = snapshot.data!.data() as Map<String, dynamic>;
          List users = List.from(data['users'] ?? []);
          users.sort(
            (a, b) => (a['score'] as int).compareTo(b['score'] as int),
          );

          return ListView(
            padding: const EdgeInsets.all(24),
            children: [
              const Text(
                'ИНДЕКСЫ ДОВЕРИЯ',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textMuted,
                ),
              ),
              const SizedBox(height: 12),
              ...users.map((u) => _buildUserCard(context, u)),

              const SizedBox(height: 32),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'АКТИВНЫЕ ОБЕЩАНИЯ',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.textMuted,
                    ),
                  ),
                  TextButton(
                    onPressed: () => _showAddPromiseModal(context, users),
                    child: const Text(
                      '+ Добавить',
                      style: TextStyle(
                        color: AppTheme.accent,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              _buildPromisesList(users),
            ],
          );
        },
      ),
    );
  }

  Widget _buildUserCard(BuildContext context, Map user) {
    int score = user['score'];
    Color scoreColor = score > 70
        ? AppTheme.success
        : (score > 30 ? Colors.orange : AppTheme.danger);

    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => UserDetailScreen(user: user, lobbyCode: lobbyCode),
        ),
      ),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppTheme.surface,
          border: Border.all(color: AppTheme.border),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: const Color(0xFFF3F4F6),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Center(
                child: Text(
                  user['name'][0].toUpperCase(),
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    user['name'] + (user['id'] == currentUserId ? ' (Вы)' : ''),
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 16,
                    ),
                  ),
                  Text(
                    'Сливов: ${user['fails']}',
                    style: const TextStyle(
                      color: AppTheme.textMuted,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
            Text(
              '$score%',
              style: TextStyle(
                fontWeight: FontWeight.w800,
                fontSize: 18,
                color: scoreColor,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPromisesList(List users) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('lobbies')
          .doc(lobbyCode)
          .collection('promises')
          .where('status', isEqualTo: 'pending')
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const SizedBox();

        var docs = snapshot.data!.docs.toList();
        docs.sort((a, b) {
          final aData = a.data() as Map<String, dynamic>;
          final bData = b.data() as Map<String, dynamic>;
          final aTime = aData['createdAt'] as Timestamp?;
          final bTime = bData['createdAt'] as Timestamp?;
          if (aTime == null || bTime == null) return 0;
          return bTime.compareTo(aTime);
        });

        if (docs.isEmpty) {
          return const Padding(
            padding: EdgeInsets.symmetric(vertical: 24),
            child: Text(
              'Нет активных обещаний. Все кристально чисты.',
              style: TextStyle(color: AppTheme.textMuted),
            ),
          );
        }

        return Column(
          children: docs.map((doc) {
            var p = doc.data() as Map<String, dynamic>;
            var targetUser = users.firstWhere(
              (u) => u['id'] == p['targetUserId'],
              orElse: () => {'name': 'Неизвестный'},
            );
            bool isMyPromise = p['targetUserId'] == currentUserId;

            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFFAFAFA),
                border: Border.all(color: AppTheme.border),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${targetUser['name']} обещал:',
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppTheme.textMuted,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    p['text'],
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 15,
                    ),
                  ),
                  const SizedBox(height: 16),

                  if (isMyPromise)
                    const Text(
                      'Ожидает решения от других участников...',
                      style: TextStyle(
                        color: AppTheme.textMuted,
                        fontSize: 13,
                        fontStyle: FontStyle.italic,
                      ),
                    )
                  else
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            style: OutlinedButton.styleFrom(
                              foregroundColor: AppTheme.danger,
                              side: const BorderSide(color: AppTheme.border),
                            ),
                            onPressed: () => _resolvePromise(
                              doc.id,
                              targetUser['id'],
                              false,
                              users,
                            ),
                            child: const Text('Слился'),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: OutlinedButton(
                            style: OutlinedButton.styleFrom(
                              foregroundColor: AppTheme.success,
                              side: const BorderSide(color: AppTheme.border),
                            ),
                            onPressed: () => _resolvePromise(
                              doc.id,
                              targetUser['id'],
                              true,
                              users,
                            ),
                            child: const Text('Сдержал'),
                          ),
                        ),
                      ],
                    ),
                ],
              ),
            );
          }).toList(),
        );
      },
    );
  }

  void _showAddPromiseModal(BuildContext context, List users) {
    final otherUsers = users.where((u) => u['id'] != currentUserId).toList();

    if (otherUsers.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'В лобби пока нет других участников. Пригласите друзей!',
          ),
        ),
      );
      return;
    }

    String selectedUserId = otherUsers.first['id'];
    final TextEditingController textController = TextEditingController();

    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.background,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setState) {
            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom,
                left: 24,
                right: 24,
                top: 24,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text(
                    'Зафиксировать обещание',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                    initialValue: selectedUserId,
                    decoration: const InputDecoration(
                      labelText: 'Кто обещает?',
                    ),
                    items: otherUsers
                        .map(
                          (u) => DropdownMenuItem<String>(
                            value: u['id'],
                            child: Text(u['name']),
                          ),
                        )
                        .toList(),
                    onChanged: (v) => setState(() => selectedUserId = v!),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: textController,
                    decoration: const InputDecoration(
                      hintText:
                          'Что именно (например, "Не пить пиво в пятницу")',
                    ),
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: () {
                      if (textController.text.trim().isEmpty) return;
                      FirebaseFirestore.instance
                          .collection('lobbies')
                          .doc(lobbyCode)
                          .collection('promises')
                          .add({
                            'text': textController.text.trim(),
                            'targetUserId': selectedUserId,
                            'status': 'pending',
                            'createdAt': FieldValue.serverTimestamp(),
                          });
                      Navigator.pop(context);
                    },
                    child: const Text('Сохранить'),
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _resolvePromise(
    String promiseId,
    String userId,
    bool kept,
    List users,
  ) async {
    await FirebaseFirestore.instance
        .collection('lobbies')
        .doc(lobbyCode)
        .collection('promises')
        .doc(promiseId)
        .update({'status': kept ? 'kept' : 'broken'});

    var userIndex = users.indexWhere((u) => u['id'] == userId);
    if (userIndex == -1) return;

    var user = Map<String, dynamic>.from(users[userIndex]);
    int currentScore = user['score'];
    List history = List.from(user['history']);

    if (kept) {
      currentScore = (currentScore + 5).clamp(0, 100);
    } else {
      currentScore = (currentScore - 15).clamp(0, 100);
      user['fails'] = (user['fails'] ?? 0) + 1;
    }

    history.add(currentScore);
    user['score'] = currentScore;
    user['history'] = history;
    users[userIndex] = user;

    await FirebaseFirestore.instance
        .collection('lobbies')
        .doc(lobbyCode)
        .update({'users': users});
  }
}

// ================= 4. USER GRAPH DETAIL SCREEN =================
class UserDetailScreen extends StatelessWidget {
  final Map user;
  final String lobbyCode;

  const UserDetailScreen({
    super.key,
    required this.user,
    required this.lobbyCode,
  });

  @override
  Widget build(BuildContext context) {
    List<int> history = List<int>.from(user['history'] ?? [100]);
    List<FlSpot> spots = [];
    for (int i = 0; i < history.length; i++) {
      spots.add(FlSpot(i.toDouble(), history[i].toDouble()));
    }

    return Scaffold(
      appBar: AppBar(title: Text(user['name'])),
      body: SingleChildScrollView(
        // Добавили скролл, так как добавится история
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: AppTheme.surface,
                border: Border.all(color: AppTheme.border),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'ИНДЕКС ДОВЕРИЯ',
                    style: TextStyle(
                      color: AppTheme.textMuted,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    '${user['score']}%',
                    style: const TextStyle(
                      fontSize: 48,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -1,
                    ),
                  ),
                  const SizedBox(height: 32),
                  SizedBox(
                    height: 150,
                    child: LineChart(
                      LineChartData(
                        gridData: const FlGridData(show: false),
                        titlesData: const FlTitlesData(show: false),
                        borderData: FlBorderData(show: false),
                        minX: 0,
                        maxX: (spots.length - 1).toDouble(),
                        minY: 0,
                        maxY: 100,
                        lineBarsData: [
                          LineChartBarData(
                            spots: spots,
                            isCurved: true,
                            color: AppTheme.accent,
                            barWidth: 3,
                            isStrokeCapRound: true,
                            dotData: const FlDotData(show: false),
                            belowBarData: BarAreaData(
                              show: true,
                              color: AppTheme.accent.withValues(alpha: 0.05),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                border: Border.all(color: AppTheme.border),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Нарушено',
                    style: TextStyle(color: AppTheme.textMuted, fontSize: 13),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${user['fails']}',
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.danger,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 48),
            const Text(
              'ИСТОРИЯ ОБЕЩАНИЙ',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: AppTheme.textMuted,
              ),
            ),
            const SizedBox(height: 16),
            _buildHistoryList(),
          ],
        ),
      ),
    );
  }

  // Виджет для вывода истории обещаний этого пользователя
  // Виджет для вывода истории обещаний этого пользователя
  Widget _buildHistoryList() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('lobbies')
          .doc(lobbyCode)
          .collection('promises')
          .where('targetUserId', isEqualTo: user['id'])
          .where('status', whereIn: ['kept', 'broken'])
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(
            child: CircularProgressIndicator(color: AppTheme.accent),
          );
        }

        var docs = snapshot.data!.docs.toList();
        docs.sort((a, b) {
          final aData = a.data() as Map<String, dynamic>;
          final bData = b.data() as Map<String, dynamic>;
          final aTime = aData['createdAt'] as Timestamp?;
          final bTime = bData['createdAt'] as Timestamp?;
          if (aTime == null || bTime == null) return 0;
          return bTime.compareTo(aTime);
        });

        if (docs.isEmpty) {
          return const Text(
            'Пока нет завершенных обещаний.',
            style: TextStyle(color: AppTheme.textMuted),
          );
        }

        return Column(
          children: docs.map((doc) {
            var p = doc.data() as Map<String, dynamic>;
            bool isKept = p['status'] == 'kept';

            return Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFFAFAFA),
                border: Border.all(color: AppTheme.border),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  StatusBadge(isKept: isKept),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      p['text'],
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: AppTheme.textMain, // Никаких зачеркиваний
                      ),
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
        );
      },
    );
  }
}

// ================= ВЕКТОРНЫЕ ИКОНКИ (SVG-ЭКВИВАЛЕНТ) =================
class StatusBadge extends StatelessWidget {
  final bool isKept;
  const StatusBadge({super.key, required this.isKept});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 24,
      height: 24,
      decoration: BoxDecoration(
        color: isKept ? AppTheme.success : AppTheme.danger,
        shape: BoxShape.circle,
      ),
      child: Center(
        child: CustomPaint(
          size: const Size(12, 12),
          painter: _BadgePainter(isKept: isKept),
        ),
      ),
    );
  }
}

class _BadgePainter extends CustomPainter {
  final bool isKept;
  _BadgePainter({required this.isKept});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white
      ..strokeWidth = 2.0
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final path = Path();
    if (isKept) {
      // Векторная галочка
      path.moveTo(size.width * 0.15, size.height * 0.55);
      path.lineTo(size.width * 0.42, size.height * 0.82);
      path.lineTo(size.width * 0.88, size.height * 0.22);
    } else {
      // Векторный крестик
      path.moveTo(size.width * 0.2, size.height * 0.2);
      path.lineTo(size.width * 0.8, size.height * 0.8);
      path.moveTo(size.width * 0.8, size.height * 0.2);
      path.lineTo(size.width * 0.2, size.height * 0.8);
    }
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
