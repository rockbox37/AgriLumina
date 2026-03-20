// lib/find_buyers_page.dart
import 'package:flutter/material.dart';
import 'package:agrilumina/find_funding_page.dart';
import 'package:agrilumina/find_sellers.dart';
import 'package:agrilumina/main.dart';
/* removed unused imports */


class FindBuyersPage extends StatelessWidget {

  final int radiusInKM = 50;
  final String myLocation = "Bugobe, DRC"; 

  final int numNearbyBuyers = 147; 
  final int yourBuyerCzonnections = 0;
  final int myCredits = 8;

    const FindBuyersPage({super.key});

    int getNearbyBuyers(String myLocation, int radiusInKM) {
      int numBuyers = 40;
      return numBuyers;
    }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 249, 166, 111),
      appBar: AppBar(
        title: Text('Find Buyers'),
        leading: IconButton(
          onPressed: () {},
          icon: Image.asset(
          'assets/images/Buyer.png',
          width: 380,
          height: 380,
          ),
        ),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            const Text('Find Buyers Column.'),
            const Text('I am a Seller.\n'),
            Text('There are  $numNearbyBuyers Buyers near you.'),
            Text(
              '$myCredits',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            const Text('I am a Buyer.'),
            Text(
              '$myCredits',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => FindFundingPage()),
                );
              }, 
              child: Text('Find Funding'), 
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
          IconButton(
            onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => MyApp()),
                );
            },
            icon:const ImageIcon(AssetImage('assets/images/Buyer.png')
            ),
            iconSize: 90.0,
          ),
          ],
        ),
      ),
    );
  }
}
