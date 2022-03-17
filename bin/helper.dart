import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;

import 'db.dart';

class Checks {
  //[date, fromId, coords]
  void geoNotify({required Telega telega}) {
    print('Notify checks...[${DateTime.now()}]');
    int todayStart = DateTime(DateTime.now().year, DateTime.now().month, DateTime.now().day, 8, 30).millisecondsSinceEpoch - Duration.millisecondsPerDay;
    DateTime morning = DateTime(DateTime.now().year, DateTime.now().month, DateTime.now().day, 8, 30);
    DateTime todayEnd = DateTime(DateTime.now().year, DateTime.now().month, DateTime.now().day, 16, 30);
    //int now = DateTime.now().millisecondsSinceEpoch;
    if (DateTime.now().isBefore(todayEnd) && DateTime.now().isAfter(morning)) {
      for (var brig in brigs) {
        print('Brigada $brig:');
        for (var id in idsByBrig[brig]!) {
          print('$id(${nameById[id]}):');
          //List<dynamic> result = telega.db!.where((row) => (row[0] * 1000 >= todayStart && id == row[1])).toList();
          //print(result);
          if ((DateTime.now().millisecondsSinceEpoch - telega.lastTimeSavedData![id]! * 1000) >= Duration.millisecondsPerMinute * 30) {
            print('${nameById[id]} is not posting geo data longer then 30 min');
            //telega.sendMessage(text: '${nameById[id]}, включи геолокацию!!!', chatId: groupIdByBrig[brig]!);
            print('${nameById[id]}, включи геолокацию!!!');
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
            print('--------------------New message or edited message----[${DateTime.now()}]------------------');
            //print('update_id = ${message['update_id']}');
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
      if (date! * 1000 - telega.lastTimeSavedData![fromId]! * 1000 >= Duration.millisecondsPerMinute * 15) {
        telega.db!.add([date, fromId, coords]);
        File file = File('db.txt');
        file.writeAsStringSync('$date $fromId ${coords[0]} ${coords[1]}\n', mode: FileMode.append);
        telega.lastTimeSavedData![fromId] = date;
        print('saved to db');
      } else {
        print((date * 1000 - telega.lastTimeSavedData![fromId]! * 1000) / 1000 / 60);
      }
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
      if (mess.containsKey('chat') && mess['chat']['type'] == 'private') {
        telega.sendMessageMenu(text: 'Меню:', chatId: mess['from']['id'], menu: [[{'text': 'show 1'}, {'text': 'show 1 1'}], [{'text': 'show 3'}, {'text': 'show 3 1'}]]);
      }
    }
  }

  Future<void> show(int brig, int day, Telega telega, int from) async {
    day = day.abs();
    //get unix time today 8:30
    DateTime todayMorningDT = DateTime(DateTime.now().year, DateTime.now().month, DateTime.now().day, 8, 30);
    int todayMorningUnix = todayMorningDT.millisecondsSinceEpoch;
    int startMoment = todayMorningUnix - Duration.millisecondsPerDay * day;
    print(startMoment);
    print(DateTime.fromMillisecondsSinceEpoch(startMoment));
    if (brig > 0 && idsByBrig.containsKey(brig)) {
      //var result = telega.db!.where((raw) => (raw[0] * 1000 >= startMoment && idsByBrig[brig]!.contains(raw[1])));
      print('results:');
      //print(result);
      String out = '';
      for (var id in idsByBrig[brig]!) {
        print('$id[${nameById[id]}]:');
        List oneIdAndTimeFiltered = telega.db!.where((row) => (row[1] == id && row[0] * 1000 >= startMoment && row[0] * 1000 <= startMoment + Duration.millisecondsPerDay)).toList();
        print('for $id filtered ${oneIdAndTimeFiltered.length} rows');
        if (oneIdAndTimeFiltered.isNotEmpty) {
          List _db = [];
          int tmp = oneIdAndTimeFiltered[0][0];
          _db.add(oneIdAndTimeFiltered[0]);
          for (var i = 1; i < oneIdAndTimeFiltered.length; i++) {
            List _row = oneIdAndTimeFiltered[i];
            if ((_row[0] * 1000 - tmp * 1000) > Duration.millisecondsPerMinute * 10) {
              _db.add(_row);
              tmp = _row[0];
            }
          }
          print('and rows with 10 min interval is ${_db.length}');
          String data = '';
          for (var row in _db) {
            data += '${row[0].toString()},${row[2][0].toString()},${row[2][1].toString()};'; 
          }
          data = data.substring(0,data.length - 1);
          print(data);
          var res = await http.post(Uri.parse('http://evpanet.lebedinets.ru/geobot/gen.php'), body: {'data': data});
          print(res.body);
          /*
          out = 'https://static-maps.yandex.ru/1.x/?l=map%26pt=';
          List coords = _db.where((row) => row[1] == id).map((e) => e[2]).toList();
          //print(coords.length);
          for (var coord in coords) {
            out += '${coord[1]},${coord[0]},${coords.indexOf(coord) + 1}';
            if (coord != coords.last) {
              out += '~';
            }
          }
          //print(_url);
          out += '%26pl=';
          for (var coord in coords) {
            out += '${coord[1]},${coord[0]}';
            if (coord != coords.last) {
              out += ',';
            }
          }
          */
          try {
            var answer = jsonDecode(res.body);
            telega.sendMessage(text: nameById[id].toString(), chatId: from);
            telega.sendMessageUrl(text: '${answer['map']['url']}', chatId: from);
            //telega.sendMessage(text: answer['map']['url'], chatId: from);
          } catch (e) {
            print(e);
          }
          
          //print(out);
        }
      }
    } else {
      print('show all');
      for (var brigade in brigs) {
        show(brigade, 1, telega, from);
        sleep(Duration(seconds: 3));
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
  Map<int, int>? lastTimeSavedData;

  Telega({required String tkn}) {
    url = 'https://api.telegram.org/bot$tkn/';
    updateId = 0;
    db = [];
    lastTimeSavedData = {};
    File file = File('db.txt');
    if (!file.existsSync()) {
      file.createSync();
    }
    //file.openRead();
    int count = 0;
    for (var line in file.readAsLinesSync()) {
      List<String> separated = line.split(' ');
      db!.add([int.parse(separated[0]), int.parse(separated[1]), [double.parse(separated[2]), double.parse(separated[3])]]);
      lastTimeSavedData![db!.last[1]] = db!.last[0];
      count++;
    }
    print('read $count rows from DB file');
    print('Last saved data:');
    for (var id in nameById.keys) {
      print('[$id] ${nameById[id]}: ${DateTime.fromMillisecondsSinceEpoch(lastTimeSavedData![id]! * 1000)}');
    }
    print('checking bot API...');
    var res = http.get(Uri.parse('$url/getMe'));
    res.then((value) => print(value.body));
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
