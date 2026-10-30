import 'package:cg_net_mobile/models/requests/installation_application/installation_application_model.dart';
import 'package:cg_net_mobile/pages/requests/installation_application/installation_plan_catalog.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const chinaHome = InstallationApplicationOption(
    productId: '3',
    productName: '中国网_100M_月',
    productLine: '中国网',
    productSpeed: '100M',
    productPrice: 299,
    monthCycle: 1,
    monthCycleUnit: '月',
    installationFee: 500,
  );
  const myanmar100 = InstallationApplicationOption(
    productId: '121',
    productName: '缅甸网_100M_月',
    productLine: '缅甸网',
    productSpeed: '100M',
    productPrice: 299,
    monthCycle: 1,
    monthCycleUnit: '月',
    installationFee: 500,
  );
  const myanmar10 = InstallationApplicationOption(
    productId: '209',
    productName: '缅甸网_10M_月',
    productLine: '缅甸网',
    productSpeed: '10M',
    productPrice: 100,
    monthCycle: 1,
    monthCycleUnit: '月',
    installationFee: 300,
  );
  const officeMobile = InstallationApplicationOption(
    productId: '249',
    productName: '办公移动网_100M_月',
    productLine: '移动网_办公',
    productSpeed: '100M',
    productPrice: 2000,
    monthCycle: 1,
    monthCycleUnit: '月',
    installationFee: 500,
  );

  final products = [chinaHome, myanmar100, myanmar10, officeMobile];

  test('keeps original productLine values as provider options', () {
    expect(availableProviderLines(products), [
      '中国网',
      '缅甸网',
      '移动网_办公',
    ]);
  });

  test('speeds and cycles are unique and filtered by prior choices', () {
    expect(availableSpeeds(products, '缅甸网'), [10, 100]);
    expect(availableCycles(products, '缅甸网', 100), [1]);
    expect(cycleUnitFor(
      products: products,
      productLine: '缅甸网',
      speedMbps: 100,
      monthCycle: 1,
    ), '月');
  });

  test('matches a package only after line, speed and cycle are set', () {
    expect(
      matchedProduct(
        products: products,
        productLine: '缅甸网',
        speedMbps: 100,
        monthCycle: 1,
      )?.productId,
      '121',
    );
    expect(
      matchedProduct(
        products: products,
        productLine: '缅甸网',
        speedMbps: 100,
        monthCycle: null,
      ),
      isNull,
    );
  });
}
