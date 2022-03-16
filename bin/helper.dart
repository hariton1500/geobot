import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;

import 'db.dart';

class Checks {
  //[date, fromId, coords]
  void geoNotify({required Telega telega}) {
    print('Notify checks...');
    int todayStart = DateTime(DateTime.now().year, DateTime.now().month, DateTime.now().day, 8, 30).millisecondsSinceEpoch - Duration.millisecondsPerDay;
    DateTime todayEnd = DateTime(DateTime.now().year, DateTime.now().month, DateTime.now().day, 16, 30);
    //int now = DateTime.now().millisecondsSinceEpoch;
    if (DateTime.now().isBefore(todayEnd)) {
      for (var brig in brigs) {
        print('Brigada $brig:');
        for (var id in idsByBrig[brig]!) {
          print('$id(${nameById[id]}):');
          List<dynamic> result = telega.db!.where((row) => (row[0] * 1000 >= todayStart && id == row[1])).toList();
          print(result);
          if (result.isEmpty) {
            telega.sendMessage(text: '${nameById[id]}, включи геолокацию!!!', chatId: groupIdByBrig[brig]!);
          }
        }
      }
    } else {
      print('Out of work time.');
    }
  }
}
class Handle {
  Future<void> getUpdates({required Telega telega}) async {
    var res = await telega.getUpdate();
    if (res is Map) {
      if (res['ok']) {
        List<dynamic> messages = res['result'];
        //print('=====================getUpdates========[${DateTime.now()}]============');
        for (var message in messages) {
          //print(message);
          if (telega.updateId! < message['update_id']) {
            print('--------------------New message or edited message----------------------');
            print('update_id = ${message['update_id']}');
            telega.updateId = message['update_id'];
            dynamic mess;
            if (message.containsKey('message')) {
              mess = message['message'];
            }
            if (message.containsKey('edited_message')) {
              mess = message['edited_message'];
            }
            print(mess);
            parse(mess, telega);
          } else {
            print('old message... ignoring');
            telega.updateId = message['update_id'];
          }
        }
      } else {
        //print('result is not ok');
      }
    }
  }

  void parse(dynamic mess, Telega telega) {
    print('start parsing');
    if (mess is Map && mess.containsKey('location')) {
      List<double> coords = [mess['location']['latitude'], mess['location']['longitude']];
      int fromId = mess['from']['id'];
      int? date;
      if (mess.containsKey('date')) {
        date = mess['date'];
      }
      if (mess.containsKey('edit_date')) {
        date = mess['edit_date'];
      }
      telega.db!.add([date, fromId, coords]);
      File file = File('db.txt');
      file.writeAsStringSync('$date $fromId ${coords[0]} ${coords[1]}\n', mode: FileMode.append);
    }
    if (mess is Map && mess.containsKey('text')) {
      if (mess['text'].toString().startsWith('show')) {
        try {
          List command = mess['text'].toString().split(' ');
          int brig = 0, day = 0;
          if (command.length >= 2) {brig = int.parse(command[1]);}
          if (command.length >= 3) {day = int.parse(command[2]);}
          show(brig, day, telega, mess['from']['id']);
          
        } catch (e) {
          print(e);
        }
      }
      if (mess['text'].toString().startsWith('db list')) {
        print('data base:');
        for (var row in telega.db!) {
          print(row);
        }
      }
    }
  }

  void show(int brig, int day, Telega telega, int from) {
    day = day.abs();
    //get unix time today 8:30
    DateTime todayMorningDT = DateTime(DateTime.now().year, DateTime.now().month, DateTime.now().day, 8, 30);
    int todayMorningUnix = todayMorningDT.millisecondsSinceEpoch;
    int startMoment = todayMorningUnix - Duration.millisecondsPerDay * day;
    print(startMoment);
    print(DateTime.fromMillisecondsSinceEpoch(startMoment));
    if (brig > 0) {
      var result = telega.db!.where((raw) => (raw[0] * 1000 >= startMoment && idsByBrig[brig]!.contains(raw[1])));
      print('results:');
      print(result);
      String out = '';
      for (var id in idsByBrig[brig]!) {
        out = 'https://static-maps.yandex.ru/1.x/?l=map&pt=';
        print('$id[${nameById[id]}]:');
        List coords = result.where((row) => row[1] == id).map((e) => e[2]).toList();
        print(coords);
        for (var coord in coords) {
          out += '${coord[1]},${coord[0]},${coords.indexOf(coord) + 1}';
          if (coord != coords.last) {
            out += '~';
          }
        }
        //print(_url);
        out += '&pl=';
        for (var coord in coords) {
          out += '${coord[1]},${coord[0]}';
          if (coord != coords.last) {
            out += ',';
          }
        }
        telega.sendMessage(text: '[${nameById[id]}]($out)', chatId: from);
        print(out);
      }
    }
  }
}

class Telega {
  String? url;
  int? updateId;
  int? chatId;
  String? text;
  List<List>? db;

  Telega({required String tkn}) {
    url = 'https://api.telegram.org/bot$tkn/';
    updateId = 0;
    db = [];
    File file = File('db.txt');
    if (!file.existsSync()) {
      file.createSync();
    }
    file.openRead();
    for (var line in file.readAsLinesSync()) {
      List<String> separated = line.split(' ');
      db!.add([int.parse(separated[0]), int.parse(separated[1]), [double.parse(separated[2]), double.parse(separated[3])]]);      
    }
  }
  Future<dynamic> getUpdate() async {
    String _url = url! + 'getUpdates';
    if (updateId != null) {
      _url += '?offset=${updateId! + 1}';
    }
    try {
      var resp = await http.get(Uri.parse(_url));
      return jsonDecode(resp.body);
    } catch (e) {
      print(e);
    }
  }

  Future<void> sendMessage({required String text, required int chatId}) async {
    String _url = url! + 'sendMessage?chat_id=$chatId&text=$text&parse_mode=markdown';
    try {
      http.get(Uri.parse(_url));
    } catch (e) {
      print(e);
    }
  }
}
