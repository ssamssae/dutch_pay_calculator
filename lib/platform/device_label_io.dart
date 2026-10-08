import 'dart:io' show Platform;

String deviceLabel() =>
    '${Platform.operatingSystem} ${Platform.operatingSystemVersion}';
