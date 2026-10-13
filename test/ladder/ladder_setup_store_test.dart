import 'package:flutter_test/flutter_test.dart';
import 'package:dutch_pay_calculator/ladder/ladder_setup.dart';
import 'package:dutch_pay_calculator/ladder/ladder_setup_store.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  test('저장한 마지막 입력을 다시 읽는다', () async {
    SharedPreferences.setMockInitialValues({});
    final store = LadderSetupStore(await SharedPreferences.getInstance());
    expect(store.load(), isNull);

    final setup = LadderSetup(
      players: const ['민수', '', '지영'],
      results: const [ResultSlot('14호차', 1), ResultSlot('12호차', 2)],
    );
    await store.save(setup);

    final again = LadderSetupStore(await SharedPreferences.getInstance()).load();
    expect(again?.players, setup.players);
    expect(again?.results, setup.results);
  });

  test('깨진 저장값은 무시한다', () async {
    SharedPreferences.setMockInitialValues({LadderSetupStore.key: '{not json'});
    final store = LadderSetupStore(await SharedPreferences.getInstance());
    expect(store.load(), isNull);
  });
}
