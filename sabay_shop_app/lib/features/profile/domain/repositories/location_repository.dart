import 'package:sabay_shop_app/features/profile/domain/entities/location_entity.dart';

abstract class LocationRepository {
  Future<List<ProvinceEntity>> getProvinces();
  Future<List<DistrictEntity>> getDistricts(int provinceId);
  Future<List<CommuneEntity>> getCommunes(int districtId);
  Future<List<VillageEntity>> getVillages(int communeId);
}
