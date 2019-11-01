import 'package:flutter/material.dart';

import './screens/product_overview_screen.dart';

void main() => runApp(MyApp());

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Shop',
      theme: ThemeData(
        primarySwatch: Colors.green,
        accentColor: Colors.amber,
        fontFamily: 'Lato',
      ),
      home: ProductOverviewScreen(),
    );
  }
}
