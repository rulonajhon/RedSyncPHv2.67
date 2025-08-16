import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

class EmergencyFab extends StatefulWidget {
  const EmergencyFab({super.key});

  @override
  State<EmergencyFab> createState() => _EmergencyFabState();
}

class _EmergencyFabState extends State<EmergencyFab> {
  @override
  Widget build(BuildContext context) {
    return FloatingActionButton(
      heroTag: "emergency_fab", // Unique tag to avoid conflicts
      onPressed: () {
        showModalBottomSheet(
          context: context,
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
          ),
          isScrollControlled: true,
          builder: (BuildContext context) {
            return Padding(
              padding: EdgeInsets.only(
                left: 18,
                right: 18,
                top: 18,
                bottom: MediaQuery.of(context).viewInsets.bottom + 18,
              ),
              child: SizedBox(
                height: 350,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Center(
                      child: Text(
                        'Is there an emergency?',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(height: 18),
                    Expanded(
                      child: ListView(
                        children: [
                          ListTile(
                            leading: const Icon(Icons.phone, color: Colors.redAccent),
                            title: const Text('Call Emergency Contact'),
                            onTap: () {
                              // Implement call emergency contact
                            },
                          ),
                          ListTile(
                            leading: const Icon(Icons.phone, color: Colors.redAccent),
                            title: const Text('Call Care Provider'),
                            onTap: () {
                              // Implement call care provider
                            },
                          ),
                          ListTile(
                            leading: const Icon(
                              FontAwesomeIcons.houseChimneyMedical,
                              color: Colors.blueAccent,
                            ),
                            title: const Text('Find Nearest Hospital'),
                            onTap: () {
                              // Implement find nearest hospital
                            },
                          ),
                          ListTile(
                            leading: const Icon(
                              FontAwesomeIcons.bookMedical,
                              color: Colors.green,
                            ),
                            title: const Text('Bleed Guide'),
                            onTap: () {
                              // Implement bleed guide
                            },
                          ),
                          ListTile(
                            leading: const Icon(
                              FontAwesomeIcons.bookMedical,
                              color: Colors.amber,
                            ),
                            title: const Text('Infusion Guide'),
                            onTap: () {
                              // Implement infusion guide
                            },
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
      foregroundColor: Colors.white,
      backgroundColor: Colors.red,
      tooltip: 'Emergency',
      elevation: 6,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
      child: const Icon(FontAwesomeIcons.triangleExclamation),
    );
  }
}
