/// The chat topics, as the app names them.
///
/// One assistant per plant and one history: a topic is not a separate chat, it
/// is the entry point the message was said from. It tags the message, chooses
/// which section of the care plan the assistant is shown, and orders what it
/// hears first — it never narrows what it knows.
///
/// A topic is a decision the owner makes about the plant, not the screen they
/// arrived from. That is why the "Soil Moisture" and "Placement" cards have no
/// topic of their own, and why a watering task and the watering card lead to
/// the same one.
///
/// Kept in step with `functions/care-sections.js`, which maps each of these to
/// the care-plan sections behind it. A value that does not exist there is
/// dropped server-side rather than reaching the prompt.
library;

class ChatTopic {
  const ChatTopic._();

  static const water = 'water';
  static const soil = 'soil';
  static const light = 'light';
  static const temperature = 'temperature';
  static const fertilizer = 'fertilizer';

  /// Health checks and anything diagnostic. Has no standing care-plan section:
  /// a diagnosis is grounded in the checks themselves.
  static const diagnostics = 'diagnostics';

  /// The chat opened from the plant header — no section on screen, no filter.
  static const general = 'general';

  static const all = <String>[
    water,
    soil,
    light,
    temperature,
    fertilizer,
    diagnostics,
    general,
  ];
}
