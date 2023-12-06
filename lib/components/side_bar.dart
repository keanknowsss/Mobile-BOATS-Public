import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import '../screens/home_screen.dart';
// import '../screens/weather_screen.dart';
import '../screens/map_screen.dart';
// import '../screens/bluetooth_screen.dart';
import '../screens/instruction_screen.dart';

class SideBar extends StatelessWidget {
  const SideBar({super.key});

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: Column(
        children: [
          const Padding(
            padding: EdgeInsets.only(top: 50, bottom: 30),
            child: ListTile(
              title: Text(
                'BOATS Menu',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
            ),
          ),
          const Divider(
            thickness: 3,
            height: 5,
          ),
          // ListTile(
          //   leading: const Icon(Icons.home),
          //   title: const Text('Home'),
          //   onTap: () => Navigator.push(
          //     context,
          //     MaterialPageRoute(builder: (context) => const HomeScreen()),
          //   ),
          // ),
          ListTile(
            leading: const Icon(Icons.sunny_snowing),
            title: const Text('Weather'),
            onTap: () => Get.to(
              HomeScreen(),
              transition: Transition.noTransition,
            ),
          ),
          ListTile(
            leading: const Icon(Icons.directions_bike),
            title: const Text('Ride Now'),
            onTap: () => Get.to(
              MapScreen(),
              transition: Transition.noTransition,
            ),
          ),
          // ListTile(
          //   leading: const Icon(Icons.bluetooth_searching),
          //   title: const Text('Bluetooth Devices'),
          //   onTap: () => Navigator.push(
          //     context,
          //     MaterialPageRoute(builder: (context) => const BluetoothScreen()),
          //   ),
          // ),
          const Spacer(),
          ListTile(
            leading: const Icon(Icons.integration_instructions_outlined),
            title: const Text('How to use BOATS'),
            onTap: () => Get.to(
              InstructionScreen(),
              transition: Transition.noTransition,
            ),
          ),
          ListTile(
            leading: const Icon(Icons.exit_to_app_sharp),
            title: const Text('Exit'),
            onTap: () => SystemNavigator.pop(),
          ),
        ],
      ),
    );
  }
}
