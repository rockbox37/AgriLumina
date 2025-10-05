// lib/secondPage.dart
import 'package:flutter/material.dart';
import 'package:my_first_flutter_app/findSellers.dart';
import 'package:my_first_flutter_app/main.dart';
import 'package:my_first_flutter_app/secondPage.dart';
import 'package:location/location.dart';


class FindFundingPage extends StatelessWidget {

  final int radiusInKM = 50;
  final String myLocation = "Bugobe, DRC"; // String myLocation = getUserLocation();  

  final int numNearbyBuyers = 147; // int numNearbyBuyers = getNearbyBuyers(myLocation, radiusInKM);
  final int yourBuyerCzonnections = 0;
  final int myCredits = 8;

  const FindFundingPage({super.key});

 /* Location getUserLocation() {
    setState((dynamic locationData) {
      // This call to setState tells the Flutter framework that something has
      // changed in this State, which causes it to rerun the build method below
      // so that the display can reflect the updated values. If we changed
      // _counter without calling setState(), then the build method would not be
      // called again, and so nothing would appear to happen.

      print('getUserLocation() called');
      //myCredits++;/

    Location location = Location();
    location = getUserLocation();

      // Now, locationData contains the device's location information
      print('Latitude: ${locationData.latitude}, Longitude: ${locationData.longitude}');

      // return the Users current location
      return getUserLocation();
    });
  }
*/

  int getNearbyBuyers(myLocation, radiusInKM) {

      
      int numBuyers = 40;
      Location location = Location();
      

      // Now, locationData contains the device's location information
      // print('Latitude: ${locationData.latitude}, Longitude: ${locationData.longitude}');

      // return the Users current location
      return numBuyers;
  
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 150, 111, 249),
      appBar: AppBar(
        title: Text('Find Funding'),
        leading: IconButton(
          onPressed: () {},
          //icon: Icon(Icons.chevron_left),
          icon: Image.asset(
          'assets/images/Buyer.png',
          width: 380,
          height: 380,
          ),
        ),
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
                // Navigate to a new screen when the button is pressed
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => SecondPage()),
                );
              }, 
              child: Text('Find Funding'), 
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
          IconButton(
            onPressed: () {
                // Navigate to a new screen when the button is pressed
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => MyApp()),
                );
            },
            //icon: const Icon(Icons.reset_tv), // The icon to display
            icon:const ImageIcon(AssetImage('assets/images/Buyer.png')
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