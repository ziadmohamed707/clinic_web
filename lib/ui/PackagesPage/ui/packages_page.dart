import 'package:flutter/material.dart';

class PackagesPage extends StatelessWidget {
  static final Map<String, List<Map<String, dynamic>>> packagesData = {
    "Package Physio": [
      {
        "name": "1 physio session",
        "totalSessions": 1,
        "remainingSessions": 1,
        "category": "Package Physio"
      },
      {
        "name": "3 physio sessions",
        "totalSessions": 3,
        "remainingSessions": 3,
        "category": "Package Physio"
      },
      {
        "name": "6 physio sessions",
        "totalSessions": 6,
        "remainingSessions": 6,
        "category": "Package Physio"
      },
      {
        "name": "12 physio sessions",
        "totalSessions": 12,
        "remainingSessions": 12,
        "category": "Package Physio"
      }
    ],
    "Package Machines": [
      {
        "name": "1 machine session",
        "totalSessions": 1,
        "remainingSessions": 1,
        "category": "Package Machines"
      },
      {
        "name": "3 machine sessions",
        "totalSessions": 3,
        "remainingSessions": 3,
        "category": "Package Machines"
      },
      {
        "name": "6 machine sessions",
        "totalSessions": 6,
        "remainingSessions": 6,
        "category": "Package Machines"
      },
      {
        "name": "12 machine sessions",
        "totalSessions": 12,
        "remainingSessions": 12,
        "category": "Package Machines"
      }
    ],
    "Package Rehabilitation": [
      {
        "name": "1 rehab session",
        "totalSessions": 1,
        "remainingSessions": 1,
        "category": "Package Rehabilitation"
      },
      {
        "name": "3 rehab sessions",
        "totalSessions": 3,
        "remainingSessions": 3,
        "category": "Package Rehabilitation"
      },
      {
        "name": "6 rehab sessions",
        "totalSessions": 6,
        "remainingSessions": 6,
        "category": "Package Rehabilitation"
      },
      {
        "name": "12 rehab sessions",
        "totalSessions": 12,
        "remainingSessions": 12,
        "category": "Package Rehabilitation"
      }
    ]
  };

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Service Packages')),
      body: ListView.builder(
        itemCount: PackagesPage.packagesData.keys.length,
        itemBuilder: (context, index) {
          String categoryTitle = PackagesPage.packagesData.keys.elementAt(
            index,
          );
          List<Map<String, dynamic>> items =
              PackagesPage.packagesData[categoryTitle]!;
          return Card(
            margin: EdgeInsets.all(16), // Consistent margin
            elevation: 4, // More pronounced shadow
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16), // Larger rounded corners
            ),
            child: Padding(
              padding: EdgeInsets.all(20), // Increased padding
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    categoryTitle,
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      color:
                          Theme.of(
                            context,
                          ).primaryColorDark, // Darker primary color for title
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 16), // Increased spacing
                  ...items.map((packageMap) {
                    final String itemName = packageMap['name'] as String;
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4.0),
                      child: ListTile(
                        leading: Icon(
                          Icons.check_circle_outline,
                          color:
                              Theme.of(context)
                                  .colorScheme
                                  .secondary, // Light green for success
                        ),
                        title: Text(
                          itemName,
                          style: Theme.of(context).textTheme.bodyLarge,
                        ),
                        onTap: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                '$itemName selected (placeholder for package details)',
                              ),
                              backgroundColor:
                                  Theme.of(context).primaryColorLight,
                            ),
                          );
                        },
                      ),
                    );
                  }),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}