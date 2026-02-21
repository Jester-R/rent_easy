import 'package:intl/intl.dart';

class AppDateUtils {
  static String pretty(DateTime value) {
    return DateFormat('dd MMM yyyy, hh:mm a').format(value);
  }
}
