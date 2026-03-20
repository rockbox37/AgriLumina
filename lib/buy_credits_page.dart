// lib/buy_credits_page.dart
import 'package:flutter/material.dart';
import 'package:agrilumina/find_buyers_page.dart';
import 'package:agrilumina/find_sellers.dart';
import 'package:agrilumina/main.dart';
import 'package:agrilumina/profile_page.dart';
/* second_page import removed — unused here */

class BuyCreditsPage extends StatefulWidget {


  const BuyCreditsPage({super.key});

  @override
  State<BuyCreditsPage> createState() => _BuyCreditsPageState();
}

class _BuyCreditsPageState extends State<BuyCreditsPage> {
  int myCredits = 12;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // backgroundColor: const Color.fromARGB(255, 27, 94, 7),
      backgroundColor: const Color.fromARGB(220, 195, 155, 70),
      appBar: AppBar(
        title: Text('Buy Credits Page'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            const Text('Buy Credits page Column.'),
            Text(
              'Your Credits Balance',
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
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => FindBuyersPage()),
                );
              }, 
              child: Text('Find Buyers'), 
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => FindSellersPage()),
                );
              }, 
              child: Text('Find Sellers'), 
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => ProfilePage()),
                );
              }, 
              child: Text('My Profile'), 
            ),
            IconButton(
            onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => MyApp()),
                );
            },
            icon:const ImageIcon(AssetImage('assets/images/icon.png')
            ),
            iconSize: 90.0,
          ),
          ],
        ),
      ),
    );
  }
}
