import 'package:intl/intl.dart';

/// Utility class for handling Indian Standard Time (IST) operations
class ISTTimeUtil {
  // IST is UTC+5:30
  static const Duration _istOffset = Duration(hours: 5, minutes: 30);

  /// Convert any DateTime to IST
  static DateTime toIST(DateTime dateTime) {
    if (dateTime.isUtc) {
      return dateTime.add(_istOffset);
    }

    // If timezone is not specified, assume it's UTC from server
    return DateTime.utc(
      dateTime.year,
      dateTime.month,
      dateTime.day,
      dateTime.hour,
      dateTime.minute,
      dateTime.second,
      dateTime.millisecond,
    ).add(_istOffset);
  }

  /// Get current IST time
  static DateTime nowIST() {
    return DateTime.now().toUtc().add(_istOffset);
  }

  /// Format DateTime for WhatsApp-style message display in IST
  static String formatMessageTime(DateTime dateTime) {
    final istTime = toIST(dateTime);
    final nowIST = ISTTimeUtil.nowIST();
    final todayIST = DateTime(nowIST.year, nowIST.month, nowIST.day);
    final messageDate = DateTime(istTime.year, istTime.month, istTime.day);

    final timeFormat = DateFormat('hh:mm a'); // 12-hour format with AM/PM
    final formattedTime = timeFormat.format(istTime);

    if (messageDate == todayIST) {
      // Today - show only time
      return formattedTime;
    } else if (messageDate == todayIST.subtract(const Duration(days: 1))) {
      // Yesterday - show "Yesterday" with time
      return 'Yesterday, $formattedTime';
    } else if (nowIST.difference(istTime).inDays < 7) {
      // This week - show day name with date and time
      final dayFormat = DateFormat('EEEE'); // Full day name
      final dateFormat = DateFormat('dd MMM'); // Day and month
      return '${dayFormat.format(istTime)}, ${dateFormat.format(istTime)} at $formattedTime';
    } else if (istTime.year == nowIST.year) {
      // This year - show date with day and time
      final dateFormat = DateFormat('EEEE, dd MMM'); // Day, date and month
      return '${dateFormat.format(istTime)} at $formattedTime';
    } else {
      // Previous years - show full date with day and time
      final dateFormat = DateFormat('EEEE, dd MMM yyyy'); // Full date with day
      return '${dateFormat.format(istTime)} at $formattedTime';
    }
  }

  /// Format DateTime for detailed timestamp display
  static String formatDetailedTime(DateTime dateTime) {
    final istTime = toIST(dateTime);
    final dateFormat = DateFormat('EEEE, dd MMMM yyyy \'at\' hh:mm a');
    return '${dateFormat.format(istTime)} IST';
  }

  /// Get timezone abbreviation for display
  static String get timezoneAbbr => 'IST';

  /// Get timezone name for display
  static String get timezoneName => 'Indian Standard Time';

  /// Format date header for chat like WhatsApp
  static String formatDateHeader(DateTime dateTime) {
    final istTime = toIST(dateTime);
    final nowIST = ISTTimeUtil.nowIST();
    final todayIST = DateTime(nowIST.year, nowIST.month, nowIST.day);
    final messageDate = DateTime(istTime.year, istTime.month, istTime.day);

    if (messageDate == todayIST) {
      return 'Today';
    } else if (messageDate == todayIST.subtract(const Duration(days: 1))) {
      return 'Yesterday';
    } else if (nowIST.difference(istTime).inDays < 7) {
      // This week - show day name
      return DateFormat('EEEE').format(istTime); // Monday, Tuesday, etc.
    } else if (istTime.year == nowIST.year) {
      // This year - show day, date and month
      return DateFormat('EEEE, dd MMMM').format(istTime); // Monday, 15 January
    } else {
      // Previous years - show day, date, month and year
      return DateFormat(
        'EEEE, dd MMMM yyyy',
      ).format(istTime); // Monday, 15 January 2023
    }
  }

  /// Check if two dates are on different days (for date header logic)
  static bool isDifferentDay(DateTime date1, DateTime date2) {
    final istDate1 = toIST(date1);
    final istDate2 = toIST(date2);

    return istDate1.year != istDate2.year ||
        istDate1.month != istDate2.month ||
        istDate1.day != istDate2.day;
  }
}
