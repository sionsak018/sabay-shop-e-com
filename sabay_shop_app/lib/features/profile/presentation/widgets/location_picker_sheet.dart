import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shimmer/shimmer.dart';
import 'package:sabay_shop_app/features/profile/domain/entities/location_entity.dart';
import 'package:sabay_shop_app/features/profile/data/repositories/location_repository_impl.dart';

class LocationPickerSheet extends ConsumerStatefulWidget {
  const LocationPickerSheet({super.key});

  @override
  ConsumerState<LocationPickerSheet> createState() => _LocationPickerSheetState();
}

class _LocationPickerSheetState extends ConsumerState<LocationPickerSheet> {
  ProvinceEntity? _selectedProvince;
  DistrictEntity? _selectedDistrict;
  CommuneEntity? _selectedCommune;
  
  List<ProvinceEntity> _provinces = [];
  List<DistrictEntity> _districts = [];
  List<CommuneEntity> _communes = [];
  List<VillageEntity> _villages = [];
  
  bool _isLoading = true;
  String _currentLevel = 'province'; // province, district, commune, village

  @override
  void initState() {
    super.initState();
    _loadProvinces();
  }

  void _safeSetState(VoidCallback fn) {
    if (mounted) setState(fn);
  }

  Future<void> _loadProvinces() async {
    _safeSetState(() => _isLoading = true);
    try {
      final repository = ref.read(locationRepositoryProvider);
      final list = await repository.getProvinces();
      _safeSetState(() {
        _provinces = list;
        _isLoading = false;
        _currentLevel = 'province';
      });
    } catch (e) {
      _safeSetState(() => _isLoading = false);
    }
  }

  Future<void> _loadDistricts(int provinceId) async {
    _safeSetState(() => _isLoading = true);
    try {
      final repository = ref.read(locationRepositoryProvider);
      final list = await repository.getDistricts(provinceId);
      _safeSetState(() {
        _districts = list;
        _isLoading = false;
        _currentLevel = 'district';
      });
    } catch (e) {
      _safeSetState(() => _isLoading = false);
    }
  }

  Future<void> _loadCommunes(int districtId) async {
    _safeSetState(() => _isLoading = true);
    try {
      final repository = ref.read(locationRepositoryProvider);
      final list = await repository.getCommunes(districtId);
      _safeSetState(() {
        _communes = list;
        _isLoading = false;
        _currentLevel = 'commune';
      });
    } catch (e) {
      _safeSetState(() => _isLoading = false);
    }
  }

  Future<void> _loadVillages(int communeId) async {
    _safeSetState(() => _isLoading = true);
    try {
      final repository = ref.read(locationRepositoryProvider);
      final list = await repository.getVillages(communeId);
      _safeSetState(() {
        _villages = list;
        _isLoading = false;
        _currentLevel = 'village';
      });
    } catch (e) {
      _safeSetState(() => _isLoading = false);
    }
  }

  void _goBack() {
    if (_currentLevel == 'village') {
      _loadCommunes(_selectedDistrict!.id);
    } else if (_currentLevel == 'commune') {
      _loadDistricts(_selectedProvince!.id);
    } else if (_currentLevel == 'district') {
      _loadProvinces();
    }
  }

  @override
  Widget build(BuildContext context) {
    String title = 'SELECT PROVINCE';
    if (_currentLevel == 'district') title = 'SELECT DISTRICT';
    if (_currentLevel == 'commune') title = 'SELECT COMMUNE';
    if (_currentLevel == 'village') title = 'SELECT VILLAGE';

    return Container(
      height: MediaQuery.of(context).size.height * 0.8,
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16, letterSpacing: 0.5),
              ),
              if (_currentLevel != 'province')
                TextButton.icon(
                  onPressed: _goBack,
                  icon: const Icon(Icons.arrow_back, size: 16),
                  label: const Text('BACK', style: TextStyle(fontWeight: FontWeight.bold)),
                ),
            ],
          ),
          const Divider(),
          Expanded(
            child: _isLoading 
              ? ListView.builder(
                  itemCount: 8,
                  itemBuilder: (context, index) => Shimmer.fromColors(
                    baseColor: Colors.grey[300]!,
                    highlightColor: Colors.grey[100]!,
                    child: ListTile(title: Container(height: 16, width: double.infinity, color: Colors.white)),
                  ),
                )
              : ListView.builder(
                  itemCount: _getItemCount(),
                  itemBuilder: (context, index) {
                    return _buildListTile(index);
                  },
                ),
          ),
        ],
      ),
    );
  }

  int _getItemCount() {
    switch (_currentLevel) {
      case 'province': return _provinces.length;
      case 'district': return _districts.length;
      case 'commune': return _communes.length;
      case 'village': return _villages.length;
      default: return 0;
    }
  }

  Widget _buildListTile(int index) {
    String name = '';
    VoidCallback onTap = () {};

    if (_currentLevel == 'province') {
      final p = _provinces[index];
      name = p.name;
      onTap = () {
        _selectedProvince = p;
        _loadDistricts(p.id);
      };
    } else if (_currentLevel == 'district') {
      final d = _districts[index];
      name = d.name;
      onTap = () {
        _selectedDistrict = d;
        _loadCommunes(d.id);
      };
    } else if (_currentLevel == 'commune') {
      final c = _communes[index];
      name = c.name;
      onTap = () {
        _selectedCommune = c;
        _loadVillages(c.id);
      };
    } else if (_currentLevel == 'village') {
      final v = _villages[index];
      name = v.name;
      onTap = () {
        Navigator.pop(context, {
          'province': _selectedProvince,
          'district': _selectedDistrict,
          'commune': _selectedCommune,
          'village': v,
        });
      };
    }

    return ListTile(
      title: Text(name, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
      trailing: _currentLevel == 'village' ? null : const Icon(Icons.chevron_right, size: 20),
      onTap: onTap,
    );
  }
}
