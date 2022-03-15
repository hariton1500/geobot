import 'dart:convert';
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
          List<dynamic> result = telega.db!.where((row) => (row[0] >= todayStart && id == row[1])).toList();
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
        print('=====================getUpdates========[${DateTime.now()}]============');
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
    }
    if (mess is Map && mess.containsKey('text')) {
      if (mess['text'].toString().startsWith('show')) {
        List command = mess['text'].toString().split(' ');
        int brig = 0, day = 0;
        if (command.length > 1) {brig = command[1];}
        if (command.length > 2) {day = command[2];}
        show(brig, day, telega);
      }
      if (mess['text'].toString().startsWith('db list')) {
        print('data base:');
        for (var row in telega.db!) {
          print(row);
        }
      }
    }
  }

  void show(int brig, int day, Telega telega) {
    day = day.abs();
    //get unix time today 8:30
    DateTime todayMorningDT = DateTime(DateTime.now().year, DateTime.now().month, DateTime.now().day, 8, 30);
    int todayMorningUnix = todayMorningDT.millisecondsSinceEpoch;
    int startMoment = todayMorningUnix - Duration.millisecondsPerDay;
    if (brig > 0) {
      var result = telega.db!.where((value) => (value[0] >= startMoment && idsByBrig[brig]!.contains(value[1])));
      print('results:');
      print(result);
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
    String _url = url! + 'sendMessage?chat_id=$chatId&text=$text';
    try {
      http.get(Uri.parse(_url));
    } catch (e) {
      print(e);
    }
  }
}