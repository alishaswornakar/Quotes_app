import 'dart:math';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:share_plus/share_plus.dart';

class HomeScreen extends StatefulWidget {
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with SingleTickerProviderStateMixin {
  String quote = "Loading...";
  String author = "";
  List quotesList = [];
  bool isFavorite = false;
  bool isLoading = true;

  late AnimationController _controller;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    fetchQuotes();

    _controller = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 500),
    );

    _fadeAnimation =
        CurvedAnimation(parent: _controller, curve: Curves.easeIn);
  }

  Future<void> fetchQuotes() async {
    var snapshot =
        await FirebaseFirestore.instance.collection('quotes').get();

    quotesList = snapshot.docs;
    showRandomQuote();
  }

  Future<void> showRandomQuote() async {
    if (quotesList.isNotEmpty) {
      final random = Random();
      var data = quotesList[random.nextInt(quotesList.length)];

      setState(() {
        isLoading = true;
      });

      await Future.delayed(Duration(milliseconds: 300));

      setState(() {
        quote = data['text'];
        author = data['author'];
        isFavorite = false;
        isLoading = false;
      });

      _controller.forward(from: 0);
    }
  }

  Future<void> toggleFavorite() async {
    final prefs = await SharedPreferences.getInstance();
    List<String> favs = prefs.getStringList('favorites') ?? [];

    String current = "$quote - $author";

    if (favs.contains(current)) {
      favs.remove(current);
      setState(() => isFavorite = false);
    } else {
      favs.add(current);
      setState(() => isFavorite = true);
    }

    await prefs.setStringList('favorites', favs);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(isFavorite ? "Added to favorites ❤️" : "Removed")),
    );
  }

  void shareQuote() {
    Share.share('"$quote" - $author');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.deepPurple, Colors.black],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Center(
          child: Padding(
            padding: EdgeInsets.all(20),
            child: isLoading
                ? CircularProgressIndicator(color: Colors.white)
                : FadeTransition(
                    opacity: _fadeAnimation,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.format_quote,
                            color: Colors.white70, size: 40),
                        SizedBox(height: 20),

                        Text(
                          "\"$quote\"",
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 24,
                            fontStyle: FontStyle.italic,
                          ),
                        ),

                        SizedBox(height: 20),

                        Text(
                          "- $author",
                          style: TextStyle(
                            color: Colors.white60,
                            fontSize: 18,
                          ),
                        ),

                        SizedBox(height: 40),

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
                            SizedBox(width: 20),
                            IconButton(
                              icon: Icon(Icons.share,
                                  color: Colors.white),
                              onPressed: shareQuote,
                            ),
                          ],
                        ),

                        SizedBox(height: 30),

                        ElevatedButton(
                          onPressed: showRandomQuote,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color.fromARGB(68, 124, 77, 255),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(30),
                            ),
                          ),
                          child: Text("New Quote"),
                        )
                      ],
                    ),
                  ),
          ),
        ),
      ),
    );
  }
}  