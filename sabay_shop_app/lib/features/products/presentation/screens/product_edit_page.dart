import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:sabay_shop_app/core/network/api_endpoints.dart';
import 'package:sabay_shop_app/features/products/domain/entities/product_entity.dart';
import 'package:sabay_shop_app/features/products/domain/entities/category_entity.dart';
import 'package:sabay_shop_app/features/products/data/repositories/product_repository_impl.dart';
import 'package:sabay_shop_app/features/products/presentation/controllers/category_controller.dart';
import 'package:sabay_shop_app/features/products/presentation/controllers/attribute_controller.dart';
import 'package:sabay_shop_app/core/theme/app_theme.dart';
import 'package:sabay_shop_app/features/profile/presentation/widgets/location_picker_sheet.dart';
import 'package:sabay_shop_app/features/profile/domain/entities/location_entity.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:shimmer/shimmer.dart';
import 'package:dio/dio.dart';

import 'package:sabay_shop_app/features/products/presentation/controllers/product_controller.dart';
import 'package:sabay_shop_app/features/auth/presentation/controllers/auth_controller.dart';

class ProductEditPage extends ConsumerStatefulWidget {
  final ProductEntity product;
  const ProductEditPage({super.key, required this.product});

  @override
  ConsumerState<ProductEditPage> createState() => _ProductEditPageState();
}

class _ProductEditPageState extends ConsumerState<ProductEditPage> {
  final _formKey = GlobalKey<FormState>();
  bool _showFormErrors = false;
  
  late TextEditingController _titleController;
  late TextEditingController _priceController;
  late TextEditingController _descriptionController;
  late TextEditingController _addressController;
  late TextEditingController _posterNameController;
  late TextEditingController _posterEmailController;
  late List<TextEditingController> _phoneControllers;
  late TextEditingController _companyNameController;

  final Map<String, TextEditingController> _attrControllers = {};
  final Map<String, String> _attrValues = {};

  int? _selectedCategoryId;
  int? _provinceId;
  int? _districtId;
  int? _communeId;
  int? _villageId;
  String? _locationString;

  String? _condition; 
  String? _status;
  late double _lat;
  late double _lng;
  
  final List<File> _newImages = [];
  final List<int> _deletedImageIds = [];
  bool _isLoading = false;

  final ImagePicker _picker = ImagePicker();
  final MapController _mapController = MapController();

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.product.title);
    _priceController = TextEditingController(text: widget.product.price.toStringAsFixed(0));
    _descriptionController = TextEditingController(text: widget.product.description);
    _addressController = TextEditingController(text: widget.product.address ?? '');
    _posterNameController = TextEditingController(text: widget.product.posterName ?? '');
    _posterEmailController = TextEditingController(text: widget.product.posterEmail ?? '');
    _companyNameController = TextEditingController(text: widget.product.companyName ?? '');
    
    _selectedCategoryId = widget.product.category?.id;
    _condition = widget.product.condition;
    _status = widget.product.status;
    _lat = widget.product.lat ?? 11.5564;
    _lng = widget.product.lng ?? 104.9282;
    _locationString = widget.product.location;
    _provinceId = widget.product.provinceId;
    _districtId = widget.product.districtId;
    _communeId = widget.product.communeId;
    _villageId = widget.product.villageId;

    // Load phones
    final phoneData = widget.product.posterPhones;
    if (phoneData != null) {
      try {
        final decoded = jsonDecode(phoneData);
        if (decoded is List) {
          _phoneControllers = decoded.map((e) => TextEditingController(text: e.toString())).toList();
        } else {
          _phoneControllers = [TextEditingController(text: phoneData)];
        }
      } catch (e) {
        _phoneControllers = [TextEditingController(text: phoneData)];
      }
    } else {
      _phoneControllers = [TextEditingController()];
    }
    if (_phoneControllers.isEmpty) _phoneControllers.add(TextEditingController());

    // Populate Attributes
    if (widget.product.attributeValues != null) {
      widget.product.attributeValues!.forEach((key, value) {
        _attrValues[key] = value.toString();
        _attrControllers[key] = TextEditingController(text: value.toString());
      });
    }
  }

  @override
  void dispose() {
    _titleController.dispose(); _priceController.dispose(); _descriptionController.dispose();
    _addressController.dispose(); _posterNameController.dispose(); _posterEmailController.dispose();
    _companyNameController.dispose();
    for (var c in _phoneControllers) { c.dispose(); }
    for (var c in _attrControllers.values) { c.dispose(); }
    super.dispose();
  }

  Future<void> _pickImages() async {
    final List<XFile> selectedImages = await _picker.pickMultiImage(imageQuality: 70);
    if (selectedImages.isNotEmpty) setState(() { _newImages.addAll(selectedImages.map((f) => File(f.path))); });
  }

  Future<void> _handleSubmit() async {
    setState(() => _showFormErrors = true);
    if (!_formKey.currentState!.validate() || _selectedCategoryId == null) return;

    setState(() => _isLoading = true);
    try {
      // PROPERLY MERGE ALL ATTRIBUTES
      final Map<String, String> finalAttributes = {};
      
      // 1. Get from controllers (Text fields & hidden values)
      _attrControllers.forEach((id, controller) {
        if (controller.text.trim().isNotEmpty) {
          finalAttributes[id] = controller.text.trim();
        }
      });

      // 2. Get from dropdown values (Selective override)
      _attrValues.forEach((id, value) {
        if (value.isNotEmpty) {
          finalAttributes[id] = value;
        }
      });

      final Map<String, dynamic> data = {
        'title': _titleController.text.trim(),
        'category_id': _selectedCategoryId,
        'description': _descriptionController.text.trim(),
        'price': _priceController.text.trim(),
        'province_id': _provinceId,
        'district_id': _districtId,
        'commune_id': _communeId,
        'village_id': _villageId,
        'location': _locationString,
        'address': _addressController.text.trim(),
        'poster_name': _posterNameController.text.trim(),
        'poster_email': _posterEmailController.text.trim(),
        'condition': _condition,
        'status': _status,
        'company_name': _companyNameController.text.trim(),
        'lat': _lat.toString(),
        'lng': _lng.toString(),
        'poster_phones': jsonEncode(_phoneControllers.map((c) => c.text.trim()).where((t) => t.isNotEmpty).toList()),
        'attributes': jsonEncode(finalAttributes),
      };

      if (_deletedImageIds.isNotEmpty) data['deleted_image_ids'] = jsonEncode(_deletedImageIds);

      final Map<String, dynamic> uploadData = Map.from(data);
      if (_newImages.isNotEmpty) {
        final List<MultipartFile> multipartImages = [];
        for (var image in _newImages) { multipartImages.add(await MultipartFile.fromFile(image.path)); }
        uploadData['images[]'] = multipartImages;
      }

      await ref.read(productRepositoryProvider).updateProduct(widget.product.id, uploadData);
      
      // បង្ខំឱ្យ Provider ទាំងអស់ទាញយកទិន្នន័យថ្មីពី Server ភ្លាមៗ
      ref.invalidate(productListControllerProvider);
      ref.invalidate(authControllerProvider); // ក្នុងករណីមានការ Update Stats ដូចជា Ads Count

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Listing updated successfully!'), backgroundColor: Colors.green));
        Navigator.pop(context, true);
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e'), backgroundColor: Colors.redAccent));
    } finally { if (mounted) setState(() => _isLoading = false); }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FD),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0.5,
        title: const Text('EDIT LISTING', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16, letterSpacing: 1.2)),
      ),
      body: _isLoading 
          ? const _EditPageSkeleton()
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Form(
                key: _formKey,
                autovalidateMode: _showFormErrors ? AutovalidateMode.always : AutovalidateMode.disabled,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildSectionHeader('AD PHOTOS *'),
                    const SizedBox(height: 12),
                    _buildImageGrid(),
                    const SizedBox(height: 32),

                    _buildSectionHeader('ITEM SPECIFICATIONS'),
                    const SizedBox(height: 16),
                    _buildConditionPicker(),
                    const SizedBox(height: 20),
                    _buildStatusPicker(),
                    if (_selectedCategoryId != null) ...[
                      const SizedBox(height: 20),
                      _buildDynamicAttributes(_selectedCategoryId!),
                    ],
                    const SizedBox(height: 32),

                    _buildSectionHeader('GENERAL INFORMATION'),
                    const SizedBox(height: 16),
                    _buildTextField(controller: _titleController, label: 'Ad Title *', hint: 'Title'),
                    const SizedBox(height: 20),
                    _buildTextField(controller: _priceController, label: 'Price (\$) *', hint: '0.00', keyboardType: TextInputType.number),
                    const SizedBox(height: 20),
                    _buildTextField(controller: _descriptionController, label: 'Description *', hint: 'Details', maxLines: 5),
                    const SizedBox(height: 32),

                    _buildSectionHeader('ITEM LOCATION'),
                    const SizedBox(height: 16),
                    _buildLocationPicker(),
                    const SizedBox(height: 20),
                    _buildTextField(controller: _addressController, label: 'Detail Address *', hint: 'St, House No...'),
                    const SizedBox(height: 20),
                    _buildMapLocationPicker(),
                    const SizedBox(height: 32),

                    _buildSectionHeader('CONTACT INFORMATION'),
                    const SizedBox(height: 16),
                    _buildTextField(controller: _posterNameController, label: 'Poster Name *', hint: 'Name'),
                    const SizedBox(height: 20),
                    _buildTextField(controller: _posterEmailController, label: 'Email *', hint: 'Email'),
                    const SizedBox(height: 20),
                    _buildPhoneFields(),
                    const SizedBox(height: 20),
                    _buildTextField(controller: _companyNameController, label: 'Business/Company Name *', hint: 'Shop Name'),
                    const SizedBox(height: 40),

                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _handleSubmit,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.primaryBlue,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 20),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          elevation: 0,
                        ),
                        child: const Text('UPDATE AD NOW', style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 1.5)),
                      ),
                    ),
                    const SizedBox(height: 80),
                  ],
                ),
              ),
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

  Widget _buildImageGrid() {
    return Container(
      height: 110,
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: ListView(
        scrollDirection: Axis.horizontal,
        clipBehavior: Clip.none,
        children: [
          InkWell(
            onTap: _pickImages,
            borderRadius: BorderRadius.circular(16),
            child: Container(
              width: 100, height: 100,
              decoration: BoxDecoration(
                color: AppTheme.primaryBlue.withOpacity(0.05),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppTheme.primaryBlue.withOpacity(0.2), width: 1.5),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.add_a_photo_rounded, color: AppTheme.primaryBlue, size: 26),
                  const SizedBox(height: 6),
                  const Text('ADD PHOTO', style: TextStyle(fontSize: 8, fontWeight: FontWeight.w900, color: AppTheme.primaryBlue)),
                ],
              ),
            ),
          ),
          const SizedBox(width: 14),
          ...widget.product.images.where((img) => !_deletedImageIds.contains(img.id)).map((img) => _buildThumbnail(
            url: ApiEndpoints.getImageUrl(img.imageUrl),
            onRemove: () => setState(() => _deletedImageIds.add(img.id)),
          )),
          ..._newImages.map((file) => _buildThumbnail(
            image: FileImage(file),
            onRemove: () => setState(() => _newImages.remove(file)),
          )),
        ],
      ),
    );
  }

  Widget _buildThumbnail({ImageProvider? image, String? url, required VoidCallback onRemove}) {
    return Container(
      width: 100, height: 100,
      margin: const EdgeInsets.only(right: 14),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.08), blurRadius: 10, offset: const Offset(0, 4))]),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: url != null 
                ? CachedNetworkImage(
                    imageUrl: url, width: 100, height: 100, fit: BoxFit.cover,
                    placeholder: (_, __) => const Center(child: CircularProgressIndicator(strokeWidth: 2)),
                    errorWidget: (_, __, ___) => Container(color: Colors.grey[100], child: const Icon(Icons.image_not_supported, color: Colors.grey)),
                  )
                : Image(image: image!, width: 100, height: 100, fit: BoxFit.cover),
            ),
          ),
          Positioned(top: -6, right: -6, child: GestureDetector(onTap: onRemove, child: Container(padding: const EdgeInsets.all(5), decoration: BoxDecoration(color: Colors.redAccent, shape: BoxShape.circle, border: Border.all(color: Colors.white, width: 2)), child: const Icon(Icons.close, color: Colors.white, size: 10)))),
        ],
      ),
    );
  }

  Widget _buildTextField({required TextEditingController controller, required String label, required String hint, TextInputType? keyboardType, int maxLines = 1, String? Function(String?)? validator}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF374151))),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller, keyboardType: keyboardType, maxLines: maxLines, 
          validator: validator ?? (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
          decoration: InputDecoration(
            hintText: hint, filled: true, fillColor: Colors.white,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey[200]!)),
            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey[200]!)),
            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppTheme.primaryBlue, width: 1.5)),
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
        const Text('Condition *', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        Row(children: [ _conditionButton('new', 'New'), const SizedBox(width: 12), _conditionButton('used', 'Used') ]),
      ],
    );
  }

  Widget _conditionButton(String value, String label) {
    final isSelected = _condition == value;
    return Expanded(child: InkWell(onTap: () => setState(() => _condition = value), child: Container(padding: const EdgeInsets.symmetric(vertical: 14), decoration: BoxDecoration(color: isSelected ? AppTheme.primaryBlue : Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: isSelected ? AppTheme.primaryBlue : Colors.grey[200]!)), child: Center(child: Text(label.toUpperCase(), style: TextStyle(fontSize: 12, fontWeight: FontWeight.w900, color: isSelected ? Colors.white : Colors.grey[600]))))));
  }

  Widget _buildStatusPicker() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Listing Status *', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        Row(
          children: [
            _statusButton('active', 'ACTIVE', Colors.green),
            const SizedBox(width: 8),
            _statusButton('sold', 'SOLD', Colors.orange),
            const SizedBox(width: 8),
            _statusButton('inactive', 'STOP/PAUSE', Colors.red),
          ],
        ),
      ],
    );
  }

  Widget _statusButton(String value, String label, Color activeColor) {
    final isSelected = _status == value;
    return Expanded(
      child: InkWell(
        onTap: () => setState(() => _status = value),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isSelected ? activeColor : Colors.white,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: isSelected ? activeColor : Colors.grey[200]!),
          ),
          child: Center(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 9,
                fontWeight: FontWeight.w900,
                color: isSelected ? Colors.white : Colors.grey[600],
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
            final String idKey = attr.id.toString();
            if (attr.type == 'select') {
              final String? currentValue = _attrValues[idKey];
              final bool valueExists = attr.options.any((o) => o.value == currentValue);
              return Padding(
                padding: const EdgeInsets.only(top: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('${attr.name}${attr.isRequired ? " *" : ""}', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<String>(
                      value: valueExists ? currentValue : null,
                      items: attr.options.map((o) => DropdownMenuItem(value: o.value, child: Text(o.value))).toList(),
                      onChanged: (v) => setState(() => _attrValues[idKey] = v!),
                      decoration: InputDecoration(filled: true, fillColor: Colors.white, border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey[200]!))),
                      validator: (v) => attr.isRequired && (v == null || v.isEmpty) ? 'Required' : null,
                    ),
                  ],
                ),
              );
            } 
            if (!_attrControllers.containsKey(idKey)) {
              _attrControllers[idKey] = TextEditingController(text: _attrValues[idKey] ?? '');
            }
            return Padding(
              padding: const EdgeInsets.only(top: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('${attr.name}${attr.isRequired ? " *" : ""}', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _attrControllers[idKey],
                    keyboardType: attr.type == 'number' ? TextInputType.number : TextInputType.text,
                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                    onChanged: (v) => _attrValues[idKey] = v,
                    decoration: InputDecoration(filled: true, fillColor: Colors.white, border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey[200]!))),
                    validator: (v) => attr.isRequired && (v == null || v.trim().isEmpty) ? 'Required' : null,
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

  Widget _buildLocationPicker() {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      const Text('Select Location *', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
      const SizedBox(height: 8),
      InkWell(
        onTap: () async {
          final result = await showModalBottomSheet(context: context, isScrollControlled: true, shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))), builder: (_) => const LocationPickerSheet());
          if (result != null) setState(() {
            _provinceId = result['province'].id; _districtId = result['district'].id; _communeId = result['commune'].id; _villageId = result['village'].id;
            _locationString = '${result['village'].name}, ${result['commune'].name}, ${result['district'].name}, ${result['province'].name}';
          });
        },
        child: Container(padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16), decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.grey[200]!)), child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [ Expanded(child: Text(_locationString ?? 'Choose location', style: TextStyle(color: _locationString == null ? Colors.grey : Colors.black, fontWeight: FontWeight.bold))), const Icon(Icons.keyboard_arrow_down) ])),
      ),
    ]);
  }

  Widget _buildMapLocationPicker() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Location on Map *', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        Container(
          height: 200,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey[300]!),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: FlutterMap(
              mapController: _mapController,
              options: MapOptions(
                initialCenter: LatLng(_lat, _lng),
                initialZoom: 13.0,
                onTap: (_, latLng) => setState(() {
                  _lat = latLng.latitude;
                  _lng = latLng.longitude;
                }),
              ),
              children: [
                TileLayer(
                  urlTemplate: 'https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png',
                  subdomains: const ['a', 'b', 'c'],
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
                      child: const Icon(Icons.location_on, color: Colors.red, size: 35),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPhoneFields() {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [ const Text('Contact Numbers *', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)), if (_phoneControllers.length < 3) TextButton(onPressed: () => setState(() => _phoneControllers.add(TextEditingController())), child: const Text('+ ADD PHONE', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: AppTheme.primaryBlue))) ]),
      ..._phoneControllers.asMap().entries.map((e) => Padding(padding: const EdgeInsets.only(bottom: 8), child: Row(children: [ Expanded(child: TextFormField(controller: e.value, keyboardType: TextInputType.phone, decoration: InputDecoration(prefixIcon: const Icon(Icons.phone, size: 16, color: Colors.grey), filled: true, fillColor: Colors.white, border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey[200]!))))), if (_phoneControllers.length > 1) IconButton(icon: const Icon(Icons.remove_circle_outline, color: Colors.red), onPressed: () => setState(() => _phoneControllers.removeAt(e.key))) ])))
    ]);
  }
}

class _EditPageSkeleton extends StatelessWidget {
  const _EditPageSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: List.generate(8, (index) => Shimmer.fromColors(
          baseColor: Colors.grey[300]!,
          highlightColor: Colors.grey[100]!,
          child: Container(
            margin: const EdgeInsets.only(bottom: 24),
            width: double.infinity,
            height: index == 0 ? 100 : 50,
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
          ),
        )),
      ),
    );
  }
}
