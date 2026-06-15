import 'package:dio/dio.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:sabay_shop_app/core/network/repositories/base_repository.dart';
import 'package:sabay_shop_app/core/network/repositories/dio_provider.dart';
import 'package:sabay_shop_app/features/profile/domain/entities/location_entity.dart';
import 'package:sabay_shop_app/features/profile/domain/repositories/location_repository.dart';

part 'location_repository_impl.g.dart';

class LocationRepositoryImpl extends BaseRepository implements LocationRepository {
  final Dio dio;

  LocationRepositoryImpl(this.dio);

  @override
  Future<List<ProvinceEntity>> getProvinces() async {
    return mapException(() async {
      final response = await dio.get('/provinces');
      final List data = response.data is List ? response.data : (response.data['data'] ?? []);
      return data.map((json) => ProvinceEntity(id: json['id'], name: json['name'] ?? '')).toList();
    });
  }

  @override
  Future<List<DistrictEntity>> getDistricts(int provinceId) async {
    return mapException(() async {
      final response = await dio.get('/districts', queryParameters: {'province_id': provinceId});
      final List data = response.data is List ? response.data : (response.data['data'] ?? []);
      return data.map((json) => DistrictEntity(id: json['id'], provinceId: json['province_id'] ?? 0, name: json['name'] ?? '')).toList();
    });
  }

  @override
  Future<List<CommuneEntity>> getCommunes(int districtId) async {
    return mapException(() async {
      final response = await dio.get('/communes', queryParameters: {'district_id': districtId});
      final List data = response.data is List ? response.data : (response.data['data'] ?? []);
      return data.map((json) => CommuneEntity(id: json['id'], districtId: json['district_id'] ?? 0, name: json['name'] ?? '')).toList();
    });
  }

  @override
  Future<List<VillageEntity>> getVillages(int communeId) async {
    return mapException(() async {
      final response = await dio.get('/villages', queryParameters: {'commune_id': communeId});
      final List data = response.data is List ? response.data : (response.data['data'] ?? []);
      return data.map((json) => VillageEntity(id: json['id'], communeId: json['commune_id'] ?? 0, name: json['name'] ?? '')).toList();
    });
  }
}

@riverpod
LocationRepository locationRepository(Ref ref) {
  return LocationRepositoryImpl(ref.watch(dioProvider));
}
