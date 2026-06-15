import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:sabay_shop_app/core/network/api_endpoints.dart';
import 'package:sabay_shop_app/features/products/domain/entities/category_entity.dart';
import 'package:sabay_shop_app/features/products/domain/entities/attribute_entity.dart';
import 'package:sabay_shop_app/features/products/data/repositories/product_repository_impl.dart';
import 'package:sabay_shop_app/features/products/presentation/controllers/category_controller.dart';
import 'package:sabay_shop_app/features/products/presentation/controllers/attribute_controller.dart';
import 'package:sabay_shop_app/core/theme/app_theme.dart';
import 'package:sabay_shop_app/features/profile/presentation/widgets/location_picker_sheet.dart';
import 'package:sabay_shop_app/features/profile/domain/entities/location_entity.dart';
import 'package:dio/dio.dart';
import 'package:go_router/go_router.dart';
import 'package:sabay_shop_app/core/router/route_name.dart';
import 'package:sabay_shop_app/features/auth/presentation/controllers/auth_controller.dart';
import 'package:sabay_shop_app/features/auth/domain/entities/user_entity.dart';
import 'package:url_launcher/url_launcher.dart';

class ProductCreatePage extends ConsumerStatefulWidget {
  const ProductCreatePage({super.key});

  @override
  ConsumerState<ProductCreatePage> createState() => _ProductCreatePageState();
}

class _ProductCreatePageState extends ConsumerState<ProductCreatePage> {
  int _step = 1; // 1: Category, 2: Information
  final _formKey = GlobalKey<FormState>();
  bool _showFormErrors = false;
  
  final _titleController = TextEditingController();
  final _priceController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _addressController = TextEditingController();
  final _posterNameController = TextEditingController();
  final _posterEmailController = TextEditingController();
  final List<TextEditingController> _phoneControllers = [TextEditingController()];
  final _companyNameController = TextEditingController();

  CategoryEntity? _selectedMainCat;
  CategoryEntity? _selectedSubCat;
  
  ProvinceEntity? _selectedProvince;
  DistrictEntity? _selectedDistrict;
  CommuneEntity? _selectedCommune;
  VillageEntity? _selectedVillage;

  String? _condition; 
  double _lat = 11.5564;
  double _lng = 104.9282;
  bool _isMapPinned = false;
  
  final Map<String, String> _attributeValues = {}; // ប្តូរពី int ទៅ String
  final List<XFile> _images = [];
  bool _isLoading = false;
  bool _agreedToTerms = false;

  final ImagePicker _picker = ImagePicker();
  final MapController _mapController = MapController();

  Future<void> _pickImages() async {
    final List<XFile> selectedImages = await _picker.pickMultiImage();
    if (selectedImages.isNotEmpty) {
      setState(() {
        if (_images.length + selectedImages.length > 10) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Max 10 photos allowed')),
          );
          _images.addAll(selectedImages.take(10 - _images.length));
        } else {
          _images.addAll(selectedImages);
        }
      });
    }
  }

  void _removeImage(int index) {
    setState(() => _images.removeAt(index));
  }

  Future<void> _handleSubmit() async {
    setState(() => _showFormErrors = true);

    final user = ref.read(authControllerProvider).value;
    if (user != null && user.adsCount >= user.postLimit) {
      _showError('You have reached your posting limit (${user.postLimit} ads)');
      return;
    }

    // 1. Basic Form Validation
    if (!_formKey.currentState!.validate()) {
      _showError('Please check all required fields');
      return;
    }

    // 2. Custom Widget Validations
    if (_condition == null) {
      _showError('Please select item condition');
      return;
    }

    if (_images.isEmpty) {
      _showError('Please add at least one photo');
      return;
    }

    if (_selectedProvince == null || _selectedDistrict == null || _selectedCommune == null) {
      _showError('Please select a complete location (Province, District, Commune)');
      return;
    }

    if (!_isMapPinned) {
      _showError('Please tap on the map to pin your exact location');
      return;
    }

    // 3. Dynamic Attributes Validation
    final currentCategoryId = _selectedSubCat?.id ?? _selectedMainCat?.id;
    if (currentCategoryId != null) {
       final attributesAsync = ref.read(categoryAttributeControllerProvider(currentCategoryId));
       if (attributesAsync.hasValue) {
          for (var attr in attributesAsync.value!) {
            if (attr.isRequired && (_attributeValues[attr.id] == null || _attributeValues[attr.id]!.trim().isEmpty)) {
              _showError('${attr.name} is required');
              return;
            }
          }
       }
    }

    if (!_agreedToTerms) {
      _showError('You must agree to the Terms and Conditions');
      return;
    }

    setState(() => _isLoading = true);
    try {
      final Map<String, dynamic> data = {
        'title': _titleController.text.trim(),
        'description': _descriptionController.text.trim(),
        'price': _priceController.text.trim(),
        'category_id': currentCategoryId,
        'province_id': _selectedProvince?.id,
        'district_id': _selectedDistrict?.id,
        'commune_id': _selectedCommune?.id,
        'village_id': _selectedVillage?.id,
        'address': _addressController.text.trim(),
        'poster_name': _posterNameController.text.trim(),
        'poster_email': _posterEmailController.text.trim(),
        'condition': _condition,
        'company_name': _companyNameController.text.trim(),
        'lat': _lat.toString(),
        'lng': _lng.toString(),
        'poster_phones': jsonEncode(_phoneControllers.map((c) => c.text.trim()).where((t) => t.isNotEmpty).toList()),
        'attributes': jsonEncode(_attributeValues),
      };

      final locationString = [
        _selectedVillage?.name,
        _selectedCommune?.name,
        _selectedDistrict?.name,
        _selectedProvince?.name
      ].whereType<String>().join(', ');
      data['location'] = locationString.isNotEmpty ? locationString : 'Cambodia';

      final Map<String, dynamic> uploadData = Map.from(data);
      final List<MultipartFile> multipartImages = [];
      for (var image in _images) {
        multipartImages.add(await MultipartFile.fromFile(image.path));
      }
      uploadData['images[]'] = multipartImages;

      await ref.read(productRepositoryProvider).createProduct(uploadData);
      
      // Refresh user profile to update ads count
      ref.invalidate(authControllerProvider);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Listing posted successfully!'), backgroundColor: Colors.green),
        );
        if (context.canPop()) {
          context.pop(true);
        } else {
          context.go(RouteName.home);
        }
      }
    } catch (e) {
      _showError(e.toString());
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: const TextStyle(fontWeight: FontWeight.bold)), 
        backgroundColor: Colors.redAccent,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 3),
      )
    );
  }

  @override
  void dispose() {
    // Clear validation errors when leaving the screen
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
      }
    });
    _titleController.dispose();
    _priceController.dispose();
    _descriptionController.dispose();
    _addressController.dispose();
    _posterNameController.dispose();
    _posterEmailController.dispose();
    for (var controller in _phoneControllers) {
      controller.dispose();
    }
    _companyNameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authControllerProvider);

    if (authState.isLoading && _step == 1) {
      return Scaffold(
        body: _CreatePageSkeleton(),
      );
    }

    if (authState.value == null && !authState.isLoading) {
      return Scaffold(
        appBar: AppBar(title: const Text('Login Required')),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.lock_outline, size: 64, color: Colors.grey),
              const SizedBox(height: 16),
              const Text('Please login to post an ad', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () => context.push(RouteName.login),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryBlue,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                ),
                child: const Text('Login Now'),
              ),
            ],
          ),
        ),
      );
    }

    final user = authState.value;
    if (user != null && user.adsCount >= user.postLimit && _step == 1) {
      return Scaffold(
        backgroundColor: const Color(0xFFF1F2F6),
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          centerTitle: true,
          title: const Text('Post Ad', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.black)),
          leading: IconButton(
            icon: const Icon(Icons.close, color: Colors.black),
            onPressed: () {
              if (context.canPop()) {
                context.pop();
              } else {
                context.go(RouteName.home);
              }
            },
          ),
        ),
        body: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            children: [
              _buildLimitReachedBanner(user),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF1F2F6),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        title: Text(_step == 1 ? 'Select Category' : 'Post Ad', 
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.black)),
        leading: IconButton(
          icon: Icon(_step == 2 ? Icons.arrow_back : Icons.close, color: Colors.black),
          onPressed: () {
            if (_step == 2) {
              ScaffoldMessenger.of(context).hideCurrentSnackBar();
              setState(() {
                _step = 1;
                _showFormErrors = false;
              });
            } else {
              if (context.canPop()) {
                context.pop();
              } else {
                context.go(RouteName.home);
              }
            }
          },
        ),
      ),
      body: _isLoading 
          ? const Center(child: CircularProgressIndicator())
          : _step == 1 ? _buildCategoryStep() : _buildInformationStep(),
    );
  }

  Widget _buildCategoryStep() {
    final categoriesAsync = ref.watch(categoryControllerProvider);
    final user = ref.watch(authControllerProvider).value;

    return categoriesAsync.when(
      data: (categories) {
        final mainCategories = categories.where((c) => c.parentId == null).toList();
        
        return Column(
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              color: Colors.white,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('What are you selling?', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                      if (user != null)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: AppTheme.primaryBlue.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            'Limit: ${user.adsCount}/${user.postLimit}',
                            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppTheme.primaryBlue),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text('Select a category for your ad', style: TextStyle(color: Colors.grey[600], fontSize: 14)),
                ],
              ),
            ),
            const Divider(height: 1),
            Expanded(
              child: Row(
                children: [
                  Expanded(
                    flex: 1,
                    child: Container(
                      color: Colors.white,
                      child: ListView.builder(
                        itemCount: mainCategories.length,
                        itemBuilder: (context, index) {
                          final cat = mainCategories[index];
                          final isSelected = _selectedMainCat?.id == cat.id;
                          return Container(
                            decoration: BoxDecoration(
                              border: Border(left: BorderSide(color: isSelected ? AppTheme.primaryBlue : Colors.transparent, width: 4)),
                              color: isSelected ? AppTheme.primaryBlue.withOpacity(0.05) : Colors.transparent,
                            ),
                            child: ListTile(
                              onTap: () => setState(() {
                                _selectedMainCat = cat;
                                _selectedSubCat = null;
                                final subs = categories.where((c) => c.parentId == cat.id).toList();
                                if (subs.isEmpty) {
                                  _step = 2;
                                }
                              }),
                              leading: cat.imageUrl != null 
                                ? Container(
                                    width: 32,
                                    height: 32,
                                    decoration: const BoxDecoration(shape: BoxShape.circle),
                                    child: ClipOval(
                                      child: CachedNetworkImage(
                                          imageUrl: ApiEndpoints.getImageUrl(cat.imageUrl!),
                                          fit: BoxFit.cover,
                                          placeholder: (context, url) => Container(color: Colors.grey[100]),
                                          errorWidget: (_, __, ___) => const Icon(Icons.category, size: 20)),
                                    ),
                                  )
                                : const Icon(Icons.category, size: 20),
                              title: Text(cat.name, style: TextStyle(
                                fontSize: 13, 
                                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                color: isSelected ? AppTheme.primaryBlue : Colors.black87
                              )),
                              trailing: Icon(Icons.chevron_right, size: 16, color: isSelected ? AppTheme.primaryBlue : Colors.grey),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                  const VerticalDivider(width: 1),
                  Expanded(
                    flex: 1,
                    child: Container(
                      color: const Color(0xFFF8F9FD),
                      child: _selectedMainCat == null 
                        ? Center(child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.category_outlined, size: 40, color: Colors.grey[300]),
                              const SizedBox(height: 8),
                              const Text('Select category', style: TextStyle(color: Colors.grey, fontSize: 12)),
                            ],
                          ))
                        : ListView.builder(
                            itemCount: categories.where((c) => c.parentId == _selectedMainCat!.id).length,
                            itemBuilder: (context, index) {
                              final subCats = categories.where((c) => c.parentId == _selectedMainCat!.id).toList();
                              final cat = subCats[index];
                              return ListTile(
                                onTap: () => setState(() {
                                  _selectedSubCat = cat;
                                  _step = 2;
                                }),
                                title: Text(cat.name, style: const TextStyle(fontSize: 13)),
                                trailing: const Icon(Icons.chevron_right, size: 16, color: Colors.grey),
                              );
                            },
                          ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        );
      },
      loading: () => Row(
        children: [
          Expanded(child: Container(color: Colors.white)),
          const VerticalDivider(width: 1),
          Expanded(child: Container(color: const Color(0xFFF8F9FD))),
        ],
      ),
      error: (err, __) => Center(child: Text('Error: $err')),
    );
  }

  Widget _buildInformationStep() {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      child: Form(
        key: _formKey,
        autovalidateMode: _showFormErrors ? AutovalidateMode.always : AutovalidateMode.disabled,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Category Header
            Container(
              padding: const EdgeInsets.all(20),
              color: Colors.white,
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(color: AppTheme.primaryBlue.withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
                    child: const Icon(Icons.category, color: AppTheme.primaryBlue, size: 20),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Category', style: TextStyle(fontSize: 12, color: Colors.grey, fontWeight: FontWeight.bold)),
                        Text('${_selectedMainCat?.name} > ${_selectedSubCat?.name ?? ""}', 
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                      ],
                    ),
                  ),
                  TextButton(
                    onPressed: () {
                      ScaffoldMessenger.of(context).hideCurrentSnackBar();
                      setState(() {
                        _step = 1;
                        _showFormErrors = false;
                      });
                    },
                    child: const Text('Change', style: TextStyle(color: AppTheme.primaryBlue, fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 12),

            // Photos Section
            _buildFormCard(
              title: 'Photos',
              subtitle: 'Add up to 10 photos. The first photo is your main cover.',
              child: SizedBox(
                height: 120,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: _images.length + 1,
                  itemBuilder: (context, index) {
                    if (index == _images.length) {
                      if (_images.length >= 10) return const SizedBox.shrink();
                      return InkWell(
                        onTap: _pickImages,
                        child: Container(
                          width: 100,
                          height: 100,
                          margin: const EdgeInsets.only(right: 12),
                          decoration: BoxDecoration(
                            color: Colors.grey[50],
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: _showFormErrors && _images.isEmpty ? Colors.redAccent : Colors.grey[200]!, style: BorderStyle.solid),
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.add_a_photo_outlined, color: Colors.grey[400]),
                              const SizedBox(height: 8),
                              Text('Add Photo', style: TextStyle(fontSize: 12, color: Colors.grey[600], fontWeight: FontWeight.bold)),
                            ],
                          ),
                        ),
                      );
                    }
                    return Stack(
                      children: [
                        Container(
                          width: 100,
                          height: 100,
                          margin: const EdgeInsets.only(right: 12),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.grey[200]!),
                            image: DecorationImage(image: FileImage(File(_images[index].path)), fit: BoxFit.cover),
                          ),
                        ),
                        if (index == 0)
                          Positioned(
                            bottom: 0,
                            left: 0,
                            right: 12,
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 4),
                              decoration: const BoxDecoration(
                                color: Colors.black54,
                                borderRadius: BorderRadius.vertical(bottom: Radius.circular(12)),
                              ),
                              child: const Text('Main', textAlign: TextAlign.center, style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                            ),
                          ),
                        Positioned(
                          top: 4,
                          right: 16,
                          child: InkWell(
                            onTap: () => _removeImage(index),
                            child: Container(
                              padding: const EdgeInsets.all(4),
                              decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle, boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 4)]),
                              child: const Icon(Icons.close, size: 14, color: Colors.black),
                            ),
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),
            ),

            const SizedBox(height: 12),

            // Basic Info Section
            _buildFormCard(
              title: 'Basic Details',
              child: Column(
                children: [
                   _buildTextField(
                    controller: _titleController,
                    label: 'Ad Title',
                    hint: 'e.g. iPhone 15 Pro Max',
                    validator: (v) {
                      if (v == null || v.trim().isEmpty) return 'Title is required';
                      if (v.trim().length < 5) return 'Title must be at least 5 characters';
                      return null;
                    },
                  ),
                  const SizedBox(height: 20),
                  _buildTextField(
                    controller: _priceController,
                    label: 'Price (\$)',
                    hint: '0.00',
                    keyboardType: TextInputType.number,
                    validator: (v) {
                      if (v == null || v.trim().isEmpty) return 'Price is required';
                      if (double.tryParse(v) == null) return 'Enter a valid price';
                      return null;
                    },
                  ),
                  const SizedBox(height: 20),
                  _buildConditionPicker(),
                  const SizedBox(height: 20),
                  if (_selectedSubCat != null || _selectedMainCat != null)
                    _buildDynamicAttributes(_selectedSubCat?.id ?? _selectedMainCat!.id),
                  const SizedBox(height: 20),
                  _buildTextField(
                    controller: _descriptionController,
                    label: 'Description',
                    hint: 'Describe what you are selling, details like color, size, condition, etc.',
                    maxLines: 5,
                    validator: (v) {
                      if (v == null || v.trim().isEmpty) return 'Description is required';
                      if (v.trim().length < 20) return 'Please provide a detailed description (min 20 chars)';
                      return null;
                    },
                  ),
                ],
              ),
            ),

            const SizedBox(height: 12),

            // Location Section
            _buildFormCard(
              title: 'Location',
              child: Column(
                children: [
                  _buildLocationPicker(),
                  const SizedBox(height: 20),
                  _buildTextField(
                    controller: _addressController,
                    label: 'Detailed Address',
                    hint: 'House No, Street, Landmark...',
                    validator: (v) => (v == null || v.trim().isEmpty) ? 'Address is required' : null,
                  ),
                  const SizedBox(height: 20),
                  _buildMapLocationPicker(),
                ],
              ),
            ),

            const SizedBox(height: 12),

            // Contact Section
            _buildFormCard(
              title: 'Contact Information',
              child: Column(
                children: [
                  _buildTextField(
                    controller: _posterNameController,
                    label: 'Name',
                    hint: 'Your name',
                    validator: (v) => (v == null || v.trim().isEmpty) ? 'Name is required' : null,
                  ),
                  const SizedBox(height: 20),
                  _buildTextField(
                    controller: _posterEmailController,
                    label: 'Email',
                    hint: 'email@example.com',
                    keyboardType: TextInputType.emailAddress,
                    validator: (v) {
                      if (v == null || v.trim().isEmpty) return 'Email is required';
                      final regex = RegExp(r'^[^@]+@[^@]+\.[^@]+');
                      if (!regex.hasMatch(v)) return 'Enter a valid email address';
                      return null;
                    },
                  ),
                  const SizedBox(height: 20),
                  _buildPhoneFields(),
                  const SizedBox(height: 20),
                  _buildTextField(
                    controller: _companyNameController,
                    label: 'Company/Shop Name',
                    hint: 'Enter your shop name',
                    validator: (v) {
                      if (v == null || v.trim().isEmpty) return 'Company/Shop name is required';
                      if (v.trim().length < 3) return 'Name is too short';
                      return null;
                    },
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                children: [
                  Row(
                    children: [
                      SizedBox(
                        height: 24, width: 24,
                        child: Checkbox(
                          value: _agreedToTerms,
                          onChanged: (v) => setState(() => _agreedToTerms = v ?? false),
                          activeColor: AppTheme.primaryBlue,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                        ),
                      ),
                      const SizedBox(width: 12),
                      const Expanded(
                        child: Text(
                          'I agree to the Terms and Conditions of Sabay Shop.',
                          style: TextStyle(fontSize: 13, color: Colors.black87),
                        ),
                      ),
                    ],
                  ),
                  if (_showFormErrors && !_agreedToTerms)
                    const Align(
                      alignment: Alignment.centerLeft,
                      child: Padding(
                        padding: EdgeInsets.only(top: 8, left: 36),
                        child: Text('You must agree to terms', style: TextStyle(color: Colors.redAccent, fontSize: 12)),
                      ),
                    ),
                  
                  const SizedBox(height: 32),

                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton(
                      onPressed: _handleSubmit,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primaryBlue,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        elevation: 0,
                      ),
                      child: const Text('Post Ad Now', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    ),
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildFormCard({required String title, String? subtitle, required Widget child}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      color: Colors.white,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          if (subtitle != null) ...[
            const SizedBox(height: 4),
            Text(subtitle, style: TextStyle(fontSize: 13, color: Colors.grey[600])),
          ],
          const SizedBox(height: 20),
          child,
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Row(
      children: [
        Container(width: 4, height: 16, decoration: BoxDecoration(color: AppTheme.primaryBlue, borderRadius: BorderRadius.circular(2))),
        const SizedBox(width: 8),
        Text(title, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 11, color: Color(0xFF374151), letterSpacing: 1.2)),
      ],
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    TextInputType? keyboardType,
    int maxLines = 1,
    String? Function(String?)? validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.black87)),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          maxLines: maxLines,
          validator: validator,
          style: const TextStyle(fontSize: 14),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(color: Colors.grey[400], fontSize: 14),
            filled: true,
            fillColor: Colors.grey[50],
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey[200]!)),
            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey[200]!)),
            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppTheme.primaryBlue, width: 1.5)),
            errorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Colors.redAccent)),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          ),
        ),
      ],
    );
  }

  Widget _buildConditionPicker() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Condition', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.black87)),
        const SizedBox(height: 8),
        Row(
          children: [
            _conditionButton('new', 'New'),
            const SizedBox(width: 12),
            _conditionButton('used', 'Used'),
          ],
        ),
        if (_showFormErrors && _condition == null)
           const Padding(
             padding: EdgeInsets.only(top: 6),
             child: Text('Item condition is required', style: TextStyle(color: Colors.redAccent, fontSize: 12)),
           ),
      ],
    );
  }

  Widget _conditionButton(String value, String label) {
    final isSelected = _condition == value;
    return Expanded(
      child: InkWell(
        onTap: () => setState(() => _condition = value),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            color: isSelected ? AppTheme.primaryBlue : Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: isSelected ? AppTheme.primaryBlue : Colors.grey[300]!),
          ),
          child: Center(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 14, 
                fontWeight: FontWeight.bold, 
                color: isSelected ? Colors.white : Colors.black87,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDynamicAttributes(int categoryId) {
    final attributesAsync = ref.watch(categoryAttributeControllerProvider(categoryId));

    return attributesAsync.when(
      data: (attributes) {
        if (attributes.isEmpty) return const SizedBox.shrink();
        return Column(
          children: attributes.map((attr) {
            return Padding(
              padding: const EdgeInsets.only(top: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('${attr.name}${attr.isRequired ? " *" : ""}', 
                      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.black87)),
                  const SizedBox(height: 8),
                  if (attr.type == 'select')
                    DropdownButtonFormField<String>(
                      value: _attributeValues[attr.id.toString()],
                      items: attr.options.map((o) => DropdownMenuItem(value: o.value, child: Text(o.value, style: const TextStyle(fontSize: 14)))).toList(),
                      onChanged: (v) => setState(() => _attributeValues[attr.id.toString()] = v!),
                      decoration: _inputDecoration(attr.name),
                      validator: (v) => attr.isRequired && (v == null || v.isEmpty) ? '${attr.name} is required' : null,
                      icon: Icon(Icons.keyboard_arrow_down, color: Colors.grey[400]),
                      style: const TextStyle(fontSize: 14, color: Colors.black),
                    )
                  else
                    TextFormField(
                      keyboardType: attr.type == 'number' ? TextInputType.number : TextInputType.text,
                      onChanged: (v) => _attributeValues[attr.id.toString()] = v,
                      decoration: _inputDecoration(attr.name),
                      style: const TextStyle(fontSize: 14),
                      validator: (v) => attr.isRequired && (v == null || v.trim().isEmpty) ? '${attr.name} is required' : null,
                    ),
                ],
              ),
            );
          }).toList(),
        );
      },
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
    );
  }

  InputDecoration _inputDecoration(String hint) {
    return InputDecoration(
      hintText: 'Enter $hint',
      hintStyle: TextStyle(color: Colors.grey[400], fontSize: 14),
      filled: true,
      fillColor: Colors.grey[50],
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey[200]!)),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey[200]!)),
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppTheme.primaryBlue, width: 1.5)),
      errorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Colors.redAccent)),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
    );
  }

  Widget _buildLocationPicker() {
    final bool hasError = _showFormErrors && (_selectedProvince == null || _selectedDistrict == null || _selectedCommune == null);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Location', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.black87)),
        const SizedBox(height: 8),
        InkWell(
          onTap: () async {
            final result = await showModalBottomSheet(
              context: context,
              isScrollControlled: true,
              backgroundColor: Colors.transparent,
              builder: (context) => const LocationPickerSheet(),
            );
            if (result != null) {
              setState(() {
                _selectedProvince = result['province'];
                _selectedDistrict = result['district'];
                _selectedCommune = result['commune'];
                _selectedVillage = result['village'];
              });
            }
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            decoration: BoxDecoration(
              color: Colors.grey[50],
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: hasError ? Colors.redAccent : Colors.grey[200]!),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    _selectedProvince == null 
                      ? 'Select location' 
                      : '${_selectedVillage?.name ?? ""}, ${_selectedCommune?.name ?? ""}, ${_selectedDistrict?.name}, ${_selectedProvince?.name}',
                    style: TextStyle(
                      color: _selectedProvince == null ? Colors.grey[400] : Colors.black87, 
                      fontSize: 14,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Icon(Icons.keyboard_arrow_down, color: Colors.grey[400]),
              ],
            ),
          ),
        ),
        if (hasError)
          const Padding(
            padding: EdgeInsets.only(top: 6),
            child: Text('Please select Province, District and Commune', style: TextStyle(color: Colors.redAccent, fontSize: 12)),
          ),
      ],
    );
  }

  Widget _buildMapLocationPicker() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('Pin Location', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.black87)),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(color: Colors.grey[100], borderRadius: BorderRadius.circular(6)),
              child: Text('${_lat.toStringAsFixed(4)}, ${_lng.toStringAsFixed(4)}', 
                  style: TextStyle(fontSize: 10, color: Colors.grey[600], fontWeight: FontWeight.bold)),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Stack(
          children: [
            Container(
              height: 250,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: (_showFormErrors && !_isMapPinned) ? Colors.redAccent : Colors.grey[200]!, width: (_showFormErrors && !_isMapPinned) ? 1.5 : 1),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: FlutterMap(
                  mapController: _mapController,
                  options: MapOptions(
                    initialCenter: LatLng(_lat, _lng),
                    initialZoom: 13.0,
                    onTap: (_, latLng) {
                      setState(() {
                        _lat = latLng.latitude;
                        _lng = latLng.longitude;
                        _isMapPinned = true;
                      });
                    },
                  ),
                  children: [
                    TileLayer(
                      urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                      tileProvider: NetworkTileProvider(
                        headers: {
                          'User-Agent': 'SabayShopApp/1.0.0 (com.sabay.shop; contact@sabay.com)',
                        },
                      ),
                    ),
                    MarkerLayer(
                      markers: [
                        Marker(
                          point: LatLng(_lat, _lng),
                          width: 40,
                          height: 40,
                          child: const Icon(Icons.location_on, color: Colors.red, size: 30),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            Positioned(
              right: 8,
              top: 8,
              child: Column(
                children: [
                  _mapButton(Icons.add, () => _mapController.move(_mapController.camera.center, _mapController.camera.zoom + 1)),
                  const SizedBox(height: 4),
                  _mapButton(Icons.remove, () => _mapController.move(_mapController.camera.center, _mapController.camera.zoom - 1)),
                ],
              ),
            ),
          ],
        ),
        if (_showFormErrors && !_isMapPinned)
          const Padding(
            padding: EdgeInsets.only(top: 8),
            child: Text('Please tap on the map to pin your location', style: TextStyle(color: Colors.redAccent, fontSize: 12)),
          ),
      ],
    );
  }

  Widget _mapButton(IconData icon, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 4)],
        ),
        child: Icon(icon, size: 20, color: AppTheme.primaryBlue),
      ),
    );
  }

  Widget _buildPhoneFields() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('Phone Numbers', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.black87)),
            if (_phoneControllers.length < 3)
              TextButton(
                onPressed: () => setState(() => _phoneControllers.add(TextEditingController())),
                child: const Row(
                  children: [
                    Icon(Icons.add, size: 14, color: AppTheme.primaryBlue),
                    SizedBox(width: 4),
                    Text('Add More', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppTheme.primaryBlue)),
                  ],
                ),
              ),
          ],
        ),
        const SizedBox(height: 4),
        ..._phoneControllers.asMap().entries.map((entry) {
          final idx = entry.key;
          final controller = entry.value;
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: controller,
                    keyboardType: TextInputType.phone,
                    style: const TextStyle(fontSize: 14),
                    decoration: _inputDecoration('Phone Number ${idx + 1}'),
                    validator: (v) {
                      if (idx == 0 && (v == null || v.trim().isEmpty)) return 'At least one phone is required';
                      if (v != null && v.isNotEmpty) {
                        if (v.length < 8) return 'Enter a valid phone number';
                      }
                      return null;
                    },
                  ),
                ),
                if (_phoneControllers.length > 1)
                  IconButton(
                    icon: const Icon(Icons.remove_circle_outline, color: Colors.redAccent),
                    onPressed: () => setState(() => _phoneControllers.removeAt(idx)),
                  ),
              ],
            ),
          );
        }),
      ],
    );
  }

  Widget _buildLimitReachedBanner(UserEntity user) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF5F5),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFFEE2E2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: const BoxDecoration(
                  color: Color(0xFFFEE2E2),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.warning_amber_rounded, color: Color(0xFFB91C1C), size: 28),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'AD LIMIT REACHED',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                        color: Color(0xFF7F1D1D),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'You have used all your active ad slots (${user.adsCount}/${user.postLimit}).',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF991B1B),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          const Text(
            'To continue posting, you can either delete your old or sold items to free up slots, or upgrade your account to a Store Member for unlimited postings and more features.',
            style: TextStyle(
              fontSize: 13,
              color: Color(0xFFB91C1C),
              height: 1.5,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () {
                    context.go(RouteName.profile);
                    // Optionally direct to a specific "My Ads" section if available
                  },
                  icon: const Icon(Icons.inventory_2_outlined, size: 18),
                  label: const Text('MANAGE MY ADS'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFFB91C1C),
                    side: const BorderSide(color: Color(0xFFFCA5A5)),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    backgroundColor: Colors.white,
                    textStyle: const TextStyle(fontWeight: FontWeight.w900, fontSize: 11, letterSpacing: 0.5),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () async {
                    final Uri url = Uri.parse('https://t.me/Sion_Sak');
                    if (await canLaunchUrl(url)) {
                      await launchUrl(url, mode: LaunchMode.externalApplication);
                    }
                  },
                  icon: const Icon(Icons.telegram, size: 18),
                  label: const Text('BECOME A STORE MEMBER'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryBlue,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    elevation: 0,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    textStyle: const TextStyle(fontWeight: FontWeight.w900, fontSize: 11, letterSpacing: 0.5),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _CreatePageSkeleton extends StatelessWidget {
  const _CreatePageSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(height: 100, color: Colors.white),
        const SizedBox(height: 1),
        Expanded(
          child: Row(
            children: [
              Expanded(child: Container(color: Colors.white)),
              const VerticalDivider(width: 1),
              Expanded(child: Container(color: const Color(0xFFF8F9FD))),
            ],
          ),
        ),
      ],
    );
  }
}
