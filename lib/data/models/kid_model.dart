import 'package:cloud_firestore/cloud_firestore.dart';

enum Gender { male, female }

class KidModel {
  final String id;
  final String parentId;
  final String name;
  final int age;
  final Gender gender;
  final String? profileImageUrl;
  final String schoolName;
  final String grade;
  final String emergencyContact;
  final String emergencyPhone;
  final String? medicalNotes;
  final DateTime createdAt;
  final DateTime updatedAt;

  KidModel({
    required this.id,
    required this.parentId,
    required this.name,
    required this.age,
    required this.gender,
    this.profileImageUrl,
    required this.schoolName,
    required this.grade,
    required this.emergencyContact,
    required this.emergencyPhone,
    this.medicalNotes,
    required this.createdAt,
    required this.updatedAt,
  });

  factory KidModel.fromJson(Map<String, dynamic> json) {
    return KidModel(
      id: json['id'] ?? '',
      parentId: json['parentId'] ?? '',
      name: json['name'] ?? '',
      age: json['age'] ?? 0,
      gender: Gender.values.firstWhere(
        (e) => e.name == json['gender'],
        orElse: () => Gender.male,
      ),
      profileImageUrl: json['profileImageUrl'],
      schoolName: json['schoolName'] ?? '',
      grade: json['grade'] ?? '',
      emergencyContact: json['emergencyContact'] ?? '',
      emergencyPhone: json['emergencyPhone'] ?? '',
      medicalNotes: json['medicalNotes'],
      createdAt: DateTime.tryParse(json['createdAt'] ?? '') ?? DateTime.now(),
      updatedAt: DateTime.tryParse(json['updatedAt'] ?? '') ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'parentId': parentId,
      'name': name,
      'age': age,
      'gender': gender.name,
      'profileImageUrl': profileImageUrl,
      'schoolName': schoolName,
      'grade': grade,
      'emergencyContact': emergencyContact,
      'emergencyPhone': emergencyPhone,
      'medicalNotes': medicalNotes,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  factory KidModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return KidModel.fromJson(data);
  }

  KidModel copyWith({
    String? id,
    String? parentId,
    String? name,
    int? age,
    Gender? gender,
    String? profileImageUrl,
    String? schoolName,
    String? grade,
    String? emergencyContact,
    String? emergencyPhone,
    String? medicalNotes,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return KidModel(
      id: id ?? this.id,
      parentId: parentId ?? this.parentId,
      name: name ?? this.name,
      age: age ?? this.age,
      gender: gender ?? this.gender,
      profileImageUrl: profileImageUrl ?? this.profileImageUrl,
      schoolName: schoolName ?? this.schoolName,
      grade: grade ?? this.grade,
      emergencyContact: emergencyContact ?? this.emergencyContact,
      emergencyPhone: emergencyPhone ?? this.emergencyPhone,
      medicalNotes: medicalNotes ?? this.medicalNotes,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
