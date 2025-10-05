// lib/secondPage.dart
import 'package:flutter/material.dart';
import 'package:my_first_flutter_app/findBuyersPage.dart';
import 'package:my_first_flutter_app/findSellers.dart';
import 'package:my_first_flutter_app/main.dart';

class SecondPage extends StatelessWidget {


  final int _credits = 0;

  const SecondPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 194, 136, 97),
      appBar: AppBar(
        title: Text('Second Page'),
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
            const Text('Second page Column.'),
            const Text('I am a Seller.'),
            Text(
              '$_credits',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            const Text('You have this many credits:'),
            Text(
              '$_credits',
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
              child: Text('Connect with Buyers'), 
            ), // Button label
            ElevatedButton(
              onPressed: () {
                // Navigate to a new screen when the button is pressed
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => FindSellersPage()),
                );
              }, 
              child: Text('Connect with Sellers'), 
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