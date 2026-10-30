import 'dart:async';

import 'package:flutter/material.dart';

import '../../theme/app_theme.dart';
import '../../widgets/mini_app_scaffold.dart';
import '../../widgets/toss_widgets.dart';
import 'team_controller.dart';

/// 팀 나누기 미니앱. 결과 카드 · 팀 수 · 사람 이름 순서로 놓는다.
class TeamScreen extends StatefulWidget {
  const TeamScreen({super.key, required this.controller});

  final TeamController controller;

  @override
  State<TeamScreen> createState() => _TeamScreenState();
}

class _TeamScreenState extends State<TeamScreen> {
  /// 연타로 결과가 두 번 바뀌지 않게 막는 시간.
  static const _splitCooldown = Duration(milliseconds: 500);

  final _fields = <TextEditingController>[];
  Timer? _splitLock;

  TeamController get _controller => widget.controller;

  @override
  void initState() {
    super.initState();
    _syncFields();
    _controller.addListener(_syncFields);
  }

  @override
  void didUpdateWidget(TeamScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller == widget.controller) return;
    oldWidget.controller.removeListener(_syncFields);
    _controller.addListener(_syncFields);
    _syncFields();
  }

  @override
  void dispose() {
    _splitLock?.cancel();
    _controller.removeListener(_syncFields);
    for (final field in _fields) {
      field.dispose();
    }
    super.dispose();
  }

  /// 이름 칸 개수와 글자를 [TeamController.names] 와 맞춘다.
  void _syncFields() {
    final names = _controller.names;
    while (_fields.length < names.length) {
      _fields.add(TextEditingController(text: names[_fields.length]));
    }
    if (_fields.length > names.length) {
      _disposeLater(_fields.sublist(names.length));
      _fields.removeRange(names.length, _fields.length);
    }
    for (var i = 0; i < names.length; i++) {
      if (_fields[i].text != names[i]) _fields[i].text = names[i];
    }
  }

  /// 지운 칸의 컨트롤러는 그 칸이 화면에서 빠진 다음 프레임에 정리한다.
  void _disposeLater(List<TextEditingController> controllers) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      for (final controller in controllers) {
        controller.dispose();
      }
    });
  }

  void _removePerson(int index) {
    if (_controller.names.length <= TeamController.minPeople) return;
    _disposeLater([_fields.removeAt(index)]);
    _controller.removePerson(index);
  }

  void _split() {
    if (_splitLock?.isActive ?? false) return;
    _splitLock = Timer(_splitCooldown, () {});
    FocusScope.of(context).unfocus();
    _controller.split();
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _controller,
      builder: (context, _) {
        final teams = _controller.teams;
        final people = _controller.names.length;
        return MiniAppScaffold(
          title: '팀 나누기',
          subtitle: '무작위로 공평하게 팀을 나눠요',
          body: ListView(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
            children: [
              if (teams != null)
                for (var t = 0; t < teams.length; t++)
                  _TeamCard(index: t, members: teams[t]),
              TossCard(
                child: TossSectionHeader(
                  title: '팀 수',
                  action: TossCountStepper(
                    id: 'teams',
                    value: _controller.teamCount,
                    min: TeamController.minTeams,
                    max: people < TeamController.maxTeams
                        ? people
                        : TeamController.maxTeams,
                    onChanged: _controller.setTeamCount,
                    format: (v) => '$v팀',
                    decreaseTooltip: '팀 줄이기',
                    increaseTooltip: '팀 늘리기',
                  ),
                ),
              ),
              TossCard(
                child: Column(
                  children: [
                    TossSectionHeader(
                      title: '사람 $people명',
                      action: TextButton.icon(
                        key: const ValueKey('person-add'),
                        style: TextButton.styleFrom(
                          foregroundColor: TossColors.accent,
                          disabledForegroundColor: TossColors.textQuaternary,
                        ),
                        onPressed: people < TeamController.maxPeople
                            ? _controller.addPerson
                            : null,
                        icon: const Icon(Icons.person_add_alt_1),
                        label: const Text('추가'),
                      ),
                    ),
                    for (var i = 0; i < people; i++)
                      Padding(
                        key: ObjectKey(_fields[i]),
                        padding: const EdgeInsets.only(bottom: 4),
                        child: Row(
                          children: [
                            Expanded(
                              child: TossNameField(
                                fieldKey: ValueKey('person-$i'),
                                controller: _fields[i],
                                hint: '${i + 1}번',
                                maxLength: 20,
                                onChanged: (text) =>
                                    _controller.renamePerson(i, text),
                              ),
                            ),
                            IconButton(
                              key: ValueKey('person-remove-$i'),
                              tooltip: '${i + 1}번 빼기',
                              onPressed: people > TeamController.minPeople
                                  ? () => _removePerson(i)
                                  : null,
                              icon: Icon(
                                Icons.remove_circle_outline,
                                color: people > TeamController.minPeople
                                    ? TossColors.textSecondary
                                    : TossColors.textQuaternary,
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
          bottom: TossBottomButton(
            buttonKey: const ValueKey('split'),
            label: teams == null ? '나누기' : '다시 나누기',
            icon: Icons.shuffle_rounded,
            onPressed: _split,
          ),
        );
      },
    );
  }
}

/// 한 팀 결과: 제목 · 인원 · 이름 알약.
class _TeamCard extends StatelessWidget {
  const _TeamCard({required this.index, required this.members});

  final int index;
  final List<String> members;

  @override
  Widget build(BuildContext context) {
    return TossCard(
      cardKey: ValueKey('team-$index'),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(0, 12, 12, 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TossSectionHeader(
              title: '${index + 1}팀',
              action: Text(
                '${members.length}명',
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: TossColors.textFaint,
                ),
              ),
            ),
            const SizedBox(height: 4),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                for (final name in members)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: TossColors.accentSoft,
                      borderRadius: BorderRadius.circular(999),
                      border: Border.all(color: TossColors.accentBorder),
                    ),
                    child: Text(
                      name,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: TossColors.textPrimary,
                      ),
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
