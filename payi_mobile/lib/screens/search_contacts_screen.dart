import 'package:flutter/material.dart';
import 'transfer_screen.dart';

class SearchContactsScreen extends StatefulWidget {
  const SearchContactsScreen({super.key});

  @override
  State<SearchContactsScreen> createState() => _SearchContactsScreenState();
}

class _SearchContactsScreenState extends State<SearchContactsScreen> {
  final _searchController = TextEditingController();
  String _query = '';

  static const List<Map<String, String>> _allContacts = [
    {'name': 'Alex Turner', 'email': 'alex@example.com'},
    {'name': 'Sarah Jenkins', 'email': 'sarah@example.com'},
    {'name': 'Mike Ross', 'email': 'mike@example.com'},
    {'name': 'Emma Wood', 'email': 'emma@example.com'},
    {'name': 'James Carter', 'email': 'james@example.com'},
    {'name': 'Lily Chen', 'email': 'lily@example.com'},
    {'name': 'David Ouma', 'email': 'david@example.com'},
    {'name': 'Grace Nduta', 'email': 'grace@example.com'},
  ];

  List<Map<String, String>> get _filteredContacts {
    if (_query.isEmpty) return _allContacts;
    final q = _query.toLowerCase();
    return _allContacts
        .where((c) =>
            c['name']!.toLowerCase().contains(q) ||
            c['email']!.toLowerCase().contains(q))
        .toList();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final mutedColor = theme.colorScheme.onSurface.withAlpha(153);
    
    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('Search Contacts'),
        backgroundColor: theme.scaffoldBackgroundColor,
        elevation: 0,
        iconTheme: IconThemeData(color: theme.colorScheme.onSurface),
        titleTextStyle: TextStyle(
          color: theme.colorScheme.onSurface,
          fontSize: 20,
          fontWeight: FontWeight.w500,
        ),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              controller: _searchController,
              autofocus: true,
              style: TextStyle(color: theme.colorScheme.onSurface),
              onChanged: (val) => setState(() => _query = val),
              decoration: InputDecoration(
                filled: true,
                fillColor: theme.colorScheme.surface,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide.none,
                ),
                hintText: 'Search by name or email...',
                hintStyle: TextStyle(color: mutedColor),
                prefixIcon: Icon(
                  Icons.search,
                  color: theme.colorScheme.primary,
                ),
                suffixIcon: _query.isNotEmpty
                    ? IconButton(
                        icon: Icon(Icons.clear, color: mutedColor),
                        onPressed: () {
                          _searchController.clear();
                          setState(() => _query = '');
                        },
                      )
                    : null,
              ),
            ),
          ),
          Expanded(
            child: _filteredContacts.isEmpty
                ? Center(
                    child: Text(
                      'No contacts found.',
                      style: TextStyle(color: mutedColor, fontSize: 16),
                    ),
                  )
                : ListView.builder(
                    itemCount: _filteredContacts.length,
                    itemBuilder: (context, index) {
                      final contact = _filteredContacts[index];
                      return ListTile(
                        leading: CircleAvatar(
                          backgroundColor:
                              theme.colorScheme.primary.withAlpha(38), // 0.15 opacity
                          child: Text(
                            contact['name']![0],
                            style: TextStyle(
                              color: theme.colorScheme.primary,
                              fontWeight: FontWeight.bold,
                              fontSize: 18,
                            ),
                          ),
                        ),
                        title: Text(
                          contact['name']!,
                          style: TextStyle(
                            color: theme.colorScheme.onSurface,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        subtitle: Text(
                          contact['email']!,
                          style: TextStyle(
                            color: mutedColor,
                            fontSize: 12,
                          ),
                        ),
                        trailing: Icon(
                          Icons.arrow_forward_ios,
                          size: 14,
                          color: mutedColor,
                        ),
                        onTap: () {
                          Navigator.pushReplacement(
                            context,
                            MaterialPageRoute(
                              builder: (context) => TransferScreen(
                                initialRecipient: contact['email'],
                              ),
                            ),
                          );
                        },
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
