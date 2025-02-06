import 'package:flutter/foundation.dart';

class FeedState extends ChangeNotifier {
  String _selectedCode = 'KRW-BTC';

  String get selectedCode => _selectedCode;

  void updateCode(String code) {
    _selectedCode = code;
    notifyListeners();
  }
}
