import 'dart:io';
void main(List<String> args) {
  List db = [];
  File file = File('db.txt');
  if (!file.existsSync()) {
    file.createSync();
  }
  //file.openRead();
  int count = 0;
  for (var line in file.readAsLinesSync()) {
    List<String> separated = line.split(' ');
    db.add([int.parse(separated[0]), int.parse(separated[1]), [double.parse(separated[2]), double.parse(separated[3])]]);
    count++;
  }
  print('read $count rows from DB file');
  List _db = [];//db.where((row) => (row[1] == 1370022113 )).toList();
  List oneIdFiltered = db.where((element) => element[1] == 1370022113).toList();
  int tmp = oneIdFiltered[0][0];
  _db.add(db[0]);
  for (var i = 1; i < oneIdFiltered.length; i++) {
    List row = oneIdFiltered[i];
    if ((row[0] * 1000 - tmp * 1000) > Duration.millisecondsPerMinute * 5) {
      _db.add(row);
      tmp = row[0];
    }
  }
  print(_db);
  print(_db.length);
}