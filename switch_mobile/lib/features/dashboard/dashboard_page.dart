import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../app/routes.dart';
import '../auth/auth_controller.dart';
import '../switches/switch_controller.dart';
import '../../models/switch_model.dart';

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<SwitchController>().fetchSwitches();
    });
  }

  void _showCreateSwitchDialog() {
    final nameController = TextEditingController();
    final intervalController = TextEditingController(text: '60');
    final graceController = TextEditingController(text: '15');
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Buat Switch Baru'),
        content: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: nameController,
                decoration: const InputDecoration(labelText: 'Nama Switch'),
                validator: (v) => v == null || v.trim().isEmpty ? 'Wajib diisi' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: intervalController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Check-in Interval (menit)',
                ),
                validator: (v) =>
                    v == null || int.tryParse(v) == null || int.parse(v) <= 0
                        ? 'Harus angka > 0'
                        : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: graceController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Grace Period (menit)',
                ),
                validator: (v) =>
                    v == null || int.tryParse(v) == null || int.parse(v) <= 0
                        ? 'Harus angka > 0'
                        : null,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (formKey.currentState!.validate()) {
                final controller = context.read<SwitchController>();
                final messenger = ScaffoldMessenger.of(context);
                final success = await controller.createSwitch(
                  name: nameController.text.trim(),
                  checkinInterval: int.parse(intervalController.text),
                  gracePeriod: int.parse(graceController.text),
                );
                if (ctx.mounted) Navigator.pop(ctx);
                if (!mounted) return;
                messenger.showSnackBar(
                  SnackBar(
                    content: Text(
                      success
                          ? 'Switch berhasil dibuat'
                          : (controller.errorMessage ?? 'Gagal membuat switch'),
                    ),
                    backgroundColor: success ? Colors.green : Colors.red,
                  ),
                );
              }
            },
            child: const Text('Simpan'),
          ),
        ],
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status.toUpperCase()) {
      case 'ARMED':
        return Colors.green;
      case 'EXPIRED':
      case 'TRIGGERED':
        return Colors.red;
      case 'DISARMED':
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    final authController = context.watch<AuthController>();
    final switchController = context.watch<SwitchController>();
    final user = authController.currentUser;

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text("Dead Man's Switch", style: TextStyle(fontSize: 18)),
            if (user != null)
              Text(
                'Halo, ${user.username}',
                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.normal),
              ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Keluar',
            onPressed: () async {
              await authController.logout();
              if (context.mounted) {
                context.go(AppRoutes.login);
              }
            },
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () => switchController.fetchSwitches(),
        child: switchController.isLoading && switchController.switches.isEmpty
            ? const Center(child: CircularProgressIndicator())
            : switchController.switches.isEmpty
                ? ListView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    children: const [
                      SizedBox(height: 100),
                      Center(
                        child: Text(
                          'Belum ada switch.\nTekan tombol + untuk membuat.',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: Colors.grey, fontSize: 16),
                        ),
                      ),
                    ],
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: switchController.switches.length,
                    itemBuilder: (context, index) {
                      final item = switchController.switches[index];
                      return _buildSwitchCard(context, item, switchController);
                    },
                  ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showCreateSwitchDialog,
        icon: const Icon(Icons.add),
        label: const Text('Buat Switch'),
      ),
    );
  }

  Widget _buildSwitchCard(
    BuildContext context,
    SwitchModel item,
    SwitchController controller,
  ) {
    final statusColor = _getStatusColor(item.status);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        title: Row(
          children: [
            Expanded(
              child: Text(
                item.name,
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: statusColor.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: statusColor),
              ),
              child: Text(
                item.status,
                style: TextStyle(
                  color: statusColor,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
            ),
          ],
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 6),
            Text('Interval: ${item.checkinInterval}m | Grace: ${item.gracePeriod}m'),
            if (item.nextDeadlineAt != null)
              Text(
                'Deadline: ${item.nextDeadlineAt}',
                style: const TextStyle(fontSize: 12, color: Colors.deepOrange),
              ),
            const SizedBox(height: 8),
            Row(
              children: [
                if (item.status == 'DISARMED')
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                    ),
                    icon: const Icon(Icons.power_settings_new, size: 16),
                    label: const Text('ARM'),
                    onPressed: () async {
                      final messenger = ScaffoldMessenger.of(context);
                      final ok = await controller.armSwitch(item.id);
                      if (!mounted) return;
                      messenger.showSnackBar(
                        SnackBar(
                          content: Text(
                            ok
                                ? 'Switch diaktifkan'
                                : (controller.errorMessage ?? 'Gagal'),
                          ),
                        ),
                      );
                    },
                  ),
                if (item.status == 'ARMED') ...[
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                    ),
                    icon: const Icon(Icons.check_circle_outline, size: 16),
                    label: const Text('Check-in'),
                    onPressed: () async {
                      final messenger = ScaffoldMessenger.of(context);
                      final ok = await controller.checkinSwitch(item.id);
                      if (!mounted) return;
                      messenger.showSnackBar(
                        SnackBar(
                          content: Text(
                            ok
                                ? 'Check-in berhasil'
                                : (controller.errorMessage ?? 'Gagal'),
                          ),
                        ),
                      );
                    },
                  ),
                  const SizedBox(width: 8),
                  OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.red,
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                    ),
                    icon: const Icon(Icons.stop_circle_outlined, size: 16),
                    label: const Text('Disarm'),
                    onPressed: () async {
                      final messenger = ScaffoldMessenger.of(context);
                      final ok = await controller.disarmSwitch(item.id);
                      if (!mounted) return;
                      messenger.showSnackBar(
                        SnackBar(
                          content: Text(
                            ok
                                ? 'Switch dimatikan'
                                : (controller.errorMessage ?? 'Gagal'),
                          ),
                        ),
                      );
                    },
                  ),
                ],
              ],
            ),
          ],
        ),
        onTap: () => context.push('/switch/${item.id}'),
      ),
    );
  }
}
