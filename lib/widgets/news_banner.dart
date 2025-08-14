// lib/widgets/news_banner.dart

import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../config.dart';

class NewsBanner extends StatefulWidget {
  const NewsBanner({Key? key}) : super(key: key);

  @override
  _NewsBannerState createState() => _NewsBannerState();
}

class _NewsBannerState extends State<NewsBanner> {
  List<dynamic> _newsArticles = [];
  int _currentIndex = 0;
  Timer? _timer;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _fetchNews();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _fetchNews() async {
    final uri = Uri.parse('$backendBaseURL/news');
    try {
      final response = await http.get(uri);
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data is List && data.isNotEmpty) {
          if (mounted) {
            setState(() {
              _newsArticles = data;
              _isLoading = false;
            });
            _startTimer();
          }
        } else {
          if (mounted) setState(() => _isLoading = false);
        }
      } else {
        if (mounted) {
          setState(() {
            _isLoading = false;
            _error = "Failed to load news feed. Status: ${response.statusCode}";
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _error = "Could not connect to news service.";
        });
      }
    }
  }

  void _startTimer() {
    _timer?.cancel();
    if (_newsArticles.length > 1) {
      _timer = Timer.periodic(const Duration(seconds: 8), (timer) {
        if (mounted) {
          setState(() {
            _currentIndex = (_currentIndex + 1) % _newsArticles.length;
          });
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 16.0),
        child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
      );
    }

    if (_error != null || _newsArticles.isEmpty) {
      return const SizedBox.shrink();
    }

    final article = _newsArticles[_currentIndex];
    final theme = Theme.of(context);

    return Container(
      margin: const EdgeInsets.only(top: 8.0),
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
      decoration: BoxDecoration(
        color: Colors.teal.shade50,
        borderRadius: BorderRadius.circular(12.0),
        border: Border(
          left: BorderSide(color: theme.primaryColor, width: 5),
        ),
      ),
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 500),
        transitionBuilder: (Widget child, Animation<double> animation) {
          return FadeTransition(opacity: animation, child: child);
        },
        child: RichText(
          key: ValueKey<int>(_currentIndex),
          text: TextSpan(
            style: const TextStyle(
              fontFamily: 'Garamond',
              fontSize: 16,
              color: Colors.black87,
              height: 1.3,
            ),
            children: <TextSpan>[
              TextSpan(
                text: '${article['title']}: ',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              TextSpan(text: article['content']),
            ],
          ),
        ),
      ),
    );
  }
}