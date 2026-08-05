/// One thing the assistant remembers about a plant.
///
/// Written only by the server, from what the owner actually said — the model's
/// own conclusions do not become facts. Read here so the owner can see the list
/// and delete from it, which is not a nicety: a fact that is wrong is repeated
/// in every later answer, and without somewhere to look it is invisible to
/// everyone including us.
library;

class PlantFact {
  final String id;

  /// One of the kinds in `functions/memory.js`. Four of them hold a single
  /// value and supersede their predecessor; the rest accumulate.
  final String kind;
  final String text;
  final DateTime statedAt;

  /// Where it came from — `chat`, `proposal_declined`. Shown so a surprising
  /// entry can be traced back to the conversation that produced it.
  final String? source;

  /// Set when a newer fact of the same single-valued kind replaced this one.
  /// Superseded facts stay: a symptom that keeps returning is the diagnosis,
  /// and no single fact holds that.
  final DateTime? supersededAt;

  const PlantFact({
    required this.id,
    required this.kind,
    required this.text,
    required this.statedAt,
    this.source,
    this.supersededAt,
  });

  bool get isCurrent => supersededAt == null;

  static PlantFact? fromDoc(String id, Map<String, dynamic> data) {
    final text = data['text']?.toString();
    final kind = data['kind']?.toString();
    if (text == null || text.isEmpty || kind == null || kind.isEmpty) return null;
    return PlantFact(
      id: id,
      kind: kind,
      text: text,
      statedAt: DateTime.tryParse(data['statedAt']?.toString() ?? '') ??
          DateTime.fromMillisecondsSinceEpoch(0),
      source: data['source']?.toString(),
      supersededAt: DateTime.tryParse(data['supersededAt']?.toString() ?? ''),
    );
  }
}
