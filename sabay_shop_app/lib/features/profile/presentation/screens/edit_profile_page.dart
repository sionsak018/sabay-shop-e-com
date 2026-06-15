import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:sabay_shop_app/features/auth/domain/entities/user_entity.dart';
import 'package:sabay_shop_app/features/auth/presentation/controllers/auth_controller.dart';
import 'package:sabay_shop_app/features/profile/data/repositories/profile_repository_impl.dart';
import 'package:sabay_shop_app/core/theme/app_theme.dart';
import 'package:sabay_shop_app/core/network/api_endpoints.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:shimmer/shimmer.dart';
import 'package:dio/dio.dart';
import 'package:sabay_shop_app/features/profile/domain/entities/location_entity.dart';
import 'package:sabay_shop_app/features/profile/presentation/widgets/location_picker_sheet.dart';

class EditProfilePage extends ConsumerStatefulWidget {
  final UserEntity user;

  const EditProfilePage({super.key, required this.user});

  @override
  ConsumerState<EditProfilePage> createState() => _EditProfilePageState();
}

class _EditProfilePageState extends ConsumerState<EditProfilePage> {
  late TextEditingController _nameController;
  late TextEditingController _phoneController;
  late TextEditingController _aboutController;
  
  File? _newAvatar;
  File? _newCover;
  bool _isLoading = false;
  bool _removeAvatar = false;
  bool _removeCover = false;

  int? _provinceId;
  int? _districtId;
  int? _communeId;
  int? _villageId;
  String? _locationString;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.user.name);
    _phoneController = TextEditingController(text: widget.user.phone ?? '');
    _aboutController = TextEditingController(text: widget.user.aboutMe ?? '');
    _locationString = widget.user.location;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _aboutController.dispose();
    super.dispose();
  }

  Future<void> _pickImage(bool isAvatar) async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery, imageQuality: 70);
    
    if (pickedFile != null) {
      setState(() {
        if (isAvatar) {
          _newAvatar = File(pickedFile.path);
          _removeAvatar = false;
        } else {
          _newCover = File(pickedFile.path);
          _removeCover = false;
        }
      });
    }
  }

  Future<void> _showLocationPicker() async {
    final result = await showModalBottomSheet<Map<String, dynamic>>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => const LocationPickerSheet(),
    );

    if (result != null) {
      setState(() {
        _provinceId = (result['province'] as ProvinceEntity).id;
        _districtId = (result['district'] as DistrictEntity).id;
        _communeId = (result['commune'] as CommuneEntity).id;
        _villageId = (result['village'] as VillageEntity).id;
        _locationString = '${(result['village'] as VillageEntity).name}, ${(result['commune'] as CommuneEntity).name}, ${(result['district'] as DistrictEntity).name}, ${(result['province'] as ProvinceEntity).name}';
      });
    }
  }

  Future<void> _handleSave() async {
    if (_nameController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Name cannot be empty')));
      return;
    }

    setState(() => _isLoading = true);
    try {
      final Map<String, dynamic> data = {
        'name': _nameController.text.trim(),
        'phone': _phoneController.text.trim(),
        'about_me': _aboutController.text.trim(),
      };

      if (_provinceId != null) data['province_id'] = _provinceId;
      if (_districtId != null) data['district_id'] = _districtId;
      if (_communeId != null) data['commune_id'] = _communeId;
      if (_villageId != null) data['village_id'] = _villageId;

      if (_removeAvatar) data['remove_avatar'] = '1';
      if (_removeCover) data['remove_cover_photo'] = '1';

      if (_newAvatar != null) {
        data['avatar'] = await MultipartFile.fromFile(_newAvatar!.path);
      }
      if (_newCover != null) {
        data['cover_photo'] = await MultipartFile.fromFile(_newCover!.path);
      }

      await ref.read(profileRepositoryProvider).updateProfile(data);
      
      // Refresh user profile in auth controller
      ref.invalidate(authControllerProvider);

      if (mounted) {
        Navigator.pop(context, true);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Profile updated successfully'), backgroundColor: Colors.green),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to update profile: $e'), backgroundColor: Colors.redAccent),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FD),
      appBar: AppBar(
        title: const Text('EDIT PROFILE', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16, letterSpacing: 1.2)),
        backgroundColor: Colors.white,
        elevation: 0.5,
      ),
      body: _isLoading 
        ? const _EditProfileSkeleton()
        : SingleChildScrollView(
            child: Column(
              children: [
                // Cover Image Selection
                GestureDetector(
                  onTap: () => _pickImage(false),
                  child: Stack(
                    children: [
                      Container(
                        height: 180,
                        width: double.infinity,
                        decoration: BoxDecoration(color: Colors.grey[100]),
                        child: _newCover != null
                            ? Image.file(_newCover!, fit: BoxFit.cover)
                            : (!_removeCover && widget.user.coverPhoto != null
                                ? CachedNetworkImage(
                                    imageUrl: ApiEndpoints.getImageUrl(widget.user.coverPhoto!), 
                                    fit: BoxFit.cover,
                                    placeholder: (context, url) => Container(color: Colors.grey[50], child: const Center(child: CircularProgressIndicator(strokeWidth: 2))),
                                    errorWidget: (context, url, error) => const Center(child: Icon(Icons.broken_image_outlined, color: Colors.grey, size: 40)),
                                  )
                                : const Center(child: Icon(Icons.add_a_photo_outlined, size: 40, color: Colors.grey))),
                      ),
                      Positioned(
                        right: 16,
                        bottom: 16,
                        child: CircleAvatar(
                          backgroundColor: Colors.black45,
                          child: const Icon(Icons.camera_alt, color: Colors.white, size: 20),
                        ),
                      ),
                      if (_newCover != null || (!_removeCover && widget.user.coverPhoto != null))
                        Positioned(
                          left: 16,
                          bottom: 16,
                          child: GestureDetector(
                            onTap: () {
                              setState(() {
                                if (_newCover != null) {
                                  _newCover = null;
                                } else {
                                  _removeCover = true;
                                }
                              });
                            },
                            child: const CircleAvatar(
                              backgroundColor: Colors.redAccent,
                              radius: 18,
                              child: Icon(Icons.delete_outline, color: Colors.white, size: 18),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                
                Transform.translate(
                  offset: const Offset(0, -50),
                  child: Column(
                    children: [
                      // Avatar Selection
                      GestureDetector(
                        onTap: () => _pickImage(true),
                        child: Stack(
                          children: [
                            Container(
                              width: 110,
                              height: 110,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(color: Colors.white, width: 4),
                                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 10)]
                              ),
                              child: ClipOval(
                                child: _newAvatar != null 
                                  ? Image.file(_newAvatar!, fit: BoxFit.cover)
                                  : (!_removeAvatar && widget.user.avatar != null 
                                      ? CachedNetworkImage(
                                          imageUrl: ApiEndpoints.getImageUrl(widget.user.avatar!),
                                          fit: BoxFit.cover,
                                          placeholder: (context, url) => Container(color: Colors.white),
                                          errorWidget: (context, url, error) => Center(
                                            child: Text(widget.user.name.isNotEmpty ? widget.user.name[0].toUpperCase() : '?', 
                                                style: const TextStyle(fontSize: 44, fontWeight: FontWeight.w900, color: AppTheme.primaryBlue)),
                                          ),
                                        )
                                      : Container(
                                          color: Colors.white,
                                          child: Center(
                                            child: Text(widget.user.name.isNotEmpty ? widget.user.name[0].toUpperCase() : '?', 
                                                style: const TextStyle(fontSize: 44, fontWeight: FontWeight.w900, color: AppTheme.primaryBlue)),
                                          ),
                                        )),
                              ),
                            ),
                            Positioned(
                              right: 0,
                              bottom: 0,
                              child: CircleAvatar(
                                radius: 18,
                                backgroundColor: AppTheme.primaryBlue,
                                child: const Icon(Icons.camera_alt, color: Colors.white, size: 16),
                              ),
                            ),
                            if (_newAvatar != null || (!_removeAvatar && widget.user.avatar != null))
                              Positioned(
                                left: 0,
                                bottom: 0,
                                child: GestureDetector(
                                  onTap: () {
                                    setState(() {
                                      if (_newAvatar != null) {
                                        _newAvatar = null;
                                      } else {
                                        _removeAvatar = true;
                                      }
                                    });
                                  },
                                  child: const CircleAvatar(
                                    radius: 18,
                                    backgroundColor: Colors.redAccent,
                                    child: Icon(Icons.delete_outline, color: Colors.white, size: 16),
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                      
                      Padding(
                        padding: const EdgeInsets.all(24.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildLabel('FULL NAME'),
                            TextField(
                              controller: _nameController,
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                              decoration: _inputDecoration('Enter your name'),
                            ),
                            const SizedBox(height: 24),
                            
                            _buildLabel('PHONE NUMBER'),
                            TextField(
                              controller: _phoneController,
                              keyboardType: TextInputType.phone,
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                              decoration: _inputDecoration('e.g. 012 345 678'),
                            ),
                            const SizedBox(height: 24),

                            _buildLabel('LOCATION'),
                            InkWell(
                              onTap: _showLocationPicker,
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: Colors.grey[200]!),
                                ),
                                child: Row(
                                  children: [
                                    const Icon(Icons.location_on_outlined, color: Colors.grey, size: 20),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Text(
                                        _locationString ?? 'Select your location',
                                        style: TextStyle(
                                          color: _locationString == null ? Colors.grey[400] : Colors.black87,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 14,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                    const Icon(Icons.keyboard_arrow_down, color: Colors.grey),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(height: 24),
                            
                            _buildLabel('BIO / ABOUT ME'),
                            TextField(
                              controller: _aboutController,
                              maxLines: 4,
                              style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 14, height: 1.5),
                              decoration: _inputDecoration('Tell people about yourself...'),
                            ),
                            const SizedBox(height: 32),
                            
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton(
                                onPressed: _handleSave,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppTheme.primaryBlue,
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(vertical: 20),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                  elevation: 0,
                                ),
                                child: const Text('SAVE CHANGES', style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 1)),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
    );
  }

  Widget _buildLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8, left: 4),
      child: Text(text, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w900, color: Colors.grey[500], letterSpacing: 1)),
    );
  }

  InputDecoration _inputDecoration(String hint) {
    return InputDecoration(
      hintText: hint,
      hintStyle: TextStyle(color: Colors.grey[400], fontWeight: FontWeight.normal),
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey[200]!)),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey[200]!)),
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppTheme.primaryBlue, width: 2)),
    );
  }
}

class _EditProfileSkeleton extends StatelessWidget {
  const _EditProfileSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        children: [
          Shimmer.fromColors(
            baseColor: Colors.grey[300]!,
            highlightColor: Colors.grey[100]!,
            child: Container(height: 180, width: double.infinity, color: Colors.white),
          ),
          Transform.translate(
            offset: const Offset(0, -50),
            child: Column(
              children: [
                Shimmer.fromColors(
                  baseColor: Colors.grey[300]!,
                  highlightColor: Colors.grey[100]!,
                  child: Container(width: 110, height: 110, decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle)),
                ),
                const SizedBox(height: 32),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Column(
                    children: List.generate(4, (index) => Shimmer.fromColors(
                      baseColor: Colors.grey[300]!,
                      highlightColor: Colors.grey[100]!,
                      child: Container(
                        margin: const EdgeInsets.only(bottom: 24),
                        width: double.infinity,
                        height: index == 3 ? 100 : 56,
                        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
                      ),
                    )),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
