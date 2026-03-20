// lib/profile_page.dart
import 'package:flutter/material.dart';
import 'package:agrilumina/buy_credits_page.dart';
import 'package:agrilumina/find_buyers_page.dart';

class ProfilePage extends StatefulWidget {


  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  int myCredits = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromARGB(242, 192, 224, 193),
      appBar: AppBar(
        title: Text('Profile Page'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            const Text('Profile Page Column.'),
            Text(
              'Credits',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            Text(
              '$myCredits',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => BuyCreditsPage()),
                );
              },
              child: Text('Buy Credits'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => FindBuyersPage()),
                );
              },
              child: Text('Find Buyers'),
            ),
          ],
        ),
      ),
    );
  }
}
