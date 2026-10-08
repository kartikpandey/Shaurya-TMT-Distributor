/// A direct child of the logged-in user in the ordering hierarchy: a
/// distributor's dealer or a dealer's sub-dealer. Comes from the dashboard
/// API's dealer list, whose entries carry `id`, `name`, `phone` and `store`.
class NetworkMember {
  final int id;
  final String name;
  final String? phone;
  final String? store;

  const NetworkMember({
    required this.id,
    required this.name,
    this.phone,
    this.store,
  });

  /// Parse a dealer-list entry; returns null when it has no usable id
  static NetworkMember? tryParse(Map<String, dynamic> json) {
    final rawId = json['id'];
    final id =
        rawId is num
            ? rawId.toInt()
            : rawId is String
            ? int.tryParse(rawId.trim())
            : null;
    if (id == null) return null;

    return NetworkMember(
      id: id,
      name: _text(json['name']) ?? 'Member #$id',
      phone: _text(json['phone']),
      store: _text(json['store']),
    );
  }

  static String? _text(dynamic value) {
    if (value is String && value.trim().isNotEmpty) return value.trim();
    if (value is num) return value.toString();
    return null;
  }
}
