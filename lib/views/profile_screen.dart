import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../services/subscription_manager.dart';

class ProfileScreen extends StatefulWidget {
  final VoidCallback onBack;

  const ProfileScreen({super.key, required this.onBack});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  bool _isLoading = false;
  final _fullNameController = TextEditingController();
  File? _avatarFile;
  Map<String, dynamic>? _subscriptionInfo;

  @override
  void initState() {
    super.initState();
    _loadUserData();
    _loadSubscriptionInfo();
  }

  void _loadUserData() {
    final user = Supabase.instance.client.auth.currentUser;
    _fullNameController.text =
        user?.userMetadata?['full_name'] ??
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
        });
      }
    } catch (error) {
      debugPrint('Error loading subscription info: $error');
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
      setState(() {
        _avatarFile = File(pickedFile.path);
        _isLoading = true;
      });

      // Automatically upload the avatar
      await _uploadAvatar();
    }
  }

  Future<void> _uploadAvatar() async {
    if (_avatarFile == null) return;

    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) {
        debugPrint('❌ No authenticated user found');
        return;
      }

      // Upload to Supabase Storage with user folder structure
      final fileName = 'avatar_${DateTime.now().millisecondsSinceEpoch}.jpg';
      final filePath = '${user.id}/$fileName';

      debugPrint('📤 Uploading avatar to: $filePath');

      // Try to upload, if file exists, use upsert option
      try {
        await Supabase.instance.client.storage
            .from('avatars')
            .upload(filePath, _avatarFile!);
      } catch (uploadError) {
        // If file exists, try to update it instead
        if (uploadError.toString().contains('already exists')) {
          debugPrint('🔄 File exists, updating instead...');
          await Supabase.instance.client.storage
              .from('avatars')
              .update(filePath, _avatarFile!);
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
          _avatarFile = null; // Clear the temporary file
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
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Subscription Management',
              style: TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            if (isActive) ...[
              const Text(
                'You have an active Traveler Pass! Manage your subscription through your device settings.',
                style: TextStyle(color: Colors.grey, fontSize: 16),
              ),
            ] else ...[
              const Text(
                'You\'re on the Free Plan with 3 scans per day.',
                style: TextStyle(color: Colors.grey, fontSize: 16),
              ),
              const SizedBox(height: 16),
              const Text(
                'Upgrade to Traveler Pass for:',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                '• Unlimited scans',
                style: TextStyle(color: Colors.grey),
              ),
              const Text(
                '• Ad-free experience',
                style: TextStyle(color: Colors.grey),
              ),
              const Text(
                '• Priority support',
                style: TextStyle(color: Colors.grey),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context);
                    // TODO: Navigate to subscription purchase screen
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(context).colorScheme.primary,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: const Text(
                    'Get Traveler Pass',
                    style: TextStyle(color: Colors.white, fontSize: 16),
                  ),
                ),
              ),
              const SizedBox(height: 8),
            ],
            SizedBox(
              width: double.infinity,
              child: TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text(
                  'Close',
                  style: TextStyle(color: Colors.grey, fontSize: 16),
                ),
              ),
            ),
          ],
        ),
      ),
    );
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
                  backgroundImage: _avatarFile != null
                      ? FileImage(_avatarFile!)
                      : (user?.userMetadata?['avatar_url'] != null
                                ? NetworkImage(
                                    user!.userMetadata!['avatar_url'],
                                  )
                                : null)
                            as ImageProvider?,
                  child: _isLoading
                      ? const CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            Colors.white,
                          ),
                        )
                      : (_avatarFile == null &&
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
    final plan = _subscriptionInfo?['plan'] ?? 'Free Plan';
    final status = _subscriptionInfo?['status'] ?? 'Active';
    final scans = _subscriptionInfo?['scans'] ?? '0/3 today';
    final isActive = _subscriptionInfo?['isActive'] ?? false;

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
                            color: Colors.green,
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
                      color: isActive ? Colors.green : Colors.grey,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    scans,
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
    return Scaffold(
      backgroundColor: const Color(0xFF1A1A1A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1A1A1A),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: widget.onBack,
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
      body: SingleChildScrollView(
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
    );
  }
}
