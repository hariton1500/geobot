import 'dart:convert';
import 'package:http/http.dart' as http;

import 'db.dart';

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
            //parse(mess);
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
    };
    if (mess is Map && mess.containsKey('text')) {
      if (mess['text'].toString().startsWith('show')) {
        List command = mess['text'].toString().split(' ');
        int brig = command[1] ?? 0;
        int day = command[2] ?? 0;
        show(brig, day, telega);
      }
    }
  }

  void show(int brig, int day, Telega telega) {
    day = day.abs();
    
    if (brig > 0) {
      telega.db.takeWhile((value) => (value[]))
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
}