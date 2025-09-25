// File: lib/models/athlete_profile.dart
import 'package:cloud_firestore/cloud_firestore.dart';

class AthleteProfile {
  final String uid;
  final String fullName;
  final int age;
  final String gender;
  final double height; // in cm
  final double weight; // in kg
  final String state;
  final String district;
  final String preferredSport;
  final String? email;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final bool submittedToSAI;
  final DateTime? submissionDate;
  final Map<String, bool> testStatus;
  final String? ageGroup; // Under-14, Under-17, Under-19, Senior
  final String? photoUrl;
  final Map<String, dynamic>? additionalInfo;

  AthleteProfile({
    required this.uid,
    required this.fullName,
    required this.age,
    required this.gender,
    required this.height,
    required this.weight,
    required this.state,
    required this.district,
    required this.preferredSport,
    this.email,
    this.createdAt,
    this.updatedAt,
    this.submittedToSAI = false,
    this.submissionDate,
    this.testStatus = const {
      'vertical_jump': false,
      'situps': false,
      'shuttle_run': false,
      'endurance_run': false,
    },
    this.ageGroup,
    this.photoUrl,
    this.additionalInfo,
  });

  // Calculate age group based on age
  String get calculatedAgeGroup {
    if (age <= 14) return 'Under-14';
    if (age <= 17) return 'Under-17';
    if (age <= 19) return 'Under-19';
    return 'Senior';
  }

  // Calculate BMI
  double get bmi {
    final heightInMeters = height / 100;
    return weight / (heightInMeters * heightInMeters);
  }

  // Get BMI category
  String get bmiCategory {
    final bmiValue = bmi;
    if (bmiValue < 18.5) return 'Underweight';
    if (bmiValue < 25) return 'Normal';
    if (bmiValue < 30) return 'Overweight';
    return 'Obese';
  }

  // Check if profile is complete
  bool get isComplete {
    return fullName.isNotEmpty &&
        age > 0 &&
        gender.isNotEmpty &&
        height > 0 &&
        weight > 0 &&
        state.isNotEmpty &&
        district.isNotEmpty &&
        preferredSport.isNotEmpty;
  }

  // Check if all tests are completed
  bool get allTestsCompleted {
    return testStatus.values.every((completed) => completed);
  }

  // Get completion percentage
  double get completionPercentage {
    if (testStatus.isEmpty) return 0.0;
    int completedCount = testStatus.values.where((completed) => completed).length;
    return (completedCount / testStatus.length) * 100;
  }

  // Convert to JSON for Firestore
  Map<String, dynamic> toJson() {
    return {
      'uid': uid,
      'fullName': fullName,
      'age': age,
      'gender': gender,
      'height': height,
      'weight': weight,
      'state': state,
      'district': district,
      'preferredSport': preferredSport,
      'email': email,
      'createdAt': createdAt != null ? Timestamp.fromDate(createdAt!) : FieldValue.serverTimestamp(),
      'updatedAt': Timestamp.fromDate(updatedAt ?? DateTime.now()),
      'submittedToSAI': submittedToSAI,
      'submissionDate': submissionDate != null ? Timestamp.fromDate(submissionDate!) : null,
      'testStatus': testStatus,
      'ageGroup': ageGroup ?? calculatedAgeGroup,
      'photoUrl': photoUrl,
      'bmi': bmi,
      'bmiCategory': bmiCategory,
      'additionalInfo': additionalInfo,
    };
  }

  // Create from Firestore document
  factory AthleteProfile.fromJson(Map<String, dynamic> json) {
    return AthleteProfile(
      uid: json['uid'] ?? '',
      fullName: json['fullName'] ?? '',
      age: json['age'] ?? 0,
      gender: json['gender'] ?? '',
      height: (json['height'] ?? 0).toDouble(),
      weight: (json['weight'] ?? 0).toDouble(),
      state: json['state'] ?? '',
      district: json['district'] ?? '',
      preferredSport: json['preferredSport'] ?? '',
      email: json['email'],
      createdAt: json['createdAt'] != null
          ? (json['createdAt'] as Timestamp).toDate()
          : null,
      updatedAt: json['updatedAt'] != null
          ? (json['updatedAt'] as Timestamp).toDate()
          : null,
      submittedToSAI: json['submittedToSAI'] ?? false,
      submissionDate: json['submissionDate'] != null
          ? (json['submissionDate'] as Timestamp).toDate()
          : null,
      testStatus: Map<String, bool>.from(json['testStatus'] ?? {
        'vertical_jump': false,
        'situps': false,
        'shuttle_run': false,
        'endurance_run': false,
      }),
      ageGroup: json['ageGroup'],
      photoUrl: json['photoUrl'],
      additionalInfo: json['additionalInfo'] != null
          ? Map<String, dynamic>.from(json['additionalInfo'])
          : null,
    );
  }

  // Copy with method for easy updates
  AthleteProfile copyWith({
    String? uid,
    String? fullName,
    int? age,
    String? gender,
    double? height,
    double? weight,
    String? state,
    String? district,
    String? preferredSport,
    String? email,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? submittedToSAI,
    DateTime? submissionDate,
    Map<String, bool>? testStatus,
    String? ageGroup,
    String? photoUrl,
    Map<String, dynamic>? additionalInfo,
  }) {
    return AthleteProfile(
      uid: uid ?? this.uid,
      fullName: fullName ?? this.fullName,
      age: age ?? this.age,
      gender: gender ?? this.gender,
      height: height ?? this.height,
      weight: weight ?? this.weight,
      state: state ?? this.state,
      district: district ?? this.district,
      preferredSport: preferredSport ?? this.preferredSport,
      email: email ?? this.email,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      submittedToSAI: submittedToSAI ?? this.submittedToSAI,
      submissionDate: submissionDate ?? this.submissionDate,
      testStatus: testStatus ?? this.testStatus,
      ageGroup: ageGroup ?? this.ageGroup,
      photoUrl: photoUrl ?? this.photoUrl,
      additionalInfo: additionalInfo ?? this.additionalInfo,
    );
  }

  @override
  String toString() {
    return 'AthleteProfile{uid: $uid, fullName: $fullName, age: $age, sport: $preferredSport}';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is AthleteProfile && other.uid == uid;
  }

  @override
  int get hashCode => uid.hashCode;
}