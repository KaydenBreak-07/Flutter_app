// File: lib/models/sai_official.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class SAIOfficialModel {
  final String uid;
  final String fullName;
  final String email;
  final String employeeId;
  final String designation;
  final String department;
  final bool approved;
  final DateTime createdAt;
  final DateTime? approvedAt;
  final String? approvedBy;
  final Map<String, bool> permissions;
  final String status; // pending, approved, rejected, suspended
  final String? rejectionReason;

  SAIOfficialModel({
    required this.uid,
    required this.fullName,
    required this.email,
    required this.employeeId,
    required this.designation,
    required this.department,
    this.approved = false,
    required this.createdAt,
    this.approvedAt,
    this.approvedBy,
    this.permissions = const {
      'view_athletes': true,
      'review_results': true,
      'export_data': false,
      'manage_users': false,
    },
    this.status = 'pending',
    this.rejectionReason,
  });

  // Convert to JSON for Firestore
  Map<String, dynamic> toJson() {
    return {
      'uid': uid,
      'fullName': fullName,
      'email': email,
      'employeeId': employeeId,
      'designation': designation,
      'department': department,
      'approved': approved,
      'createdAt': Timestamp.fromDate(createdAt),
      'approvedAt': approvedAt != null ? Timestamp.fromDate(approvedAt!) : null,
      'approvedBy': approvedBy,
      'permissions': permissions,
      'status': status,
      'rejectionReason': rejectionReason,
      'role': 'sai_official',
    };
  }

  // Create from Firestore document
  factory SAIOfficialModel.fromJson(Map<String, dynamic> json) {
    return SAIOfficialModel(
      uid: json['uid'] ?? '',
      fullName: json['fullName'] ?? '',
      email: json['email'] ?? '',
      employeeId: json['employeeId'] ?? '',
      designation: json['designation'] ?? '',
      department: json['department'] ?? '',
      approved: json['approved'] ?? false,
      createdAt: json['createdAt'] != null
          ? (json['createdAt'] as Timestamp).toDate()
          : DateTime.now(),
      approvedAt: json['approvedAt'] != null
          ? (json['approvedAt'] as Timestamp).toDate()
          : null,
      approvedBy: json['approvedBy'],
      permissions: Map<String, bool>.from(json['permissions'] ?? {
        'view_athletes': true,
        'review_results': true,
        'export_data': false,
        'manage_users': false,
      }),
      status: json['status'] ?? 'pending',
      rejectionReason: json['rejectionReason'],
    );
  }

  // Copy with method
  SAIOfficialModel copyWith({
    String? uid,
    String? fullName,
    String? email,
    String? employeeId,
    String? designation,
    String? department,
    bool? approved,
    DateTime? createdAt,
    DateTime? approvedAt,
    String? approvedBy,
    Map<String, bool>? permissions,
    String? status,
    String? rejectionReason,
  }) {
    return SAIOfficialModel(
      uid: uid ?? this.uid,
      fullName: fullName ?? this.fullName,
      email: email ?? this.email,
      employeeId: employeeId ?? this.employeeId,
      designation: designation ?? this.designation,
      department: department ?? this.department,
      approved: approved ?? this.approved,
      createdAt: createdAt ?? this.createdAt,
      approvedAt: approvedAt ?? this.approvedAt,
      approvedBy: approvedBy ?? this.approvedBy,
      permissions: permissions ?? this.permissions,
      status: status ?? this.status,
      rejectionReason: rejectionReason ?? this.rejectionReason,
    );
  }

  // Get approval status display
  String get approvalStatusDisplay {
    switch (status) {
      case 'approved':
        return 'Approved';
      case 'rejected':
        return 'Rejected';
      case 'suspended':
        return 'Suspended';
      default:
        return 'Pending Approval';
    }
  }

  // Get status color
  Color get statusColor {
    switch (status) {
      case 'approved':
        return const Color(0xFF4CAF50); // Green
      case 'rejected':
        return const Color(0xFFF44336); // Red
      case 'suspended':
        return const Color(0xFFFF9800); // Orange
      default:
        return const Color(0xFFFFC107); // Amber
    }
  }

  // Check if official has specific permission
  bool hasPermission(String permission) {
    return permissions[permission] ?? false;
  }

  // Get display name for designation
  String get designationDisplay {
    switch (designation.toLowerCase()) {
      case 'director_general':
        return 'Director General';
      case 'joint_director':
        return 'Joint Director';
      case 'deputy_director':
        return 'Deputy Director';
      case 'assistant_director':
        return 'Assistant Director';
      case 'sports_officer':
        return 'Sports Officer';
      case 'talent_scout':
        return 'Talent Scout';
      case 'coach':
        return 'Coach';
      case 'sports_scientist':
        return 'Sports Scientist';
      case 'data_analyst':
        return 'Data Analyst';
      default:
        return designation;
    }
  }

  @override
  String toString() {
    return 'SAIOfficialModel{uid: $uid, fullName: $fullName, designation: $designation, status: $status}';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is SAIOfficialModel && other.uid == uid;
  }

  @override
  int get hashCode => uid.hashCode;
}
