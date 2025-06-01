import 'package:sighttrack/barrel.dart';
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
      appBar: AppBar(title: const Text('Data')),
      body: Column(
        children: [
          // Toggle for Global/Local
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: 16.0,
              vertical: 12.0,
            ),
            child: Container(
              height: 48,
              width: double.infinity,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: () {
                        setState(() {
                          _viewMode = 'Global';
                        });
                      },
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        margin: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color:
                              _viewMode == 'Global'
                                  ? Colors.teal.shade500
                                  : Colors.teal.shade500.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Center(
                          child: Text(
                            'Global',
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
                    ),
                  ),
                  Expanded(
                    child: GestureDetector(
                      onTap: () {
                        setState(() {
                          _viewMode = 'Local';
                        });
                      },
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        margin: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color:
                              _viewMode == 'Local'
                                  ? Colors.teal.shade500
                                  : Colors.teal.shade500.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Center(
                          child: Text(
                            'Local',
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
                    ),
                  ),
                ],
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
