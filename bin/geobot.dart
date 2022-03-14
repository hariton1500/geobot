import 'dart:async';

import 'helper.dart';

Future<void> main(List<String> arguments) async {
  String tkn = '5126470721:AAGSXjtS16F8UowAG8IwuIeJxDyzLzdhHXw';

  Telega telega = Telega(tkn: tkn);
  Handle handle = Handle();

  Timer.periodic(Duration(milliseconds: 1000), (timer) => handle.getUpdates(telega: telega));
}
