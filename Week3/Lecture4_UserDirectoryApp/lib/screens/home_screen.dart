import 'package:flutter/material.dart';

import '../models/user.dart';
import '../services/api_service.dart';
import '../widgets/user_card.dart';
import 'user_detail_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final ApiService apiService = ApiService();

  late Future<List<User>> futureUsers;

  @override
  void initState() {
    Future<List<User>> loadUsers() async {
  final apiUsers = await apiService.fetchUsers();

  final myUser = User(
    id: 0,
    name: "Aeman Imtiaz",
    email: "khanaeman@example.com",
    phone: "+92 300 1234567",
    website: "aeman.dev",
    company: "BS Information Technology",
    city: "Islamabad",
  );

  return [
    myUser,
    ...apiUsers,
  ];
}
    super.initState();
futureUsers = loadUsers();
  }

  Future<void> refreshUsers() async {
    setState(() {
      futureUsers = apiService.fetchUsers();
    });

    await futureUsers;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "User Directory",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),

      body: RefreshIndicator(
        onRefresh: refreshUsers,

        child: FutureBuilder<List<User>>(
          future: futureUsers,

          builder: (context, snapshot) {
            // Loading
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(
                child: CircularProgressIndicator(),
              );
            }

            // Error
            if (snapshot.hasError) {
              return Center(
                child: Text(
                  "Error: ${snapshot.error}",
                  textAlign: TextAlign.center,
                ),
              );
            }

            // No Data
            if (!snapshot.hasData || snapshot.data!.isEmpty) {
              return const Center(
                child: Text("No Users Found"),
              );
            }

            final users = snapshot.data!;

            // Success
            return ListView.builder(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(12),

              itemCount: users.length,

              itemBuilder: (context, index) {
                return UserCard(
                  user: users[index],

                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => UserDetailScreen(
                          user: users[index],
                        ),
                      ),
                    );
                  },
                );
              },
            );
          },
        ),
      ),
    );
  }
}