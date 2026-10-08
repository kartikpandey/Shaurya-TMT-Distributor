import 'package:intl/intl.dart';

class AppFormatters {
  // ---- IST ----
  // Every time in the app is Indian Standard Time, whatever the phone's
  // time zone. IST values are held as plain (non-UTC) wall-clock DateTimes.

  static const Duration istOffset = Duration(hours: 5, minutes: 30);

  /// Current date and time in IST
  static DateTime nowIst() => _istWallClock(DateTime.now().toUtc());

  /// Parse a backend timestamp as IST. Values with a UTC marker or offset
  /// are converted; values without one are already IST and kept as-is.
  static DateTime? parseIst(String? value) {
    if (value == null) return null;
    final parsed = DateTime.tryParse(value.trim());
    if (parsed == null) return null;
    return parsed.isUtc ? _istWallClock(parsed) : parsed;
  }

  static DateTime _istWallClock(DateTime utc) {
    final t = utc.add(istOffset);
    return DateTime(
      t.year,
      t.month,
      t.day,
      t.hour,
      t.minute,
      t.second,
      t.millisecond,
      t.microsecond,
    );
  }

  /// Format currency (Indian Rupees)
  static String formatCurrency(double amount) {
    final formatter = NumberFormat.currency(
      locale: 'en_IN',
      symbol: '₹',
      decimalDigits: 2,
    );
    return formatter.format(amount);
  }

  /// Format number with commas
  static String formatNumber(num number) {
    final formatter = NumberFormat('#,##,##0.00', 'en_IN');
    return formatter.format(number);
  }

  /// Format large numbers (e.g., 1000 -> 1K)
  static String formatCompactNumber(num number) {
    if (number >= 1000000) {
      return '${(number / 1000000).toStringAsFixed(1)}M';
    } else if (number >= 1000) {
      return '${(number / 1000).toStringAsFixed(1)}K';
    }
    return number.toString();
  }

  /// Format date to readable format
  static String formatDate(DateTime date, [String format = 'dd MMM, yyyy']) {
    return DateFormat(format).format(date);
  }

  /// Format time
  static String formatTime(DateTime dateTime) {
    return DateFormat('hh:mm a').format(dateTime);
  }

  /// Format date and time
  static String formatDateTime(DateTime dateTime) {
    return DateFormat('dd MMM, yyyy hh:mm a').format(dateTime);
  }

  /// Format relative time (e.g., "2 hours ago")
  static String formatRelativeTime(DateTime dateTime) {
    final now = nowIst();
    final difference = now.difference(dateTime);

    if (difference.inSeconds < 60) {
      return 'Just now';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d ago';
    } else {
      return formatDate(dateTime);
    }
  }

  /// Capitalize first letter
  static String capitalize(String text) {
    if (text.isEmpty) return text;
    return text[0].toUpperCase() + text.substring(1);
  }

  /// Format phone number
  static String formatPhoneNumber(String phoneNumber) {
    final digits = phoneNumber.replaceAll(RegExp(r'\D'), '');
    if (digits.length == 10) {
      return '+91 ${digits.substring(0, 5)} ${digits.substring(5)}';
    }
    return phoneNumber;
  }

  /// Format product size with unit
  static String formatProductSize(String size) {
    return 'ShauryaTMT $size';
  }

  /// Format order ID
  static String formatOrderId(String id) {
    return 'ORD-${id.substring(0, 8).toUpperCase()}';
  }
}
