import 'dart:async';
import 'dart:io';
import 'db.dart';
import 'helper.dart';

Future<void> main(List<String> arguments) async {

  const int keepInMemoryDays = 8;

  String tkn;// = arguments[0].toString();
  File tknFile = File('tkn.txt');
  tkn = tknFile.readAsStringSync();
  print('token is $tkn');

  Telega telega = Telega(tkn: tkn);
  Handle handle = Handle();
  Checks checks = Checks();

  bool checkTimeAt({required int h, required int m}) {
    DateTime now = DateTime.now();
    return (now.hour == h && now.minute == m);
  }
  Timer.periodic(Duration(seconds: 2), (timer) => handle.getUpdates(telega: telega));
  Timer.periodic(Duration(days: 1), (timer) => telega.cleanOldData(beforeDays: keepInMemoryDays));
  Timer(Duration(seconds: 600), () => checks.geoNotify(telega: telega));
  Timer.periodic(Duration(minutes: 60), (timer) => checks.geoNotify(telega: telega));
  Timer.periodic(Duration(minutes: 1), (timer) {
    //this periodic is for creating reports
    try {
      for (var brig in brigs) {
        if (checkTimeAt(h: 8, m: 4 + brig)) {
          telega.sendMessage(text: 'Отчет по вчерашнему движению бригады № $brig', chatId: groupIdByBrig[brig]!);
          handle.show(brig, 1, telega, groupIdByBrig[brig]!);
        }
      }
    } catch (e) {
      print(e);
    }
    if (checkTimeAt(h: 8, m: 1)) {
      telega.getWorkings();
    }
  });
}
