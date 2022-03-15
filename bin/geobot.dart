import 'dart:async';

import 'helper.dart';

Future<void> main(List<String> arguments) async {
  String tkn = arguments[0].toString();

  Telega telega = Telega(tkn: tkn);
  Handle handle = Handle();
  Checks checks = Checks();

  Timer.periodic(Duration(seconds: 2), (timer) => handle.getUpdates(telega: telega));
  
  Timer(Duration(seconds: 10), () => checks.geoNotify(telega: telega));
  Timer.periodic(Duration(minutes: 30), (timer) => checks.geoNotify(telega: telega));
}
