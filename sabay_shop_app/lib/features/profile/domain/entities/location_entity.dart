import 'package:equatable/equatable.dart';

class ProvinceEntity extends Equatable {
  final int id;
  final String name;

  const ProvinceEntity({required this.id, required this.name});

  @override
  List<Object?> get props => [id, name];
}

class DistrictEntity extends Equatable {
  final int id;
  final int provinceId;
  final String name;

  const DistrictEntity({required this.id, required this.provinceId, required this.name});

  @override
  List<Object?> get props => [id, provinceId, name];
}

class CommuneEntity extends Equatable {
  final int id;
  final int districtId;
  final String name;

  const CommuneEntity({required this.id, required this.districtId, required this.name});

  @override
  List<Object?> get props => [id, districtId, name];
}

class VillageEntity extends Equatable {
  final int id;
  final int communeId;
  final String name;

  const VillageEntity({required this.id, required this.communeId, required this.name});

  @override
  List<Object?> get props => [id, communeId, name];
}
