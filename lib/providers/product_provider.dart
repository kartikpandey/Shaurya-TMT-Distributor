import 'package:flutter/material.dart';
import '../config/constants/product_catalog.dart';
import '../models/product_model.dart';

class ProductProvider extends ChangeNotifier {
  List<ProductModel> _products = [];
  List<ProductModel> _filteredProducts = [];
  // Always false while the catalog is hardcoded; set it once loaded from an API
  final bool _isLoading = false;
  String _selectedGrade = 'All';
  String _selectedSize = 'All';

  // Getters
  List<ProductModel> get products => _filteredProducts;
  bool get isLoading => _isLoading;
  String get selectedGrade => _selectedGrade;
  String get selectedSize => _selectedSize;

  ProductProvider() {
    _loadCatalog();
  }

  // Load the hardcoded catalog (see PRODUCT_CATALOG.md)
  void _loadCatalog() {
    _products =
        ProductCatalog.variants
            .map(
              (v) => ProductModel(
                variantId: v.variantId,
                name: v.name,
                size: v.size,
                grade: v.grade,
                quantity: 0,
                unitPrice: v.pricePerTonne,
                totalPrice: 0,
                unit: 'tonnes',
              ),
            )
            .toList();
    _filteredProducts = List.from(_products);
  }

  // Filter products by grade and size
  void filterProducts({required String grade, required String size}) {
    _selectedGrade = grade;
    _selectedSize = size;

    _filteredProducts =
        _products.where((product) {
          final gradeMatch = grade == 'All' || product.grade == grade;
          final sizeMatch = size == 'All' || product.size == size;
          return gradeMatch && sizeMatch;
        }).toList();

    notifyListeners();
  }

  // Reset filters
  void resetFilters() {
    _selectedGrade = 'All';
    _selectedSize = 'All';
    _filteredProducts = List.from(_products);
    notifyListeners();
  }

  // Get available sizes
  List<String> getAvailableSizes() {
    return [
      'All',
      ...{..._products.map((p) => p.size)},
    ].cast<String>();
  }

  // Get available grades
  List<String> getAvailableGrades() {
    return [
      'All',
      ...{..._products.map((p) => p.grade)},
    ].cast<String>();
  }
}
