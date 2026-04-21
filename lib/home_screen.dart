import 'dart:math';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:share_plus/share_plus.dart';

class HomeScreen extends StatefulWidget {
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with SingleTickerProviderStateMixin {

  String quote = "";
  String author = "";
  bool isLoading = true;
  bool isFavorite = false;

  String selectedCategory = "motivational";

  List<String> categories = [
    "motivational",
    "love",
    "life",
    "success"
  ];

  late AnimationController _controller;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    fetchQuote();

    _controller = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 500),
    );

    _fadeAnimation =
        CurvedAnimation(parent: _controller, curve: Curves.easeIn);
  }

  //  FIRESTORE FETCH
  Future<void> fetchQuote() async {
    setState(() => isLoading = true);

    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('quotes')
          .where('category', isEqualTo: selectedCategory)
          .get();

      if (snapshot.docs.isNotEmpty) {
        final random = Random();
        final doc =
            snapshot.docs[random.nextInt(snapshot.docs.length)];

        setState(() {
          quote = doc['text'];
          author = doc['author'];
          isLoading = false;
          isFavorite = false;
        });

        _controller.forward(from: 0);
      } else {
        setState(() {
          quote = "No quotes found";
          author = "";
          isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        quote = "Error loading quotes";
        author = "";
        isLoading = false;
      });
    }
  }

  //  FAVORITE (LOCAL)
  Future<void> toggleFavorite() async {
  final user = FirebaseAuth.instance.currentUser;
  if (user == null) return;

  final docRef = FirebaseFirestore.instance
      .collection('users')
      .doc(user.uid)
      .collection('favorites')
      .doc("$quote-$author");
      final doc = await docRef.get();

  if (doc.exists) {
    await docRef.delete();
    isFavorite = false;
  } else {
    await docRef.set({
      'quote': quote,
      'author': author,
      'timestamp': FieldValue.serverTimestamp(),
    });
    isFavorite = true;
  }
   setState(() {});
}

  //  SHARE
  void shareQuote() {
    Share.share('"$quote" - $author');
  }

  Widget glassCard(Widget child) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(25),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
        child: Container(
          padding: EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.08),
            borderRadius: BorderRadius.circular(25),
            border: Border.all(color: Colors.white24),
          ),
          child: child,
        ),
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.deepPurple, Colors.black],
          ),
        ),
        child: Padding(
          padding: EdgeInsets.all(20),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [

              //  CATEGORY DROPDOWN
              Container(
                padding: EdgeInsets.symmetric(horizontal: 15),
                decoration: BoxDecoration(
                  color: Colors.white10,
                  borderRadius: BorderRadius.circular(15),
                ),
                child: DropdownButton<String>(
                  value: selectedCategory,
                  dropdownColor: Colors.black,
                  underline: SizedBox(),
                  style: TextStyle(color: Colors.white),
                  items: categories
                      .map<DropdownMenuItem<String>>((category) {
                    return DropdownMenuItem<String>(
                      value: category,
                      child: Text(category.toUpperCase()),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setState(() {
                      selectedCategory = value!;
                    });
                    fetchQuote();
                  },
                ),
              ),

              SizedBox(height: 30),

              // CARD
              glassCard(
                Column(
                  children: [
                    isLoading
                        ? CircularProgressIndicator(color: Colors.white)
                        : FadeTransition(
                            opacity: _fadeAnimation,
                            child: Column(
                              children: [
                                Icon(Icons.format_quote,
                                    color: Colors.white70),
                                SizedBox(height: 15),
                                Text(
                                  "\"$quote\"",
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 20),
                                ),
                                SizedBox(height: 10),
                                Text("- $author",
                                    style: TextStyle(
                                        color: Colors.white60)),
                              ],
                            ),
                          ),

                    SizedBox(height: 20),

                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        IconButton(
                          icon: Icon(
                            isFavorite
                                ? Icons.favorite
                                : Icons.favorite_border,
                            color: Colors.red,
                          ),
                          onPressed: toggleFavorite,
                        ),
                        IconButton(
                          icon: Icon(Icons.share,
                              color: Colors.white),
                          onPressed: shareQuote,
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              SizedBox(height: 30),

              ElevatedButton(
                onPressed: fetchQuote,
                child: Text("New Quote"),
              )
            ],
          ),
        ),
      ),
    );
  }
}