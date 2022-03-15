import 'db.dart';

void main(List<String> args) {
  print(DateTime(2022, 3, 15, 8, 30));  
  DateTime todayMorningDT = DateTime(DateTime.now().year, DateTime.now().month, DateTime.now().day, 8, 30);
  int todayMorningUnix = todayMorningDT.millisecondsSinceEpoch;
  print(todayMorningUnix);
  print(Duration.millisecondsPerDay);

}