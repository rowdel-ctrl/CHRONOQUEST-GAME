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
          ? PowerUps.fromJson(Map<String, dynamic>.from(json['powerUps'] as Map))
          : PowerUps(),
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
      };
}
