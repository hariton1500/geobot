import 'helper.dart';

Future<void> main(List<String> arguments) async {
  String tkn = '5126470721:AAGSXjtS16F8UowAG8IwuIeJxDyzLzdhHXw';

  Telega telega = Telega(tkn: tkn);

  var res = await telega.getUpdate();
  if (res is Map) {
    if (res['ok']) {
      List<dynamic> messages = res['result'];
      for (var message in messages) {
        print('=====================getUpdate====================');
        print('update_id = ${message['update_id']}');
        dynamic mess;
        if (message.containsKey('message')) {
          mess = message['message'];
        }
        if (message.containsKey('edited_message')) {
          mess = message['edited_message'];
        }
        print(mess);
      }
    } else {
      print('result is not ok');
    }
  }
}
