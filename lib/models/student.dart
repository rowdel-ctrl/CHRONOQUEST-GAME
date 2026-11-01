class PowerUps {
  int fiftyFifty;
  int timeFreeze;
  int shield;

  PowerUps({
    this.fiftyFifty = 0,
    this.timeFreeze = 0,
    this.shield = 0,
  });

  factory PowerUps.fromJson(Map<String, dynamic> json) {
    return PowerUps(
      fiftyFifty: json['fiftyFifty'] as int? ?? 0,
      timeFreeze: json['timeFreeze'] as int? ?? 0,
      shield: json['shield'] as int? ?? json['extraLife'] as int? ?? 0,
    );
  }

  Map<String, dynamic> toJson() => {
        'fiftyFifty': fiftyFifty,
        'timeFreeze': timeFreeze,
        'shield': shield,
      };
}

/// What the server holds of a student's wallet, as read from a fresh sign-in or
/// profile (never from the cached copy, which can be older than the phone).
class ServerWallet {
  final String studentId;
  final int coins;
  final PowerUps powerUps;
  final Set<String> unlockedCharacters;

  ServerWallet({
    required this.studentId,
    required this.coins,
    required this.powerUps,
    required this.unlockedCharacters,
  });

  factory ServerWallet.of(Student student) => ServerWallet(
        studentId: student.id,
        coins: student.coins,
        powerUps: student.powerUps,
        unlockedCharacters: student.unlockedCharacters.toSet(),
      );

  /// A student who never saved one (every account made before wallets reached the
  /// server) comes back as all zeros and no characters.
  bool get isEmpty =>
      coins == 0 &&
      powerUps.fiftyFifty == 0 &&
      powerUps.timeFreeze == 0 &&
      powerUps.shield == 0 &&
      unlockedCharacters.isEmpty;
}

class Student {
  final String id;
  final String username;
  final String name;
  final String classCode;
  final String schoolName;
  final String gradeLevel;
  int score;
  String levelReached;
  int coins;
  PowerUps powerUps;

  /// Characters this student bought (the free ones are not listed).
  List<String> unlockedCharacters;
  bool mustChangePassword;
  final bool isActive;
  final String? lastActive;

  Student({
    this.mustChangePassword = false,
    required this.id,
    required this.username,
    required this.name,
    required this.classCode,
    this.schoolName = '',
    required this.gradeLevel,
    this.score = 0,
    this.levelReached = 'pre-colonial',
    this.coins = 0,
    PowerUps? powerUps,
    this.unlockedCharacters = const [],
    this.isActive = true,
    this.lastActive,
  }) : powerUps = powerUps ?? PowerUps();

  factory Student.fromJson(Map<String, dynamic> json) {
    return Student(
      id: json['_id'] as String? ?? json['id'] as String? ?? '',
      username: json['username'] as String? ?? '',
      mustChangePassword: json['mustChangePassword'] as bool? ?? false,
      name: json['name'] as String? ?? '',
      classCode: json['classCode'] as String? ?? '',
      schoolName: json['schoolName'] as String? ?? '',
      gradeLevel: json['gradeLevel'] as String? ?? 'grade5',
      score: json['score'] as int? ?? 0,
      levelReached: json['levelReached'] as String? ?? 'pre-colonial',
      coins: json['coins'] as int? ?? 0,
      powerUps: json['powerUps'] != null
          ? PowerUps.fromJson(
              Map<String, dynamic>.from(json['powerUps'] as Map))
          : PowerUps(),
      unlockedCharacters: [
        for (final id in (json['unlockedCharacters'] as List?) ?? const [])
          '$id',
      ],
      isActive: json['isActive'] as bool? ?? true,
      lastActive: json['lastActive'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'username': username,
        'name': name,
        'classCode': classCode,
        'schoolName': schoolName,
        'gradeLevel': gradeLevel,
        'score': score,
        'levelReached': levelReached,
        'coins': coins,
        'powerUps': powerUps.toJson(),
        'unlockedCharacters': unlockedCharacters,
      };
}
