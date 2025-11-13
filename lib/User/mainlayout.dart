import 'package:tripbudgeter/User/archive.dart';
import 'package:tripbudgeter/User/home.dart';  
import 'package:tripbudgeter/User/trips.dart';
import 'package:tripbudgeter/User/profile.dart'; 
import 'package:tripbudgeter/User/bnb.dart';
import 'package:flutter/material.dart';

class MainLayout extends StatefulWidget {
  @override
  _MainLayoutState createState() => _MainLayoutState();
}

class _MainLayoutState extends State<MainLayout> {
  int _selectedIndex = 0;

  final List<Widget> _pages = [
    HomeScreen(),  
    TripsScreen(),     
    ArchiveScreen(),  
    ProfileScreen(),   
  ];

  void _onTap(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _pages[_selectedIndex],
      bottomNavigationBar: BnbScreen(
        currentIndex: _selectedIndex,
        onTap: _onTap, 
      ),
    );
  }
}
