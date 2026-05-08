import 'package:flutter/material.dart';
import 'package:ndiscord/config/theme.dart';
import 'package:ndiscord/models/server.dart';

class MemberList extends StatelessWidget {
  final List<ServerMember> members;

  const MemberList({super.key, required this.members});

  @override
  Widget build(BuildContext context) {
    final onlineMembers = members.where((m) => m.isOnline).toList();
    final offlineMembers = members.where((m) => !m.isOnline).toList();

    return Container(
      width: 240,
      color: AppColors.surface,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          if (onlineMembers.isNotEmpty) ...[
            Text(
              'ONLINE — ${onlineMembers.length}',
              style: const TextStyle(
                color: AppColors.textMuted,
                fontSize: 12,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(height: 8),
            ...onlineMembers.map((m) => _MemberTile(member: m, isOnline: true)),
          ],
          if (offlineMembers.isNotEmpty) ...[
            const SizedBox(height: 16),
            Text(
              'OFFLINE — ${offlineMembers.length}',
              style: const TextStyle(
                color: AppColors.textMuted,
                fontSize: 12,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(height: 8),
            ...offlineMembers.map((m) => _MemberTile(member: m, isOnline: false)),
          ],
        ],
      ),
    );
  }
}

class _MemberTile extends StatelessWidget {
  final ServerMember member;
  final bool isOnline;

  const _MemberTile({required this.member, required this.isOnline});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Stack(
            children: [
              CircleAvatar(
                radius: 16,
                backgroundColor: isOnline ? AppColors.primary : AppColors.textMuted,
                backgroundImage: member.avatarUrl != null ? NetworkImage(member.avatarUrl!) : null,
                child: member.avatarUrl == null
                    ? Text(
                        member.username[0].toUpperCase(),
                        style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold),
                      )
                    : null,
              ),
              Positioned(
                bottom: 0,
                right: 0,
                child: Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    color: isOnline ? AppColors.green : AppColors.textMuted,
                    shape: BoxShape.circle,
                    border: Border.all(color: AppColors.surface, width: 2),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  member.effectiveName,
                  style: TextStyle(
                    color: isOnline ? AppColors.textPrimary : AppColors.textMuted,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                if (member.role != 'member')
                  Text(
                    member.role.toUpperCase(),
                    style: TextStyle(
                      color: member.role == 'owner' ? AppColors.yellow : AppColors.textMuted,
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
