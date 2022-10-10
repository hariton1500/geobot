import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;

import 'db.dart';

class Checks {
  //[date, fromId, coords]
  void geoNotify({required Telega telega}) {
    try {
      print('Nnnnnnoooooooottttttiiiiiiffffffyyyyyyy checks...[${DateTime.now()}]');
      DateTime periodStart = Handle().todayAt(8, 30);
      DateTime periodEnd = Handle().todayAt(16, 30);
      print('period of today working time is from $periodStart till $periodEnd');
      if (!(DateTime.now().isAfter((periodStart.add(Duration(minutes: 20)))) && DateTime.now().isBefore(periodEnd))) {
        print('out of working time.');
      } else {
        print('it is time to check...');
        for (var brig in brigs) {
          for (var id in idsByBrig[brig]!) {
            List<dynamic> lastRowOfId = telega.db!.lastWhere((row) => row[1] == id);
            DateTime lastTimeOfId = DateTime.fromMillisecondsSinceEpoch(lastRowOfId[0] * 1000);
            print('last time of id $id[${nameById[id]}] was at $lastTimeOfId');
            Duration difference = DateTime.now().difference(lastTimeOfId);
            print('diff is ${difference.inMinutes} min');
            if (difference.inMinutes >= 60 && telega.workingIds!.contains(id)) {
                print('${nameById[id]}, включи геолокацию!!! Данные не поступают ${difference.inMinutes} минут');
                telega.sendMessage(text: '${nameById[id]}, включи геолокацию!!! Данные не поступают ${difference.inMinutes} минут', chatId: groupIdByBrig[brig]!);
            }
          }
        }
      }
    } catch (e) {
      print(e);
    }
  }
}
class Handle {
  static const storePeriodGeo = 7;
  Future<void> getUpdates({required Telega telega}) async {
    var res = await telega.getUpdate();
    if (res is Map) {
      if (res['ok']) {
        List<dynamic> messages = res['result'];
        //print('=====================getUpdates========[${DateTime.now()}]============');
        for (var message in messages) {
          //print(message);
          if (telega.updateId! < message['update_id']) {
            print('[${DateTime.now()}]---New message or edited message---');
            //print('update_id = ${message['update_id']}');
            telega.updateId = message['update_id'];
            dynamic mess;
            if (message.containsKey('message')) {
              mess = message['message'];
            }
            if (message.containsKey('edited_message')) {
              mess = message['edited_message'];
            }
            //print(mess);
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
    print('parse:');
    if (mess is Map && mess.containsKey('location')) {
      List<double> coords = [mess['location']['latitude'], mess['location']['longitude']];
      int fromId = mess['from']['id'];
      int date = 0;
      if (mess.containsKey('date')) {
        date = mess['date'];
      }
      if (mess.containsKey('edit_date')) {
        date = mess['edit_date'];
      }
      if (date * 1000 - ((telega.lastTimeSavedData ?? {fromId : 0})[fromId] ?? 0) * 1000 >= Duration.millisecondsPerMinute * storePeriodGeo) {
        telega.db!.add([date, fromId, coords]);
        File file = File('db.txt');
        file.writeAsStringSync('$date $fromId ${coords[0]} ${coords[1]}\n', mode: FileMode.append);
        //10001
        try {
          print('copying to geobot.php: ${{'date': date.toString(), 'id': fromId.toString(), 'location': coords.toString()}}');
          http.post(Uri.parse('https://billing.evpanet.com/api/geobot.php'), body: {'date': date.toString(), 'id': fromId.toString(), 'location': coords.toString()}).then((value) => print(value.statusCode));
        } catch (e) {
          print('10001' + e.toString());
        }
        telega.lastTimeSavedData![fromId] = date;
        print('From $fromId[${nameById[fromId]}] saving to db');
      } else {
        print('From $fromId[${nameById[fromId]}] past only ${(date * 1000 - telega.lastTimeSavedData![fromId]! * 1000) / 1000 ~/ 60} minutes');
      }
    }
    if (mess is Map && mess.containsKey('text')) {
      print(mess);
      if (mess['text'].toString().startsWith('show')) {
        //10002
        try {
          List command = mess['text'].toString().split(' ');
          int brig = 0, day = 0;
          if (command.length >= 2) {brig = int.parse(command[1]);}
          if (command.length >= 3) {day = int.parse(command[2]);}
          show(brig, day, telega, mess['from']['id']);
          
        } catch (e) {
          print('10002:' + e.toString());
        }
      }
      if (mess['text'].toString().startsWith('db list')) {
        print('data base:');
        for (var row in telega.db!) {
          print(row);
        }
      }
      if (mess.containsKey('chat') && mess['chat']['type'] == 'private') {
        //telega.sendMessageMenu(text: 'Меню:', chatId: mess['from']['id'], menu: [[{'text': 'show 1'}, {'text': 'show 1 1'}], [{'text': 'show 3'}, {'text': 'show 3 1'}]]);
      }
    }
  }

  DateTime todayAt(int h, int m) {
    if (h >= 0 && h <= 23 && m >= 0 && m <= 59) {
      return DateTime(DateTime.now().year, DateTime.now().month, DateTime.now().day, h, m);
    } else {
      return DateTime.now();
    }
    
  }
  Future<void> show(int brig, int pastDays, Telega telega, int from) async {
    print('sssssssssssssssssssshhhhhhhhhhhhhhhhhhooooooooooooooooowwwwwwwwwwwwwwwwww');
    pastDays = pastDays.abs();
    print('check parameters...');
    if (brigs.contains(brig) && pastDays <= 7) {
      print('ok. continue.');
      print('show geo moves for brigade $brig for period of past days $pastDays');
      DateTime periodStart = todayAt(8, 30).subtract(Duration(days: pastDays));
      DateTime periodEnd = todayAt(16, 30).subtract(Duration(days: pastDays));
      print('period from $periodStart to $periodEnd');
      if (brig > 0) {
        try {
          print('selecting for period:');
          List<List<dynamic>> selected = telega.db!.where((row) => DateTime.fromMillisecondsSinceEpoch(row[0] * 1000).isAfter(periodStart) && DateTime.fromMillisecondsSinceEpoch(row[0] * 1000).isBefore(periodEnd)).toList();
          print('from ${telega.db!.length} rows selected ${selected.length} rows.');
          print('selecting ids:');
          selected.removeWhere((row) => !idsByBrig[brig]!.contains(row[1]));
          print('${selected.length} selected.');
          List<Map<String, dynamic>> requestData = [];
          for (var id in idsByBrig[brig]!) {
            requestData.add({'name': '${nameById[id]}', 'data': selected.where((row) => row[1] == id).map<List>((e) => [e[0], e[2][0], e[2][1]]).toList()});
          }
          //print(jsonEncode(requestData));
          try {
            var res = await http.post(Uri.parse('http://evpanet.lebedinets.ru/geobot/gen.php'), body: jsonEncode(requestData));
            print(res.body);
            var answer = jsonDecode(res.body);
            telega.sendMessageUrl(text: '${answer['map']['url']}', chatId: from);
          } catch (e) {
            print(e);
          }
        } catch (e) {
          print(e);
        }
      }
    } else {
      print('not correct. ignoring.');
    }
  }

}

class Telega {
  String? url;
  int? updateId;
  int? chatId;
  String? text;
  List<List>? db;
  Map<int, int>? lastTimeSavedData;
  List<int>? workingIds;

  Telega({required String tkn}) {
    url = 'https://api.telegram.org/bot$tkn/';
    updateId = 0;
    db = [];
    lastTimeSavedData = {};
    try {
      File file = File('db.txt');
      if (!file.existsSync()) {
        file.createSync();
      }
      int count = 0;
      for (var line in file.readAsLinesSync()) {
        List<String> separated = line.split(' ');
        db!.add([int.parse(separated[0]), int.parse(separated[1]), [double.parse(separated[2]), double.parse(separated[3])]]);
        lastTimeSavedData![db!.last[1]] = db!.last[0];
        count++;
      }
      print('read $count rows from DB file');
    } catch (e) {
      print(e);
    }
    print('Last saved data:');
    for (var id in nameById.keys) {
      print('[$id] ${nameById[id]}: ${DateTime.fromMillisecondsSinceEpoch(lastTimeSavedData![id]?? 0 * 1000)}');
    }
    print('checking bot API...');
    try {
      var res = http.get(Uri.parse(url! + 'getMe'));
      res.then((value) => print('my name is ${jsonDecode(value.body)['result']['first_name']}'));
    } catch (e) {
      print(e);
      exit(0);
    }
    try {
      getWorkings();
    } catch (e) {
      print(e);
    }
  }

  void cleanOldData({required int beforeDays}) {
    try {
      db!.removeWhere((row) => DateTime.fromMillisecondsSinceEpoch(row[0] * 1000).isBefore(DateTime.now().subtract(Duration(days: beforeDays))));
    } catch (e) {
      print(e);
    }
  }

  void getWorkings() {
    try {
      print('getting workings...');
      var res = http.get(Uri.parse('http://billing.evpanet.com/api/active_workers.php'));
      res.then((answer) {
        var _unknown = jsonDecode(answer.body);
        if (_unknown is List) {
          workingIds = _unknown.map((e) => int.parse(e)).toList();
          print(workingIds!.map((id) => {id: nameById[id]}).toList());
        }
      });
    } catch (e) {
      print(e);
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
  Future<void> sendMessageUrl({required String text, required int chatId}) async {
    String _url = url! + 'sendMessage';
    try {
      http.post(Uri.parse(_url), body: {'chat_id': chatId.toString(), 'text': text, 'entities': [{'offset': 0, 'length': 46, 'type': 'url'}].toString()});
    } catch (e) {
      print(e);
    }
  }

  Future<void> sendMessageMenu({required String text, required int chatId, required List<List<Map<String, String>>> menu}) async {
    print('sending menu:');
    print(menu.toString());
    String _url = url! + 'sendMessage';
    try {
      /*
      List<List<Map<String, String>>> inlineKeyboardButtons = [[{}]];
      for (var row in menu) {
        List<Map<String, String>> rowButtons = [{}];
        for (var button in row) {
          rowButtons.add({'text': button});
        }
        inlineKeyboardButtons.add(rowButtons);
      }
      */
      //print(inlineKeyboardButtons.toString());
      http.post(Uri.parse(_url), body: {'chat_id': chatId.toString(), 'text': text, 'reply_markup': {'keyboard': menu}.toString()}).then((value) => print(value.body));
    } catch (e) {
      print(e);
    }
  }


}
