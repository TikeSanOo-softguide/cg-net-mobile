import 'package:cg_net_mobile/models/user_model/user_model.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('parses profile fields from nested account response', () {
    final profile = UserProfileModel.fromJson({
      'data': {
        'account': {
          'account': 'FTTH12349',
          'password': '456789',
          'name': 'Myat Noe Tint',
          'mobile': '09484828',
          'address': 'Moengla',
          'area': '勐拉区',
          'areaid': 9,
          'productID': 218,
          'productName': '村_缅甸网_10M_月',
          'productLine': '缅甸网_村',
          'productSpeed': '10M',
          'productPrice': 128,
          'starttime': '2026-10-01 16:29:45',
          'endtime': '2030-09-09 10:35:11',
          'status': '账户正常',
          'onlineStatus': '离线',
        },
        'broadbandAccount': {
          'account_number': 'FTTH12349',
          'service_type': 'FTTH',
        },
        'wallet': {'balance': 0, 'version': 0, 'status': 'active'},
        'packages': [],
      },
    });

    expect(profile.accountNumber, 'FTTH12349');
    expect(profile.fullName, 'Myat Noe Tint');
    expect(profile.phone, '09484828');
    expect(profile.status, '账户正常');
    expect(profile.walletBalance, '0');
    expect(profile.serviceType, 'FTTH');
    expect(profile.address, 'Moengla');
    expect(profile.area, '勐拉区');
    expect(profile.productName, '村_缅甸网_10M_月');
    expect(profile.productLine, '缅甸网_村');
    expect(profile.productSpeed, '10M');
    expect(profile.productPrice, '128');
    expect(profile.startTime, '2026-10-01 16:29:45');
    expect(profile.endTime, '2030-09-09 10:35:11');
    expect(profile.onlineStatus, '离线');
  });

  test('reads broadband account details separately from user profile', () {
    final profile = UserProfileModel.fromJson({
      'data': {
        'user': {
          'id': 57,
          'phone': '959771705651',
          'name': 'mimi',
          'broadband_account_number': 'FTTHFTTH123456789',
          'status': 'active',
        },
        'account': {
          'id': null,
          'account': 'FTTH123456789',
          'name': 'Myat Noe Tint',
          'mobile': '09260484828',
          'address': 'Mengla',
          'area': '勐拉区',
          'productName': '村_缅甸网_10M_月',
          'productLine': '缅甸网_村',
          'productSpeed': '10M',
          'productPrice': 128,
          'starttime': '2026-10-01 16:29:45',
          'endtime': '2030-09-09 10:35:11',
          'status': '账户正常',
          'onlineStatus': '离线',
        },
        'broadbandAccount': {
          'account_number': 'FTTH123456789',
          'service_type': 'FTTH',
        },
        'wallet': {'balance': 0},
      },
    });

    expect(profile.id, '57');
    expect(profile.fullName, 'mimi');
    expect(profile.status, 'active');
    expect(profile.accountNumber, 'FTTH123456789');
    expect(profile.accountName, 'Myat Noe Tint');
    expect(profile.accountPhone, '09260484828');
    expect(profile.accountStatus, '账户正常');
    expect(profile.address, 'Mengla');
    expect(profile.area, '勐拉区');
    expect(profile.productName, '村_缅甸网_10M_月');
  });

  test('restores account details from the cached profile shape', () {
    final profile = UserProfileModel.fromJson({
      'data': {
        'user': {
          'id': '57',
          'phone': '959771705651',
          'name': 'mimi',
          'status': 'active',
        },
        'account': {
          'account': 'FTTH123456789',
          'name': 'Myat Noe Tint',
          'mobile': '09260484828',
          'status': '账户正常',
          'address': 'Mengla',
          'area': '勐拉区',
          'productName': '村_缅甸网_10M_月',
          'productLine': '缅甸网_村',
          'productSpeed': '10M',
          'productPrice': '128',
          'starttime': '2026-10-01 16:29:45',
          'endtime': '2030-09-09 10:35:11',
          'onlineStatus': '离线',
        },
        'broadbandAccount': {
          'account_number': 'FTTH123456789',
          'service_type': 'FTTH',
        },
        'wallet': {'balance': '0'},
      },
    });

    expect(profile.accountNumber, 'FTTH123456789');
    expect(profile.accountName, 'Myat Noe Tint');
    expect(profile.accountPhone, '09260484828');
    expect(profile.accountStatus, '账户正常');
    expect(profile.address, 'Mengla');
    expect(profile.area, '勐拉区');
    expect(profile.productName, '村_缅甸网_10M_月');
    expect(profile.productLine, '缅甸网_村');
    expect(profile.productSpeed, '10M');
    expect(profile.productPrice, '128');
    expect(profile.startTime, '2026-10-01 16:29:45');
    expect(profile.endTime, '2030-09-09 10:35:11');
    expect(profile.onlineStatus, '离线');
    expect(profile.walletBalance, '0');
    expect(profile.serviceType, 'FTTH');
  });

  test('restores wallet and service type when cache keeps them beside data',
      () {
    final profile = UserProfileModel.fromJson({
      'data': {
        'user': {
          'id': '57',
          'phone': '09757943906',
          'name': 'Sophia',
          'status': 'active',
        },
        'account': {
          'account': 'FTTH123456789',
          'name': 'Myat Noe Tint',
        },
      },
      'broadbandAccount': {
        'account_number': 'FTTH123456789',
        'service_type': 'FTTH',
      },
      'wallet': {'balance': '25000'},
    });

    expect(profile.walletBalance, '25000');
    expect(profile.serviceType, 'FTTH');
    expect(profile.accountNumber, 'FTTH123456789');
    expect(profile.fullName, 'Sophia');
  });
}
