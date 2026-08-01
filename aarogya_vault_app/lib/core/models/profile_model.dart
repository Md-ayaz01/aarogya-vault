class ProfileModel {
  final int id;
  final int userId;
  final String fullName;
  final String dob;
  final String gender;
  final String bloodGroup;
  final String address;
  final String emergencyContactName;
  final String emergencyContactPhone;
  final String aadhaarNumber;
  final int healthScore;
  final String phone;
  final String email;

  ProfileModel({
    required this.id,
    required this.userId,
    required this.fullName,
    required this.dob,
    required this.gender,
    required this.bloodGroup,
    required this.address,
    required this.emergencyContactName,
    required this.emergencyContactPhone,
    required this.aadhaarNumber,
    required this.healthScore,
    required this.phone,
    required this.email,
  });

  String get ageString {
    if (dob.isEmpty) return "Unknown Age";
    try {
      final birthDate = DateTime.parse(dob);
      final currentDate = DateTime.now();
      int age = currentDate.year - birthDate.year;
      if (currentDate.month < birthDate.month ||
          (currentDate.month == birthDate.month && currentDate.day < birthDate.day)) {
        age--;
      }
      return "$age Years";
    } catch (_) {
      return "Unknown Age";
    }
  }

  factory ProfileModel.fromJson(Map<String, dynamic> json) {
    return ProfileModel(
      id: json['id'] ?? 0,
      userId: json['user_id'] ?? 0,
      fullName: json['full_name'] ?? 'Guest Patient',
      dob: json['dob'] ?? '',
      gender: json['gender'] ?? '',
      bloodGroup: json['blood_group'] ?? 'O+',
      address: json['address'] ?? '',
      emergencyContactName: json['emergency_contact_name'] ?? '',
      emergencyContactPhone: json['emergency_contact_phone'] ?? '',
      aadhaarNumber: json['aadhaar_number'] ?? '',
      healthScore: json['health_score'] ?? 92,
      phone: json['phone'] ?? '',
      email: json['email'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'full_name': fullName,
      'dob': dob,
      'gender': gender,
      'blood_group': bloodGroup,
      'address': address,
      'emergency_contact_name': emergencyContactName,
      'emergency_contact_phone': emergencyContactPhone,
      'aadhaar_number': aadhaarNumber,
      'health_score': healthScore,
      'phone': phone,
      'email': email,
    };
  }

  factory ProfileModel.mock() {
    return ProfileModel(
      id: 1,
      userId: 1,
      fullName: "Majid Shaikh",
      dob: "1998-01-12",
      gender: "Male",
      bloodGroup: "O+",
      address: "Dewas, Madhya Pradesh, India",
      emergencyContactName: "Sikandar Shaikh (Father)",
      emergencyContactPhone: "+91 91234 56789",
      aadhaarNumber: "XXXX XXXX 1234",
      healthScore: 92,
      phone: "+91 98765 43210",
      email: "majid@aarogyavault.com",
    );
  }
}
