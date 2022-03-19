import 'dart:async';
import 'dart:io';
import 'db.dart';
import 'helper.dart';

Future<void> main(List<String> arguments) async {
  String tkn;// = arguments[0].toString();
  File tknFile = File('tkn.txt');
  //tknFile.openRead();
  tkn = tknFile.readAsStringSync();
  print(tkn);

  Telega telega = Telega(tkn: tkn);
  Handle handle = Handle();
  Checks checks = Checks();

  bool checkTimeAt({required int h, required int m}) {
    DateTime now = DateTime.now();
    return (now.hour == h && now.minute == m);
  }
  Timer.periodic(Duration(seconds: 2), (timer) => handle.getUpdates(telega: telega));
  
  Timer(Duration(seconds: 10), () => checks.geoNotify(telega: telega));
  Timer.periodic(Duration(minutes: 60), (timer) => checks.geoNotify(telega: telega));
  Timer.periodic(Duration(minutes: 1), (timer) {
    //this periodic is for creating reports
    try {
      for (var brig in brigs) {
        if (checkTimeAt(h: 8, m: 1 + brig)) {
          telega.sendMessage(text: 'Отчет по вчерашнему движению бригады № $brig', chatId: groupIdByBrig[0]!);
          handle.show(brig, 1, telega, groupIdByBrig[0]!);
        }
      }
    } catch (e) {
      print(e);
    }
  });
}
