import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:sabay_shop_app/features/products/domain/entities/category_entity.dart';
import 'package:sabay_shop_app/features/products/data/repositories/product_repository_impl.dart';

part 'category_controller.g.dart';

@riverpod
class CategoryController extends _$CategoryController {
  @override
  FutureOr<List<CategoryEntity>> build() async {
    final repository = ref.read(productRepositoryProvider);
    return await repository.getCategories();
  }
}
