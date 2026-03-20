import 'package:flutter/material.dart';
import 'package:agrilumina/find_buyers_page.dart';
import 'package:agrilumina/main.dart';
import 'package:agrilumina/profile_page.dart';

class FindSellersPage extends StatefulWidget {
  const FindSellersPage({super.key});

  final String title = 'Find Sellers Page';

  @override
  State<FindSellersPage> createState() => _FindSellersPageState();
}

class _FindSellersPageState extends State<FindSellersPage> {
  int myCredits = 0;
  int numNearbySellers = 23;

  void _incrementCounter() {
    setState(() {
      myCredits++;
    });
  }
  void _decrementCounter() {
    setState(() {
      myCredits--;
    });
  }
  void _resetCounter() {
    setState(() {
      myCredits = 0;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: Text(widget.title),
        elevation: 1,
        leading: IconButton(
          onPressed: () {},
          icon: Image.asset(
          'assets/images/icon.png',
          width: 380,
          height: 380,
          ),
        ),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            const Text('You have this many credits:'),
            Text(
              '$myCredits',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            Text('There are: $numNearbySellers nearby sellers.'),
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => ProfilePage()),
                );
              }, 
              child: Text('Edit my Profile'), 
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
      floatingActionButton: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          FloatingActionButton(
            onPressed: _incrementCounter,
            tooltip: 'Increment',
            focusColor: Colors.amber,
            hoverColor: Colors.blue,
            child: const Icon(Icons.add),
          ),
          const SizedBox(height: 10),
          TextButton(
            onPressed: _decrementCounter,
            child: const Text('Go Down'),
          ),
          TextButton(
            onPressed: _resetCounter,
            child: const Text('RESET'),
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
    );
  }
}
