import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:dotted_border/dotted_border.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../services/subscription_manager.dart';

class ReadyView extends StatefulWidget {
  final VoidCallback onTakePhoto;
  final VoidCallback onPickFromGallery;
  final VoidCallback onSubmit;
  final VoidCallback onRemoveImage;
  final VoidCallback onUpgrade;
  final VoidCallback onProfile;
  final Uint8List? imageBytes;
  final String language;
  final ValueChanged<String?> onLanguageChanged;
  final User? user;

  const ReadyView({
    super.key,
    required this.onTakePhoto,
    required this.onPickFromGallery,
    required this.onSubmit,
    required this.onRemoveImage,
    required this.onUpgrade,
    required this.onProfile,
    this.imageBytes,
    required this.language,
    required this.onLanguageChanged,
    this.user,
  });

  @override
  State<ReadyView> createState() => _ReadyViewState();
}

class _ReadyViewState extends State<ReadyView> {
  int _remainingScans = 3;
  bool _hasTravelerPass = false;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadSubscriptionInfo();
  }

  Future<void> _loadSubscriptionInfo() async {
    final remaining = await SubscriptionManager.getRemainingScans();
    final hasPass = await SubscriptionManager.hasTravelerPass();

    if (mounted) {
      setState(() {
        _remainingScans = remaining;
        _hasTravelerPass = hasPass;
        _isLoading = false;
      });
    }
  }

  void _showImageSourceSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF2A2A2A),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => SafeArea(
        child: Wrap(
          children: <Widget>[
            ListTile(
              leading: const Icon(Icons.photo_camera, color: Colors.white),
              title: const Text(
                'Take a photo',
                style: TextStyle(color: Colors.white),
              ),
              onTap: () {
                widget.onTakePhoto();
                Navigator.of(context).pop();
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library, color: Colors.white),
              title: const Text(
                'Choose from gallery',
                style: TextStyle(color: Colors.white),
              ),
              onTap: () {
                widget.onPickFromGallery();
                Navigator.of(context).pop();
              },
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final languages = ['Chinese', 'English', 'Japanese', 'Korean'];
    final theme = Theme.of(context);

    return Stack(
      children: [
        SingleChildScrollView(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const SizedBox(height: 60), // Space for the profile button
              Text(
                'Altas AI',
                style: theme.textTheme.displayMedium?.copyWith(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Snap a photo of any menu to get instant translations and dish descriptions.',
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyLarge?.copyWith(
                  fontSize: 16,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 16),
              // Show remaining scans or loading indicator
              if (_isLoading)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 10.0),
                  child: SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                )
              else if (!_hasTravelerPass) ...[
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: _remainingScans > 0
                        ? Colors.green.withOpacity(0.2)
                        : Colors.red.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: _remainingScans > 0 ? Colors.green : Colors.red,
                      width: 1,
                    ),
                  ),
                  child: Text(
                    _remainingScans > 0
                        ? '$_remainingScans free scans remaining today'
                        : 'Daily limit reached - Upgrade for unlimited scans',
                    style: TextStyle(
                      color: _remainingScans > 0 ? Colors.green : Colors.red,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ] else ...[
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.blue.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.blue, width: 1),
                  ),
                  child: const Text(
                    '✨ Traveler Pass - Unlimited Scans',
                    style: TextStyle(
                      color: Colors.blue,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
              const SizedBox(height: 16),
              GestureDetector(
                onTap: () => _showImageSourceSheet(context),
                child: DottedBorder(
                  borderType: BorderType.RRect,
                  radius: const Radius.circular(12),
                  padding: const EdgeInsets.all(6),
                  dashPattern: const [8, 4],
                  strokeWidth: 2,
                  color: theme.colorScheme.outline,
                  child: Container(
                    height: 200,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: widget.imageBytes != null
                        ? Stack(
                            alignment: Alignment.center,
                            children: [
                              ClipRRect(
                                borderRadius: BorderRadius.circular(12),
                                child: Image.memory(
                                  widget.imageBytes!,
                                  fit: BoxFit.cover,
                                  width: double.infinity,
                                  height: double.infinity,
                                ),
                              ),
                              Positioned(
                                top: 8,
                                right: 8,
                                child: Container(
                                  decoration: BoxDecoration(
                                    color: Colors.black.withValues(alpha: 0.7),
                                    shape: BoxShape.circle,
                                  ),
                                  child: IconButton(
                                    icon: const Icon(
                                      Icons.close,
                                      color: Colors.white,
                                      size: 20,
                                    ),
                                    onPressed: widget.onRemoveImage,
                                  ),
                                ),
                              ),
                            ],
                          )
                        : Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.camera_alt,
                                size: 48,
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Take a photo or upload',
                                style: TextStyle(
                                  color: theme.colorScheme.onSurfaceVariant,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'PNG, JPG, or HEIC (MAX. 10MB)',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: theme.colorScheme.onSurfaceVariant
                                      .withValues(alpha: 0.7),
                                ),
                              ),
                            ],
                          ),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: widget.imageBytes != null ? widget.onSubmit : null,
                child: const Text(
                  'Decode Menu',
                  style: TextStyle(fontSize: 18),
                ),
              ),

              const SizedBox(height: 8),
              _AdvancedOptionsWidget(
                language: widget.language,
                onLanguageChanged: widget.onLanguageChanged,
                theme: theme,
                languages: languages,
              ),
            ],
          ),
        ),
        // Profile button positioned at top right
        if (widget.user != null)
          Positioned(
            top: 0,
            right: 0,
            child: Container(
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainerHighest,
                shape: BoxShape.circle,
              ),
              child: IconButton(
                icon: const Icon(Icons.person),
                onPressed: widget.onProfile,
                color: theme.colorScheme.onSurface,
              ),
            ),
          ),
      ],
    );
  }
}

class _AdvancedOptionsWidget extends StatefulWidget {
  final String language;
  final ValueChanged<String?> onLanguageChanged;
  final ThemeData theme;
  final List<String> languages;

  const _AdvancedOptionsWidget({
    required this.language,
    required this.onLanguageChanged,
    required this.theme,
    required this.languages,
  });

  @override
  State<_AdvancedOptionsWidget> createState() => _AdvancedOptionsWidgetState();
}

class _AdvancedOptionsWidgetState extends State<_AdvancedOptionsWidget>
    with SingleTickerProviderStateMixin {
  bool _isExpanded = false;
  late AnimationController _animationController;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    _animation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _toggleExpansion() {
    setState(() {
      _isExpanded = !_isExpanded;
      if (_isExpanded) {
        _animationController.forward();
      } else {
        _animationController.reverse();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        GestureDetector(
          onTap: _toggleExpansion,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Advanced Options',
                style: TextStyle(
                  fontSize: 14,
                  color: widget.theme.colorScheme.onSurfaceVariant,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(width: 8),
              AnimatedRotation(
                turns: _isExpanded ? 0.5 : 0,
                duration: const Duration(milliseconds: 200),
                child: Icon(
                  Icons.keyboard_arrow_down,
                  color: widget.theme.colorScheme.onSurfaceVariant,
                  size: 20,
                ),
              ),
            ],
          ),
        ),
        SizeTransition(
          sizeFactor: _animation,
          child: Padding(
            padding: const EdgeInsets.only(top: 12),
            child: DropdownButtonFormField<String>(
              initialValue: widget.language,
              decoration: InputDecoration(
                labelText: 'Translate to',
                labelStyle: TextStyle(
                  color: widget.theme.colorScheme.onSurfaceVariant,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              dropdownColor: widget.theme.colorScheme.surfaceContainerHighest,
              style: TextStyle(color: widget.theme.colorScheme.onSurface),
              items: widget.languages.map((String value) {
                return DropdownMenuItem<String>(
                  value: value,
                  child: Text(
                    value,
                    style: TextStyle(color: widget.theme.colorScheme.onSurface),
                  ),
                );
              }).toList(),
              onChanged: widget.onLanguageChanged,
            ),
          ),
        ),
      ],
    );
  }
}
