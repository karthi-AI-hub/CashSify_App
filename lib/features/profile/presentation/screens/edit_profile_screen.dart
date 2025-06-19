import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter/services.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import '../../../../theme/app_colors.dart';
import '../../../../theme/app_spacing.dart';
import '../../../../theme/app_text_styles.dart';
import '../../../../core/widgets/form/custom_button.dart';
import '../../../../core/widgets/form/custom_text_field.dart';
import 'package:cashsify_app/core/providers/loading_provider.dart';
import 'package:cashsify_app/core/widgets/layout/loading_overlay.dart';
import 'package:cashsify_app/core/providers/user_provider.dart';
import 'package:cashsify_app/core/models/user_state.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cashsify_app/core/services/supabase_service.dart';
import 'dart:io';

class EditProfileScreen extends ConsumerStatefulWidget {
  const EditProfileScreen({super.key});

  @override
  ConsumerState<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends ConsumerState<EditProfileScreen> with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _upiController = TextEditingController();
  final _bankAccountController = TextEditingController();
  final _ifscController = TextEditingController();
  final _accountHolderController = TextEditingController();
  String _selectedGender = 'Male';
  DateTime? _selectedDate;
  String? _phoneNumber;
  String? _email;
  String? _profileImageUrl;
  final _dateFormat = DateFormat('dd MMM yyyy');
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  bool _isSaving = false;
  bool _hasChanged = false;
  XFile? _pickedImage;
  bool _isDisposed = false;

  @override
  void initState() {
    super.initState();
    _initializeData();
    _initializeAnimations();
  }

  void _initializeData() {
    final user = ref.read(userProvider).asData?.value;
    if (user != null) {
      _nameController.text = user.name ?? '';
      _upiController.text = user.upiId ?? '';
      _phoneNumber = user.phoneNumber;
      _email = user.email;
      _profileImageUrl = user.profileImageUrl;
      _selectedGender = user.gender ?? 'Male';
      _selectedDate = user.dob;
      final bank = user.bankAccount ?? {};
      _bankAccountController.text = bank['account_no'] ?? '';
      _ifscController.text = bank['ifsc'] ?? '';
      _accountHolderController.text = bank['name'] ?? '';
    }
  }

  void _initializeAnimations() {
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeOut,
      ),
    );
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.1),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeOut,
      ),
    );
    _animationController.forward();
  }

  @override
  void dispose() {
    _isDisposed = true;
    _nameController.dispose();
    _upiController.dispose();
    _bankAccountController.dispose();
    _ifscController.dispose();
    _accountHolderController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  String? _validateName(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please enter your full name';
    }
    return null;
  }

  String? _validateEmail(String? value) {
    if (value != null && value.isNotEmpty) {
      final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
      if (!emailRegex.hasMatch(value)) {
        return 'Please enter a valid email address';
      }
    }
    return null;
  }

  String? _validateBankAccount(String? value) {
    if (value != null && value.isNotEmpty) {
      if (value.length < 6) {
        return 'Invalid Bank account number';
      }
    }
    return null;
  }

  String? _validateIFSC(String? value) {
    if (value != null && value.isNotEmpty) {
      if (value.length < 6) {
        return 'Invalid Bank code';
      }
    }
    return null;
  }

  String? _validateUPI(String? value) {
    if (value != null && value.isNotEmpty) {
      final upiRegex = RegExp(r'^[\w.-]+@[\w.-]+$');
      if (!upiRegex.hasMatch(value)) {
        return 'Please enter a valid UPI ID';
      }
    }
    return null;
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? DateTime(2000),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: AppColors.primary,
              onPrimary: Colors.white,
              surface: Colors.white,
              onSurface: Colors.black,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  void _onFieldChanged() {
    setState(() {
      _hasChanged = true;
    });
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 80,
      maxWidth: 800,
      maxHeight: 800,
    );
    if (picked != null) {
      setState(() {
        _pickedImage = picked;
        _hasChanged = true;
      });
    }
  }

  Future<String?> _uploadProfileImage(XFile image) async {
    final userService = ref.read(userServiceProvider);
    final userId = ref.read(userProvider).asData?.value?.id;
    if (userId == null) return null;

    final file = File(image.path);
    return await userService.uploadProfileImage(file, userId);
  }

  Widget _buildAnimatedSection(Widget child, {int delay = 0}) {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: SlideTransition(
        position: _slideAnimation,
        child: child,
      ),
    );
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;

    if (_isDisposed) return;
    setState(() => _isSaving = true);
    String? uploadedUrl;

    try {
      // Show loading state
      ref.read(loadingProvider.notifier).state = LoadingState.loading;

      if (_pickedImage != null) {
        uploadedUrl = await _uploadProfileImage(_pickedImage!);
        if (uploadedUrl == null) {
          if (!mounted || _isDisposed) return;
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Failed to upload profile image')),
          );
          return;
        }
      }

      if (_hasChanged) {
        // Update profile
        await ref.read(userProvider.notifier).updateProfile(
          name: _nameController.text.trim(),
          gender: _selectedGender,
          dob: _selectedDate,
          upiId: _upiController.text.trim().isEmpty ? null : _upiController.text.trim(),
          bankAccount: (_bankAccountController.text.trim().isEmpty &&
                        _ifscController.text.trim().isEmpty &&
                        _accountHolderController.text.trim().isEmpty)
              ? null
              : {
                  'account_no': _bankAccountController.text.trim().isEmpty ? null : _bankAccountController.text.trim(),
                  'ifsc': _ifscController.text.trim().isEmpty ? null : _ifscController.text.trim(),
                  'name': _accountHolderController.text.trim().isEmpty ? null : _accountHolderController.text.trim(),
                },
          profileImageUrl: uploadedUrl ?? _profileImageUrl,
        );

        // Force refresh user data immediately
        await ref.read(userProvider.notifier).refreshUser();
      }

      if (!mounted || _isDisposed) return;
      
      // Show success message
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Profile updated successfully!')),
      );

      // Pop back to profile screen with result
      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted || _isDisposed) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error updating profile: ${e.toString()}')),
      );
    } finally {
      if (!_isDisposed) {
        setState(() => _isSaving = false);
        ref.read(loadingProvider.notifier).state = LoadingState.initial;
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final loadingState = ref.watch(loadingProvider);
    final userNotifier = ref.read(userProvider.notifier);

    return LoadingOverlay(
      isLoading: loadingState == LoadingState.loading || _isSaving,
      message: (loadingState == LoadingState.loading || _isSaving) ? 'Saving profile...' : null,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Edit Profile'),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => context.pop(),
          ),
          elevation: 0,
          backgroundColor: Colors.transparent,
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Profile Picture Section
                _buildAnimatedSection(
                  Center(
                    child: Stack(
                      children: [
                        Hero(
                          tag: 'profile_picture',
                          child: Container(
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: colorScheme.primary.withOpacity(0.2),
                                  blurRadius: 10,
                                  spreadRadius: 2,
                                ),
                              ],
                            ),
                            child: CircleAvatar(
                              radius: 48,
                              backgroundColor: colorScheme.primary,
                              backgroundImage: _pickedImage != null
                                  ? FileImage(File(_pickedImage!.path)) as ImageProvider<Object>
                                  : (_profileImageUrl != null && _profileImageUrl!.isNotEmpty
                                      ? NetworkImage(_profileImageUrl!) as ImageProvider<Object>
                                      : null),
                              child: (_pickedImage == null && (_profileImageUrl == null || _profileImageUrl!.isEmpty))
                                  ? Text(
                                      (_nameController.text.isNotEmpty) ? _nameController.text[0].toUpperCase() : 'U',
                                      style: textTheme.headlineLarge?.copyWith(
                                        color: colorScheme.onPrimary,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    )
                                  : null,
                            ),
                          ),
                        ),
                        Positioned(
                          right: 0,
                          bottom: 0,
                          child: Material(
                            color: colorScheme.primary,
                            borderRadius: BorderRadius.circular(20),
                            child: InkWell(
                              borderRadius: BorderRadius.circular(20),
                              onTap: _pickImage,
                              child: Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: colorScheme.primary,
                                  shape: BoxShape.circle,
                                  boxShadow: [
                                    BoxShadow(
                                      color: colorScheme.primary.withOpacity(0.3),
                                      blurRadius: 8,
                                      offset: const Offset(0, 2),
                                    ),
                                  ],
                                ),
                                child: Icon(
                                  Icons.camera_alt,
                                  size: 20,
                                  color: colorScheme.onPrimary,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.xl),

                // Account Information Section
                _buildAnimatedSection(
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.person_outline,
                            color: colorScheme.primary,
                            size: 24,
                          ),
                          const SizedBox(width: AppSpacing.sm),
                          Text(
                            'Account Information',
                            style: textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: colorScheme.onSurface,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.md),
                      CustomTextField(
                        controller: _nameController,
                        label: 'Full Name',
                        prefix: Icon(
                          Icons.person_outline,
                          color: colorScheme.primary,
                        ),
                        error: _nameController.text.isEmpty ? 'Name is required' : _validateName(_nameController.text),
                        onChanged: (_) => _onFieldChanged(),
                        validator: _validateName,
                      ),
                      const SizedBox(height: AppSpacing.md),
                      // Email (read-only)
                      CustomTextField(
                        controller: TextEditingController(text: _email ?? ''),
                        label: 'Email Address',
                        prefix: Icon(
                          Icons.email_outlined,
                          color: colorScheme.primary,
                        ),
                        enabled: false,
                        filled: true,
                        fillColor: colorScheme.surfaceVariant.withOpacity(0.5),
                        validator: (value) {
                          if ((_email ?? '').isEmpty) {
                            return 'Email is required';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: AppSpacing.md),
                      // Phone (read-only)
                      CustomTextField(
                        enabled: false,
                        label: 'Mobile Number',
                        prefix: Icon(
                          Icons.phone_android,
                          color: colorScheme.primary,
                        ),
                        controller: TextEditingController(text: _phoneNumber ?? ''),
                        hint: 'Primary identity - cannot be changed',
                        filled: true,
                        fillColor: colorScheme.surfaceVariant.withOpacity(0.5),
                        validator: (value) {
                          if ((_phoneNumber ?? '').isEmpty) {
                            return 'Mobile number is required';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: AppSpacing.md),
                      DropdownButtonFormField<String>(
                        value: _selectedGender,
                        decoration: InputDecoration(
                          labelText: 'Gender',
                          prefixIcon: Icon(
                            Icons.person_outline,
                            color: colorScheme.primary,
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        items: ['Male', 'Female', 'Other']
                            .map((gender) => DropdownMenuItem(
                                  value: gender,
                                  child: Text(gender),
                                ))
                            .toList(),
                        onChanged: (value) {
                          if (value != null) {
                            setState(() {
                              _selectedGender = value;
                              _hasChanged = true;
                            });
                          }
                        },
                      ),
                      const SizedBox(height: AppSpacing.md),
                      InkWell(
                        onTap: () async {
                          await _selectDate(context);
                          _onFieldChanged();
                        },
                        child: InputDecorator(
                          decoration: InputDecoration(
                            labelText: 'Date of Birth',
                            prefixIcon: Icon(
                              Icons.calendar_today,
                              color: colorScheme.primary,
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: Text(
                            _selectedDate != null
                                ? _dateFormat.format(_selectedDate!)
                                : 'Select Date',
                            style: textTheme.bodyLarge,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.xl),

                // Payment Details Section
                _buildAnimatedSection(
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.payment_outlined,
                            color: colorScheme.primary,
                            size: 24,
                          ),
                          const SizedBox(width: AppSpacing.sm),
                          Text(
                            'Payment Details',
                            style: textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: colorScheme.onSurface,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.md),
                      CustomTextField(
                        controller: _bankAccountController,
                        label: 'Bank Account Number',
                        prefix: Icon(
                          Icons.account_balance,
                          color: colorScheme.primary,
                        ),
                        keyboardType: TextInputType.number,
                        error: _validateBankAccount(_bankAccountController.text),
                        onChanged: (_) => _onFieldChanged(),
                        validator: _validateBankAccount,
                      ),
                      const SizedBox(height: AppSpacing.md),
                      CustomTextField(
                        controller: _accountHolderController,
                        label: 'Account Holder Name',
                        prefix: Icon(
                          Icons.account_box,
                          color: colorScheme.primary,
                        ),
                        onChanged: (_) => _onFieldChanged(),
                        validator: (value) => null,
                      ),
                      const SizedBox(height: AppSpacing.md),
                      CustomTextField(
                        controller: _ifscController,
                        label: 'IFSC Code',
                        prefix: Icon(
                          Icons.code,
                          color: colorScheme.primary,
                        ),
                        inputFormatters: [
                          TextInputFormatter.withFunction((oldValue, newValue) {
                            return TextEditingValue(
                              text: newValue.text.toUpperCase(),
                              selection: newValue.selection,
                            );
                          }),
                          FilteringTextInputFormatter.allow(RegExp(r'[A-Z0-9]')),
                        ],
                        error: _validateIFSC(_ifscController.text),
                        onChanged: (_) => _onFieldChanged(),
                        validator: _validateIFSC,
                      ),
                      const SizedBox(height: AppSpacing.md),
                      CustomTextField(
                        controller: _upiController,
                        label: 'UPI ID',
                        prefix: Icon(
                          Icons.payment,
                          color: colorScheme.primary,
                        ),
                        error: _validateUPI(_upiController.text),
                        onChanged: (_) => _onFieldChanged(),
                        validator: _validateUPI,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.xl),

                // Save Changes Button
                _buildAnimatedSection(
                  CustomButton(
                    onPressed: !_hasChanged || _isSaving
                        ? null
                        : _saveProfile,
                    text: _isSaving ? 'Saving...' : 'Save Changes',
                    isFullWidth: true,
                    isLoading: _isSaving,
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),
              ],
            ),
          ),
        ),
      ),
    );
  }
} 