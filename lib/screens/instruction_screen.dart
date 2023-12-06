import 'package:flutter/material.dart';
import '../components/app_bar.dart';
import '../components/side_bar.dart';

class InstructionScreen extends StatelessWidget {
  const InstructionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: SideBar(),
      appBar: BoatsAppBar(),
      body: SingleChildScrollView(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('Test'),
          ],
        ),
      ),
    );
  }
}
