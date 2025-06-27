import 'package:clinic_management_system/ui/AddClientPage/ui/add_client_page.dart';
import 'package:clinic_management_system/ui/PackagesPage/ui/packages_page.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
// ignore: deprecated_member_use
import 'dart:html' as html;

class ClientListPage extends StatefulWidget {
  @override
  _ClientListPageState createState() => _ClientListPageState();
}

class _ClientListPageState extends State<ClientListPage> {
  final clientBox = Hive.box('clients');
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  TextEditingController _searchController = TextEditingController();
  List<Map<String, dynamic>> _filteredClients = [];

  @override
  void initState() {
    super.initState();
    _filterClients(''); // Initialize with all clients
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    _filterClients(_searchController.text);
  }

  void _filterClients(String query) {
    final allClients =
        clientBox.keys
            .where((key) => key != 'lastId')
            .map((key) {
              // Explicitly cast and convert to Map<String, dynamic>
              final client = Map<String, dynamic>.from(
                clientBox.get(key) as Map? ?? {},
              );
              if (client == null) return null;
              return {'key': key, 'client': client};
            })
            .where((item) => item != null)
            .cast<Map<String, dynamic>>()
            .toList();

    setState(() {
      if (query.isEmpty) {
        _filteredClients = allClients;
      } else {
        _filteredClients =
            allClients.where((item) {
              final client = item['client'] as Map<String, dynamic>;
              final name = client['name']?.toString().toLowerCase() ?? '';
              final id = client['id']?.toString().toLowerCase() ?? '';
              final phone = client['phone']?.toString().toLowerCase() ?? '';
              return name.contains(query.toLowerCase()) ||
                  id.contains(query.toLowerCase()) ||
                  phone.contains(query.toLowerCase());
            }).toList();

        _filteredClients.sort((a, b) {
          final nameA = (a['client']['name'] as String?) ?? '';
          final nameB = (b['client']['name'] as String?) ?? '';
          return nameA.compareTo(nameB);
        }); // Sort alphabetically
      }
    });
  }

  void _editClient(Map<String, dynamic> client, String clientKey) async {
    final nameController = TextEditingController(
      text: client['name']?.toString() ?? '',
    );
    final ageController = TextEditingController(
      text: client['age']?.toString() ?? '',
    );
    final phoneController = TextEditingController(
      text: client['phone']?.toString() ?? '',
    );
    final detailsController = TextEditingController(
      text: client['details']?.toString() ?? '',
    );

    List<Map<String, dynamic>> _dialogSelectedClientPackages = [];
    String? _dialogSelectedPackageCategory;
    String? _dialogSelectedPackageItem;

    await showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Text(
              'Edit Client',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            content: Container(
              width: double.maxFinite,
              constraints: BoxConstraints(
                maxHeight: MediaQuery.of(context).size.height * 0.8,
                maxWidth: MediaQuery.of(context).size.width * 0.9,
              ),
              child: StatefulBuilder(
                builder: (BuildContext context, StateSetter setStateDialog) {
                  // Initialize dialog's package list when dialog is first built
                  if (_dialogSelectedClientPackages.isEmpty &&
                      (client['bookedPackages'] as List?)?.isNotEmpty == true) {
                    _dialogSelectedClientPackages =
                        List<Map<String, dynamic>>.from(
                          client['bookedPackages'],
                        );
                  }

                  return SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        TextField(
                          controller: nameController,
                          decoration: InputDecoration(
                            labelText: 'Name',
                            border: OutlineInputBorder(),
                          ),
                        ),
                        SizedBox(height: 16),
                        TextField(
                          controller: ageController,
                          keyboardType: TextInputType.number,
                          decoration: InputDecoration(
                            labelText: 'Age',
                            border: OutlineInputBorder(),
                          ),
                        ),
                        SizedBox(height: 16),
                        TextField(
                          controller: phoneController,
                          keyboardType: TextInputType.phone,
                          decoration: InputDecoration(
                            labelText: 'Phone Number',
                            border: OutlineInputBorder(),
                          ),
                        ),
                        SizedBox(height: 16),
                        TextField(
                          controller: detailsController,
                          decoration: InputDecoration(
                            labelText: 'Details',
                            border: OutlineInputBorder(),
                          ),
                          maxLines: 3,
                        ),
                        SizedBox(height: 24),
                        Text(
                          'Service Packages:',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        SizedBox(height: 8),

                        // Dropdown for Package Category
                        DropdownButtonFormField<String>(
                          value: _dialogSelectedPackageCategory,
                          hint: Text('Select Package Category'),
                          isExpanded: true,
                          items:
                              PackagesPage.packagesData.keys.map((
                                String category,
                              ) {
                                return DropdownMenuItem<String>(
                                  value: category,
                                  child: Text(category),
                                );
                              }).toList(),
                          onChanged: (String? newValue) {
                            setStateDialog(() {
                              _dialogSelectedPackageCategory = newValue;
                              _dialogSelectedPackageItem = null;
                            });
                          },
                          decoration: InputDecoration(
                            border: OutlineInputBorder(),
                          ),
                        ),
                        SizedBox(height: 16),
                        // Dropdown for Specific Package Item
                        if (_dialogSelectedPackageCategory != null)
                          DropdownButtonFormField<String>(
                            value: _dialogSelectedPackageItem,
                            hint: Text('Select Package Item'),
                            isExpanded: true,
                            items:
                                (PackagesPage
                                            .packagesData[_dialogSelectedPackageCategory!] ??
                                        [])
                                    .map((Map<String, dynamic> packageMap) {
                                      // Changed from (String item)
                                      final String itemName =
                                          packageMap['name']
                                              as String; // Extract the name
                                      return DropdownMenuItem<String>(
                                        value:
                                            itemName, // Use the extracted name
                                        child: Text(
                                          itemName,
                                        ), // Display the extracted name
                                      );
                                    })
                                    .toList(),
                            onChanged: (String? newValue) {
                              setStateDialog(() {
                                _dialogSelectedPackageItem = newValue;
                              });
                            },
                            decoration: InputDecoration(
                              border: OutlineInputBorder(),
                            ),
                          ),
                        SizedBox(height: 16),
                        ElevatedButton.icon(
                          icon: Icon(Icons.add_shopping_cart),
                          label: Text('Add Selected Package'),
                          onPressed:
                              (_dialogSelectedPackageCategory != null &&
                                      _dialogSelectedPackageItem != null)
                                  ? () {
                                    final String itemName =
                                        _dialogSelectedPackageItem!;
                                    final List<Map<String, dynamic>>
                                    packagesInCategory =
                                        PackagesPage
                                            .packagesData[_dialogSelectedPackageCategory!] ??
                                        [];

                                    final Map<String, dynamic>?
                                    packageToAdd = packagesInCategory.firstWhere(
                                      (pkg) => pkg['name'] == itemName,
                                      orElse:
                                          () =>
                                              <
                                                String,
                                                dynamic
                                              >{}, // Return null if not found
                                    );

                                    if (packageToAdd != null) {
                                      final newPackageForClient = {
                                        'name': packageToAdd['name'],
                                        'totalSessions':
                                            packageToAdd['totalSessions'],
                                        'remainingSessions':
                                            packageToAdd['totalSessions'], // New booking starts with full sessions
                                        'category': packageToAdd['category'],
                                      };
                                      setStateDialog(() {
                                        if (!_dialogSelectedClientPackages.any(
                                          (p) =>
                                              p['name'] ==
                                              newPackageForClient['name'],
                                        )) {
                                          _dialogSelectedClientPackages.add(
                                            newPackageForClient,
                                          );
                                        } else {
                                          ScaffoldMessenger.of(
                                            context,
                                          ).showSnackBar(
                                            SnackBar(
                                              content: Text(
                                                '$itemName is already added.',
                                              ),
                                            ),
                                          );
                                        }
                                      });
                                    }
                                  }
                                  : null,
                        ),
                        SizedBox(height: 16),
                        Text(
                          'Client\'s Booked Packages:',
                          style: Theme.of(context).textTheme.titleSmall,
                        ),
                        SizedBox(height: 8),
                        _dialogSelectedClientPackages.isEmpty
                            ? Container(
                              padding: EdgeInsets.all(16),
                              child: Text('No packages booked yet.'),
                            )
                            : Container(
                              constraints: BoxConstraints(maxHeight: 200),
                              child: ListView.builder(
                                shrinkWrap: true,
                                itemCount: _dialogSelectedClientPackages.length,
                                itemBuilder: (context, index) {
                                  final package =
                                      _dialogSelectedClientPackages[index];
                                  // Ensure sessions are treated as integers
                                  int remainingSessions =
                                      (package['remainingSessions'] as num?)
                                          ?.toInt() ??
                                      0;
                                  int totalSessions =
                                      (package['totalSessions'] as num?)
                                          ?.toInt() ??
                                      0;

                                  return Card(
                                    margin: EdgeInsets.symmetric(vertical: 4),
                                    child: ListTile(
                                      dense: true,
                                      title: Text(
                                        package['name'] ?? 'Unknown Package',
                                        style: TextStyle(fontSize: 14),
                                      ),
                                      subtitle: Text(
                                        'Sessions: $remainingSessions / $totalSessions',
                                      ),
                                      trailing: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          IconButton(
                                            icon: Icon(
                                              Icons.remove_circle_outline,
                                              size: 20,
                                              color:
                                                  Theme.of(
                                                    context,
                                                  ).primaryColor,
                                            ),
                                            tooltip: 'Decrement Session',
                                            onPressed:
                                                remainingSessions > 0
                                                    ? () {
                                                      setStateDialog(() {
                                                        _dialogSelectedClientPackages[index]['remainingSessions'] =
                                                            remainingSessions -
                                                            1;
                                                      });
                                                    }
                                                    : null,
                                          ),
                                          Text(
                                            '$remainingSessions',
                                            style: TextStyle(
                                              fontSize: 14,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                          IconButton(
                                            icon: Icon(
                                              Icons.add_circle_outline,
                                              size: 20,
                                              color:
                                                  Theme.of(
                                                    context,
                                                  ).colorScheme.secondary,
                                            ),
                                            tooltip: 'Increment Session',
                                            onPressed:
                                                remainingSessions <
                                                        totalSessions
                                                    ? () {
                                                      setStateDialog(() {
                                                        _dialogSelectedClientPackages[index]['remainingSessions'] =
                                                            remainingSessions +
                                                            1;
                                                      });
                                                    }
                                                    : null,
                                          ),
                                          SizedBox(width: 8), // Spacer
                                          IconButton(
                                            icon: Icon(
                                              Icons.delete_forever_outlined,
                                              color: Colors.redAccent,
                                              size: 20,
                                            ),
                                            tooltip: 'Remove Package',
                                            onPressed: () {
                                              setStateDialog(() {
                                                _dialogSelectedClientPackages
                                                    .removeAt(index);
                                              });
                                            },
                                          ),
                                        ],
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ),
                      ],
                    ),
                  );
                },
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text('Cancel'),
                style: TextButton.styleFrom(foregroundColor: Colors.grey[700]),
              ),
              TextButton.icon(
                icon: Icon(Icons.delete, color: Colors.red),
                label: Text('Delete', style: TextStyle(color: Colors.red)),
                onPressed: () async {
                  Navigator.pop(context); // Close edit dialog
                  await _deleteClient(clientKey);
                  _filterClients(
                    _searchController.text,
                  ); // Re-filter to update list
                },
              ),
              ElevatedButton(
                onPressed: () async {
                  if (nameController.text.trim().isEmpty ||
                      phoneController.text.trim().isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Name and Phone Number are required.'),
                        backgroundColor: Colors.orange,
                      ),
                    );
                    return;
                  }

                  final updatedClient = {
                    'id': client['id'],
                    'name': nameController.text.trim(),
                    'age': ageController.text.trim(),
                    'phone': phoneController.text.trim(),
                    'details': detailsController.text.trim(),
                    'bookedPackages':
                        _dialogSelectedClientPackages, // Fixed: Added this line
                  };

                  try {
                    await clientBox.put(clientKey, updatedClient);
                    await _firestore
                        .collection('clients')
                        .doc(clientKey)
                        .set(updatedClient);

                    Navigator.pop(context);
                    _filterClients(
                      _searchController.text,
                    ); // Re-filter to update list

                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Client updated successfully.'),
                        backgroundColor: Colors.green,
                      ),
                    );
                  } catch (e) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Failed to update client: $e'),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                },
                child: Text('Save'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).primaryColor,
                ),
              ),
            ],
          ),
    );
  }

  Future<bool> _deleteClient(String clientKey) async {
    bool? confirm = await showDialog<bool>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Text(
              'Delete Client',
              style: TextStyle(color: Colors.red[800]),
            ),
            content: Text(
              'Are you sure you want to delete this client? This action cannot be undone.',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(context, true),
                style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                child: Text('Delete'),
              ),
            ],
          ),
    );

    if (confirm == true) {
      try {
        await clientBox.delete(clientKey);
        await _firestore.collection('clients').doc(clientKey).delete();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Client deleted successfully.'),
            backgroundColor: Theme.of(context).colorScheme.secondary,
          ),
        );
        return true;
      } catch (e) {
        print('Error deleting client: $e');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to delete client: $e'),
            backgroundColor: Colors.redAccent,
          ),
        );
        return false;
      }
    }
    return false;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Clients List'),
        actions: [
          IconButton(
            icon: Icon(Icons.add, color: Colors.white),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => AddClientPage()),
              ).then(
                (_) => _filterClients(_searchController.text),
              ); // Refresh list after adding
            },
            tooltip: 'Add New Client',
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                labelText: 'Search Clients by Name, ID, or Phone',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                suffixIcon:
                    _searchController.text.isNotEmpty
                        ? IconButton(
                          icon: Icon(Icons.clear),
                          onPressed: () {
                            _searchController.clear();
                          },
                        )
                        : null,
              ),
            ),
          ),
          Expanded(
            child:
                _filteredClients.isEmpty
                    ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.people_alt_outlined,
                            size: 60,
                            color: Colors.grey,
                          ),
                          SizedBox(height: 10),
                          Text(
                            'No clients found.',
                            style: Theme.of(context).textTheme.headlineSmall
                                ?.copyWith(color: Colors.grey),
                          ),
                          if (_searchController.text.isNotEmpty)
                            Text(
                              'Try a different search term or add a new client.',
                              textAlign: TextAlign.center,
                              style: Theme.of(context).textTheme.bodyMedium
                                  ?.copyWith(color: Colors.grey),
                            ),
                        ],
                      ),
                    )
                    : ListView.builder(
                      itemCount: _filteredClients.length,
                      itemBuilder: (context, index) {
                        final item = _filteredClients[index];
                        final client = item['client'] as Map<String, dynamic>;
                        final clientKey = item['key'] as String;

                        return Card(
                          margin: EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 8,
                          ),
                          elevation: 1,
                          child: Dismissible(
                            key: Key(clientKey),
                            direction: DismissDirection.endToStart,
                            background: Container(
                              color: Colors.red,
                              alignment: Alignment.centerRight,
                              padding: EdgeInsets.only(right: 20),
                              child: Icon(Icons.delete, color: Colors.white),
                            ),
                            confirmDismiss:
                                (direction) => _deleteClient(clientKey),
                            child: ListTile(
                              contentPadding: EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 8,
                              ),
                              leading: CircleAvatar(
                                backgroundColor:
                                    Theme.of(context).primaryColorLight,
                                child: Text(
                                  client['name'] != null &&
                                          client['name'].toString().isNotEmpty
                                      ? client['name']
                                          .toString()[0]
                                          .toUpperCase()
                                      : '?',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              title: Text(
                                '${client['name'] ?? 'Unknown'}',
                                style: Theme.of(context).textTheme.titleMedium
                                    ?.copyWith(fontWeight: FontWeight.bold),
                              ),
                              subtitle: Text(
                                'ID: ${client['id'] ?? 'N/A'} | Age: ${client['age'] ?? 'N/A'} | Phone: ${client['phone'] ?? 'N/A'}',
                                style: Theme.of(context).textTheme.bodySmall,
                              ),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  IconButton(
                                    icon: Icon(
                                      Icons.edit,
                                      color: Theme.of(context).primaryColor,
                                    ),
                                    onPressed:
                                        () => _editClient(client, clientKey),
                                    tooltip: 'Edit Client',
                                  ),
                                  IconButton(
                                    icon: Icon(
                                      Icons.chat,
                                      color:
                                          Theme.of(
                                            context,
                                          ).colorScheme.secondary,
                                    ),
                                    onPressed: () {
                                      final clientName =
                                          client['name']?.toString() ??
                                          'Client';
                                      final message = Uri.encodeComponent(
                                        'Hello $clientName, we\'re contacting you from the clinic.',
                                      );
                                      final phoneStr =
                                          client['phone']?.toString() ?? '';
                                      if (phoneStr.isNotEmpty) {
                                        final phone =
                                            phoneStr.startsWith('+')
                                                ? phoneStr
                                                : '+2$phoneStr';
                                        final url =
                                            'https://wa.me/$phone?text=$message';
                                        html.window.open(url, '_blank');
                                      } else {
                                        ScaffoldMessenger.of(
                                          context,
                                        ).showSnackBar(
                                          SnackBar(
                                            content: Text(
                                              'No phone number available for this client.',
                                            ),
                                            backgroundColor: Colors.orange,
                                          ),
                                        );
                                      }
                                    },
                                    tooltip: 'Send WhatsApp Message',
                                  ),
                                ],
                              ),
                              onTap: () => _editClient(client, clientKey),
                            ),
                          ),
                        );
                      },
                    ),
          ),
        ],
      ),
    );
  }
}
