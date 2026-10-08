/// Hardcoded product catalog used until the backend exposes a catalog API.
/// See PRODUCT_CATALOG.md at the repository root before editing: every
/// [variantId] must match a product_variant_id in the Django backend.
class CatalogVariant {
  final int variantId;
  final String size;
  final String grade;
  final double pricePerTonne; // ₹, sent as unit_price

  const CatalogVariant({
    required this.variantId,
    required this.size,
    required this.grade,
    required this.pricePerTonne,
  });

  String get name => 'ShauryaTMT $size';
}

class ProductCatalog {
  static const List<CatalogVariant> variants = [
    // Grade A
    CatalogVariant(
      variantId: 1,
      size: '6mm',
      grade: 'Grade A',
      pricePerTonne: 62000,
    ),
    CatalogVariant(
      variantId: 2,
      size: '8mm',
      grade: 'Grade A',
      pricePerTonne: 60500,
    ),
    CatalogVariant(
      variantId: 3,
      size: '10mm',
      grade: 'Grade A',
      pricePerTonne: 59500,
    ),
    CatalogVariant(
      variantId: 4,
      size: '12mm',
      grade: 'Grade A',
      pricePerTonne: 58500,
    ),
    CatalogVariant(
      variantId: 5,
      size: '16mm',
      grade: 'Grade A',
      pricePerTonne: 58000,
    ),
    CatalogVariant(
      variantId: 6,
      size: '20mm',
      grade: 'Grade A',
      pricePerTonne: 58000,
    ),
    // Grade B
    CatalogVariant(
      variantId: 7,
      size: '6mm',
      grade: 'Grade B',
      pricePerTonne: 60000,
    ),
    CatalogVariant(
      variantId: 8,
      size: '8mm',
      grade: 'Grade B',
      pricePerTonne: 58500,
    ),
    CatalogVariant(
      variantId: 9,
      size: '10mm',
      grade: 'Grade B',
      pricePerTonne: 57500,
    ),
    CatalogVariant(
      variantId: 10,
      size: '12mm',
      grade: 'Grade B',
      pricePerTonne: 56500,
    ),
    CatalogVariant(
      variantId: 11,
      size: '16mm',
      grade: 'Grade B',
      pricePerTonne: 56000,
    ),
    CatalogVariant(
      variantId: 12,
      size: '20mm',
      grade: 'Grade B',
      pricePerTonne: 56000,
    ),
  ];
}
