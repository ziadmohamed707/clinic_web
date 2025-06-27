// lib/ui/manage_users_page.dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:clinic_management_system/ui/ManageUserPage/bloc/manage_users_bloc.dart';
import 'package:clinic_management_system/ui/ManageUserPage/bloc/manage_users_event.dart';
import 'package:clinic_management_system/ui/ManageUserPage/bloc/manage_users_state.dart';
import 'package:clinic_management_system/ui/ManageUserPage/repository/user_repository.dart';

class ManageUsersPage extends StatelessWidget {
  const ManageUsersPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => ManageUsersBloc(userRepository: UserRepository())..add(LoadUsers()),
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Manage Users'),
          actions: [
            Builder(
              builder: (innerContext) => IconButton(
                icon: const Icon(Icons.add_circle_outline),
                onPressed: () => _showAddUserDialog(innerContext),
                tooltip: 'Add New User',
              ),
            ),
          ],
        ),
        body: BlocConsumer<ManageUsersBloc, ManageUsersState>(
          listener: (context, state) {
            if (state.error != null) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(state.error!),
                  backgroundColor: Colors.redAccent,
                ),
              );
            }
            if (state.successMessage != null) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(state.successMessage!),
                  backgroundColor: Colors.green,
                ),
              );
            }
          },
          builder: (context, state) {
            if (state.isLoading) {
              return const Center(child: CircularProgressIndicator());
            }

            if (state.users.isEmpty) {
              return _buildEmptyState(context);
            }

            return _buildUserList(context, state.users);
          },
        ),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.supervised_user_circle_rounded,
            size: 60,
            color: Colors.grey,
          ),
          const SizedBox(height: 10),
          const Text(
            'No users added yet.',
            style: TextStyle(fontSize: 18, color: Colors.grey),
          ),
          const SizedBox(height: 10),
          ElevatedButton.icon(
            icon: const Icon(Icons.add),
            label: const Text('Add First User'),
            onPressed: () => _showAddUserDialog(context),
          ),
        ],
      ),
    );
  }

  Widget _buildUserList(BuildContext context, List<Map<String, dynamic>> users) {
    return RefreshIndicator(
      onRefresh: () async {
        context.read<ManageUsersBloc>().add(LoadUsers());
      },
      child: ListView.builder(
        itemCount: users.length,
        itemBuilder: (context, index) {
          final user = users[index];
          final String userName = user['username'] ?? 'N/A';
          final String userRole = user['role'] ?? 'No Role';

          return Card(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: ListTile(
              leading: CircleAvatar(
                backgroundColor: Theme.of(context).primaryColorLight,
                child: const Icon(Icons.person_outline),
              ),
              title: Text(
                userName,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              subtitle: Text(
                'Role: ${userRole.toUpperCase()}',
              ),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: Icon(
                      Icons.edit_outlined,
                      color: Theme.of(context).primaryColor,
                    ),
                    onPressed: () => _showAddUserDialog(context, userToEdit: user),
                    tooltip: 'Edit user',
                  ),
                  IconButton(
                    icon: const Icon(
                      Icons.delete_outline,
                      color: Colors.redAccent,
                    ),
                    onPressed: () => _deleteUser(context, user['id'] as String),
                    tooltip: 'Delete user',
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  void _showAddUserDialog(BuildContext context, {Map<String, dynamic>? userToEdit}) {
    final bloc = BlocProvider.of<ManageUsersBloc>(context);
    showDialog(
      context: context,
      builder: (_) {
        return BlocProvider.value(
          value: bloc,
          child: _AddEditUserDialog(userToEdit: userToEdit),
        );
      },
    );
  }

  Future<void> _deleteUser(BuildContext context, String userId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete User?'),
        content: const Text('This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text(
              'Delete',
              style: TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      context.read<ManageUsersBloc>().add(DeleteUser(userId));
    }
  }
}

class _AddEditUserDialog extends StatefulWidget {
  final Map<String, dynamic>? userToEdit;

  const _AddEditUserDialog({this.userToEdit});

  @override
  __AddEditUserDialogState createState() => __AddEditUserDialogState();
}

class __AddEditUserDialogState extends State<_AddEditUserDialog> {
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  final List<String> _availableRoles = ['admin', 'desk', 'doctor'];
  String? _selectedRole;
  late bool _isEditing;

  @override
  void initState() {
    super.initState();
    _isEditing = widget.userToEdit != null;
    if (_isEditing) {
      _usernameController.text = widget.userToEdit?['username'] ?? '';
      _selectedRole = widget.userToEdit?['role'] ?? _availableRoles.first;
    } else {
      _selectedRole = _availableRoles.first;
    }
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _submitForm() {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedRole == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a role'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    try {
      if (_isEditing) {
        final updatedData = {
          'id': widget.userToEdit!['id'],
          'username': _usernameController.text.trim(),
          'role': _selectedRole!,
        };
        if (_passwordController.text.isNotEmpty) {
          updatedData['password'] = _passwordController.text;
        }
        context.read<ManageUsersBloc>().add(UpdateUser(updatedData));
      } else {
        final userData = {
          'username': _usernameController.text.trim(),
          'password': _passwordController.text,
          'role': _selectedRole!,
        };
        context.read<ManageUsersBloc>().add(AddUser(userData));
      }
      Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(_isEditing ? 'Edit User' : 'Add New User'),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _usernameController,
                decoration: const InputDecoration(
                  labelText: 'Username',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Username is required';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _passwordController,
                decoration: InputDecoration(
                  labelText: 'Password',
                  hintText: _isEditing ? 'Leave blank to keep current' : null,
                  border: const OutlineInputBorder(),
                ),
                obscureText: true,
                validator: (value) {
                  if (!_isEditing && (value == null || value.isEmpty)) {
                    return 'Password is required';
                  }
                  if (value != null && value.isNotEmpty && value.length < 6) {
                    return 'Password must be at least 6 characters';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: _selectedRole,
                decoration: const InputDecoration(
                  labelText: 'Role',
                  border: OutlineInputBorder(),
                ),
                items: _availableRoles
                    .map((role) => DropdownMenuItem(
                          value: role,
                          child: Text(role.toUpperCase()),
                        ))
                    .toList(),
                onChanged: (value) => setState(() => _selectedRole = value),
                validator: (value) =>
                    value == null ? 'Please select a role' : null,
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _submitForm,
          style: ElevatedButton.styleFrom(
            backgroundColor: Theme.of(context).primaryColor,
          ),
          child: Text(_isEditing ? 'Save Changes' : 'Add User'),
        ),
      ],
    );
  }
}


// // lib/ui/manage_users_page.dart
// import 'package:clinic_management_system/ui/ManageUserPage/bloc/manage_users_bloc.dart';
// import 'package:clinic_management_system/ui/ManageUserPage/bloc/manage_users_event.dart';
// import 'package:clinic_management_system/ui/ManageUserPage/bloc/manage_users_state.dart';
// import 'package:flutter/material.dart';
// import 'package:flutter_bloc/flutter_bloc.dart';

// class ManageUsersPage extends StatelessWidget {
//   const ManageUsersPage({Key? key}) : super(key: key);

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: Text('Manage Users'),
//         actions: [
//           IconButton(
//             icon: Icon(Icons.add_circle_outline),
//             onPressed: () => _showAddUserDialog(context),
//             tooltip: 'Add New User',
//           ),
//         ],
//       ),
//       body: BlocConsumer<ManageUsersBloc, ManageUsersState>(
//         listener: (context, state) {
//           if (state.error != null) {
//             ScaffoldMessenger.of(context).showSnackBar(
//               SnackBar(
//                 content: Text(state.error!),
//                 backgroundColor: Colors.redAccent,
//               ),
//             );
//           }
//         },
//         builder: (context, state) {
//           if (state.isLoading) {
//             return const Center(child: CircularProgressIndicator());
//           }

//           if (state.users.isEmpty) {
//             return _buildEmptyState(context);
//           }

//           return _buildUserList(context, state.users);
//         },
//       ),
//     );
//   }

//   Widget _buildEmptyState(BuildContext context) {
//     return Center(
//       child: Column(
//         mainAxisAlignment: MainAxisAlignment.center,
//         children: [
//           const Icon(
//             Icons.supervised_user_circle_rounded,
//             size: 60,
//             color: Colors.grey,
//           ),
//           const SizedBox(height: 10),
//           const Text(
//             'No users added yet.',
//             style: TextStyle(fontSize: 18, color: Colors.grey),
//           ),
//           const SizedBox(height: 10),
//           ElevatedButton.icon(
//             icon: const Icon(Icons.add),
//             label: const Text('Add First User'),
//             onPressed: () => _showAddUserDialog(context),
//           ),
//         ],
//       ),
//     );
//   }

//   Widget _buildUserList(
//       BuildContext context, List<Map<String, dynamic>> users) {
//     return ListView.builder(
//       itemCount: users.length,
//       itemBuilder: (context, index) {
//         final user = users[index];
//         final String userName = user['username'] as String? ?? 'N/A';
//         final String userRole = user['role'] as String? ?? 'No Role';

//         return Card(
//           margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
//           child: ListTile(
//             leading: CircleAvatar(
//               backgroundColor: Theme.of(context).primaryColorLight,
//               child: const Icon(Icons.person_outline),
//             ),
//             title: Text(
//               userName,
//               style: const TextStyle(fontWeight: FontWeight.bold),
//             ),
//             subtitle: Text(
//               'Role: ${userRole.toUpperCase()}',
//             ),
//             trailing: Row(
//               mainAxisSize: MainAxisSize.min,
//               children: [
//                 IconButton(
//                   icon: Icon(
//                     Icons.edit_outlined,
//                     color: Theme.of(context).primaryColor,
//                   ),
//                   onPressed: () => _showAddUserDialog(context, userToEdit: user),
//                   tooltip: 'Edit user',
//                 ),
//                 IconButton(
//                   icon: const Icon(
//                     Icons.delete_outline,
//                     color: Colors.redAccent,
//                   ),
//                   onPressed: () => _deleteUser(context, user['id'] as String),
//                   tooltip: 'Delete user',
//                 ),
//               ],
//             ),
//           ),
//         );
//       },
//     );
//   }

//   void _showAddUserDialog(BuildContext context,
//       {Map<String, dynamic>? userToEdit}) {
//     showDialog(
//       context: context,
//       // Use BlocProvider.value to pass the BLoC instance to the dialog route.
//       builder: (_) => BlocProvider.value(
//         value: BlocProvider.of<ManageUsersBloc>(context),
//         child: _AddEditUserDialog(userToEdit: userToEdit),
//       ),
//     );
//   }

//   Future<void> _deleteUser(BuildContext context, String userId) async {
//     bool? confirmDelete = await showDialog<bool>(
//       context: context,
//       builder: (context) => AlertDialog(
//         title: const Text('Delete user?'),
//         content: const Text(
//           'Are you sure you want to delete this user? This action cannot be undone.',
//         ),
//         actions: [
//           TextButton(
//             onPressed: () => Navigator.pop(context, false),
//             child: const Text('Cancel'),
//           ),
//           TextButton(
//             onPressed: () => Navigator.pop(context, true),
//             child: const Text('Delete', style: TextStyle(color: Colors.red)),
//           ),
//         ],
//       ),
//     );

//     if (confirmDelete == true) {
//       context.read<ManageUsersBloc>().add(DeleteUser(userId));
//     }
//   }
// }

// // A separate StatefulWidget for the dialog to manage its own form state.
// class _AddEditUserDialog extends StatefulWidget {
//   final Map<String, dynamic>? userToEdit;

//   const _AddEditUserDialog({this.userToEdit});

//   @override
//   State<_AddEditUserDialog> createState() => _AddEditUserDialogState();
// }

// class _AddEditUserDialogState extends State<_AddEditUserDialog> {
//   final _formKey = GlobalKey<FormState>();
//   final _usernameController = TextEditingController();
//   final _passwordController = TextEditingController();
//   final List<String> _availableRoles = ['admin', 'desk', 'doctor'];
//   String? _selectedRole;
//   late bool isEditing;

//   @override
//   void initState() {
//     super.initState();
//     isEditing = widget.userToEdit != null;
//     if (isEditing) {
//       _usernameController.text = widget.userToEdit!['username'] as String? ?? '';
//       _selectedRole = widget.userToEdit!['role'] as String?;
//     }
//   }

//   @override
//   void dispose() {
//     _usernameController.dispose();
//     _passwordController.dispose();
//     super.dispose();
//   }

//   void _submitForm() {
//     if (_formKey.currentState!.validate()) {
//       if (_selectedRole == null) {
//         ScaffoldMessenger.of(context).showSnackBar(
//           const SnackBar(
//             content: Text('Please select a user role.'),
//             backgroundColor: Colors.orange,
//           ),
//         );
//         return;
//       }

//       if (isEditing) {
//         final Map<String, dynamic> updatedData = {
//           'id': widget.userToEdit!['id'],
//           'username': _usernameController.text.trim(),
//           'role': _selectedRole,
//         };
//         // Only include password if it was changed
//         if (_passwordController.text.isNotEmpty) {
//           updatedData['password'] = _passwordController.text;
//         }
//         // Merge with original data to preserve fields not in the form (e.g., old password)
//         final finalUserData = {...widget.userToEdit!, ...updatedData};

//         context.read<ManageUsersBloc>().add(UpdateUser(finalUserData));
//       } else {
//         final userData = {
//           'username': _usernameController.text.trim(),
//           // Storing password directly is insecure. This is for demonstration.
//           'password': _passwordController.text,
//           'role': _selectedRole,
//         };
//         context.read<ManageUsersBloc>().add(AddUser(userData));
//       }
//       Navigator.pop(context);
//     }
//   }

//   @override
//   Widget build(BuildContext context) {
//     return AlertDialog(
//       title: Text(isEditing ? 'Edit user' : 'Add New User'),
//       content: SingleChildScrollView(
//         child: Form(
//           key: _formKey,
//           child: Column(
//             mainAxisSize: MainAxisSize.min,
//             children: [
//               TextFormField(
//                 controller: _usernameController,
//                 decoration: const InputDecoration(labelText: 'Username'),
//                 validator: (value) {
//                   if (value == null || value.isEmpty) {
//                     return 'Please enter a username';
//                   }
//                   return null;
//                 },
//               ),
//               const SizedBox(height: 16),
//               TextFormField(
//                 controller: _passwordController,
//                 decoration: InputDecoration(
//                   labelText: 'Password',
//                   hintText: isEditing ? 'Leave blank to keep current' : null,
//                 ),
//                 obscureText: true,
//                 validator: (value) {
//                   // Required for new users
//                   if (!isEditing && (value == null || value.isEmpty)) {
//                     return 'Please enter a password';
//                   }
//                   // Length check if a password is provided (for new or edited users)
//                   if (value != null && value.isNotEmpty && value.length < 6) {
//                     return 'Password must be at least 6 characters';
//                   }
//                   return null;
//                 },
//               ),
//               const SizedBox(height: 20),
//               DropdownButtonFormField<String>(
//                 value: _selectedRole,
//                 hint: const Text('Select Role'),
//                 isExpanded: true,
//                 items: _availableRoles.map((String role) {
//                   return DropdownMenuItem<String>(
//                     value: role,
//                     child: Text(role.toUpperCase()),
//                   );
//                 }).toList(),
//                 onChanged: (String? newValue) {
//                   setState(() {
//                     _selectedRole = newValue;
//                   });
//                 },
//                 validator: (value) =>
//                     value == null ? 'Please select a role' : null,
//               ),
//             ],
//           ),
//         ),
//       ),
//       actions: [
//         TextButton(
//           onPressed: () => Navigator.pop(context),
//           child: const Text('Cancel'),
//         ),
//         ElevatedButton(
//           onPressed: _submitForm,
//           child: Text(isEditing ? 'Save Changes' : 'Add User'),
//         ),
//       ],
//     );
//   }
// }




// // lib/ui/manage_users_page.dart
// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:flutter/material.dart';
// import 'package:hive/hive.dart';
// import 'package:uuid/uuid.dart';

// class ManageUsersPage extends StatefulWidget {
//   const ManageUsersPage({Key? key}) : super(key: key);

//   @override
//   State<ManageUsersPage> createState() => _ManageUsersPageState();
// }

// class _ManageUsersPageState extends State<ManageUsersPage> {
//   late Box _usersBox;
//   final FirebaseFirestore _firestore = FirebaseFirestore.instance;
//   List<Map<String, dynamic>> _users = [];
//   final _formKey = GlobalKey<FormState>();
//   final _usernameController = TextEditingController(); // Changed from _nameController
//   final _passwordController = TextEditingController(); // Added for password

//   // Define available roles
//   final List<String> _availableRoles = ['admin', 'desk', 'doctor'];
//   String? _selectedRole; // To store the selected role

//   @override
//   void initState() {
//     super.initState();
//     _usersBox = Hive.box('users');
//     _loadUsers();
//   }

//   void _loadUsers() {
//     final usersData = _usersBox.values.toList();
//     setState(() {
//       _users =
//           usersData
//               .map((user) => Map<String, dynamic>.from(user as Map))
//               .toList();
//     });
//   }

//   Future<void> _saveuserToFirestore(Map<String, dynamic> userData) async {
//     try {
//       await _firestore
//           .collection('users')
//           .doc(userData['id'] as String)
//           .set(userData);
//     } catch (e) {
//       print('Error saving user to Firestore: $e');
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(
//           content: Text('Failed to sync user to cloud: $e'),
//           backgroundColor: Colors.red,
//         ),
//       );
//     }
//   }

//   void _showAdduserDialog({Map<String, dynamic>? userToEdit}) {
//     bool isEditing = userToEdit != null;
//     if (isEditing) {
//       _usernameController.text = userToEdit['username'] as String? ?? ''; // Changed from name
//       // Password field is typically not pre-filled for editing for security
//       _passwordController.clear();
//       _selectedRole = userToEdit['role'] as String?;
//     } else {
//       _usernameController.clear();
//       _passwordController.clear();
//       _selectedRole = null;
//     }

//     showDialog(
//       context: context,
//       builder: (context) {
//         return StatefulBuilder(
//           // Use StatefulBuilder for dialog's own state
//           builder: (BuildContext context, StateSetter setStateDialog) {
//             return AlertDialog(
//               title: Text(isEditing ? 'Edit user' : 'Add New User'),
//               content: SingleChildScrollView(
//                 child: Form(
//                   key: _formKey,
//                   child: Column(
//                     mainAxisSize: MainAxisSize.min,
//                     children: [
//                       TextFormField(
//                         controller: _usernameController, // Changed controller
//                         decoration: InputDecoration(labelText: 'Username'), // Changed label
//                         validator: (value) {
//                           if (value == null || value.isEmpty) {
//                             return 'Please enter a username';
//                           }
//                           return null;
//                         },
//                       ),
//                       SizedBox(height: 16),
//                       TextFormField(
//                         controller: _passwordController, // Added controller
//                         decoration: InputDecoration(labelText: 'Password'), // Added label
//                         obscureText: true, // Hide password
//                         validator: (value) {
//                           if (value == null || value.isEmpty) {
//                             return 'Please enter a password';
//                           }
//                           if (!isEditing && value.length < 6) { // Password length check for new users
//                             return 'Password must be at least 6 characters';
//                           }
//                           return null;
//                         },
//                       ),
//                       SizedBox(height: 20),
//                       Text(
//                         'Role:',
//                         style: Theme.of(context).textTheme.titleMedium,
//                       ),
//                       DropdownButtonFormField<String>(
//                         value: _selectedRole,
//                         hint: Text('Select Role'),
//                         isExpanded: true,
//                         items:
//                             _availableRoles.map((String role) {
//                               return DropdownMenuItem<String>(
//                                 value: role,
//                                 child: Text(role.toUpperCase()),
//                               );
//                             }).toList(),
//                         onChanged: (String? newValue) {
//                           setStateDialog(() {
//                             _selectedRole = newValue;
//                           });
//                         },
//                         validator:
//                             (value) =>
//                                 value == null ? 'Please select a role' : null,
//                       ),
//                     ],
//                   ),
//                 ),
//               ),
//               actions: [
//                 TextButton(
//                   onPressed: () => Navigator.pop(context),
//                   child: Text('Cancel'),
//                 ),
//                 ElevatedButton(
//                   onPressed: () async {
//                     if (_formKey.currentState!.validate()) {
//                       if (_selectedRole == null) {
//                         // Check if role is selected
//                         ScaffoldMessenger.of(context).showSnackBar(
//                           SnackBar(
//                             content: Text('Please select a user role.'),
//                             backgroundColor: Colors.orange,
//                           ),
//                         );
//                         return;
//                       }

//                       final userData = {
//                         'id':
//                             isEditing
//                                 ? userToEdit['id'] as String
//                                 : Uuid().v4(),
//                         'username': _usernameController.text.trim(), // Changed from name
//                         // Storing password directly is insecure. This is for demonstration.
//                         'password': _passwordController.text, // Storing password (INSECURE)
//                         'role': _selectedRole,
//                       };

//                       if (isEditing) {
//                         await _usersBox.put(userData['id'], userData);
//                       } else {
//                         await _usersBox.put(userData['id'], userData);
//                       }
//                       await _saveuserToFirestore(userData);
//                       _loadUsers(); // Refresh the list
//                       Navigator.pop(context); // Close dialog
//                     }
//                   },
//                   child: Text(isEditing ? 'Save Changes' : 'Add User'),
//                 ),
//               ],
//             );
//           },
//         );
//       },
//     ).then((_) {
//       // Reset fields when dialog is dismissed, regardless of how
//       _usernameController.clear();
//       _passwordController.clear();
//       _selectedRole = null;
//     });
//   }

//   Future<void> _deleteuser(String userId) async {
//     bool? confirmDelete = await showDialog<bool>(
//       context: context,
//       builder:
//           (context) => AlertDialog(
//             title: Text('Delete user?'),
//             content: Text(
//               'Are you sure you want to delete this user? This action cannot be undone.',
//             ),
//             actions: [
//               TextButton(
//                 onPressed: () => Navigator.pop(context, false),
//                 child: Text('Cancel'),
//               ),
//               TextButton(
//                 onPressed: () => Navigator.pop(context, true),
//                 child: Text('Delete', style: TextStyle(color: Colors.red)),
//               ),
//             ],
//           ),
//     );

//     if (confirmDelete == true) {
//       await _usersBox.delete(userId);
//       try {
//         await _firestore.collection('users').doc(userId).delete();
//       } catch (e) {
//         print('Error deleting user from Firestore: $e');
//         // Optionally show a snackbar for Firestore deletion failure
//       }
//       _loadUsers();
//     }
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: Text('Manage Users'),
//         actions: [
//           IconButton(
//             icon: Icon(Icons.add_circle_outline),
//             onPressed: () => _showAdduserDialog(),
//             tooltip: 'Add New User',
//           ),
//         ],
//       ),
//       body:
//           _users.isEmpty
//               ? Center(
//                 child: Column(
//                   mainAxisAlignment: MainAxisAlignment.center,
//                   children: [
//                     Icon(
//                       Icons.supervised_user_circle_rounded,
//                       size: 60,
//                       color: Colors.grey,
//                     ),
//                     SizedBox(height: 10),
//                     Text(
//                       'No users added yet.',
//                       style: TextStyle(fontSize: 18, color: Colors.grey),
//                     ),
//                     SizedBox(height: 10),
//                     ElevatedButton.icon(
//                       icon: Icon(Icons.add),
//                       label: Text('Add First User'),
//                       onPressed: () => _showAdduserDialog(),
//                     ),
//                   ],
//                 ),
//               )
//               : ListView.builder(
//                 itemCount: _users.length,
//                 itemBuilder: (context, index) {
//                   final user = _users[index];
//                 // Display username instead of name/email
//                 final String userName = user['username'] as String? ?? 'N/A';
//                   final String userRole = user['role'] as String? ?? 'No Role';

//                   return Card(
//                     margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
//                     child: ListTile(
//                       leading: CircleAvatar(
//                         child: Icon(Icons.person_outline),
//                         backgroundColor: Theme.of(context).primaryColorLight,
//                       ),
//                       title: Text(
//                         userName,
//                         style: TextStyle(fontWeight: FontWeight.bold),
//                       ),
//                       subtitle: Text(
//                         'Role: ${userRole.toUpperCase()}', // Removed email from subtitle
//                       ),
//                       trailing: Row(
//                         mainAxisSize: MainAxisSize.min,
//                         children: [
//                           IconButton(
//                             icon: Icon(
//                               Icons.edit_outlined,
//                               color: Theme.of(context).primaryColor,
//                             ),
//                             onPressed:
//                                 () => _showAdduserDialog(userToEdit: user),
//                             tooltip: 'Edit user',
//                           ),
//                           IconButton(
//                             icon: Icon(
//                               Icons.delete_outline,
//                               color: Colors.redAccent,
//                             ),
//                             onPressed: () => _deleteuser(user['id'] as String),
//                             tooltip: 'Delete user',
//                           ),
//                         ],
//                       ),
//                     ),
//                   );
//                 },
//               ),
//     );
//   }
// }
