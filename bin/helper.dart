import 'dart:convert';
import 'package:http/http.dart' as http;

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
}

class Telega {
  String? url;
  int? updateId;
  int? chatId;
  String? text;

  Telega({required String tkn}) {
    url = 'https://api.telegram.org/bot$tkn/';
    updateId = 0;
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