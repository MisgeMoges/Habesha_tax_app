import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:habesha_tax_app/features/auth/views/auth_screen.dart';
import 'package:image_picker/image_picker.dart';
// import 'dart:io';
// import '../bloc/auth_bloc.dart';
// import '../bloc/auth_state.dart';
// import '../bloc/auth_event.dart';
// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:habesha_tax_app/core/services/cloudinary_service.dart';

// class ProfileScreen extends StatefulWidget {
//   const ProfileScreen({super.key});

//   @override
//   State<ProfileScreen> createState() => _ProfileScreenState();
// }

// class _ProfileScreenState extends State<ProfileScreen> {
//   final _formKey = GlobalKey<FormState>();
//   final _firstNameController = TextEditingController();
//   final _lastNameController = TextEditingController();
//   final _middleNameController = TextEditingController();
//   final _emailController = TextEditingController();
//   final _christeningNameController = TextEditingController();
//   final _spiritualFatherNameController = TextEditingController();
//   String _selectedCategory = 'Member';
//   String _selectedMaritalStatus = 'Single';
//   String _selectedGender = 'Male';
//   String _selectedMembershipType = 'Partial';
//   File? _profileImage;
//   bool _isEditing = false;
//   final _dateOfBirthController = TextEditingController();
//   final _nationalityController = TextEditingController();
//   final _addressController = TextEditingController();
//   final _postcodeController = TextEditingController();
//   final _mobileNumberController = TextEditingController();
//   final _emergencyContactNameController = TextEditingController();
//   final _emergencyContactRelationController = TextEditingController();
//   final _emergencyContactPhoneController = TextEditingController();
//   final _membershipApplicationSignatureController = TextEditingController();
//   bool _membershipCommitmentConfirmed = false;
//   bool _consentContactChurch = false;
//   bool _consentDataUse = false;
//   DateTime? _membershipApplicationDate;
//   DateTime? _applicationReceivedDate;

//   final List<String> _memberCategories = [
//     'Clergy',
//     'Member',
//     'Priest',
//     'Deacon',
//     'Sunday Students Member',
//     'Elder',
//     'Youth',
//     'Children',
//   ];

//   final List<String> _maritalStatusOptions = [
//     'Single',
//     'Married',
//     'Divorced',
//     'Widowed',
//   ];

//   final List<String> _genderOptions = ['Male', 'Female'];

//   final List<String> _membershipTypes = ['Full Member', 'Associate Member'];

//   // Add a static list of nationalities (shortened for brevity)
//   final List<String> _nationalities = [
//     'Ethiopian',
//     'Eritrean',
//     'American',
//     'British',
//     'Canadian',
//     'Australian',
//     'German',
//     'French',
//     'Italian',
//     'Kenyan',
//     'Nigerian',
//     'South African',
//     'Indian',
//     'Chinese',
//     'Japanese',
//     'Other',
//   ];
//   String? _selectedNationality;

//   @override
//   void initState() {
//     super.initState();
//     _loadUserData();
//   }

//   void _loadUserData() {
//     final authState = context.read<AuthBloc>().state;
//     if (authState is Authenticated) {
//       _firstNameController.text = authState.user.firstName;
//       _lastNameController.text = authState.user.lastName;
//       _middleNameController.text = authState.user.middleName ?? '';
//       _emailController.text = authState.user.email;
//       _christeningNameController.text = authState.user.christeningName ?? '';
//       _spiritualFatherNameController.text =
//           authState.user.spiritualFatherName ?? '';
//       _selectedCategory = authState.user.memberCategory;
//       _selectedMaritalStatus = authState.user.maritalStatus ?? 'Single';
//       _selectedGender = authState.user.gender ?? 'Male';
//       // Map old membershipType values to new dropdown options
//       final oldType = authState.user.membershipType ?? '';
//       if (oldType == 'Full') {
//         _selectedMembershipType = 'Full Member';
//       } else if (oldType == 'Partial') {
//         _selectedMembershipType = 'Associate Member';
//       } else if (['Full Member', 'Associate Member'].contains(oldType)) {
//         _selectedMembershipType = oldType;
//       } else {
//         _selectedMembershipType = 'Full Member'; // fallback
//       }
//       _dateOfBirthController.text = authState.user.dateOfBirth ?? '';
//       _nationalityController.text = authState.user.nationality ?? '';
//       // Map legacy/variant nationality values to dropdown options
//       final loadedNationality = _nationalityController.text;
//       if (_nationalities.contains(loadedNationality)) {
//         _selectedNationality = loadedNationality;
//       } else if (loadedNationality == 'Ethiopia' &&
//           _nationalities.contains('Ethiopian')) {
//         _selectedNationality = 'Ethiopian';
//         _nationalityController.text = 'Ethiopian';
//       } else {
//         _selectedNationality = _nationalities.first;
//         _nationalityController.text = _nationalities.first;
//       }
//       _addressController.text = authState.user.address ?? '';
//       _postcodeController.text = authState.user.postcode ?? '';
//       _mobileNumberController.text = authState.user.mobileNumber ?? '';
//       _emergencyContactNameController.text =
//           authState.user.emergencyContactName ?? '';
//       _emergencyContactRelationController.text =
//           authState.user.emergencyContactRelation ?? '';
//       _emergencyContactPhoneController.text =
//           authState.user.emergencyContactPhone ?? '';
//       _membershipCommitmentConfirmed =
//           authState.user.membershipCommitmentConfirmed ?? false;
//       _consentContactChurch = authState.user.consentContactChurch ?? false;
//       _consentDataUse = authState.user.consentDataUse ?? false;
//       _membershipApplicationSignatureController.text =
//           authState.user.membershipApplicationSignature ?? '';
//       _membershipApplicationDate = authState.user.membershipApplicationDate
//           ?.toDate();
//       _applicationReceivedDate = authState.user.applicationReceivedDate
//           ?.toDate();
//     }
//   }

//   Future<void> _pickImage() async {
//     try {
//       print('Starting image picker...');
//       final ImagePicker picker = ImagePicker();
//       final XFile? image = await picker.pickImage(
//         source: ImageSource.gallery,
//         maxWidth: 512,
//         maxHeight: 512,
//         imageQuality: 80,
//       );

//       if (image != null) {
//         print('Image selected: ${image.path}');
//         print('Image size: ${await File(image.path).length()} bytes');

//         setState(() {
//           _profileImage = File(image.path);
//         });

//         ScaffoldMessenger.of(context).showSnackBar(
//           const SnackBar(
//             content: Text('Image selected successfully!'),
//             backgroundColor: Colors.green,
//           ),
//         );
//       } else {
//         print('No image selected');
//       }
//     } catch (e) {
//       print('Error picking image: $e');
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(
//           content: Text('Failed to pick image: $e'),
//           backgroundColor: Colors.red,
//         ),
//       );
//     }
//   }

//   void _toggleEdit() {
//     setState(() {
//       _isEditing = !_isEditing;
//       if (!_isEditing) {
//         _loadUserData(); // Reset data if canceling edit
//       }
//     });
//   }

//   void _saveChanges() async {
//     if (!_formKey.currentState!.validate()) {
//       print('Form validation failed');
//       return;
//     }

//     print('Starting profile update...');
//     print('Profile image selected:  ${_profileImage != null}');
//     String? uploadedImageUrl;
//     if (_profileImage != null) {
//       print('Profile image path: ${_profileImage!.path}');
//       print('Profile image exists: ${_profileImage!.existsSync()}');
//       // Upload the image to Cloudinary and get the URL
//       uploadedImageUrl = await CloudinaryService.uploadImage(
//         _profileImage!,
//         folder: 'church_app',
//       );
//       print('Uploaded image URL: $uploadedImageUrl');
//     }

//     context.read<AuthBloc>().add(
//       UpdateProfileRequested(
//         firstName: _firstNameController.text.trim(),
//         lastName: _lastNameController.text.trim(),
//         middleName: _middleNameController.text.trim(),
//         memberCategory: _selectedCategory,
//         maritalStatus: _selectedMaritalStatus,
//         gender: _selectedGender,
//         membershipType: _selectedMembershipType,
//         christeningName: _christeningNameController.text.trim(),
//         spiritualFatherName: _spiritualFatherNameController.text.trim(),
//         profileImage:
//             null, // No need to pass the File, URL is handled in profilePicture
//         dateOfBirth: _dateOfBirthController.text.trim(),
//         nationality: _nationalityController.text.trim(),
//         address: _addressController.text.trim(),
//         postcode: _postcodeController.text.trim(),
//         mobileNumber: _mobileNumberController.text.trim(),
//         emergencyContactName: _emergencyContactNameController.text.trim(),
//         emergencyContactRelation: _emergencyContactRelationController.text
//             .trim(),
//         emergencyContactPhone: _emergencyContactPhoneController.text.trim(),
//         membershipCommitmentConfirmed: _membershipCommitmentConfirmed,
//         consentContactChurch: _consentContactChurch,
//         consentDataUse: _consentDataUse,
//         membershipApplicationSignature:
//             _membershipApplicationSignatureController.text.trim(),
//         membershipApplicationDate: _membershipApplicationDate != null
//             ? Timestamp.fromDate(_membershipApplicationDate!)
//             : null,
//         applicationReceivedDate: _applicationReceivedDate != null
//             ? Timestamp.fromDate(_applicationReceivedDate!)
//             : null,
//       ),
//     );

//     setState(() {
//       _isEditing = false;
//     });
//   }

//   @override
//   void dispose() {
//     _firstNameController.dispose();
//     _lastNameController.dispose();
//     _middleNameController.dispose();
//     _emailController.dispose();
//     _christeningNameController.dispose();
//     _spiritualFatherNameController.dispose();
//     _dateOfBirthController.dispose();
//     _nationalityController.dispose();
//     _addressController.dispose();
//     _postcodeController.dispose();
//     _mobileNumberController.dispose();
//     _emergencyContactNameController.dispose();
//     _emergencyContactRelationController.dispose();
//     _emergencyContactPhoneController.dispose();
//     _membershipApplicationSignatureController.dispose();
//     super.dispose();
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: const Text('Profile'),
//         actions: [
//           IconButton(
//             icon: Icon(_isEditing ? Icons.close : Icons.edit),
//             onPressed: _toggleEdit,
//           ),
//           if (_isEditing)
//             IconButton(icon: const Icon(Icons.check), onPressed: _saveChanges),
//         ],
//       ),
//       body: BlocListener<AuthBloc, AuthState>(
//         listener: (context, state) {
//           if (state is AuthLoading) {
//             ScaffoldMessenger.of(context).showSnackBar(
//               const SnackBar(content: Text('Updating profile...')),
//             );
//           } else if (state is AuthError) {
//             ScaffoldMessenger.of(context).showSnackBar(
//               SnackBar(
//                 content: Text(state.message),
//                 backgroundColor: Colors.red,
//               ),
//             );
//           } else if (state is Authenticated) {
//             ScaffoldMessenger.of(context).showSnackBar(
//               const SnackBar(content: Text('Profile updated successfully')),
//             );
//           }
//         },
//         child: BlocBuilder<AuthBloc, AuthState>(
//           builder: (context, state) {
//             if (state is AuthLoading) {
//               return const Center(child: CircularProgressIndicator());
//             }
//             if (state is! Authenticated) {
//               return const Center(child: Text('Not authenticated'));
//             }

//             return SingleChildScrollView(
//               padding: const EdgeInsets.all(16),
//               child: Form(
//                 key: _formKey,
//                 child: Column(
//                   crossAxisAlignment: CrossAxisAlignment.center,
//                   children: [
//                     GestureDetector(
//                       onTap: _isEditing ? _pickImage : null,
//                       child: Stack(
//                         children: [
//                           CircleAvatar(
//                             radius: 50,
//                             backgroundImage: _profileImage != null
//                                 ? FileImage(_profileImage!)
//                                 : (state.user.profilePicture?.isNotEmpty ??
//                                       false)
//                                 ? NetworkImage(state.user.profilePicture!)
//                                       as ImageProvider
//                                 : const AssetImage('assets/images/logo1.png'),
//                           ),
//                           if (_isEditing)
//                             Positioned(
//                               bottom: 0,
//                               right: 0,
//                               child: Container(
//                                 padding: const EdgeInsets.all(4),
//                                 decoration: const BoxDecoration(
//                                   color: Colors.deepPurple,
//                                   shape: BoxShape.circle,
//                                 ),
//                                 child: const Icon(
//                                   Icons.camera_alt,
//                                   color: Colors.white,
//                                   size: 20,
//                                 ),
//                               ),
//                             ),
//                         ],
//                       ),
//                     ),
//                     const SizedBox(height: 24),
//                     TextFormField(
//                       controller: _firstNameController,
//                       decoration: const InputDecoration(
//                         labelText: 'First Name',
//                         border: OutlineInputBorder(),
//                       ),
//                       enabled: _isEditing,
//                       validator: (value) {
//                         if (value == null || value.isEmpty) {
//                           return 'Please enter your first name';
//                         }
//                         return null;
//                       },
//                     ),
//                     const SizedBox(height: 16),
//                     TextFormField(
//                       controller: _lastNameController,
//                       decoration: const InputDecoration(
//                         labelText: 'Last Name',
//                         border: OutlineInputBorder(),
//                       ),
//                       enabled: _isEditing,
//                       validator: (value) {
//                         if (value == null || value.isEmpty) {
//                           return 'Please enter your last name';
//                         }
//                         return null;
//                       },
//                     ),
//                     const SizedBox(height: 16),
//                     TextFormField(
//                       controller: _middleNameController,
//                       decoration: const InputDecoration(
//                         labelText: 'Middle Name (Optional)',
//                         border: OutlineInputBorder(),
//                       ),
//                       enabled: _isEditing,
//                     ),
//                     const SizedBox(height: 16),
//                     TextFormField(
//                       controller: _spiritualFatherNameController,
//                       decoration: const InputDecoration(
//                         labelText: 'Spiritual Father Name',
//                         border: OutlineInputBorder(),
//                       ),
//                       enabled: _isEditing,
//                     ),
//                     const SizedBox(height: 16),
//                     TextFormField(
//                       controller: _christeningNameController,
//                       decoration: const InputDecoration(
//                         labelText: 'Christening Name',
//                         border: OutlineInputBorder(),
//                       ),
//                       enabled: _isEditing,
//                     ),
//                     const SizedBox(height: 16),
//                     TextFormField(
//                       controller: _emailController,
//                       decoration: const InputDecoration(
//                         labelText: 'Email',
//                         border: OutlineInputBorder(),
//                       ),
//                       enabled: false, // Email cannot be changed
//                     ),
//                     const SizedBox(height: 16),
//                     DropdownButtonFormField<String>(
//                       value: _selectedCategory,
//                       decoration: const InputDecoration(
//                         labelText: 'Member Category',
//                         border: OutlineInputBorder(),
//                       ),
//                       items: _memberCategories
//                           .map(
//                             (category) => DropdownMenuItem(
//                               value: category,
//                               child: Text(category),
//                             ),
//                           )
//                           .toList(),
//                       onChanged: _isEditing
//                           ? (value) {
//                               if (value != null) {
//                                 setState(() => _selectedCategory = value);
//                               }
//                             }
//                           : null,
//                     ),
//                     const SizedBox(height: 16),
//                     DropdownButtonFormField<String>(
//                       value: _selectedMaritalStatus,
//                       decoration: const InputDecoration(
//                         labelText: 'Marital Status',
//                         border: OutlineInputBorder(),
//                       ),
//                       items: _maritalStatusOptions
//                           .map(
//                             (status) => DropdownMenuItem(
//                               value: status,
//                               child: Text(status),
//                             ),
//                           )
//                           .toList(),
//                       onChanged: _isEditing
//                           ? (value) {
//                               if (value != null) {
//                                 setState(() => _selectedMaritalStatus = value);
//                               }
//                             }
//                           : null,
//                     ),
//                     const SizedBox(height: 16),
//                     DropdownButtonFormField<String>(
//                       value: _selectedGender,
//                       decoration: const InputDecoration(
//                         labelText: 'Gender',
//                         border: OutlineInputBorder(),
//                       ),
//                       items: _genderOptions
//                           .map(
//                             (gender) => DropdownMenuItem(
//                               value: gender,
//                               child: Text(gender),
//                             ),
//                           )
//                           .toList(),
//                       onChanged: _isEditing
//                           ? (value) {
//                               if (value != null) {
//                                 setState(() => _selectedGender = value);
//                               }
//                             }
//                           : null,
//                     ),
//                     const SizedBox(height: 16),
//                     DropdownButtonFormField<String>(
//                       value: _selectedMembershipType,
//                       decoration: const InputDecoration(
//                         labelText: 'Membership Type',
//                         border: OutlineInputBorder(),
//                       ),
//                       items: _membershipTypes
//                           .map(
//                             (type) => DropdownMenuItem(
//                               value: type,
//                               child: Text(type),
//                             ),
//                           )
//                           .toList(),
//                       onChanged: _isEditing
//                           ? (value) {
//                               if (value != null) {
//                                 setState(() => _selectedMembershipType = value);
//                               }
//                             }
//                           : null,
//                     ),
//                     const SizedBox(height: 16),
//                     // Personal Info
//                     TextFormField(
//                       controller: _dateOfBirthController,
//                       enabled: _isEditing, // allow tap only in edit mode
//                       readOnly: true,
//                       decoration: const InputDecoration(
//                         labelText: 'Date of Birth',
//                         border: OutlineInputBorder(),
//                       ),
//                       onTap: _isEditing
//                           ? () async {
//                               final picked = await showDatePicker(
//                                 context: context,
//                                 initialDate:
//                                     _dateOfBirthController.text.isNotEmpty
//                                     ? DateTime.tryParse(
//                                             _dateOfBirthController.text,
//                                           ) ??
//                                           DateTime(2000)
//                                     : DateTime(2000),
//                                 firstDate: DateTime(1900),
//                                 lastDate: DateTime.now(),
//                               );
//                               if (picked != null) {
//                                 setState(() {
//                                   _dateOfBirthController.text = picked
//                                       .toIso8601String()
//                                       .split('T')[0];
//                                 });
//                               }
//                             }
//                           : null,
//                     ),
//                     const SizedBox(height: 12),
//                     DropdownButtonFormField<String>(
//                       value:
//                           _selectedNationality ??
//                           (_nationalityController.text.isNotEmpty
//                               ? _nationalityController.text
//                               : null),
//                       decoration: const InputDecoration(
//                         labelText: 'Nationality',
//                         border: OutlineInputBorder(),
//                       ),
//                       items: _nationalities
//                           .map(
//                             (nation) => DropdownMenuItem(
//                               value: nation,
//                               child: Text(nation),
//                             ),
//                           )
//                           .toList(),
//                       onChanged: _isEditing
//                           ? (value) {
//                               setState(() {
//                                 _selectedNationality = value;
//                                 _nationalityController.text = value ?? '';
//                               });
//                             }
//                           : null,
//                     ),
//                     const SizedBox(height: 12),
//                     TextFormField(
//                       controller: _addressController,
//                       enabled: _isEditing,
//                       decoration: const InputDecoration(labelText: 'Address'),
//                     ),
//                     const SizedBox(height: 12),
//                     TextFormField(
//                       controller: _postcodeController,
//                       enabled: _isEditing,
//                       decoration: const InputDecoration(labelText: 'Postcode'),
//                     ),
//                     const SizedBox(height: 12),
//                     TextFormField(
//                       controller: _mobileNumberController,
//                       enabled: _isEditing,
//                       decoration: const InputDecoration(
//                         labelText: 'Mobile Number',
//                       ),
//                     ),
//                     const SizedBox(height: 12),
//                     // Emergency Contact
//                     const Divider(),
//                     const Text(
//                       'Emergency Contact',
//                       style: TextStyle(fontWeight: FontWeight.bold),
//                     ),
//                     TextFormField(
//                       controller: _emergencyContactNameController,
//                       enabled: _isEditing,
//                       decoration: const InputDecoration(labelText: 'Full Name'),
//                     ),
//                     const SizedBox(height: 12),
//                     TextFormField(
//                       controller: _emergencyContactRelationController,
//                       enabled: _isEditing,
//                       decoration: const InputDecoration(
//                         labelText: 'Relationship',
//                       ),
//                     ),
//                     const SizedBox(height: 12),
//                     TextFormField(
//                       controller: _emergencyContactPhoneController,
//                       enabled: _isEditing,
//                       decoration: const InputDecoration(
//                         labelText: 'Phone Number',
//                       ),
//                     ),
//                   ],
//                 ),
//               ),
//             );
//           },
//         ),
//       ),
//     );
//   }
// }

import 'package:flutter/material.dart';

// Import your respective screens here
import 'account_info.dart';
import '../../general/home/home_screen.dart';
import '../../auth/bloc/auth_bloc.dart';
import '../../auth/bloc/auth_event.dart';
import '../../auth/bloc/auth_state.dart';
import '../../auth/views/auth_screen.dart';
import '../../settings/view/settings_screen.dart';
import '../../security/view/security_code_screen.dart';
import '../../privacy/view/privacy_policy_screen.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final List<Map<String, dynamic>> profileItems = [
      {
        'icon': Icons.account_circle,
        'label': 'Account Info',
        'color': Colors.deepPurpleAccent,
        'screen': AccountInfoScreen(),
      },
      {
        'icon': Icons.lock,
        'label': 'Security Code',
        'color': Colors.green,
        'screen': SecurityCodeScreen(),
      },
      {
        'icon': Icons.privacy_tip,
        'label': 'Privacy Policy',
        'color': Colors.blueGrey,
        'screen': HomeScreen(),
      },
      {
        'icon': Icons.settings,
        'label': 'Settings',
        'color': Colors.lightGreen,
        'screen': SettingsScreen(),
      },
      {
        'icon': Icons.logout,
        'label': 'Logout',
        'color': Colors.red,
        'screen': null, // special handling
      },
    ];

    return Scaffold(
      backgroundColor: const Color(0xFFFFFFFF),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text(
          'Profile',
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black),
        ),
        centerTitle: true,
        leading: const Padding(
          padding: EdgeInsets.all(12),
          child: Icon(Icons.grid_view_rounded, color: Colors.black),
        ),
        actions: [
          IconButton(
            onPressed: () {
              // Navigate to edit profile screen
            },
            icon: const Icon(Icons.edit, color: Colors.black),
          ),
        ],
      ),
      body: Column(
        children: [
          const SizedBox(height: 8),
          Center(
            child: Stack(
              children: [
                const CircleAvatar(
                  radius: 50,
                  backgroundImage: AssetImage('assets/images/profile.webp'),
                ),
                Positioned(
                  bottom: 0,
                  right: 4,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.edit,
                      size: 20,
                      color: Colors.deepPurple,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          const Text(
            "Hewan Adam",
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
          ),
          const SizedBox(height: 4),
          const Text("hewan@gmail.com", style: TextStyle(color: Colors.grey)),
          const SizedBox(height: 24),
          Expanded(
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              itemCount: profileItems.length,
              separatorBuilder: (_, __) => const SizedBox(height: 10),
              itemBuilder: (_, index) {
                final item = profileItems[index];
                return GestureDetector(
                  onTap: () {
                    if (item['label'] == 'Logout') {
                      // Handle logout
                      showDialog(
                        context: context,
                        builder: (_) => AlertDialog(
                          title: const Text("Logout"),
                          content: const Text(
                            "Are you sure you want to logout?",
                          ),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(context),
                              child: const Text("Cancel"),
                            ),
                            TextButton(
                              onPressed: () {
                                context.read<AuthBloc>().add(
                                  SignOutRequested(),
                                );
                                Navigator.pushAndRemoveUntil(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => const AuthScreen(),
                                  ),
                                  (route) => false,
                                );
                              },
                              child: const Text("Logout"),
                            ),
                          ],
                        ),
                      );
                    } else {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => item['screen']),
                      );
                    }
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 14,
                    ),

                    child: Row(
                      children: [
                        Icon(item['icon'], color: item['color'], size: 32),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Text(
                            item['label'],
                            style: const TextStyle(fontSize: 20),
                          ),
                        ),
                        const Icon(
                          Icons.arrow_forward_ios,
                          size: 20,
                          color: Colors.grey,
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
