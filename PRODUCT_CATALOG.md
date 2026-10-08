# Product Catalog (hardcoded)

The backend does not yet expose a product catalog API, so the app ships with a
hardcoded list of TMT bar variants and their prices. This list drives the
product screen and the `items` of every order sent to the create-order API.

**Source of truth in code:** [`lib/config/constants/product_catalog.dart`](lib/config/constants/product_catalog.dart)

## ⚠️ Before release

The variant ids and prices below are **placeholders**. Each `product_variant_id`
must match a real product variant in the Django backend. Otherwise orders will
fail or book the wrong product. Check them against the backend and update the
Dart file and this table together.

## Current variants

All prices are in ₹ per tonne. Orders are placed in tonnes, and quantities can
be fractional (for example 2.5 t).

| product_variant_id | Product         | Size | Grade   | Price / tonne (₹) |
|-------------------:|-----------------|------|---------|------------------:|
| 1                  | ShauryaTMT 6mm  | 6mm  | Grade A | 62,000 |
| 2                  | ShauryaTMT 8mm  | 8mm  | Grade A | 60,500 |
| 3                  | ShauryaTMT 10mm | 10mm | Grade A | 59,500 |
| 4                  | ShauryaTMT 12mm | 12mm | Grade A | 58,500 |
| 5                  | ShauryaTMT 16mm | 16mm | Grade A | 58,000 |
| 6                  | ShauryaTMT 20mm | 20mm | Grade A | 58,000 |
| 7                  | ShauryaTMT 6mm  | 6mm  | Grade B | 60,000 |
| 8                  | ShauryaTMT 8mm  | 8mm  | Grade B | 58,500 |
| 9                  | ShauryaTMT 10mm | 10mm | Grade B | 57,500 |
| 10                 | ShauryaTMT 12mm | 12mm | Grade B | 56,500 |
| 11                 | ShauryaTMT 16mm | 16mm | Grade B | 56,000 |
| 12                 | ShauryaTMT 20mm | 20mm | Grade B | 56,000 |

## How prices reach an order

The price shown on the product screen is sent unchanged as each item's
`unit_price` in the create-order payload:

```json
{"product_variant_id": 4, "quantity": 2.5, "unit_price": 58500}
```

No GST or other tax is added in the app.

## Changing the catalog

1. Edit the `variants` list in `lib/config/constants/product_catalog.dart`.
   Keep every `variantId` unique.
2. Update the table above to match.
3. Ship a new app build. The prices are compiled into the app, so users on
   older builds keep ordering at the old prices until they update.

## Replacing with an API

Once the backend has a catalog endpoint, load it in
`ProductProvider._loadCatalog()` (`lib/providers/product_provider.dart`), then
delete `product_catalog.dart` and this file. Nothing else reads the catalog
directly.
