import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:market_ledger/screens/date_selection_screen.dart';

class LocationSelectionScreen extends StatelessWidget {
  const LocationSelectionScreen({super.key});

  Future<void> _saveSelectionAndNavigate(
      BuildContext context, bool isNew) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('is_new_location', isNew);

    String storeType = isNew ? 'جديد' : 'قديم';
    String storeName = isNew ? 'المحل الجديد' : 'المحل القديم';

    if (context.mounted) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (context) => DateSelectionScreen(
            storeType: storeType,
            storeName: storeName,
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Directionality(
        textDirection: TextDirection.rtl,
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Theme.of(context)
                    .colorScheme
                    .primaryContainer
                    .withValues(alpha: 0.3),
                Theme.of(context).colorScheme.surface,
              ],
            ),
          ),
          child: SafeArea(
            child: Center(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.store,
                      size: 80,
                      color: Colors.teal,
                    ),
                    const SizedBox(height: 24),
                    const Text(
                      'اختر نوع المحل',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.teal,
                      ),
                    ),
                    const SizedBox(height: 40),
                    ElevatedButton.icon(
                      onPressed: () => _saveSelectionAndNavigate(context, true),
                      icon: const Icon(Icons.add_business),
                      label: const Text('محل جديد'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 30, vertical: 15),
                        textStyle:
                            const TextStyle(fontSize: 18, color: Colors.white),
                      ),
                    ),
                    const SizedBox(height: 20),
                    ElevatedButton.icon(
                      onPressed: () =>
                          _saveSelectionAndNavigate(context, false),
                      icon: const Icon(Icons.store),
                      label: const Text('محل قديم'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.orange,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 30, vertical: 15),
                        textStyle:
                            const TextStyle(fontSize: 18, color: Colors.white),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
