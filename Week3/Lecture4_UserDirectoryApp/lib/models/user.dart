class User {
  final int id;
  final String name;
  final String email;
  final String phone;
  final String website;
  final String company;
  final String city;

  User({
    required this.id,
    required this.name,
    required this.email,
    required this.phone,
    required this.website,
    required this.company,
    required this.city,
  });

  // Convert JSON to Dart Object
  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'],
      name: json['name'],
      email: json['email'],
      phone: json['phone'],
      website: json['website'],
      company: json['company']['name'],
      city: json['address']['city'],
    );
  }

  // Convert Dart Object to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'phone': phone,
      'website': website,
      'company': company,
      'city': city,
    };
  }
}