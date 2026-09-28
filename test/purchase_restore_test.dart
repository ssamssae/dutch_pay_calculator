import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:dutch_pay_calculator/services/purchase_restore.dart';

PurchaseDetails purchase(String id, PurchaseStatus status) => PurchaseDetails(
  productID: id,
  verificationData: PurchaseVerificationData(
    localVerificationData: '',
    serverVerificationData: '',
    source: 'test',
  ),
  transactionDate: null,
  status: status,
);

void main() {
  late StreamController<List<PurchaseDetails>> stream;
  setUp(() => stream = StreamController<List<PurchaseDetails>>.broadcast());
  tearDown(() => stream.close());
  Future<RestoreResult> run(
    Future<void> Function() request, {
    bool available = true,
  }) => restorePurchase(
    productId: 'remove_ads',
    purchases: stream.stream,
    isAvailable: () async => available,
    requestRestore: request,
    timeout: const Duration(milliseconds: 20),
  );
  test('empty store history is not success', () async {
    expect(
      await run(() async {
        stream.add([]);
      }),
      RestoreResult.noPurchases,
    );
  });
  test('matching restored entitlement is success', () async {
    expect(
      await run(() async {
        stream.add([purchase('remove_ads', PurchaseStatus.restored)]);
      }),
      RestoreResult.restored,
    );
  });
  test('different product does not restore ad removal', () async {
    expect(
      await run(() async {
        stream.add([purchase('other', PurchaseStatus.restored)]);
      }),
      RestoreResult.noPurchases,
    );
  });
  test('unavailable store does not send request or report success', () async {
    expect(
      await run(() async {
        fail('must not request');
      }, available: false),
      RestoreResult.unavailable,
    );
  });
  test('request exception is failure', () async {
    expect(
      await run(() async {
        throw StateError('offline');
      }),
      RestoreResult.failed,
    );
  });
  test('stream error is failure', () async {
    expect(
      await run(() async {
        stream.addError(StateError('offline'));
      }),
      RestoreResult.failed,
    );
  });
  test(
    'request completion without result is not success or empty history',
    () async {
      expect(await run(() async {}), RestoreResult.failed);
    },
  );
  test('pending purchase is not restore success', () async {
    expect(
      await run(() async {
        stream.add([purchase('remove_ads', PurchaseStatus.pending)]);
      }),
      RestoreResult.failed,
    );
  });
  test('restore waits for asynchronous result', () async {
    expect(
      await run(() async {
        Timer(
          const Duration(milliseconds: 1),
          () => stream.add([purchase('remove_ads', PurchaseStatus.restored)]),
        );
      }),
      RestoreResult.restored,
    );
    expect(stream.hasListener, isFalse);
  });
  test('request failure wins over an earlier restored event', () async {
    expect(
      await run(() async {
        stream.add([purchase('remove_ads', PurchaseStatus.restored)]);
        throw StateError('partial failure');
      }),
      RestoreResult.failed,
    );
  });
  test('multiple batches retain a matching entitlement', () async {
    expect(
      await run(() async {
        stream.add([purchase('other', PurchaseStatus.restored)]);
        await Future<void>.delayed(Duration.zero);
        stream.add([purchase('remove_ads', PurchaseStatus.restored)]);
      }),
      RestoreResult.restored,
    );
  });
}
