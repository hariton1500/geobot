import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
void main(List<String> args) {
  var res = http.get(Uri.parse('http://billing.evpanet.com/api/active_workers.php'));
  res.then((answer) {
    List<int>? workingIds;
    var _workingIds = jsonDecode(answer.body);
    if (_workingIds is List) {workingIds = _workingIds.map((e) => int.parse(e)).toList();}
    print(workingIds);
    print(workingIds.runtimeType);
    print(workingIds![0].runtimeType);
  });
}