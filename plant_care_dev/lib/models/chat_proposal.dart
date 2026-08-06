/// A change to the plant's own data that the assistant offered in chat.
///
/// The owner's statements are recorded silently — being asked to confirm a
/// sentence you just typed is absurd. What arrives as a card is the
/// *consequence*: telling the assistant the plant moved to a darker window is a
/// fact, stretching the watering schedule from nine days to eleven is a
/// decision, and that one changes when the reminders fire.
///
/// Which is also why there are two buttons rather than one. A card nobody
/// touched and a card someone rejected look identical without the second, so
/// the assistant would keep re-offering the same change every week to an owner
/// who has already said no.
library;

class ChatProposal {
  /// Field on the plant document. The server keeps the whitelist; the app never
  /// invents one, and the server re-checks whatever comes back to it.
  final String field;

  /// What the plant holds now — null when the field was never set. Kept so the
  /// card can show "9 days → 11 days" instead of asserting a number on its own.
  final Object? from;
  final Object? to;

  /// One sentence, already in the owner's language, saying what changed.
  final String reason;

  final DateTime offeredAt;
  final ProposalOutcome outcome;

  const ChatProposal({
    required this.field,
    required this.from,
    required this.to,
    required this.reason,
    required this.offeredAt,
    this.outcome = ProposalOutcome.open,
  });

  /// How long an untouched card stays actionable.
  ///
  /// The figures behind it were computed for the conditions of the day it was
  /// offered. Applying a fortnight-old recalculation is worse than not
  /// applying it — but the card itself stays in the transcript, because it is
  /// part of the conversation that happened.
  static const shelfLife = Duration(days: 7);

  bool isExpiredAt(DateTime now) =>
      outcome == ProposalOutcome.open && now.difference(offeredAt) > shelfLife;

  bool isActionableAt(DateTime now) =>
      outcome == ProposalOutcome.open && !isExpiredAt(now);

  ChatProposal resolved(ProposalOutcome next) => ChatProposal(
    field: field,
    from: from,
    to: to,
    reason: reason,
    offeredAt: offeredAt,
    outcome: next,
  );

  static ChatProposal? fromJson(
    Map<String, dynamic>? json, {
    DateTime? offeredAt,
  }) {
    if (json == null) return null;
    final field = json['field']?.toString();
    final reason = json['reason']?.toString();
    if (field == null || field.isEmpty || reason == null || reason.isEmpty) {
      return null;
    }
    return ChatProposal(
      field: field,
      from: json['from'],
      to: json['to'],
      reason: reason,
      offeredAt: offeredAt ?? DateTime.now(),
      outcome: ProposalOutcome.values.firstWhere(
        (o) => o.name == json['outcome'],
        orElse: () => ProposalOutcome.open,
      ),
    );
  }

  Map<String, dynamic> toMap() => {
    'field': field,
    'from': from,
    'to': to,
    'reason': reason,
    'offeredAt': offeredAt.toIso8601String(),
    'outcome': outcome.name,
  };
}

enum ProposalOutcome { open, applied, declined }

/// A one-off reminder the assistant offered to set.
///
/// Separate from [ChatProposal] because it changes nothing about the plant —
/// it adds something to the deck. Routine care is already scheduled by rules, so
/// this only ever covers acts that belong to a date rather than a rhythm:
/// repotting in a fortnight, checking on the plant after a trip.
class SuggestedTask {
  final String title;
  final int dueInDays;

  const SuggestedTask({required this.title, required this.dueInDays});

  static SuggestedTask? fromJson(Map<String, dynamic>? json) {
    if (json == null) return null;
    final title = json['title']?.toString().trim();
    final due = json['dueInDays'];
    if (title == null || title.isEmpty || due is! num) return null;
    return SuggestedTask(title: title, dueInDays: due.round());
  }
}
