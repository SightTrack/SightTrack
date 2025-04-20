import 'package:sighttrack/barrel.dart';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class DataScreen extends StatefulWidget {
  const DataScreen({super.key});

  @override
  DataScreenState createState() => DataScreenState();
}

class DataScreenState extends State<DataScreen> {
  String _viewMode = 'Global';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[900],
      appBar: AppBar(
        title: const Text('Data Page'),
        backgroundColor: Colors.grey[900],
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: Column(
        children: [
          // Toggle for Global/Local
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: 16.0,
              vertical: 12.0,
            ),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(4.0),
              decoration: BoxDecoration(
                color: Colors.grey[850],
                borderRadius: BorderRadius.circular(10),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.4),
                    offset: const Offset(0, 2),
                    blurRadius: 8,
                  ),
                ],
              ),
              child: CupertinoSegmentedControl<String>(
                groupValue: _viewMode,
                onValueChanged: (String value) {
                  setState(() {
                    _viewMode = value;
                  });
                },
                children: {
                  'Global': DecoratedBox(
                    decoration: BoxDecoration(
                      color:
                          _viewMode == 'Global'
                              ? Colors.teal.shade500
                              : Colors.grey[850],
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Container(
                      width: 100,
                      alignment: Alignment.center,
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      color:
                          Colors
                              .transparent, // Transparent to avoid grey background
                      child: Text(
                        'Global',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color:
                              _viewMode == 'Global'
                                  ? Colors.white
                                  : Colors.grey[400],
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ),
                  'Local': DecoratedBox(
                    decoration: BoxDecoration(
                      color:
                          _viewMode == 'Local'
                              ? Colors.teal.shade500
                              : Colors.grey[850],
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Container(
                      width: 100,
                      alignment: Alignment.center,
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      color: Colors.transparent,
                      child: Text(
                        'Local',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color:
                              _viewMode == 'Local'
                                  ? Colors.white
                                  : Colors.grey[400],
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ),
                },
                borderColor: Colors.transparent,
                selectedColor: Colors.teal.shade500,
                unselectedColor: Colors.grey[850]!,
                pressedColor: Colors.teal.shade600,
                padding: const EdgeInsets.all(0),
              ),
            ),
          ),
          // Content based on view mode
          Expanded(child: _viewMode == 'Global' ? GlobalView() : LocalView()),
        ],
      ),
    );
  }
}
