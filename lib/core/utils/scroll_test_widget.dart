import 'package:flutter/material.dart';
import 'ios_scroll_physics.dart';

/// A simple test widget to verify scrolling works on iOS
class ScrollTestWidget extends StatelessWidget {
  const ScrollTestWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Scroll Test')),
      body: ListView.builder(
        physics: getPlatformScrollPhysics(),
        itemCount: 50,
        itemBuilder: (context, index) {
          return ListTile(
            title: Text('Item $index'),
            subtitle: Text('This is item number $index for testing scrolling'),
            leading: CircleAvatar(child: Text('$index')),
          );
        },
      ),
    );
  }
}
