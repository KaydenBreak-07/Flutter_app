// File: lib/screens/test_screens/vertical_jump_test.dart
import 'package:flutter/material.dart';
import '../video_upload_screen.dart';

class VerticalJumpTest extends StatelessWidget {
  const VerticalJumpTest({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return VideoUploadScreen(
      testType: 'vertical_jump',
      testTitle: 'Vertical Jump Test',
    );
  }
}
