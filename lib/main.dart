import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as supabase;
import 'package:supabase_flutter/supabase_flutter.dart';
import 'firebase_options.dart';
import 'features/auth/ui/pages/login_page.dart';
import 'features/home/presentation/pages/home_page.dart';
import 'features/schedule/presentation/pages/schedule_page.dart';
import 'reels_page.dart';
import 'menu_page.dart';
import 'features/prd/presentation/pages/prd_work_dashboard.dart';
import 'features/sports/presentation/pages/admin_sports_page.dart';
import 'features/literary/presentation/pages/admin_literary_page.dart';
import 'utils/admin_page_helper.dart';
// 🎬 Splash screen removed
// 🟢 Added the notification service import here
import 'home/constitution_page.dart';
import 'dart:async';
// Unused cloud_firestore import removed
import 'core/services/notification_service.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'core/services/preferences_service.dart';
import 'core/supabase/supabase_config.dart';
import 'core/theme/app_colors.dart';

import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

// Top-level background message handler for FCM
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await dotenv.load(fileName: ".env");
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  debugPrint("Handling a background message: ${message.messageId}");
}

void main() async {
  runZonedGuarded(
    () async {
      WidgetsFlutterBinding.ensureInitialized();
      try {
        await dotenv.load(fileName: ".env");
      } catch (e) {
        debugPrint("Dotenv load failed: $e");
      }

      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );

      await supabase.Supabase.initialize(
        url: SupabaseConfig.url,
        publishableKey: SupabaseConfig.anonKey,
      );

      await PreferencesService.init();
      themeNotifier.value = PreferencesService.getThemeMode();

      runApp(const MyApp());
      WidgetsBinding.instance.addPostFrameCallback((_) {
        unawaited(_configureNotificationsAfterLaunch());
      });
    },
    (error, stack) {
      debugPrint("Global Error: $error");
      debugPrint(stack.toString());
    },
  );
}

Future<void> _configureNotificationsAfterLaunch() async {
  if (kIsWeb) return;

  try {
    await NotificationService.init();
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
    await FirebaseMessaging.instance.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );
  } catch (e) {
    debugPrint("Notification setup failed: $e");
  }
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: themeNotifier,
      builder: (context, currentThemeMode, child) {
        return MaterialApp(
          debugShowCheckedModeBanner: false,
          themeMode: currentThemeMode,
          theme: AppTheme.light(),
          darkTheme: AppTheme.dark(),
          // 🎬 AuthGate handles logging in or auto-routing to AppRoot
          home: const AuthGate(),
          onGenerateRoute: (settings) {
            // Standard routes
            if (settings.name == '/login') {
              return MaterialPageRoute(
                builder: (context) => const LoginScreen(),
              );
            }
            if (settings.name == '/constitution') {
              return MaterialPageRoute(
                builder: (context) => const ConstitutionPage(),
              );
            }
            return null;
          },
        );
      },
    );
  }
}

// --- ADDED: AUTH GATE FOR AUTO-LOGIN ---
// --- ADDED: AUTH GATE FOR AUTO-LOGIN ---
class AuthGate extends StatefulWidget {
  const AuthGate({super.key});

  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  // --- STATE MACHINE VARIABLES ---
  // These drive build() and are only changed via setState()
  bool _isLoading = true;
  bool _isLoggedIn = false;
  Map<String, dynamic>? _studentData;
  bool _isAdmin = false;
  String _studentID = '';
  String _userName = 'Student';
  String? _stableKey;
  String? _studentLookupMessage;

  StreamSubscription<supabase.AuthState>? _authSubscription;
  Timer? _authLoadTimeout;
  supabase.User? _currentUser;

  @override
  void initState() {
    super.initState();
    final auth = supabase.Supabase.instance.client.auth;
    _authSubscription = auth.onAuthStateChange.listen((state) {
      unawaited(_onAuthStateChanged(state.session?.user));
    });
    unawaited(_onAuthStateChanged(auth.currentUser));
    _authLoadTimeout = Timer(const Duration(seconds: 8), () {
      if (!mounted || !_isLoading) return;
      debugPrint('AuthGate: auth state timed out, showing login screen.');
      setState(() {
        _isLoading = false;
        _isLoggedIn = false;
        _currentUser = null;
        _studentData = null;
      });
    });
  }

  Future<void> _onAuthStateChanged(supabase.User? user) async {
    _authLoadTimeout?.cancel();
    if (user == null) {
      // Logged out
      if (mounted) {
        setState(() {
          _isLoading = false;
          _isLoggedIn = false;
          _currentUser = null;
          _studentData = null;
          _studentLookupMessage = null;
        });
      }
      return;
    }

    // If same user and data is already loaded, do nothing
    if (user.id == _currentUser?.id &&
        (_studentData != null || _studentLookupMessage != null)) {
      return;
    }

    _currentUser = user;

    // First time: show loader while we fetch
    if (_studentData == null && mounted) {
      setState(() => _isLoading = true);
    }

    try {
      final String? userEmail = user.email?.trim().toLowerCase();
      if (userEmail == null || userEmail.isEmpty) {
        throw StateError('Supabase user email is missing.');
      }
      final studentData = await supabase.Supabase.instance.client
          .from('students')
          .select()
          .eq('auth_email', userEmail)
          .maybeSingle();
      final String rStr = studentData?['role']?.toString().toLowerCase().trim() ?? '';
      final String aRoleStr = studentData?['assigned_role']?.toString().toLowerCase().trim() ?? '';
      final String desigStr = studentData?['designation']?.toString().toLowerCase().trim() ?? '';
      final String fullRoleText = "$rStr $aRoleStr $desigStr";
      final bool isAdmin = rStr == 'admin' ||
          studentData?['is_admin'] == true ||
          fullRoleText.contains('admin') ||
          fullRoleText.contains('executive') ||
          fullRoleText.contains('chairman') ||
          fullRoleText.contains('general secretary') ||
          fullRoleText.contains('president') ||
          fullRoleText.contains('secretary') ||
          fullRoleText.contains('treasurer') ||
          fullRoleText.contains('union director');

      final String searchId = userEmail.contains('@')
          ? userEmail.split('@')[0].trim()
          : userEmail;

      final Map<String, dynamic> data;
      final String docId;

      if (studentData != null) {
        data = _normalizeSupabaseStudentData(studentData, userEmail);
        docId =
            studentData['firestore_id']?.toString() ??
            studentData['id']?.toString() ??
            user.id;
      } else {
        data = const {};
        docId = 'NOT_FOUND';
      }

      // Compute derived values
      final String studentID = data['studentID']?.toString() ?? searchId;
      final String userName = data['fullName']?.toString() ?? 'Student';

      if (mounted) {
        setState(() {
          _isLoading = false;
          _isLoggedIn = true;
          _studentData = studentData == null ? null : data;
          _studentID = studentID;
          _userName = userName;
          _isAdmin = isAdmin;
          _stableKey = 'AppRoot_$docId';
          _studentLookupMessage = studentData == null
              ? 'No Supabase student row found for this auth_email.'
              : null;
        });
      }
    } catch (e) {
      debugPrint('AuthGate: Error fetching student data: $e');
      if (mounted) {
        // Still let them in; just with empty data
        setState(() {
          _isLoading = false;
          _isLoggedIn = true;
          _studentData = null;
          _isAdmin = false;
          _stableKey = 'AppRoot_ERROR';
          _studentLookupMessage =
              'No Supabase student row found for this auth_email.';
        });
      }
    }
  }

  Map<String, dynamic> _normalizeSupabaseStudentData(
    Map<String, dynamic> row,
    String authEmail,
  ) {
    final personalEmail = row['personal_email']?.toString();
    final studentId =
        row['student_id']?.toString() ??
        row['studentID']?.toString() ??
        row['cic_no']?.toString();

    return {
      ...row,
      'uid': row['firebase_uid'] ?? row['uid'] ?? row['id'],
      'fullName': row['full_name'] ?? row['fullName'] ?? row['name'],
      'studentID': studentId,
      'cicNo': row['cic_no'] ?? row['cicNo'] ?? studentId,
      'class': row['class_name'] ?? row['class'],
      'personalEmail': personalEmail,
      'email': row['email'],
      'authEmail': row['auth_email'] ?? authEmail,
      'assignedRole': row['assigned_role'] ?? row['assignedRole'],
      'assigned_role': row['assigned_role'] ?? row['assignedRole'],
      'role': row['role'],
      'designation': row['designation'],
      'isAdmin': row['is_admin'] ?? row['isAdmin'] ?? false,
      'is_admin': row['is_admin'] ?? row['isAdmin'] ?? false,
      'unionBalance': row['union_balance'] ?? row['unionBalance'] ?? 0,
      'unionTotalPaid': row['union_total_paid'] ?? row['unionTotalPaid'] ?? 0,
      'storeBalance': row['store_balance'] ?? row['storeBalance'] ?? 0,
      'storeTotalAdded':
          row['store_total_added'] ?? row['storeTotalAdded'] ?? 0,
      'libraryFine': row['library_fine'] ?? row['libraryFine'] ?? 0,
      'libraryStatus': row['library_status'] ?? row['libraryStatus'],
      'prdPrintBalance':
          row['prd_print_balance'] ?? row['prdPrintBalance'] ?? 0,
      'prdPrintTotalAdded':
          row['prd_print_total_added'] ?? row['prdPrintTotalAdded'] ?? 0,
    };
  }

  @override
  void dispose() {
    _authLoadTimeout?.cancel();
    _authSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    if (!_isLoggedIn) {
      return const LoginScreen();
    }
    if (_studentLookupMessage != null) {
      return Scaffold(
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Text(
              _studentLookupMessage!,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 16, color: Colors.redAccent),
            ),
          ),
        ),
      );
    }
    return AppRoot(
      key: ValueKey(_stableKey),
      studentID: _studentID,
      userName: _userName,
      isAdmin: _isAdmin,
      studentData: _studentData,
    );
  }
}

class AppRoot extends StatefulWidget {
  final String studentID;
  final String userName;
  final bool isAdmin;
  final Map<String, dynamic>? studentData; // 🟢 Add this

  const AppRoot({
    super.key,
    required this.studentID,
    required this.userName,
    required this.isAdmin,
    this.studentData,
  });

  @override
  State<AppRoot> createState() => AppRootState();
}

class _RoleTabInfo {
  final String label;
  final IconData icon;
  final Widget page;

  _RoleTabInfo({
    required this.label,
    required this.icon,
    required this.page,
  });
}

_RoleTabInfo? _getRoleTabInfo({
  required String studentID,
  required Map<String, dynamic>? studentData,
  required bool isAdmin,
}) {
  final String role = studentData?['role']?.toString().toLowerCase().trim() ?? '';
  final String assignedRole = (studentData?['assigned_role'] ?? studentData?['assignedRole'])?.toString().toLowerCase().trim() ?? '';
  final String designation = studentData?['designation']?.toString().toLowerCase().trim() ?? '';
  final String fullText = "$role $assignedRole $designation";


  final bool isExecOrFullAdmin = isAdmin ||
      role == 'admin' ||
      studentData?['is_admin'] == true ||
      fullText.contains('executive') ||
      fullText.contains('chairman') ||
      fullText.contains('president') ||
      fullText.contains('secretary') ||
      fullText.contains('treasurer') ||
      fullText.contains('union director');

  if (isExecOrFullAdmin) {
    return _RoleTabInfo(
      label: 'Management',
      icon: Icons.dashboard_customize_rounded,
      page: MenuPage(
        isAdmin: true,
        studentID: studentID,
        studentData: studentData,
      ),
    );
  }

  // Use pre-existing AdminPageHelper to load the department dashboard
  final List<String> accessible = AdminPageHelper.getAccessibleCommittees(studentData);
  if (accessible.isNotEmpty) {
    final String committeeName = accessible.first;
    final Widget? pageWidget = AdminPageHelper.getPageByName(committeeName);
    if (pageWidget != null) {
      IconData icon = Icons.dashboard_rounded;
      if (committeeName.contains('PRD')) {
        icon = Icons.campaign_rounded;
      } else if (committeeName.contains('Sports')) {
        icon = Icons.sports_soccer_rounded;
      } else if (committeeName.contains('Literary')) {
        icon = Icons.edit_note_rounded;
      } else if (committeeName.contains('Library')) {
        icon = Icons.menu_book_rounded;
      } else if (committeeName.contains('Fine Arts')) {
        icon = Icons.palette_rounded;
      } else if (committeeName.contains('Store')) {
        icon = Icons.shopping_cart_rounded;
      } else if (committeeName.contains('Social')) {
        icon = Icons.public_rounded;
      } else if (committeeName.contains('Research')) {
        icon = Icons.science_rounded;
      } else if (committeeName.contains('CUC')) {
        icon = Icons.school_rounded;
      }

      return _RoleTabInfo(
        label: committeeName,
        icon: icon,
        page: pageWidget,
      );
    }
  }

  // Fallback keyword matching
  if (fullText.contains('public relations') || fullText.contains('prd')) {
    return _RoleTabInfo(
      label: 'PRD',
      icon: Icons.campaign_rounded,
      page: const PrdWorkDashboard(),
    );
  }

  if (fullText.contains('sports')) {
    return _RoleTabInfo(
      label: 'Sports',
      icon: Icons.sports_soccer_rounded,
      page: const AdminSportsPage(),
    );
  }

  if (fullText.contains('literary')) {
    return _RoleTabInfo(
      label: 'Literary',
      icon: Icons.edit_note_rounded,
      page: const AdminLiteraryPage(),
    );
  }

  return null;
}

class AppRootState extends State<AppRoot> {
  int _selectedIndex = 0;
  final Set<int> _loadedTabs = {0};
  DateTime? _lastBackPressedAt;
  late List<Widget> _pages;
  late List<BottomNavigationBarItem> _navItems;

  void switchTab(int index) {
    setState(() {
      _selectedIndex = index;
      _loadedTabs.add(index);
    });
  }

  @override
  void initState() {
    super.initState();
    debugPrint("AppRoot: Initializing State for ${widget.studentID}");

    _initPagesAndTabs();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _saveDeviceToken();
    });
  }

  @override
  void didUpdateWidget(AppRoot oldWidget) {
    super.didUpdateWidget(oldWidget);
    debugPrint("AppRoot: didUpdateWidget for ${widget.studentID}");
    if (oldWidget.studentID != widget.studentID ||
        oldWidget.isAdmin != widget.isAdmin ||
        oldWidget.studentData != widget.studentData) {
      _initPagesAndTabs();
      _selectedIndex = 0;
      _loadedTabs
        ..clear()
        ..add(0);
    }
  }

  void _initPagesAndTabs() {
    final roleTab = _getRoleTabInfo(
      studentID: widget.studentID,
      studentData: widget.studentData,
      isAdmin: widget.isAdmin,
    );

    _pages = [
      HomePage(
        studentID: widget.studentID,
        studentName: widget.userName,
        isAdmin: widget.isAdmin,
        studentData: widget.studentData,
        onTabSwitch: switchTab,
      ),
      if (roleTab != null) roleTab.page,
      const SchedulePage(),
      const ReelsPage(),
    ];

    _navItems = [
      const BottomNavigationBarItem(
        icon: Icon(Icons.home_outlined),
        activeIcon: Icon(Icons.home_rounded),
        label: 'Home',
      ),
      if (roleTab != null)
        BottomNavigationBarItem(
          icon: Icon(roleTab.icon),
          activeIcon: Icon(roleTab.icon),
          label: roleTab.label,
        ),
      const BottomNavigationBarItem(
        icon: Icon(Icons.calendar_month_outlined),
        activeIcon: Icon(Icons.calendar_month_rounded),
        label: 'Schedule',
      ),
      const BottomNavigationBarItem(
        icon: Icon(Icons.videocam_outlined),
        activeIcon: Icon(Icons.videocam_rounded),
        label: 'Reels',
      ),
    ];
  }

  Future<void> _saveDeviceToken() async {
    if (kIsWeb) return;
    try {
      String? token = await FirebaseMessaging.instance.getToken();

      if (token != null) {
        await Supabase.instance.client
            .from('students')
            .update({'fcm_token': token})
            .eq('student_id', widget.studentID);
      }
    } catch (e) {
      debugPrint("Error saving token: $e");
    }
  }

  @override
  void dispose() {
    debugPrint("AppRoot: Disposing State for ${widget.studentID}");
    super.dispose();
  }

  bool _canPop = false;

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: _canPop,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        final shouldPop = await _handleBackPress();
        if (shouldPop && context.mounted) {
          setState(() {
            _canPop = true;
          });
          Navigator.of(context).maybePop();
        }
      },
      child: Scaffold(
        body: IndexedStack(
          index: _selectedIndex,
          children: List.generate(
            _pages.length,
            (index) => _loadedTabs.contains(index)
                ? _pages[index]
                : const SizedBox.shrink(),
          ),
        ),
        bottomNavigationBar: BottomNavigationBar(
          currentIndex: _selectedIndex >= _pages.length ? 0 : _selectedIndex,
          onTap: switchTab,
          items: _navItems,
        ),
      ),
    );
  }

  Future<bool> _handleBackPress() async {
    if (_selectedIndex != 0) {
      switchTab(0);
      return false;
    }

    final now = DateTime.now();
    if (_lastBackPressedAt == null ||
        now.difference(_lastBackPressedAt!) > const Duration(seconds: 2)) {
      _lastBackPressedAt = now;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Press back again to exit'),
          duration: Duration(seconds: 2),
        ),
      );
      return false;
    }

    return true;
  }
}
