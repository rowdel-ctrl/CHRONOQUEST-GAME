/// Guest mode: someone trying the game without a class code (a demo). A guest
/// plays the first era only. Nothing is sent to the server, the teacher never
/// sees it, and coins and progress stay on this phone. Each time the game is
/// opened as a guest it starts fresh.
class GuestMode {
  /// The id the guest has for the phone-only wallet and hearts. A real student's
  /// id is a long server-made one, so it can never be this.
  static const String studentId = 'guest';

  /// The only era a guest can play.
  static const String eraId = 'pre-colonial';

  /// Whether a guest is playing right now. Not saved: closing the game ends it.
  /// Read by the services that talk to the server, so none of them ever sends a
  /// guest's results, wallet or progress (a guest has no login to send them with).
  static bool active = false;
}
