import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/app_controller.dart';
import '../../core/translations.dart';
import '../../core/widgets.dart';

class FriendsScreen extends StatelessWidget {
  const FriendsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppController>();
    final strings = ZStrings.of(context);
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        SectionHeader(title: strings.friends),
        const SizedBox(height: 14),
        TextField(
          decoration: const InputDecoration(prefixIcon: Icon(Icons.search_rounded), hintText: 'Search user'),
          onChanged: app.searchUsers,
        ),
        const SizedBox(height: 14),
        if (app.searchedUsers.isNotEmpty) ...[
          const Text('Search Results', style: TextStyle(fontWeight: FontWeight.w800)),
          const SizedBox(height: 10),
          ...app.searchedUsers.map((user) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: ZCard(
                  child: Row(
                    children: [
                      CircleAvatar(child: Text(user['username'].toString()[0].toUpperCase())),
                      const SizedBox(width: 12),
                      Expanded(child: Text(user['username'].toString())),
                      PrimaryButton(label: 'Add', onPressed: () => app.sendFriendRequest(user['id'].toString()), icon: Icons.person_add_alt_1_rounded),
                    ],
                  ),
                ),
              )),
          const SizedBox(height: 14),
        ],
        if (app.friendRequests.isNotEmpty) ...[
          const Text('Friend Requests', style: TextStyle(fontWeight: FontWeight.w800)),
          const SizedBox(height: 10),
          ...app.friendRequests.map((request) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: ZCard(
                  child: Row(
                    children: [
                      Expanded(child: Text(request['sender_username'].toString())),
                      FilledButton(
                        onPressed: () => app.acceptFriendRequest(request['id'].toString()),
                        child: const Text('Accept'),
                      )
                    ],
                  ),
                ),
              )),
          const SizedBox(height: 14),
        ],
        ...app.friends.map((friend) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: ZCard(
                child: Row(
                  children: [
                    CircleAvatar(child: Text(friend['username'].toString()[0].toUpperCase())),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(friend['username'].toString(), style: const TextStyle(fontWeight: FontWeight.w800)),
                          Text('${strings.level} ${friend['level']} • ${strings.wins} ${friend['wins']}'),
                        ],
                      ),
                    ),
                    const Chip(label: Text('Online')),
                  ],
                ),
              ),
            )),
      ],
    );
  }
}
