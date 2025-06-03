import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter/services.dart';
import '../../../../theme/app_colors.dart';
import '../../../../theme/app_spacing.dart';
import '../../../../theme/app_text_styles.dart';
import '../../../../core/widgets/form/custom_button.dart';
import '../../../../core/widgets/form/custom_text_field.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _mobileController = TextEditingController(text: '+91 80722 23275');
  final _bankAccountController = TextEditingController();
  final _ifscController = TextEditingController();
  final _upiController = TextEditingController();
  String _selectedGender = 'Male';
  DateTime? _selectedDate;
  final _dateFormat = DateFormat('dd MMM yyyy');
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    // Initialize with current values
    _nameController.text = 'KS'; // Replace with actual user data
    _emailController.text = 'ks@email.com'; // Replace with actual user data
    _bankAccountController.text = 'XXXXXX1234'; // Replace with actual user data
    _ifscController.text = 'SBIN0001234'; // Replace with actual user data
    _upiController.text = 'ks@upi'; // Replace with actual user data

    // Initialize animations
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
    _nameController.dispose();
    _emailController.dispose();
    _mobileController.dispose();
    _bankAccountController.dispose();
    _ifscController.dispose();
    _upiController.dispose();
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
    if (value == null || value.isEmpty) {
      return 'Please enter your bank account number';
    }
    if (value.length < 9 || value.length > 18) {
      return 'Please enter a valid bank account number';
    }
    return null;
  }

  String? _validateIFSC(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please enter your IFSC code';
    }
    final ifscRegex = RegExp(r'^[A-Z]{4}0[A-Z0-9]{6}$');
    if (!ifscRegex.hasMatch(value)) {
      return 'Please enter a valid IFSC code';
    }
    return null;
  }

  String? _validateUPI(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please enter your UPI ID';
    }
    final upiRegex = RegExp(r'^[\w.-]+@[\w.-]+$');
    if (!upiRegex.hasMatch(value)) {
      return 'Please enter a valid UPI ID';
    }
    return null;
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? DateTime.now(),
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

  Widget _buildAnimatedSection(Widget child, {int delay = 0}) {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: SlideTransition(
        position: _slideAnimation,
        child: child,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
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
                            radius: 50,
                            backgroundColor: colorScheme.primaryContainer,
                            child: Text(
                              _nameController.text.isNotEmpty ? _nameController.text[0].toUpperCase() : 'K',
                              style: textTheme.headlineLarge?.copyWith(
                                color: colorScheme.onPrimaryContainer,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
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
                            onTap: () {
                              // TODO: Implement image picker
                            },
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
                      error: _validateName(_nameController.text),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    CustomTextField(
                      controller: _emailController,
                      label: 'Email Address',
                      prefix: Icon(
                        Icons.email_outlined,
                        color: colorScheme.primary,
                      ),
                      keyboardType: TextInputType.emailAddress,
                      error: _validateEmail(_emailController.text),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    CustomTextField(
                      enabled: false,
                      label: 'Mobile Number',
                      prefix: Icon(
                        Icons.phone_android,
                        color: colorScheme.primary,
                      ),
                      controller: _mobileController,
                      hint: 'Primary identity - cannot be changed',
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
                          });
                        }
                      },
                    ),
                    const SizedBox(height: AppSpacing.md),
                    InkWell(
                      onTap: () => _selectDate(context),
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
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.xl),

              // Save Changes Button
              _buildAnimatedSection(
                CustomButton(
                  onPressed: () {
                    if (_formKey.currentState!.validate()) {
                      final nameError = _validateName(_nameController.text);
                      final emailError = _validateEmail(_emailController.text);
                      final bankError = _validateBankAccount(_bankAccountController.text);
                      final ifscError = _validateIFSC(_ifscController.text);
                      final upiError = _validateUPI(_upiController.text);

                      if (nameError == null &&
                          emailError == null &&
                          bankError == null &&
                          ifscError == null &&
                          upiError == null) {
                        // TODO: Implement save changes logic
                        context.pop();
                      }
                    }
                  },
                  text: 'Save Changes',
                  isFullWidth: true,
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
            ],
          ),
        ),
      ),
    );
  }
} 