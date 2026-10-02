/// Static package catalog for list + detail screens.
class PackageCatalogItem {
  const PackageCatalogItem({
    required this.id,
    required this.imagePath,
    required this.titleKey,
    required this.descriptionKey,
    required this.pricePoints,
    required this.speedMbps,
    this.popular = false,
  });

  final String id;
  final String imagePath;
  final String titleKey;
  final String descriptionKey;
  final int pricePoints;
  final String speedMbps;
  final bool popular;
}

class PackageCatalog {
  PackageCatalog._();

  static const items = <PackageCatalogItem>[
    PackageCatalogItem(
      id: '1m',
      imagePath: 'assets/images/packages/package_1m.png',
      titleKey: 'package.item_1m_title',
      descriptionKey: 'package.item_1m_body',
      pricePoints: 15000,
      speedMbps: '20',
      popular: true,
    ),
    PackageCatalogItem(
      id: '3m',
      imagePath: 'assets/images/packages/package_3m.png',
      titleKey: 'package.item_3m_title',
      descriptionKey: 'package.item_3m_body',
      pricePoints: 40000,
      speedMbps: '20',
    ),
    PackageCatalogItem(
      id: '6m',
      imagePath: 'assets/images/packages/package_6m.png',
      titleKey: 'package.item_6m_title',
      descriptionKey: 'package.item_6m_body',
      pricePoints: 75000,
      speedMbps: '30',
    ),
    PackageCatalogItem(
      id: '1y',
      imagePath: 'assets/images/packages/package_1y.png',
      titleKey: 'package.item_1y_title',
      descriptionKey: 'package.item_1y_body',
      pricePoints: 140000,
      speedMbps: '30',
    ),
    PackageCatalogItem(
      id: '1m_b',
      imagePath: 'assets/images/packages/package_1m.png',
      titleKey: 'package.item_1m_title',
      descriptionKey: 'package.item_1m_body',
      pricePoints: 15000,
      speedMbps: '20',
    ),
    PackageCatalogItem(
      id: '3m_b',
      imagePath: 'assets/images/packages/package_3m.png',
      titleKey: 'package.item_3m_title',
      descriptionKey: 'package.item_3m_body',
      pricePoints: 40000,
      speedMbps: '20',
    ),
    PackageCatalogItem(
      id: '1m_extra',
      imagePath: 'assets/images/packages/package_1m.png',
      titleKey: 'package.item_1m_title',
      descriptionKey: 'package.item_1m_body',
      pricePoints: 15000,
      speedMbps: '20',
    ),
  ];

  static PackageCatalogItem? byId(String id) {
    for (final item in items) {
      if (item.id == id) return item;
    }
    return null;
  }
}
