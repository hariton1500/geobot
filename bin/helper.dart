import 'dart:convert';
import 'package:http/http.dart' as http;

class Handle {
  
}

class Telega {
  String? url;
  int? updateId;
  int? chatId;
  String? text;

  Telega({required String tkn}) {
    url = 'https://api.telegram.org/bot$tkn/';
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