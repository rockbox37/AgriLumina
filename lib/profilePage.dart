// lib/secondPage.dart
import 'package:flutter/material.dart';
import 'package:my_first_flutter_app/buyCreditsPage.dart';
import 'package:my_first_flutter_app/findBuyersPage.dart';
import 'package:my_first_flutter_app/findFundingPage.dart';
import 'package:my_first_flutter_app/findSellers.dart';
import 'package:my_first_flutter_app/main.dart';
import 'package:my_first_flutter_app/secondPage.dart';

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
      // backgroundColor: const Color.fromARGB(255, 27, 94, 7),
      backgroundColor: const Color.fromARGB(242, 192, 224, 193),
      appBar: AppBar(
        title: Text('Profile Page'),
      ),
      body: Center(
        child: Column(
          // Column is also a layout widget. It takes a list of children and
          // arranges them vertically. By default, it sizes itself to fit its
          // children horizontally, and tries to be as tall as its parent.
          //
          // TRY THIS: Invoke "debug painting" (choose the "Toggle Debug Paint"
          // action in the IDE, or press "p" in the console), to see the
          // wireframe for each widget.
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            const Text('Profile page Column.'),
            const Text('I am a Seller.'),
            Text(
              'Your Profile',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            Text(
              '$myCredits',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            Text('You have $myCredits credits.'),
            Text(
              '$myCredits',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            ElevatedButton(
              onPressed: () {
                // Navigate to a new screen when the button is pressed
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => FindBuyersPage()),
                );
              }, 
              child: Text('Find Buyers'), 
            ), // Button label
            ElevatedButton(
              onPressed: () {
                // Navigate to a new screen when the button is pressed
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => FindSellersPage()),
                );
              }, 
              child: Text('Find Sellers'), 
            ), // Button label
            ElevatedButton(
              onPressed: () {
                // Navigate to a new screen when the button is pressed
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => BuyCreditsPage()),
                );
              }, 
              child: Text('Buy Credits'), 
            ), // Button label
            ElevatedButton(
              onPressed: () {
                // Navigate to a new screen when the button is pressed
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => FindFundingPage()),
                );
              }, 
              child: Text('Find Funding'), 
            ), // Button label
            IconButton(
            onPressed: () {
                // Navigate to a new screen when the button is pressed
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => MyApp()),
                );
            },
            //icon: const Icon(Icons.reset_tv), // The icon to display
            icon:const ImageIcon(AssetImage('assets/images/icon.png')
            ),
            iconSize: 90.0, // Optional: customize the icon size
            //color: Colors.red, // Optional: customize the icon color)
          ),
          ],
        ),
      ),
    );
  }
}