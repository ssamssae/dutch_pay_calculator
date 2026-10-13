/// 결과 한 줄 = 라벨 + 자리 개수. 예: 12호차 × 2.
class ResultSlot {
  const ResultSlot(this.label, this.count);

  final String label;
  final int count;

  @override
  bool operator ==(Object other) =>
      other is ResultSlot && other.label == label && other.count == count;

  @override
  int get hashCode => Object.hash(label, count);

  @override
  String toString() => 'ResultSlot($label × $count)';
}

/// 설정 화면의 입력 한 벌. 참가자 이름(빈 칸 허용)과 결과 줄 목록.
class LadderSetup {
  LadderSetup({
    required List<String> players,
    required List<ResultSlot> results,
  }) : players = List.unmodifiable(players),
       results = List.unmodifiable(results);

  /// 처음 실행 기본값: 3명, 당첨 1·꽝 2. 라벨만 바꾸면 「1명·2명 나누기」가 된다.
  factory LadderSetup.initial() =>
      LadderSetup(players: const ['', '', ''], results: winLose(3));

  static const minPlayers = 2;
  static const maxPlayers = 12;

  final List<String> players;
  final List<ResultSlot> results;

  /// 화면에 쓸 이름. 빈 칸은 「1번·2번…」.
  List<String> get playerNames => [
    for (var i = 0; i < players.length; i++)
      _orDefault(players[i], '${i + 1}번'),
  ];

  /// 화면에 쓸 결과 라벨. 빈 칸은 「결과 1·결과 2…」.
  List<String> get resultLabels => [
    for (var i = 0; i < results.length; i++)
      _orDefault(results[i].label, '결과 ${i + 1}'),
  ];

  /// 결과 라벨을 개수만큼 펼친 목록. 길이 = 결과 자리 합계.
  List<String> get expandedResults {
    final labels = resultLabels;
    return [
      for (var i = 0; i < results.length; i++)
        for (var k = 0; k < results[i].count; k++) labels[i],
    ];
  }

  int get slotTotal => results.fold(0, (sum, r) => sum + r.count);

  /// 참가자 수 - 결과 자리 합계. 양수 = 남은 자리, 음수 = 넘친 자리.
  int get remaining => players.length - slotTotal;

  bool get canStart =>
      players.length >= minPlayers &&
      players.length <= maxPlayers &&
      results.isNotEmpty &&
      results.every((r) => r.count >= 1) &&
      remaining == 0;

  /// 빠른 채우기 「당첨/꽝」: 당첨 1 + 나머지 꽝.
  static List<ResultSlot> winLose(int players) => [
    const ResultSlot('당첨', 1),
    ResultSlot('꽝', players - 1),
  ];

  /// 빠른 채우기 「1등~N등」.
  static List<ResultSlot> ranks(int players) => [
    for (var i = 1; i <= players; i++) ResultSlot('$i등', 1),
  ];

  /// 빠른 채우기 「순서 1~N」.
  static List<ResultSlot> order(int players) => [
    for (var i = 1; i <= players; i++) ResultSlot('$i번째', 1),
  ];

  Map<String, Object> toJson() => {
    'players': players,
    'results': [
      for (final r in results) {'label': r.label, 'count': r.count},
    ],
  };

  /// 저장값을 되살린다. 형식이 틀리거나 범위를 벗어나면 null.
  static LadderSetup? fromJson(Object? json) {
    if (json is! Map) return null;
    final players = json['players'];
    final results = json['results'];
    if (players is! List || results is! List) return null;
    if (players.length < minPlayers || players.length > maxPlayers) return null;
    if (players.any((p) => p is! String)) return null;
    final slots = <ResultSlot>[];
    for (final r in results) {
      if (r is! Map) return null;
      final label = r['label'];
      final count = r['count'];
      if (label is! String || count is! int) return null;
      if (count < 1 || count > maxPlayers) return null;
      slots.add(ResultSlot(label, count));
    }
    if (slots.isEmpty) return null;
    return LadderSetup(players: players.cast<String>(), results: slots);
  }

  static String _orDefault(String text, String fallback) {
    final trimmed = text.trim();
    return trimmed.isEmpty ? fallback : trimmed;
  }
}
