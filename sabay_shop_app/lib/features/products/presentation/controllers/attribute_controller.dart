import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:sabay_shop_app/features/products/domain/entities/attribute_entity.dart';
import 'package:sabay_shop_app/features/products/data/repositories/product_repository_impl.dart';

part 'attribute_controller.g.dart';

@riverpod
class CategoryAttributeController extends _$CategoryAttributeController {
  @override
  FutureOr<List<CategoryAttributeEntity>> build(int categoryId) async {
    final repository = ref.read(productRepositoryProvider);
    return await repository.getCategoryAttributes(categoryId);
  }
}
