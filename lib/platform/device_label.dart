// 피드백 메일에 넣을 기기 문자열. 웹은 dart:io 가 없으므로 조건부 import 로 분기한다.
export 'device_label_stub.dart' if (dart.library.io) 'device_label_io.dart';
