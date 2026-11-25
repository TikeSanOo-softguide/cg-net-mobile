import 'package:cg_net_mobile/core/storage/list_snapshot_store.dart';
import 'package:cg_net_mobile/core/storage/local_prefs/local_prefs.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  test('keeps each user list separate and drops wifi passwords', () async {
    final preferences = await SharedPreferences.getInstance();
    final store = ListSnapshotStore(preferences);
    await preferences.setString(LocalPrefs.sessionUserIdKey, 'user-a');

    await store.write(ListSnapshotStore.complaint, [
      {'id': 1, 'failure_type': 'slow'},
    ]);
    await store.write(
      ListSnapshotStore.changeWifi,
      [
        {'id': 9, 'new_password': 'secret', 'status': 'under_review'},
      ],
      omitKeys: ListSnapshotStore.wifiSecretKeys,
    );

    expect(store.read(ListSnapshotStore.complaint), [
      {'id': 1, 'failure_type': 'slow'},
    ]);
    expect(store.read(ListSnapshotStore.changeWifi), [
      {'id': 9, 'status': 'under_review'},
    ]);

    await preferences.setString(LocalPrefs.sessionUserIdKey, 'user-b');
    expect(store.read(ListSnapshotStore.complaint), isNull);

    await preferences.setString(LocalPrefs.sessionUserIdKey, 'user-a');
    expect(store.read(ListSnapshotStore.complaint), isNotNull);

    await store.clear();
    expect(store.read(ListSnapshotStore.complaint), isNull);
    expect(store.read(ListSnapshotStore.changeWifi), isNull);
  });

  test('showroom snapshot does not require a signed-in user', () async {
    final preferences = await SharedPreferences.getInstance();
    final store = ListSnapshotStore(preferences);

    await store.write(
      ListSnapshotStore.showroom,
      [
        {'id': 3, 'code': 'YG'},
      ],
      shared: true,
    );

    expect(store.read(ListSnapshotStore.showroom, shared: true), [
      {'id': 3, 'code': 'YG'},
    ]);
  });
}
