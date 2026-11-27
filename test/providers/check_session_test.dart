// The "your account is open on another device" notice should not wait for the student to do
// something that saves. checkSession asks the server whether the saved login still counts; it
// must stay quiet for a guest and for a phone that is not logged in (nothing to check).
import 'package:chronoquest/providers/auth_provider.dart';
import 'package:chronoquest/services/guest_mode.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  tearDown(() => GuestMode.active = false);

  test('not logged in: nothing is asked', () async {
    final auth = AuthNotifier();
    await auth.checkSession(); // would throw on a real request with no login
    expect(auth.state.isLoggedIn, isFalse);
  });

  test('a guest is never checked (a guest has no account on the server)', () async {
    final auth = AuthNotifier();
    GuestMode.active = true;
    await auth.checkSession();
    expect(auth.state.isLoggedIn, isFalse);
  });
}
