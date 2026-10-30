import 'package:cg_net_mobile/models/requests/installation_application/installation_application_model.dart';
import 'package:cg_net_mobile/models/user_model/user_model.dart';
import 'package:cg_net_mobile/pages/requests/installation_application/installation_request_draft.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('installation customer validators', () {
    test('requires a full name', () {
      expect(installationFullNameError(null), 'requests.required');
      expect(installationFullNameError('   '), 'requests.required');
      expect(installationFullNameError('Aung Aung'), isNull);
    });

    test('requires a complete address', () {
      expect(installationAddressError(''), 'requests.required');
      expect(
        installationAddressError('No. 12, Inya Road, Yangon'),
        isNull,
      );
    });

    test('validates phone numbers with app country rules', () {
      expect(installationPhoneError(null), 'login.phone_required');
      expect(installationPhoneError('123'), 'login.phone_invalid');
      expect(installationPhoneError('09234567890'), isNull);
    });
  });

  test('draft keeps customer fields when going back from later steps', () {
    final notifier = InstallationRequestDraftNotifier()
      ..begin(
        profile: const UserProfileModel(
          id: '8',
          fullName: 'Profile Name',
          phone: '95912345678',
          accountNumber: '',
          username: '',
        ),
      )
      ..setFullName('Maung Maung')
      ..setPhone('09987654321')
      ..setAddress('Building A, Room 5');

    expect(notifier.state.fullName, 'Maung Maung');
    expect(notifier.state.phone, '09987654321');
    expect(notifier.state.address, 'Building A, Room 5');
    expect(notifier.state.serviceType, 'FTTH');
  });

  test('draft maps customer info into the request payload', () {
    final request = const InstallationRequestDraft(
      userId: 8,
      serviceType: 'FTTH',
      productId: '249',
      productName: '100M',
      fullName: 'Maung Maung',
      phone: '09987654321',
      address: 'Inya Road',
    ).toRequest();

    expect(request, isA<InstallationApplicationModel>());
    expect(request.idName, 'Maung Maung');
    expect(request.phone, '09987654321');
    expect(request.address, 'Inya Road');
    expect(request.productId, '249');
  });
}
