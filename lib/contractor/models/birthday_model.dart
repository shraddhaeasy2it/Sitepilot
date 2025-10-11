import 'package:flutter/material.dart';

class Birthday {
  final String id;
  String name;
  DateTime date;
  String relation;
  DateTime createdAt;

  Birthday({
    required this.id,
    required this.name,
    required this.date,
    required this.relation,
    required this.createdAt,
  });

  Birthday copyWith({
    String? id,
    String? name,
    DateTime? date,
    String? relation,
    DateTime? createdAt,
  }) {
    return Birthday(
      id: id ?? this.id,
      name: name ?? this.name,
      date: date ?? this.date,
      relation: relation ?? this.relation,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  int get daysUntilBirthday {
    final now = DateTime.now();
    final thisYearBirthday = DateTime(now.year, date.month, date.day);
    if (thisYearBirthday.isAfter(now)) {
      return thisYearBirthday.difference(now).inDays;
    } else {
      final nextYearBirthday = DateTime(now.year + 1, date.month, date.day);
      return nextYearBirthday.difference(now).inDays;
    }
  }

  bool get isToday {
    final now = DateTime.now();
    return date.month == now.month && date.day == now.day;
  }
}

class BirthdayProvider with ChangeNotifier {
  final List<Birthday> _birthdays = [
    Birthday(
      id: '1',
      name: 'John Doe',
      date: DateTime(1990, 5, 15),
      relation: 'Family',
      createdAt: DateTime.now().subtract(const Duration(days: 30)),
    ),
    Birthday(
      id: '2',
      name: 'Jane Smith',
      date: DateTime(1985, 12, 25),
      relation: 'Friend',
      createdAt: DateTime.now().subtract(const Duration(days: 15)),
    ),
  ];

  List<Birthday> get birthdays => _birthdays;

  List<Birthday> get upcomingBirthdays {
    return _birthdays.where((birthday) => birthday.daysUntilBirthday <= 30).toList()
      ..sort((a, b) => a.daysUntilBirthday.compareTo(b.daysUntilBirthday));
  }

  List<Birthday> get todaysBirthdays => _birthdays.where((birthday) => birthday.isToday).toList();

  void addBirthday(Birthday birthday) {
    _birthdays.add(birthday);
    notifyListeners();
  }

  void updateBirthday(String id, Birthday updatedBirthday) {
    final index = _birthdays.indexWhere((birthday) => birthday.id == id);
    if (index != -1) {
      _birthdays[index] = updatedBirthday;
      notifyListeners();
    }
  }

  void deleteBirthday(String id) {
    _birthdays.removeWhere((birthday) => birthday.id == id);
    notifyListeners();
  }
}