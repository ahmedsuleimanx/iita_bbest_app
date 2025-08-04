import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:animate_do/animate_do.dart';

import '../../../core/theme/app_theme.dart';
import '../../../providers/auth_provider.dart';
import '../../widgets/common/custom_button.dart';
import '../../widgets/common/custom_text_field.dart';
import '../../widgets/common/loading_overlay.dart';

class EditProfileScreen extends ConsumerStatefulWidget {
  const EditProfileScreen({super.key});

  @override
  ConsumerState<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends ConsumerState<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _addressController = TextEditingController();
  
  File? _imageFile;
  final _picker = ImagePicker();
  bool _isLoading = false;
  String? _currentProfileImage;
  List<String> _addresses = [];
  
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
    _addressController.dispose();
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
      _addresses = List<String>.from(user.addresses);
    }
  }
  
  Future<void> _pickImage(ImageSource source) async {
    try {
      final pickedFile = await _picker.pickImage(source: source);
      if (pickedFile != null) {
        setState(() {
          _imageFile = File(pickedFile.path);
        });
      }
    } catch (e) {
      _showErrorSnackBar('Error picking image: $e');
    }
  }

  void _removeImage() {
    setState(() {
      _imageFile = null;
      _currentProfileImage = null;
    });
  }
  
  Future<String?> _uploadImage() async {
    if (_imageFile == null) return _currentProfileImage;
    
    try {
      final user = ref.read(currentUserProvider);
      if (user == null) return null;
      
      final storageRef = FirebaseStorage.instance
          .ref()
          .child('user_profile_images')
          .child('${user.id}.jpg');
      
      final uploadTask = storageRef.putFile(_imageFile!);
      final snapshot = await uploadTask.whenComplete(() {});
      final downloadUrl = await snapshot.ref.getDownloadURL();
      
      return downloadUrl;
    } catch (e) {
      _showErrorSnackBar('Error uploading image: $e');
      return null;
    }
  }
  
  void _showErrorSnackBar(String message) {
    if (!mounted) return;
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppTheme.errorColor,
      ),
    );
  }
  
  void _showSuccessSnackBar(String message) {
    if (!mounted) return;
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppTheme.successColor,
      ),
    );
  }

  void _addAddress() {
    if (_addressController.text.trim().isEmpty) return;
    
    setState(() {
      _addresses.add(_addressController.text.trim());
      _addressController.clear();
    });
  }
  
  void _removeAddress(int index) {
    setState(() {
      _addresses.removeAt(index);
    });
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
        profileImageUrl: profileImageUrl ?? _currentProfileImage,
        addresses: _addresses,
      );
      
      if (mounted) {
        _showSuccessSnackBar('Profile updated successfully');
        context.pop(); // Go back to profile screen
      }
    } catch (e) {
      if (mounted) {
        _showErrorSnackBar('Error updating profile: $e');
      }
    } finally {
      if (mounted) {
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
        title: const Text('Edit Profile'),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.check),
            onPressed: _updateProfile,
            tooltip: 'Save Changes',
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
                      CircleAvatar(
                        radius: 60,
                        backgroundColor: Colors.grey.shade200,
                        backgroundImage: _imageFile != null
                            ? FileImage(_imageFile!) as ImageProvider
                            : user.profileImageUrl != null
                                ? NetworkImage(user.profileImageUrl!)
                                : null,
                        child: user.profileImageUrl == null && _imageFile == null
                            ? const Icon(
                                Icons.person,
                                size: 60,
                                color: Colors.grey,
                              )
                            : null,
                      ),
                      Positioned(
                        bottom: 0,
                        right: 0,
                        child: Container(
                          decoration: const BoxDecoration(
                            color: AppTheme.primaryColor,
                            shape: BoxShape.circle,
                          ),
                          padding: const EdgeInsets.all(8),
                          child: PopupMenuButton<String>(
                            icon: const Icon(
                              Icons.more_vert,
                              color: Colors.white,
                              size: 20,
                            ),
                            itemBuilder: (context) => [
                              const PopupMenuItem<String>(
                                value: 'camera',
                                child: Row(
                                  children: [
                                    Icon(Icons.camera_alt),
                                    SizedBox(width: 8),
                                    Text('Take Photo'),
                                  ],
                                ),
                              ),
                              const PopupMenuItem<String>(
                                value: 'gallery',
                                child: Row(
                                  children: [
                                    Icon(Icons.photo_library),
                                    SizedBox(width: 8),
                                    Text('Choose from Gallery'),
                                  ],
                                ),
                              ),
                              if (user.profileImageUrl != null || _imageFile != null)
                                const PopupMenuItem<String>(
                                  value: 'remove',
                                  child: Row(
                                    children: [
                                      Icon(Icons.delete, color: Colors.red),
                                      SizedBox(width: 8),
                                      Text('Remove Photo', style: TextStyle(color: Colors.red)),
                                    ],
                                  ),
                                ),
                            ],
                            onSelected: (value) {
                              switch (value) {
                                case 'camera':
                                  _pickImage(ImageSource.camera);
                                  break;
                                case 'gallery':
                                  _pickImage(ImageSource.gallery);
                                  break;
                                case 'remove':
                                  _removeImage();
                                  break;
                              }
                            },
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              
              const SizedBox(height: 32),
              
              // Edit Profile Form
              FadeInUp(
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        'Personal Information',
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
                      const SizedBox(height: 16),
                      
                      // Email (disabled, for display only)
                      CustomTextField(
                        controller: TextEditingController(text: user.email),
                        label: 'Email',
                        prefixIcon: Icons.email_outlined,
                        isReadOnly: true,
                        isEnabled: false,
                        helperText: 'Email cannot be changed',
                      ),
                      const SizedBox(height: 24),
                      
                      // Addresses Section
                      Text(
                        'Delivery Addresses',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),
                      
                      // Current Addresses List
                      if (_addresses.isNotEmpty) ..._buildAddressList(),
                      
                      // Add New Address
                      Row(
                        children: [
                          Expanded(
                            child: CustomTextField(
                              controller: _addressController,
                              label: 'New Address',
                              hintText: 'Enter delivery address',
                              prefixIcon: Icons.location_on_outlined,
                            ),
                          ),
                          const SizedBox(width: 8),
                          IconButton(
                            onPressed: _addAddress,
                            icon: const Icon(Icons.add_circle),
                            color: AppTheme.primaryColor,
                            tooltip: 'Add Address',
                          ),
                        ],
                      ),
                      
                      const SizedBox(height: 32),
                      
                      // Save Button
                      CustomButton(
                        text: 'Save Changes',
                        onPressed: _updateProfile,
                        icon: Icons.save,
                      ),
                      const SizedBox(height: 16),
                      
                      // Cancel Button
                      CustomButton(
                        text: 'Cancel',
                        onPressed: () => context.pop(),
                        type: ButtonType.outline,
                        icon: Icons.cancel,
                      ),
                    ],
                  ),
                ),
              ),
              
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }
  
  List<Widget> _buildAddressList() {
    return [
      ...List.generate(_addresses.length, (index) {
        return Card(
          margin: const EdgeInsets.only(bottom: 8),
          child: ListTile(
            leading: const Icon(Icons.location_on),
            title: Text(_addresses[index]),
            trailing: IconButton(
              icon: const Icon(Icons.delete, color: Colors.red),
              onPressed: () => _removeAddress(index),
              tooltip: 'Remove Address',
            ),
          ),
        );
      }),
      const SizedBox(height: 16),
    ];
  }
}