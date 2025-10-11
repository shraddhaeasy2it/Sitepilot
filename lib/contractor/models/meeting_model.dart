import 'package:flutter/material.dart';

class Meeting {
  final String id;
  final String title;
  final DateTime dateTime;
  final String? description;
  final String invitedCompany; // The company being invited to the meeting
  final List<String> invitedWorkerIds;
  final List<String> invitedWorkerNames;
  final List<String> invitedWorkerCompanies;
  final String siteId;
  final String siteName;
  final String organizerCompany; // The company scheduling the meeting
  final DateTime createdAt;

  Meeting({
    required this.id,
    required this.title,
    required this.dateTime,
    this.description,
    required this.invitedCompany,
    required this.invitedWorkerIds,
    required this.invitedWorkerNames,
    required this.invitedWorkerCompanies,
    required this.siteId,
    required this.siteName,
    required this.organizerCompany,
    required this.createdAt,
  });

  Meeting copyWith({
    String? id,
    String? title,
    DateTime? dateTime,
    String? description,
    String? invitedCompany,
    List<String>? invitedWorkerIds,
    List<String>? invitedWorkerNames,
    List<String>? invitedWorkerCompanies,
    String? siteId,
    String? siteName,
    String? organizerCompany,
    DateTime? createdAt,
  }) {
    return Meeting(
      id: id ?? this.id,
      title: title ?? this.title,
      dateTime: dateTime ?? this.dateTime,
      description: description ?? this.description,
      invitedCompany: invitedCompany ?? this.invitedCompany,
      invitedWorkerIds: invitedWorkerIds ?? this.invitedWorkerIds,
      invitedWorkerNames: invitedWorkerNames ?? this.invitedWorkerNames,
      invitedWorkerCompanies: invitedWorkerCompanies ?? this.invitedWorkerCompanies,
      siteId: siteId ?? this.siteId,
      siteName: siteName ?? this.siteName,
      organizerCompany: organizerCompany ?? this.organizerCompany,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}

class MeetingProvider extends ChangeNotifier {
  final List<Meeting> _meetings = [];

  List<Meeting> get meetings => _meetings;

  List<Meeting> get upcomingMeetings {
    final now = DateTime.now();
    return _meetings.where((meeting) => meeting.dateTime.isAfter(now)).toList()
      ..sort((a, b) => a.dateTime.compareTo(b.dateTime));
  }

  void addMeeting(Meeting meeting) {
    _meetings.add(meeting);
    notifyListeners();
  }

  void updateMeeting(String id, Meeting updatedMeeting) {
    final index = _meetings.indexWhere((meeting) => meeting.id == id);
    if (index != -1) {
      _meetings[index] = updatedMeeting;
      notifyListeners();
    }
  }

  void deleteMeeting(String id) {
    _meetings.removeWhere((meeting) => meeting.id == id);
    notifyListeners();
  }

  // Get meetings for a specific company
  List<Meeting> getMeetingsForCompany(String companyName) {
    return _meetings.where((meeting) =>
      meeting.organizerCompany == companyName ||
      meeting.invitedWorkerCompanies.contains(companyName)
    ).toList();
  }
}