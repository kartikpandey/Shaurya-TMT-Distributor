import 'package:intl/intl.dart';
import '../utils/formatters.dart';

/// One super-coin credit or debit from the reward ledger API
/// (`GET /api/v1/distribution/rewards/`).
///
/// That API is not deployed yet, so its response is unconfirmed. Parsing
/// accepts the field names the older customer-coins API uses (`msg`,
/// `created_at` as "dd/MM/yyyy, hh:mm AM", `total_coins`) plus common
/// alternatives, including the `items` list other distribution APIs use.
/// Confirmed live shape: `{"total_points": 1000, "items": [{"order_id":
/// "ORD-…", "points": 1000, "quantity": 0.0, "created_at": "2026-09-30T…"}]}`.
class RewardLedgerEntry {
  final String description;

  /// Order that earned or spent the coins, when the entry is tied to one
  final String? orderId;

  /// Always positive; [isCredit] gives the direction
  final int coins;
  final bool isCredit;
  final DateTime? date;

  const RewardLedgerEntry({
    required this.description,
    this.orderId,
    required this.coins,
    required this.isCredit,
    this.date,
  });

  int get signedCoins => isCredit ? coins : -coins;

  static RewardLedgerEntry? tryParse(Map<String, dynamic> json) {
    final rawCoins = _first(json, const [
      'coins',
      'coin',
      'super_coins',
      'points',
      'amount',
    ]);
    final coins =
        rawCoins is num ? rawCoins : num.tryParse('${rawCoins ?? ''}'.trim());
    if (coins == null) return null;

    final orderId = _text(json['order_id']);
    final description =
        _text(
          _first(json, const ['msg', 'message', 'description', 'remarks']),
        ) ??
        (orderId != null ? 'Order reward' : 'Super coins');
    final type =
        _text(
          _first(json, const ['type', 'transaction_type', 'coin_type']),
        )?.toLowerCase() ??
        '';
    final wording = '$type ${description.toLowerCase()}';
    final isDebit =
        coins < 0 ||
        wording.contains('debit') ||
        wording.contains('redeem') ||
        wording.contains('expire');

    return RewardLedgerEntry(
      description: description,
      orderId: orderId,
      coins: coins.abs().round(),
      isCredit: !isDebit,
      date: _parseDate(_text(_first(json, const ['created_at', 'date']))),
    );
  }

  static final _backendDate = DateFormat('dd/MM/yyyy, hh:mm a');

  static DateTime? _parseDate(String? value) {
    if (value == null) return null;
    try {
      return _backendDate.parseLoose(value);
    } catch (_) {
      return AppFormatters.parseIst(value);
    }
  }

  static dynamic _first(Map<String, dynamic> json, List<String> keys) {
    for (final key in keys) {
      if (json[key] != null) return json[key];
    }
    return null;
  }

  static String? _text(dynamic value) {
    if (value is String && value.trim().isNotEmpty) return value.trim();
    if (value is num) return value.toString();
    return null;
  }
}

/// Parsed customer-coins response: the ledger (newest first) and balance
class RewardLedger {
  final List<RewardLedgerEntry> entries;

  /// Current reward points: the API's total when sent, else the ledger sum
  final int balance;

  const RewardLedger({required this.entries, required this.balance});

  int get totalEarned =>
      entries.where((e) => e.isCredit).fold(0, (sum, e) => sum + e.coins);
  int get totalRedeemed =>
      entries.where((e) => !e.isCredit).fold(0, (sum, e) => sum + e.coins);

  /// Balance right after [index]'s entry, working back from the current one
  int balanceAfter(int index) {
    var balanceAfter = balance;
    for (var i = 0; i < index; i++) {
      balanceAfter -= entries[i].signedCoins;
    }
    return balanceAfter;
  }

  factory RewardLedger.fromResponse(Map<String, dynamic> json) {
    List? rawEntries;
    for (final key in const [
      'data',
      'customer_coins',
      'coins',
      'ledger',
      'items',
      'result',
    ]) {
      if (json[key] is List) {
        rawEntries = json[key] as List;
        break;
      }
    }

    final entries =
        (rawEntries ?? const [])
            .whereType<Map>()
            .map((e) => RewardLedgerEntry.tryParse(e.cast<String, dynamic>()))
            .whereType<RewardLedgerEntry>()
            .toList()
          ..sort(
            (a, b) => (b.date ?? DateTime(0)).compareTo(a.date ?? DateTime(0)),
          );

    final rawTotal = RewardLedgerEntry._first(json, const [
      'total_points',
      'total_coins',
      'balance',
      'coins_balance',
      'total',
    ]);
    final total =
        rawTotal is num ? rawTotal : num.tryParse('${rawTotal ?? ''}'.trim());

    return RewardLedger(
      entries: entries,
      balance:
          total?.round() ?? entries.fold(0, (sum, e) => sum + e.signedCoins),
    );
  }
}
