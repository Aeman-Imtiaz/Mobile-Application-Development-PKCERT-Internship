import 'package:flutter/material.dart';

import '../models/user.dart';

class UserDetailScreen extends StatelessWidget {
  final User user;

  const UserDetailScreen({
    super.key,
    required this.user,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "User Details",
          style: TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
      ),

      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),

        child: Column(
          children: [

            // Profile Section
            CircleAvatar(
              radius: 50,
              backgroundColor: Colors.indigo,
              child: Text(
                user.name[0],
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 40,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),

            const SizedBox(height: 16),


            Text(
              user.name,
              style: const TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.bold,
              ),
            ),


            const SizedBox(height: 25),


            // Information Cards

            DetailCard(
              icon: Icons.email,
              title: "Email",
              value: user.email,
            ),


            DetailCard(
              icon: Icons.phone,
              title: "Phone",
              value: user.phone,
            ),


            DetailCard(
              icon: Icons.language,
              title: "Website",
              value: user.website,
            ),


            DetailCard(
              icon: Icons.business,
              title: "Company",
              value: user.company,
            ),


            DetailCard(
              icon: Icons.location_on,
              title: "City",
              value: user.city,
            ),

          ],
        ),
      ),
    );
  }
}


// Reusable Detail Card Widget

class DetailCard extends StatelessWidget {

  final IconData icon;
  final String title;
  final String value;


  const DetailCard({
    super.key,
    required this.icon,
    required this.title,
    required this.value,
  });


  @override
  Widget build(BuildContext context) {

    return Card(

      elevation: 4,

      margin: const EdgeInsets.only(
        bottom: 12,
      ),

      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(15),
      ),


      child: ListTile(

        leading: CircleAvatar(
          backgroundColor: Colors.indigo.shade100,

          child: Icon(
            icon,
            color: Colors.indigo,
          ),
        ),


        title: Text(
          title,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),


        subtitle: Text(value),

      ),
    );
  }
}