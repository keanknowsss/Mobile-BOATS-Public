import 'package:intl/intl.dart';

String getDay(final day, String format) {
  DateTime time = DateTime.fromMillisecondsSinceEpoch(day * 1000);
  final convertedDay = DateFormat(format).format(time);
  return convertedDay;
}
