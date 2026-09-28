import 'dart:async';

import 'package:in_app_purchase/in_app_purchase.dart';

enum RestoreResult {
  restored('구매 내역을 복원했습니다'),
  noPurchases('복원할 구매 내역이 없습니다'),
  unavailable('지금은 스토어에 연결할 수 없어요'),
  failed('구매 복원을 확인하지 못했어요. 잠시 후 다시 시도해 주세요');

  const RestoreResult(this.message);
  final String message;
}

/// Request completion alone does not prove that a purchase was restored.
Future<RestoreResult> restorePurchase({
  required String productId,
  required Stream<List<PurchaseDetails>> purchases,
  required Future<bool> Function() isAvailable,
  required Future<void> Function() requestRestore,
  Duration timeout = const Duration(seconds: 30),
}) async {
  final received = Completer<void>();
  var restored = false;
  var failed = false;
  var completedBatch = false;
  StreamSubscription<List<PurchaseDetails>>? subscription;
  try {
    if (!await isAvailable().timeout(timeout)) {
      return RestoreResult.unavailable;
    }
    subscription = purchases.listen(
      (batch) {
        final matching = batch.where((p) => p.productID == productId);
        failed |= matching.any(
          (p) =>
              p.status == PurchaseStatus.error ||
              p.status == PurchaseStatus.canceled,
        );
        restored |= matching.any((p) => p.status == PurchaseStatus.restored);
        completedBatch |=
            batch.isEmpty ||
            batch.every((p) => p.status == PurchaseStatus.restored);
        if ((failed || restored || completedBatch) && !received.isCompleted) {
          received.complete();
        }
      },
      onError: (Object error) {
        failed = true;
        if (!received.isCompleted) received.complete();
      },
    );
    await requestRestore().timeout(timeout);
    await received.future.timeout(timeout);
    // Drain queued stream callbacks before interpreting the completed request.
    await Future<void>.delayed(Duration.zero);
    if (failed) return RestoreResult.failed;
    return restored ? RestoreResult.restored : RestoreResult.noPurchases;
  } catch (_) {
    return RestoreResult.failed;
  } finally {
    await subscription?.cancel();
  }
}
