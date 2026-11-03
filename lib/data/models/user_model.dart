class UserModel {
  const UserModel({
    required this.id,
    required this.name,
    required this.username,
    required this.email,
    required this.phone,
    required this.website,
    required this.company,
  });

  final int id;
  final String name;
  final String username;
  final String email;
  final String phone;
  final String website;
  final CompanyModel company;

  String get companyName => company.name;

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] is int
          ? json['id'] as int
          : int.tryParse(json['id']?.toString() ?? '') ?? 0,
      name: (json['name'] ?? '').toString(),
      username: (json['username'] ?? '').toString(),
      email: (json['email'] ?? '').toString(),
      phone: (json['phone'] ?? '').toString(),
      website: (json['website'] ?? '').toString(),
      company: json['company'] is Map<String, dynamic>
          ? CompanyModel.fromJson(json['company'] as Map<String, dynamic>)
          : CompanyModel(name: (json['company'] ?? '').toString()),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'username': username,
      'email': email,
      'phone': phone,
      'website': website,
      'company': company.toJson(),
    };
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is UserModel &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          name == other.name &&
          username == other.username &&
          email == other.email &&
          phone == other.phone &&
          website == other.website &&
          company == other.company;

  @override
  int get hashCode =>
      Object.hash(id, name, username, email, phone, website, company);

  @override
  String toString() =>
      'UserModel(id: $id, name: $name, username: $username, email: $email)';
}

class CompanyModel {
  const CompanyModel({required this.name, this.catchPhrase = '', this.bs = ''});

  final String name;
  final String catchPhrase;
  final String bs;

  factory CompanyModel.fromJson(Map<String, dynamic> json) {
    return CompanyModel(
      name: (json['name'] ?? '').toString(),
      catchPhrase: (json['catchPhrase'] ?? '').toString(),
      bs: (json['bs'] ?? '').toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {'name': name, 'catchPhrase': catchPhrase, 'bs': bs};
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CompanyModel &&
          runtimeType == other.runtimeType &&
          name == other.name &&
          catchPhrase == other.catchPhrase &&
          bs == other.bs;

  @override
  int get hashCode => Object.hash(name, catchPhrase, bs);

  @override
  String toString() => 'CompanyModel(name: $name)';
}
