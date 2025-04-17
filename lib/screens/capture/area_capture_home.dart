import 'dart:async';
import 'package:amplify_flutter/amplify_flutter.dart';
import 'package:flutter/material.dart';
import 'package:sighttrack/models/UserSettings.dart';
import 'package:sighttrack/util.dart';

class AreaCaptureHome extends StatefulWidget {
  const AreaCaptureHome({super.key});

  @override
  State<AreaCaptureHome> createState() => _AreaCaptureHomeState();
}

class _AreaCaptureHomeState extends State<AreaCaptureHome> {
  UserSettings? _userSettings;
  String _timeRemaining = '';
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _initializeWrapper();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _initializeWrapper() async {
    _userSettings = await Util.getUserSettings();
    setState(() {
      _startTimer();
    });
    if (_userSettings != null && _userSettings?.isAreaCaptureActive == false) {
      if (!mounted) return;
      Navigator.pop(context);
    }
  }

  void _startTimer() {
    _timer?.cancel();
    if (_userSettings?.isAreaCaptureActive == true &&
        _userSettings?.areaCaptureEnd != null) {
      _timer = Timer.periodic(
        Duration(seconds: 1),
        (_) => _updateTimeRemaining(),
      );
    }
  }

  void _updateTimeRemaining() async {
    if (_userSettings?.areaCaptureEnd == null) {
      setState(() => _timeRemaining = '');
      _timer?.cancel();
      return;
    }

    final endTime = _userSettings!.areaCaptureEnd!.getDateTimeInUtc();
    final now = DateTime.now().toUtc();
    final difference = endTime.difference(now);

    if (difference.isNegative) {
      setState(() => _timeRemaining = '');
      _timer?.cancel();
      final deactivatedSettings = _userSettings!.copyWith(
        isAreaCaptureActive: false,
        areaCaptureEnd: null,
      );
      await Amplify.DataStore.save(deactivatedSettings);
      _userSettings = deactivatedSettings;

      if (!mounted) return;
      Navigator.pop(context);
      return;
    }

    final minutes = difference.inMinutes;
    final seconds = difference.inSeconds % 60;
    setState(
      () => _timeRemaining = '$minutes:${seconds.toString().padLeft(2, '0')}',
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SingleChildScrollView(
        child: SafeArea(
          child: Padding(
            padding: EdgeInsets.all(16),
            child: Column(
              children: [
                Center(
                  child: Text(
                    'Area Capture',
                    style: TextStyle(color: Colors.white, fontSize: 25),
                  ),
                ),
                SizedBox(height: 20),
                Text(
                  _userSettings?.isAreaCaptureActive == true &&
                          _timeRemaining.isNotEmpty
                      ? 'Time Remaining: $_timeRemaining'
                      : 'Loading',
                  style: TextStyle(color: Colors.white, fontSize: 18),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
