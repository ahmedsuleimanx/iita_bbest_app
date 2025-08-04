import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:animate_do/animate_do.dart';

import '../../../core/theme/app_theme.dart';
import '../../../services/local_image_service.dart';
import '../../../providers/auth_provider.dart';
import '../../widgets/common/adaptive_image.dart';
import '../../widgets/common/custom_button.dart';
import '../../widgets/common/custom_text_field.dart';
import '../../widgets/common/loading_overlay.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _phoneController = TextEditingController();
  
  File? _imageFile;
  final _picker = ImagePicker();
  bool _isLoading = false;
  bool _isEditing = false;
  String? _currentProfileImage;
  
  @override
  void initState() {
    super.initState();
    _loadUserData();
  }
  
  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _phoneController.dispose();
    super.dispose();
  }
  
  void _loadUserData() {
    final user = ref.read(currentUserProvider);
    if (user != null) {
      _firstNameController.text = user.firstName;
      _lastNameController.text = user.lastName;
      if (user.phoneNumber != null && user.phoneNumber!.isNotEmpty) {
        _phoneController.text = user.phoneNumber!;
      }
      if (user.profileImageUrl != null && user.profileImageUrl!.isNotEmpty) {
        _currentProfileImage = user.profileImageUrl;
      }
    }
  }
  
  Future<void> _pickImage() async {
    try {
      final pickedFile = await _picker.pickImage(source: ImageSource.gallery);
      if (pickedFile != null) {
        setState(() {
          _imageFile = File(pickedFile.path);
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error picking image: $e'),
            backgroundColor: AppTheme.errorColor,
          ),
        );
      }
    }
  }
  
  Future<String?> _uploadImage() async {
    if (_imageFile == null) return _currentProfileImage;
    
    try {
      final user = ref.read(currentUserProvider);
      if (user == null) return null;
      
      // Upload image to local storage
      final imagePath = await LocalImageService.uploadImage(
        imageFile: _imageFile!,
        uploadType: UploadType.user,
        customFileName: '${user.id}_profile.jpg',
      );
      
      return imagePath;
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error uploading image: $e'),
            backgroundColor: AppTheme.errorColor,
          ),
        );
      }
      return null;
    }
  }
  
  Future<void> _updateProfile() async {
    if (!_formKey.currentState!.validate()) return;
    
    setState(() => _isLoading = true);
    
    try {
      // Upload image if selected
      String? profileImageUrl;
      if (_imageFile != null) {
        profileImageUrl = await _uploadImage();
        if (profileImageUrl == null && _currentProfileImage == null) {
          throw Exception('Failed to upload profile image');
        }
      }
      
      // Update user profile
      await ref.read(authProvider.notifier).updateProfile(
        firstName: _firstNameController.text.trim(),
        lastName: _lastNameController.text.trim(),
        phoneNumber: _phoneController.text.trim(),
        profileImageUrl: profileImageUrl,
      );
      
      if (mounted) {
        setState(() {
          _isEditing = false;
          _imageFile = null;
        });
        
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Profile updated successfully'),
            backgroundColor: AppTheme.successColor,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error updating profile: $e'),
            backgroundColor: AppTheme.errorColor,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }
  
  Future<void> _handleSignOut() async {
    setState(() => _isLoading = true);
    
    try {
      await ref.read(authProvider.notifier).signOut();
      if (mounted) {
        context.go('/auth/login');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error signing out: $e'),
            backgroundColor: AppTheme.errorColor,
          ),
        );
        setState(() => _isLoading = false);
      }
    }
  }
  
  @override
  Widget build(BuildContext context) {
    final user = ref.watch(currentUserProvider);
    
    if (user == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Profile'),
        elevation: 0,
        actions: [
          if (!_isEditing)
            IconButton(
              icon: const Icon(Icons.edit),
              onPressed: () => setState(() => _isEditing = true),
              tooltip: 'Edit Profile',
            )
          else
            IconButton(
              icon: const Icon(Icons.close),
              onPressed: () => setState(() {
                _isEditing = false;
                _loadUserData(); // Reset form data
                _imageFile = null;
              }),
              tooltip: 'Cancel',
            ),
        ],
      ),
      body: LoadingOverlay(
        isLoading: _isLoading,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: 16),
              
              // Profile Image
              FadeInDown(
                child: Center(
                  child: Stack(
                    children: [
                      Container(
                        width: 120,
                        height: 120,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.grey.shade200,
                        ),
                        child: ClipOval(
                          child: _imageFile != null
                              ? Image.file(
                                  _imageFile!,
                                  width: 120,
                                  height: 120,
                                  fit: BoxFit.cover,
                                )
                              : user.profileImageUrl != null && user.profileImageUrl!.isNotEmpty
                                  ? AdaptiveImage(
                                      imagePath: user.profileImageUrl!,
                                      width: 120,
                                      height: 120,
                                      fit: BoxFit.cover,
                                      errorWidget: Icon(
                                        Icons.person,
                                        size: 60,
                                        color: Colors.grey.shade400,
                                      ),
                                    )
                                  : Icon(
                                      Icons.person,
                                      size: 60,
                                      color: Colors.grey.shade400,
                                    ),
                        ),
                      ),
                      if (_isEditing)
                        Positioned(
                          bottom: 0,
                          right: 0,
                          child: Container(
                            decoration: const BoxDecoration(
                              color: AppTheme.primaryColor,
                              shape: BoxShape.circle,
                            ),
                            padding: const EdgeInsets.all(8),
                            child: InkWell(
                              onTap: _pickImage,
                              child: const Icon(
                                Icons.camera_alt,
                                color: Colors.white,
                                size: 20,
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
              
              const SizedBox(height: 24),
              
              // User Name
              if (!_isEditing) ...[  
                FadeInUp(
                  delay: const Duration(milliseconds: 200),
                  child: Text(
                    user.fullName,
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                
                const SizedBox(height: 8),
                
                // User Email
                FadeInUp(
                  delay: const Duration(milliseconds: 250),
                  child: Text(
                    user.email,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: AppTheme.textSecondary,
                    ),
                  ),
                ),
                
                const SizedBox(height: 32),
                
                // User Info Card
                FadeInUp(
                  delay: const Duration(milliseconds: 300),
                  child: Card(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    elevation: 2,
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildInfoRow(Icons.phone, 'Phone', 
                            user.phoneNumber?.isNotEmpty == true 
                              ? user.phoneNumber! 
                              : 'Not provided'),
                          const Divider(height: 24),
                          _buildInfoRow(Icons.calendar_today, 'Member Since', 
                            _formatDate(user.createdAt)),
                          if (user.isAdmin) ... [
                            const Divider(height: 24),
                            _buildInfoRow(Icons.admin_panel_settings, 'Role', 'Administrator'),
                          ],
                        ],
                      ),
                    ),
                  ),
                ),
                
                const SizedBox(height: 32),
                
                // Actions
                FadeInUp(
                  delay: const Duration(milliseconds: 400),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _buildActionButton(
                        'My Orders',
                        Icons.shopping_bag_outlined,
                        () => context.go('/orders'),
                      ),
                      const SizedBox(height: 12),
                      _buildActionButton(
                        'My Addresses',
                        Icons.location_on_outlined,
                        () {/* TODO: Navigate to addresses screen */},
                      ),
                      const SizedBox(height: 12),
                      _buildActionButton(
                        'Settings',
                        Icons.settings_outlined,
                        () {/* TODO: Navigate to settings screen */},
                      ),
                      const SizedBox(height: 12),
                      _buildActionButton(
                        'Help & Support',
                        Icons.help_outline,
                        () {/* TODO: Navigate to help screen */},
                      ),
                      const SizedBox(height: 24),
                      CustomButton(
                        text: 'Sign Out',
                        onPressed: _handleSignOut,
                        type: ButtonType.outline,
                        icon: Icons.logout,
                      ),
                    ],
                  ),
                ),
              ] else ... [
                // Edit Profile Form
                FadeInUp(
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text(
                          'Edit Profile',
                          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 24),
                        
                        // First Name
                        CustomTextField(
                          controller: _firstNameController,
                          label: 'First Name',
                          hintText: 'Enter first name',
                          prefixIcon: Icons.person_outline,
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'First name is required';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),
                        
                        // Last Name
                        CustomTextField(
                          controller: _lastNameController,
                          label: 'Last Name',
                          hintText: 'Enter last name',
                          prefixIcon: Icons.person_outline,
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Last name is required';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),
                        
                        // Phone Number
                        CustomTextField(
                          controller: _phoneController,
                          label: 'Phone Number',
                          hintText: 'Enter phone number',
                          prefixIcon: Icons.phone_outlined,
                          keyboardType: TextInputType.phone,
                        ),
                        const SizedBox(height: 32),
                        
                        // Save Button
                        CustomButton(
                          text: 'Save Changes',
                          onPressed: _updateProfile,
                          isLoading: _isLoading,
                          icon: Icons.save,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
              
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
  
  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppTheme.primaryColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              icon,
              color: AppTheme.primaryColor,
              size: 20,
            ),
          ),
          const SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  fontSize: 12,
                  color: AppTheme.textSecondary,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
  
  Widget _buildActionButton(String title, IconData icon, VoidCallback onTap) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Ink(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
          decoration: BoxDecoration(
            color: Colors.grey.shade50,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.grey.shade200),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppTheme.primaryColor.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  icon,
                  color: AppTheme.primaryColor,
                  size: 20,
                ),
              ),
              const SizedBox(width: 16),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const Spacer(),
              const Icon(
                Icons.arrow_forward_ios,
                color: AppTheme.textSecondary,
                size: 16,
              ),
            ],
          ),
        ),
      ),
    );
  }
  
  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
} 