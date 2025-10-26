// lib/widgets/expandable_fab.dart
import 'package:flutter/material.dart';

class ExpandableFab extends StatefulWidget {
  final Function onAddPressed;
  final Function onSharePressed;

  const ExpandableFab({
    Key? key,
    required this.onAddPressed,
    required this.onSharePressed,
  }) : super(key: key);

  @override
  _ExpandableFabState createState() => _ExpandableFabState();
}

class _ExpandableFabState extends State<ExpandableFab> {
  bool _isFabExpanded = false;

  void _toggleFab() {
    setState(() {
      _isFabExpanded = !_isFabExpanded; // Wechselt den Zustand des FABs
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        if (_isFabExpanded) ...[
          // Erster Button (Preis hinzufügen)
          FloatingActionButton(
            heroTag: 'addPriceFab',
            backgroundColor: Theme.of(context).colorScheme.secondary,
            foregroundColor: Theme.of(context).colorScheme.onSecondary,
            onPressed: () {
              widget.onAddPressed(); // Preis hinzufügen
            },
            child: Icon(Icons.add),
          ),
          SizedBox(height: 8),
          // Zweiter Button (Teilen)
          FloatingActionButton(
            heroTag: 'shareFab',
            backgroundColor: Theme.of(context).colorScheme.primary,
            foregroundColor: Theme.of(context).colorScheme.onPrimary,
            onPressed: () {
              widget.onSharePressed(); // Teilen
            },
            child: Icon(Icons.share),
          ),
          SizedBox(height: 8),
        ],
        // Haupt-FAB (aufklappbar)
        FloatingActionButton(
          heroTag: 'mainFab',
          backgroundColor: Theme.of(context).colorScheme.primary,
          foregroundColor: Theme.of(context).colorScheme.onPrimary,
          onPressed: _toggleFab,
          child: Icon(_isFabExpanded ? Icons.close : Icons.menu),
        ),
      ],
    );
  }
}