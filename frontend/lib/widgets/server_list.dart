import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ndiscord/config/theme.dart';
import 'package:ndiscord/providers/server_provider.dart';
import 'package:ndiscord/models/server.dart';

class ServerList extends ConsumerWidget {
  final VoidCallback onDMSelected;

  const ServerList({super.key, required this.onDMSelected});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final serverState = ref.watch(serverProvider);

    return Container(
      width: 72,
      color: AppColors.surface,
      child: Column(
        children: [
          const SizedBox(height: 12),
          _ServerIcon(
            icon: Icons.chat_bubble,
            isSelected: false,
            onTap: onDMSelected,
            tooltip: 'Direct Messages',
          ),
          const SizedBox(height: 8),
          Container(width: 32, height: 2, color: AppColors.divider),
          const SizedBox(height: 8),
          Expanded(
            child: ListView.builder(
              itemCount: serverState.servers.length,
              itemBuilder: (context, index) {
                final server = serverState.servers[index];
                final isSelected = serverState.selectedServer?.id == server.id;
                return _ServerIcon(
                  icon: Icons.dns,
                  isSelected: isSelected,
                  label: server.name.substring(0, server.name.length.clamp(0, 2)).toUpperCase(),
                  onTap: () {
                    ref.read(serverProvider.notifier).selectServer(server);
                  },
                  tooltip: server.name,
                );
              },
            ),
          ),
          const SizedBox(height: 8),
          _ServerIcon(
            icon: Icons.add,
            isSelected: false,
            onTap: () => _showCreateServerDialog(context, ref),
            tooltip: 'Add Server',
            isAction: true,
          ),
          const SizedBox(height: 12),
        ],
      ),
    );
  }

  void _showCreateServerDialog(BuildContext context, WidgetRef ref) {
    final nameController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: const Text('Create Server', style: TextStyle(color: AppColors.textPrimary)),
        content: TextField(
          controller: nameController,
          decoration: const InputDecoration(hintText: 'Server name'),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              if (nameController.text.isNotEmpty) {
                ref.read(serverProvider.notifier).createServer(nameController.text, null);
                Navigator.pop(context);
              }
            },
            child: const Text('Create'),
          ),
        ],
      ),
    );
  }
}

class _ServerIcon extends StatelessWidget {
  final IconData icon;
  final bool isSelected;
  final VoidCallback onTap;
  final String? label;
  final String tooltip;
  final bool isAction;

  const _ServerIcon({
    required this.icon,
    required this.isSelected,
    required this.onTap,
    this.label,
    required this.tooltip,
    this.isAction = false,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: isSelected
                ? AppColors.primary
                : isAction
                    ? AppColors.surfaceLight
                    : AppColors.background,
            borderRadius: BorderRadius.circular(isSelected ? 16 : 24),
          ),
          child: Center(
            child: label != null
                ? Text(
                    label!,
                    style: TextStyle(
                      color: isSelected ? Colors.white : AppColors.textSecondary,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  )
                : Icon(
                    icon,
                    color: isSelected
                        ? Colors.white
                        : isAction
                            ? AppColors.green
                            : AppColors.textSecondary,
                    size: 24,
                  ),
          ),
        ),
      ),
    );
  }
}
