import 'package:altas_ai/views/upgrade_view.dart';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../services/subscription_manager.dart';
import '../services/preferences_manager.dart';

class ProfileScreen extends StatefulWidget {
  final VoidCallback onBack;
  final Future<void> Function(String priceId) onUpgrade;

  const ProfileScreen({
    super.key,
    required this.onBack,
    required this.onUpgrade,
  });

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  bool _isLoading = false;
  bool _isLoadingSubscription = true;
  bool _isProcessingSubscription = false;
  final _fullNameController = TextEditingController();
  Uint8List? _avatarBytes;
  Map<String, dynamic>? _subscriptionInfo;
  String _defaultLanguage = 'English';

  @override
  void initState() {
    super.initState();
    _loadUserData();
    _loadSubscriptionInfo();
    _fetchAppConfig();
    _loadLanguagePreference();
  }

  Future<void> _loadLanguagePreference() async {
    final language = await PreferencesManager.getDefaultLanguage();
    if (mounted) {
      setState(() {
        _defaultLanguage = language;
      });
    }
  }

  Future<void> _fetchAppConfig() async {
    await SubscriptionManager.fetchFreeDailyLimit();
  }

  void _loadUserData() {
    final user = Supabase.instance.client.auth.currentUser;
    _fullNameController.text = user?.userMetadata?['full_name'] ??
        user?.userMetadata?['name'] ??
        user?.email?.split('@')[0] ??
        'User';
  }

  Future<void> _loadSubscriptionInfo() async {
    try {
      final info = await SubscriptionManager.getSubscriptionInfo();
      if (mounted) {
        setState(() {
          _subscriptionInfo = info;
          _isLoadingSubscription = false;
        });
      }
    } catch (error) {
      debugPrint('Error loading subscription info: $error');
      if (mounted) {
        setState(() {
          _isLoadingSubscription = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _fullNameController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      final bytes = await pickedFile.readAsBytes();
      setState(() {
        _avatarBytes = bytes;
        _isLoading = true;
      });

      // Automatically upload the avatar
      await _uploadAvatar(pickedFile);
    }
  }

  Future<void> _uploadAvatar(XFile pickedFile) async {
    if (_avatarBytes == null) return;

    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) {
        debugPrint('❌ No authenticated user found');
        return;
      }

      // Upload to Supabase Storage with user folder structure
      final fileExt = pickedFile.path.split('.').last;
      final fileName =
          'avatar_${DateTime.now().millisecondsSinceEpoch}.$fileExt';
      final filePath = '${user.id}/$fileName';

      debugPrint('📤 Uploading avatar to: $filePath');

      // Try to upload, if file exists, use upsert option
      try {
        await Supabase.instance.client.storage
            .from('avatars')
            .uploadBinary(filePath, _avatarBytes!);
      } catch (uploadError) {
        // If file exists, try to update it instead
        if (uploadError.toString().contains('already exists')) {
          debugPrint('🔄 File exists, updating instead...');
          await Supabase.instance.client.storage
              .from('avatars')
              .updateBinary(filePath, _avatarBytes!);
        } else {
          rethrow; // Re-throw if it's a different error
        }
      }

      final avatarUrl = Supabase.instance.client.storage
          .from('avatars')
          .getPublicUrl(filePath);

      debugPrint('✅ Avatar uploaded successfully: $avatarUrl');

      // Update user metadata
      debugPrint('📝 Updating user metadata with avatar URL');
      await Supabase.instance.client.auth.updateUser(
        UserAttributes(data: {'avatar_url': avatarUrl}),
      );

      // Also update the profiles table
      debugPrint('📝 Updating profiles table');
      await Supabase.instance.client.from('profiles').upsert({
        'id': user.id,
        'avatar_url': avatarUrl,
        'updated_at': DateTime.now().toIso8601String(),
      });

      debugPrint('✅ Avatar upload completed successfully');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Avatar updated successfully!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (error) {
      debugPrint('❌ Avatar upload failed: $error');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to update avatar: ${error.toString()}'),
            backgroundColor: Theme.of(context).colorScheme.error,
            duration: const Duration(seconds: 5),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _avatarBytes = null; // Clear the temporary bytes
        });
      }
    }
  }

  Future<void> _showEditNameDialog() async {
    final nameController = TextEditingController(
      text: _fullNameController.text,
    );

    final result = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF2A2A2A),
        title: const Text('Edit Name', style: TextStyle(color: Colors.white)),
        content: TextField(
          controller: nameController,
          autofocus: true,
          style: const TextStyle(color: Colors.white),
          decoration: InputDecoration(
            hintText: 'Enter your name',
            hintStyle: const TextStyle(color: Colors.grey),
            enabledBorder: UnderlineInputBorder(
              borderSide: BorderSide(
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
            focusedBorder: UnderlineInputBorder(
              borderSide: BorderSide(
                color: Theme.of(context).colorScheme.primary,
                width: 2,
              ),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(nameController.text),
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.primary,
            ),
            child: const Text('Save', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (result != null && result.isNotEmpty) {
      setState(() {
        _fullNameController.text = result;
      });
      await _updateProfileName(result);
    }
  }

  Future<void> _updateProfileName(String newName) async {
    setState(() {
      _isLoading = true;
    });

    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) return;

      // Update user metadata
      await Supabase.instance.client.auth.updateUser(
        UserAttributes(data: {'full_name': newName}),
      );

      // Also update the profiles table
      await Supabase.instance.client.from('profiles').upsert({
        'id': user.id,
        'full_name': newName,
        'updated_at': DateTime.now().toIso8601String(),
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Name updated successfully!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Failed to update name. Please try again.'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _signOut() async {
    setState(() {
      _isLoading = true;
    });
    try {
      await Supabase.instance.client.auth.signOut();
      // Navigation will be handled automatically by AuthGate
      // But we can pop all routes to ensure clean navigation
      if (mounted) {
        Navigator.of(context).popUntil((route) => route.isFirst);
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Failed to sign out. Please try again.'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _showSubscriptionManagement() {
    final isActive = _subscriptionInfo?['isActive'] ?? false;

    if (isActive) {
      // Show subscription details and cancellation option for Traveler Pass users
      _showTravelerPassManagement();
    } else {
      // Show upgrade options for free users
      showModalBottomSheet(
        context: context,
        backgroundColor: const Color(0xFF1A1A1A),
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        builder: (context) => Container(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              UpgradeView(onCheckout: widget.onUpgrade),
              const SizedBox(height: 8),
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text(
                  'Maybe Later',
                  style: TextStyle(color: Colors.grey, fontSize: 14),
                ),
              ),
            ],
          ),
        ),
      );
    }
  }

  void _showTravelerPassManagement() {
    final plan = _subscriptionInfo?['plan'] ?? 'Traveler Pass';
    final planDuration = _subscriptionInfo?['planDuration'] ?? 'monthly';
    final endDate = _subscriptionInfo?['endDate'];
    final isCancelling = _subscriptionInfo?['isCancelling'] ?? false;

    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1A1A1A),
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => SingleChildScrollView(
        child: Container(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: isCancelling
                          ? Colors.orange.withValues(alpha: 0.2)
                          : Colors.green.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      isCancelling ? Icons.schedule : Icons.check_circle,
                      color: isCancelling ? Colors.orange : Colors.green,
                      size: 32,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          plan,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          planDuration == 'yearly'
                              ? 'Annual Plan'
                              : 'Monthly Plan',
                          style: const TextStyle(
                            color: Colors.grey,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              if (isCancelling) ...[
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.orange.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: Colors.orange.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.info_outline,
                          color: Colors.orange, size: 20),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Subscription will end on ${endDate != null ? _formatDate(endDate) : 'billing date'}',
                          style: const TextStyle(
                            color: Colors.orange,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 24),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFF2A2A2A),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  children: [
                    _buildBenefitRow(Icons.camera_alt, 'Unlimited scans'),
                    const SizedBox(height: 12),
                    _buildBenefitRow(Icons.language, 'All languages'),
                    const SizedBox(height: 12),
                    _buildBenefitRow(Icons.support_agent, 'Priority support'),
                    if (endDate != null) ...[
                      const SizedBox(height: 16),
                      const Divider(color: Colors.grey),
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            isCancelling ? 'Access until:' : 'Renews on:',
                            style: const TextStyle(
                                color: Colors.grey, fontSize: 14),
                          ),
                          Text(
                            _formatDate(endDate),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 24),
              if (isCancelling)
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.of(context).pop();
                      _showResumeConfirmation();
                    },
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      backgroundColor: Colors.green,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text(
                      'Resume Subscription',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                )
              else
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(
                    onPressed: () {
                      Navigator.of(context).pop();
                      _showCancelConfirmation();
                    },
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      side: const BorderSide(color: Colors.red),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text(
                      'Cancel Subscription',
                      style: TextStyle(
                        color: Colors.red,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text(
                    'Close',
                    style: TextStyle(color: Colors.grey, fontSize: 14),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBenefitRow(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, color: Colors.green, size: 20),
        const SizedBox(width: 12),
        Text(
          text,
          style: const TextStyle(color: Colors.white, fontSize: 14),
        ),
      ],
    );
  }

  String _formatDate(String dateStr) {
    try {
      final date = DateTime.parse(dateStr);
      final months = [
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
        'Dec'
      ];
      return '${months[date.month - 1]} ${date.day}, ${date.year}';
    } catch (e) {
      return dateStr;
    }
  }

  Future<void> _showCancelConfirmation() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF2A2A2A),
        title: const Text(
          'Cancel Subscription?',
          style: TextStyle(color: Colors.white),
        ),
        content: const Text(
          'Are you sure you want to cancel your Traveler Pass? You will lose access to unlimited scans at the end of your current billing period.',
          style: TextStyle(color: Colors.grey),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text(
              'Keep Subscription',
              style: TextStyle(color: Colors.white),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(
              foregroundColor: Colors.red,
            ),
            child: const Text('Cancel Subscription'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await _cancelSubscription();
    }
  }

  Future<void> _cancelSubscription() async {
    setState(() {
      _isProcessingSubscription = true;
    });

    try {
      final success = await SubscriptionManager.cancelSubscription();

      if (mounted) {
        if (success) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                  'Subscription cancelled successfully. You will have access until the end of your billing period.'),
              backgroundColor: Colors.green,
              duration: Duration(seconds: 4),
            ),
          );
          // Reload subscription info
          await _loadSubscriptionInfo();
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text(
                  'Failed to cancel subscription. Please try again or contact support.'),
              backgroundColor: Theme.of(context).colorScheme.error,
              duration: const Duration(seconds: 4),
            ),
          );
        }
      }
    } catch (error) {
      debugPrint('Error cancelling subscription: $error');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${error.toString()}'),
            backgroundColor: Theme.of(context).colorScheme.error,
            duration: const Duration(seconds: 4),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isProcessingSubscription = false;
        });
      }
    }
  }

  Future<void> _showResumeConfirmation() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF2A2A2A),
        title: const Text(
          'Resume Subscription?',
          style: TextStyle(color: Colors.white),
        ),
        content: const Text(
          'Your subscription will continue and you will be charged at the next billing cycle. You will keep unlimited access to all features.',
          style: TextStyle(color: Colors.grey),
        ),
        actionsAlignment: MainAxisAlignment.center,
        actionsPadding: const EdgeInsets.only(bottom: 16, left: 24, right: 24),
        actions: [
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.of(context).pop(true),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: const Text(
                    'Confirm',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text(
                  'Cancel',
                  style: TextStyle(color: Colors.grey, fontSize: 14),
                ),
              ),
            ],
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await _resumeSubscription();
    }
  }

  Future<void> _resumeSubscription() async {
    setState(() {
      _isProcessingSubscription = true;
    });

    try {
      final success = await SubscriptionManager.resumeSubscription();

      if (mounted) {
        if (success) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                  'Subscription resumed successfully! Your subscription will continue as normal.'),
              backgroundColor: Colors.green,
              duration: Duration(seconds: 4),
            ),
          );
          // Reload subscription info
          await _loadSubscriptionInfo();
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text(
                  'Failed to resume subscription. Please try again or contact support.'),
              backgroundColor: Theme.of(context).colorScheme.error,
              duration: const Duration(seconds: 4),
            ),
          );
        }
      }
    } catch (error) {
      debugPrint('Error resuming subscription: $error');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${error.toString()}'),
            backgroundColor: Theme.of(context).colorScheme.error,
            duration: const Duration(seconds: 4),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isProcessingSubscription = false;
        });
      }
    }
  }

  Widget _buildUserInfoCard() {
    final user = Supabase.instance.client.auth.currentUser;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF2A2A2A),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.withValues(alpha: 0.3), width: 1),
      ),
      child: Row(
        children: [
          GestureDetector(
            onTap: _isLoading ? null : _pickImage,
            child: Stack(
              children: [
                CircleAvatar(
                  radius: 30,
                  backgroundColor: const Color(0xFF4A90E2),
                  backgroundImage: _avatarBytes != null
                      ? MemoryImage(_avatarBytes!)
                      : (user?.userMetadata?['avatar_url'] != null
                          ? NetworkImage(
                              user!.userMetadata!['avatar_url'],
                            )
                          : null) as ImageProvider?,
                  child: _isLoading
                      ? const CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            Colors.white,
                          ),
                        )
                      : (_avatarBytes == null &&
                              user?.userMetadata?['avatar_url'] == null
                          ? const Icon(
                              Icons.person,
                              size: 30,
                              color: Colors.white,
                            )
                          : null),
                ),
                if (!_isLoading)
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.primary,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 2),
                      ),
                      child: const Icon(
                        Icons.camera_alt,
                        size: 12,
                        color: Colors.white,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                GestureDetector(
                  onTap: _showEditNameDialog,
                  child: Text(
                    _fullNameController.text.isEmpty
                        ? 'Tap to add name'
                        : _fullNameController.text,
                    style: TextStyle(
                      color: _fullNameController.text.isEmpty
                          ? Colors.grey
                          : Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  user?.email ?? 'No email',
                  style: const TextStyle(color: Colors.grey, fontSize: 14),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: _showEditNameDialog,
            icon: const Icon(Icons.edit, size: 18),
            style: IconButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.primary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.all(8),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSubscriptionCard() {
    if (_isLoadingSubscription) {
      return Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: const Color(0xFF2A2A2A),
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    height: 18,
                    width: 120,
                    child: LinearProgressIndicator(
                      backgroundColor: Color(0xFF3A3A3A),
                      valueColor:
                          AlwaysStoppedAnimation<Color>(Color(0xFF4A4A4A)),
                    ),
                  ),
                  SizedBox(height: 8),
                  SizedBox(
                    height: 14,
                    width: 80,
                    child: LinearProgressIndicator(
                      backgroundColor: Color(0xFF3A3A3A),
                      valueColor:
                          AlwaysStoppedAnimation<Color>(Color(0xFF4A4A4A)),
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(Colors.grey),
              ),
            ),
          ],
        ),
      );
    }

    final plan = _subscriptionInfo?['plan'] ?? 'Free Plan';
    final status = _subscriptionInfo?['status'] ?? 'Active';
    final scans = _subscriptionInfo?['scans'] ?? '0/3 today';
    final isActive = _subscriptionInfo?['isActive'] ?? false;
    final isCancelling = _subscriptionInfo?['isCancelling'] ?? false;
    final endDate = _subscriptionInfo?['endDate'];

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF2A2A2A),
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: _showSubscriptionManagement,
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        plan,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      if (isActive) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: isCancelling ? Colors.orange : Colors.green,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Text(
                            'PRO',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    status,
                    style: TextStyle(
                      color: isCancelling
                          ? Colors.orange
                          : (isActive ? Colors.green : Colors.grey),
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    isCancelling && endDate != null
                        ? 'Until ${_formatDate(endDate)}'
                        : scans,
                    style: const TextStyle(color: Colors.grey, fontSize: 12),
                  ),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_ios, color: Colors.grey, size: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildLanguagePreferenceCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF2A2A2A),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.withValues(alpha: 0.3), width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.language,
                color: Theme.of(context).colorScheme.primary,
                size: 20,
              ),
              const SizedBox(width: 12),
              const Text(
                'Default Translation Language',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Text(
            'This language will be used by default when translating menus',
            style: TextStyle(
              color: Colors.grey,
              fontSize: 13,
            ),
          ),
          const SizedBox(height: 16),
          DropdownButtonFormField<String>(
            value: _defaultLanguage,
            decoration: InputDecoration(
              filled: true,
              fillColor: const Color(0xFF1A1A1A),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16.0,
                vertical: 12.0,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12.0),
                borderSide: BorderSide(
                  color: Colors.grey.withValues(alpha: 0.3),
                  width: 1,
                ),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12.0),
                borderSide: BorderSide(
                  color: Colors.grey.withValues(alpha: 0.3),
                  width: 1,
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12.0),
                borderSide: BorderSide(
                  color: Theme.of(context).colorScheme.primary,
                  width: 2,
                ),
              ),
            ),
            dropdownColor: const Color(0xFF2A2A2A),
            style: const TextStyle(color: Colors.white),
            items: PreferencesManager.availableLanguages.map((String value) {
              return DropdownMenuItem<String>(
                value: value,
                child: Text(value),
              );
            }).toList(),
            onChanged: (String? newValue) async {
              if (newValue != null) {
                setState(() {
                  _defaultLanguage = newValue;
                });
                await PreferencesManager.setDefaultLanguage(newValue);
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Default language set to $newValue'),
                      backgroundColor: Colors.green,
                      duration: const Duration(seconds: 2),
                    ),
                  );
                }
              }
            },
          ),
        ],
      ),
    );
  }

  Widget _buildLogOutButton() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF1E3A8A),
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: _isLoading ? null : _signOut,
        child: Row(
          children: [
            const Expanded(
              child: Text(
                'Log Out',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            if (_isLoading)
              const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              )
            else
              const Icon(Icons.logout, color: Colors.white, size: 20),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Scaffold(
          backgroundColor: const Color(0xFF1A1A1A),
          appBar: AppBar(
            backgroundColor: const Color(0xFF1A1A1A),
            elevation: 0,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.white),
              onPressed: _isLoading || _isProcessingSubscription
                  ? null
                  : widget.onBack,
            ),
            title: const Text(
              'Profile & Settings',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
            centerTitle: true,
          ),
          body: AbsorbPointer(
            absorbing: _isLoading || _isProcessingSubscription,
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'User Info',
                    style: TextStyle(
                      color: Colors.grey,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 12),
                  _buildUserInfoCard(),
                  const SizedBox(height: 32),
                  const Text(
                    'Subscription Management',
                    style: TextStyle(
                      color: Colors.grey,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 12),
                  _buildSubscriptionCard(),
                  const SizedBox(height: 32),
                  const Text(
                    'Preferences',
                    style: TextStyle(
                      color: Colors.grey,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 12),
                  _buildLanguagePreferenceCard(),
                  const SizedBox(height: 32),
                  const Text(
                    'Account Actions',
                    style: TextStyle(
                      color: Colors.grey,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 12),
                  _buildLogOutButton(),
                ],
              ),
            ),
          ),
        ),
        if (_isLoading)
          Container(
            color: Colors.black.withValues(alpha: 0.7),
            child: const Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                  SizedBox(height: 16),
                  Text(
                    'Processing...',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ),
        if (_isProcessingSubscription)
          Container(
            color: Colors.black.withValues(alpha: 0.7),
            child: const Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                  SizedBox(height: 16),
                  Text(
                    'Updating subscription...',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      decoration: TextDecoration.none,
                    ),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}
