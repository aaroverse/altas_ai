import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:async';

import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'config/app_config.dart';
import 'config/dev_config.dart';
import 'models/menu_item.dart';
import 'views/ready_view.dart';
import 'views/processing_view.dart';
import 'views/result_view.dart';
import 'views/error_view.dart';
import 'views/auth_screen.dart';
import 'views/profile_screen.dart';
import 'views/upgrade_view.dart';
import 'services/subscription_manager.dart';
import 'services/preferences_manager.dart';

import 'package:url_launcher/url_launcher.dart';

// Define the states of the application
enum AppState { ready, processing, result, error }

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Supabase with secure configuration
  await Supabase.initialize(
    url:
        AppConfig.isConfigValid ? AppConfig.supabaseUrl : DevConfig.supabaseUrl,
    anonKey: AppConfig.isConfigValid
        ? AppConfig.supabaseAnonKey
        : DevConfig.supabaseAnonKey,
  );
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    // Modern Dark Theme Design Tokens
    const colorPrimary = Color(0xFF4F46E5);
    const colorSecondary = Color(0xFF06B6D4);
    const colorAccent = Color(0xFF10B981);

    // Dark theme colors
    const colorBackgroundDark = Color(0xFF0F0F0F);
    const colorSurfaceDark = Color(0xFF1A1A1A);
    const colorCardDark = Color(0xFF2A2A2A);
    const colorTextDark = Color(0xFFFFFFFF);
    const colorSubtleDark = Color(0xFF9CA3AF);
    const colorBorderDark = Color(0xFF374151);

    // Create dark theme
    final darkTheme = ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: const ColorScheme.dark(
        primary: colorPrimary,
        secondary: colorSecondary,
        tertiary: colorAccent,
        surface: colorSurfaceDark,
        onSurface: colorTextDark,
        onPrimary: Colors.white,
        onSecondary: Colors.white,
        error: Color(0xFFEF4444),
        onError: Colors.white,
        outline: colorBorderDark,
        surfaceContainerHighest: colorCardDark,
        onSurfaceVariant: colorSubtleDark,
      ),
      scaffoldBackgroundColor: colorBackgroundDark,
      fontFamily: GoogleFonts.inter().fontFamily,
      textTheme:
          GoogleFonts.interTextTheme(ThemeData.dark().textTheme).copyWith(
        displayLarge: const TextStyle(
          fontWeight: FontWeight.w700,
          color: colorTextDark,
        ),
        displayMedium: const TextStyle(
          fontWeight: FontWeight.w700,
          color: colorTextDark,
        ),
        displaySmall: const TextStyle(
          fontWeight: FontWeight.w700,
          color: colorTextDark,
        ),
        headlineLarge: const TextStyle(
          fontWeight: FontWeight.w700,
          color: colorTextDark,
        ),
        headlineMedium: const TextStyle(
          fontWeight: FontWeight.w600,
          color: colorTextDark,
        ),
        headlineSmall: const TextStyle(
          fontWeight: FontWeight.w600,
          color: colorTextDark,
        ),
        titleLarge: const TextStyle(
          fontWeight: FontWeight.w600,
          color: colorTextDark,
        ),
        titleMedium: const TextStyle(
          fontWeight: FontWeight.w600,
          color: colorTextDark,
        ),
        titleSmall: const TextStyle(
          fontWeight: FontWeight.w500,
          color: colorSubtleDark,
        ),
        bodyLarge: const TextStyle(color: colorTextDark),
        bodyMedium: const TextStyle(color: colorSubtleDark),
        bodySmall: const TextStyle(color: colorSubtleDark),
        labelLarge: const TextStyle(
          color: colorTextDark,
          fontWeight: FontWeight.w500,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: colorPrimary,
          foregroundColor: Colors.white,
          textStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12.0),
          ),
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
          minimumSize: const Size(double.infinity, 56),
          elevation: 0,
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: colorPrimary,
          textStyle: const TextStyle(fontWeight: FontWeight.w500),
        ),
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        color: colorCardDark,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12.0),
          side: const BorderSide(color: colorBorderDark, width: 1),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: colorCardDark,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16.0,
          vertical: 16.0,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12.0),
          borderSide: const BorderSide(color: colorBorderDark, width: 1),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12.0),
          borderSide: const BorderSide(color: colorBorderDark, width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12.0),
          borderSide: const BorderSide(color: colorPrimary, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12.0),
          borderSide: const BorderSide(color: Color(0xFFEF4444), width: 1),
        ),
        labelStyle: const TextStyle(color: colorSubtleDark),
        hintStyle: const TextStyle(color: colorSubtleDark),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: colorSurfaceDark,
        foregroundColor: colorTextDark,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: TextStyle(
          color: colorTextDark,
          fontSize: 18,
          fontWeight: FontWeight.w600,
        ),
        iconTheme: IconThemeData(color: colorTextDark),
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: colorSurfaceDark,
        selectedItemColor: colorPrimary,
        unselectedItemColor: colorSubtleDark,
        type: BottomNavigationBarType.fixed,
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: colorPrimary,
        foregroundColor: Colors.white,
      ),
      expansionTileTheme: const ExpansionTileThemeData(
        shape: Border(),
        collapsedIconColor: colorPrimary,
        iconColor: colorPrimary,
        tilePadding: EdgeInsets.zero,
        textColor: colorTextDark,
        collapsedTextColor: colorTextDark,
      ),
      dividerTheme: const DividerThemeData(
        color: colorBorderDark,
        thickness: 1,
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: colorCardDark,
        contentTextStyle: const TextStyle(color: colorTextDark),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12.0),
        ),
        behavior: SnackBarBehavior.floating,
      ),
    );

    return MaterialApp(
      title: 'Altas AI',
      theme: darkTheme,
      darkTheme: darkTheme,
      themeMode: ThemeMode.dark,
      home: kIsWeb
          ? Scaffold(
              backgroundColor: colorBackgroundDark,
              body: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 600),
                  child: const AuthGate(),
                ),
              ),
            )
          : const AuthGate(),
      debugShowCheckedModeBanner: false,
    );
  }
}

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<AuthState>(
      stream: Supabase.instance.client.auth.onAuthStateChange,
      builder: (context, snapshot) {
        final session = snapshot.data?.session;
        if (session != null) {
          return const HomePage();
        } else {
          return const AuthScreen();
        }
      },
    );
  }
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> with WidgetsBindingObserver {
  AppState _state = AppState.ready;
  List<MenuItem> _result = [];
  String _errorMessage = '';
  XFile? _imageFile;
  Uint8List? _imageBytes;
  String _language = 'English';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _loadLanguagePreference();
  }

  Future<void> _loadLanguagePreference() async {
    final savedLanguage = await PreferencesManager.getDefaultLanguage();
    setState(() {
      _language = savedLanguage;
    });
  }

  // Generic method to get an image
  Future<void> _getImage(ImageSource source) async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: source);

    if (pickedFile != null) {
      final bytes = await pickedFile.readAsBytes();
      setState(() {
        _imageFile = pickedFile;
        _imageBytes = bytes;
      });
    }
  }

  // Method to handle taking a photo
  Future<void> _takePhoto() async {
    await _getImage(ImageSource.camera);
  }

  // Method to handle picking from gallery
  Future<void> _pickFromGallery() async {
    await _getImage(ImageSource.gallery);
  }

  // Method to remove the selected image
  void _removeImage() {
    setState(() {
      _imageFile = null;
      _imageBytes = null;
    });
  }

  // Method to handle language change
  void _handleLanguageChanged(String? newLanguage) async {
    if (newLanguage != null) {
      setState(() {
        _language = newLanguage;
      });
      // Save the preference
      await PreferencesManager.setDefaultLanguage(newLanguage);
    }
  }

  // Method to submit the form
  Future<void> _submit() async {
    if (_imageFile == null || _imageBytes == null) return;

    // Check if user can scan
    final canScan = await SubscriptionManager.canScan();
    if (!canScan) {
      setState(() {
        _errorMessage =
            'You\'ve reached your daily limit of 3 scans. Upgrade to Traveler Pass for unlimited scans!';
        _state = AppState.error;
      });
      return;
    }

    setState(() {
      _state = AppState.processing;
    });

    try {
      var request = http.MultipartRequest(
        'POST',
        Uri.parse(
          AppConfig.isConfigValid ? AppConfig.webhookUrl : DevConfig.webhookUrl,
        ),
      );

      // Add authorization header for Supabase Edge Function
      request.headers['Authorization'] =
          'Bearer ${AppConfig.isConfigValid ? AppConfig.supabaseAnonKey : DevConfig.supabaseAnonKey}';
      request.headers['apikey'] = AppConfig.isConfigValid
          ? AppConfig.supabaseAnonKey
          : DevConfig.supabaseAnonKey;

      request.fields['targetLanguage'] = _language;

      if (kIsWeb) {
        request.files.add(
          http.MultipartFile.fromBytes(
            'file',
            _imageBytes!,
            filename: _imageFile!.name,
          ),
        );
      } else {
        request.files.add(
          await http.MultipartFile.fromPath(
            'file', // Use 'file' as the key for the webhook
            _imageFile!.path,
          ),
        );
      }

      final response = await request.send();

      if (response.statusCode == 200) {
        final responseBody = await response.stream.bytesToString();
        final decodedResponse = json.decode(responseBody);

        // The direct webhook returns an 'output' key
        if (decodedResponse['output'] != null) {
          final List<dynamic> itemsJson = decodedResponse['output'];
          final items =
              itemsJson.map((item) => MenuItem.fromJson(item)).toList();

          // Sort the items to have recommended ones first
          items.sort((a, b) {
            if (a.isRecommended && !b.isRecommended) return -1;
            if (!a.isRecommended && b.isRecommended) return 1;
            return 0;
          });

          // Increment scan usage with enhanced metadata
          await SubscriptionManager.incrementScanUsage(
            targetLanguage: _language,
            webhookResponse: decodedResponse,
          );

          setState(() {
            _result = items;
            _state = AppState.result;
          });

          // Don't show upgrade prompt immediately after scan, wait for user to go back to main screen
        } else {
          setState(() {
            _errorMessage =
                decodedResponse['error'] ?? 'Failed to process image.';
            _state = AppState.error;
          });
        }
      } else {
        final errorBody = await response.stream.bytesToString();
        setState(() {
          _errorMessage =
              'Server error. Please ensure the backend is running and accessible. Details: $errorBody';
          _state = AppState.error;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage =
            'An unexpected error occurred. Please check your connection. Details: $e';
        _state = AppState.error;
      });
    }
  }

  // Method to reset the app state
  void _resetState() {
    setState(() {
      _state = AppState.ready;
      _result = [];
      _errorMessage = '';
      _imageFile = null;
      _imageBytes = null;
      // Don't reset language - keep user's preference
    });

    // Check if user has reached daily limit and show upgrade prompt when returning to main screen
    _checkAndShowUpgradePrompt();
  }

  void _goToProfile() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => ProfileScreen(
          onBack: () => Navigator.of(context).pop(),
          onUpgrade: _redirectToCheckout,
        ),
      ),
    );
  }

  Future<void> _redirectToCheckout(String priceId) async {
    // Check if user is authenticated
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Please log in to continue'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
      return;
    }

    // Show a loading indicator
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Redirecting to checkout...')),
      );
    }

    try {
      // Verify we have a valid session
      final session = Supabase.instance.client.auth.currentSession;
      if (session == null) {
        throw 'No valid session found. Please log in again.';
      }

      final response = await Supabase.instance.client.functions.invoke(
        'create-checkout-session',
        body: {'priceId': priceId},
      );

      if (response.status == 200 && response.data != null) {
        if (response.data['url'] != null) {
          final checkoutUrl = response.data['url'];

          if (await canLaunchUrl(Uri.parse(checkoutUrl))) {
            await launchUrl(Uri.parse(checkoutUrl), webOnlyWindowName: '_self');
          } else {
            throw 'Could not launch $checkoutUrl';
          }
        } else if (response.data['error'] != null) {
          throw 'Server error: ${response.data['error']}';
        } else {
          throw 'Invalid response from server: missing URL';
        }
      } else {
        final errorMessage = response.data?['error'] ?? 'Unknown server error';
        throw 'Server responded with status ${response.status}: $errorMessage';
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${error.toString()}'),
            backgroundColor: Theme.of(context).colorScheme.error,
            duration: const Duration(seconds: 5),
          ),
        );
      }
    }
  }

  // Check if user has reached daily limit and show upgrade prompt
  Future<void> _checkAndShowUpgradePrompt() async {
    final remainingScans = await SubscriptionManager.getRemainingScans();
    final hasTravelerPass = await SubscriptionManager.hasTravelerPass();

    // Only show prompt for free users who have used all their scans
    if (!hasTravelerPass && remainingScans == 0) {
      if (mounted) {
        _showUpgradeDialog();
      }
    }
  }

  void _showUpgradeDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF2A2A2A),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        content: UpgradeView(onCheckout: _redirectToCheckout),
        actionsAlignment: MainAxisAlignment.center,
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text(
              'Maybe Later',
              style: TextStyle(color: Colors.grey, fontSize: 14),
            ),
          ),
        ],
      ),
    );
  }

  // Render the appropriate view based on the state
  Widget _renderContent() {
    final user = Supabase.instance.client.auth.currentUser;

    switch (_state) {
      case AppState.ready:
        return ReadyView(
          user: user,
          onTakePhoto: _takePhoto,
          onPickFromGallery: _pickFromGallery,
          onSubmit: _submit,
          onRemoveImage: _removeImage,
          imageBytes: _imageBytes,
          language: _language,
          onLanguageChanged: _handleLanguageChanged,
          onUpgrade: () => _showUpgradeDialog(),
          onProfile: _goToProfile,
        );
      case AppState.processing:
        return const ProcessingView();
      case AppState.result:
        return ResultView(items: _result, onReset: _resetState);
      case AppState.error:
        return ErrorView(message: _errorMessage, onReset: _resetState);
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    if (state == AppLifecycleState.resumed) {
      // Refresh subscription status when app becomes active
      // This helps catch subscription changes from Stripe payments
      _refreshSubscriptionStatus();
    }
  }

  Future<void> _refreshSubscriptionStatus() async {
    // Force refresh of subscription status
    // This will be called when the app resumes, which happens after
    // returning from Stripe checkout
    setState(() {
      // Trigger a rebuild which will refresh subscription checks
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(
              maxWidth: 500,
            ), // Max width for tablet
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: _renderContent(),
            ),
          ),
        ),
      ),
      floatingActionButton: _state == AppState.result
          ? FloatingActionButton(
              onPressed: _resetState,
              tooltip: 'Scan Another Menu',
              child: const Icon(Icons.refresh),
            )
          : null,
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.fromLTRB(24.0, 16.0, 24.0, 16.0),
        child: Text(
          'Uploaded images are used only for processing and are not stored.',
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(fontSize: 10),
        ),
      ),
    );
  }
}
