import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'switch_controller.dart';
import '../../models/trigger_model.dart';

class SwitchDetailPage extends StatefulWidget {
  final int switchId;

  const SwitchDetailPage({super.key, required this.switchId});

  @override
  State<SwitchDetailPage> createState() => _SwitchDetailPageState();
}

class _SwitchDetailPageState extends State<SwitchDetailPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<SwitchController>().fetchSwitchDetail(widget.switchId);
    });
  }

  void _showAddTriggerDialog() {
    final targetController = TextEditingController();
    String selectedType = 'EMAIL';

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Tambah Trigger Baru'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButtonFormField<String>(
                initialValue: selectedType,
                decoration: const InputDecoration(labelText: 'Tipe Trigger'),
                items: const [
                  DropdownMenuItem(value: 'EMAIL', child: Text('EMAIL')),
                  DropdownMenuItem(value: 'WEBHOOK', child: Text('WEBHOOK (URL)')),
                  DropdownMenuItem(value: 'WHATSAPP', child: Text('WHATSAPP')),
                ],
                onChanged: (val) {
                  if (val != null) {
                    setDialogState(() => selectedType = val);
                  }
                },
              ),
              const SizedBox(height: 12),
              TextField(
                controller: targetController,
                decoration: InputDecoration(
                  labelText: selectedType == 'EMAIL'
                      ? 'Email Tujuan'
                      : selectedType == 'WEBHOOK'
                          ? 'URL Webhook'
                          : 'Nomor WhatsApp',
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Batal'),
            ),
            ElevatedButton(
              onPressed: () async {
                final target = targetController.text.trim();
                if (target.isEmpty) return;

                final controller = context.read<SwitchController>();
                final messenger = ScaffoldMessenger.of(context);
                final ok = await controller.createTrigger(
                  switchId: widget.switchId,
                  type: selectedType,
                  target: target,
                );
                if (ctx.mounted) Navigator.pop(ctx);
                if (!mounted) return;
                messenger.showSnackBar(
                  SnackBar(
                    content: Text(
                      ok
                          ? 'Trigger berhasil ditambahkan'
                          : (controller.errorMessage ?? 'Gagal menambah trigger'),
                    ),
                    backgroundColor: ok ? Colors.green : Colors.red,
                  ),
                );
              },
              child: const Text('Simpan'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<SwitchController>();
    final sw = controller.selectedSwitch;

    return Scaffold(
      appBar: AppBar(
        title: Text(sw != null ? sw.name : 'Detail Switch'),
        actions: [
          if (sw != null)
            IconButton(
              icon: const Icon(Icons.history),
              tooltip: 'Log History',
              onPressed: () => context.push('/switch/${sw.id}/events'),
            ),
          if (sw != null && sw.status == 'DISARMED')
            IconButton(
              icon: const Icon(Icons.delete_outline, color: Colors.red),
              tooltip: 'Hapus Switch',
              onPressed: () async {
                final messenger = ScaffoldMessenger.of(context);
                final router = GoRouter.of(context);
                final confirm = await showDialog<bool>(
                  context: context,
                  builder: (ctx) => AlertDialog(
                    title: const Text('Hapus Switch?'),
                    content: const Text('Tindakan ini tidak dapat dibatalkan.'),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(ctx, false),
                        child: const Text('Batal'),
                      ),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                        onPressed: () => Navigator.pop(ctx, true),
                        child: const Text('Hapus'),
                      ),
                    ],
                  ),
                );

                if (confirm == true) {
                  final ok = await controller.deleteSwitch(widget.switchId);
                  if (!mounted) return;
                  if (ok) {
                    router.pop();
                  } else {
                    messenger.showSnackBar(
                      SnackBar(
                        content: Text(controller.errorMessage ?? 'Gagal menghapus'),
                      ),
                    );
                  }
                }
              },
            ),
        ],
      ),
      body: controller.isLoading && sw == null
          ? const Center(child: CircularProgressIndicator())
          : sw == null
              ? const Center(child: Text('Switch tidak ditemukan'))
              : RefreshIndicator(
                  onRefresh: () => controller.fetchSwitchDetail(widget.switchId),
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Status Card
                        Card(
                          child: Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Column(
                              children: [
                                Text(
                                  sw.status,
                                  style: TextStyle(
                                    fontSize: 24,
                                    fontWeight: FontWeight.bold,
                                    color: sw.status == 'ARMED'
                                        ? Colors.green
                                        : Colors.grey,
                                  ),
                                ),
                                const SizedBox(height: 12),
                                Text('Check-in Interval: ${sw.checkinInterval} Menit'),
                                Text('Grace Period: ${sw.gracePeriod} Menit'),
                                if (sw.lastCheckinAt != null)
                                  Text('Last Check-in: ${sw.lastCheckinAt}'),
                                if (sw.nextDeadlineAt != null)
                                  Text(
                                    'Next Deadline: ${sw.nextDeadlineAt}',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: Colors.deepOrange,
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Action Buttons
                        Row(
                          children: [
                            if (sw.status == 'DISARMED')
                              Expanded(
                                child: ElevatedButton.icon(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.green,
                                    foregroundColor: Colors.white,
                                  ),
                                  icon: const Icon(Icons.power_settings_new),
                                  label: const Text('ARM SWITCH'),
                                  onPressed: () => controller.armSwitch(sw.id),
                                ),
                              ),
                            if (sw.status == 'ARMED') ...[
                              Expanded(
                                child: ElevatedButton.icon(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.blue,
                                    foregroundColor: Colors.white,
                                  ),
                                  icon: const Icon(Icons.check_circle_outline),
                                  label: const Text('CHECK-IN NOW'),
                                  onPressed: () => controller.checkinSwitch(sw.id),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: OutlinedButton.icon(
                                  style: OutlinedButton.styleFrom(
                                    foregroundColor: Colors.red,
                                  ),
                                  icon: const Icon(Icons.stop_circle_outlined),
                                  label: const Text('DISARM'),
                                  onPressed: () => controller.disarmSwitch(sw.id),
                                ),
                              ),
                            ],
                          ],
                        ),

                        const SizedBox(height: 24),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'Daftar Trigger Action',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.add_circle),
                              color: Colors.deepOrange,
                              onPressed: _showAddTriggerDialog,
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),

                        // Triggers List
                        if (controller.triggers.isEmpty)
                          const Padding(
                            padding: EdgeInsets.symmetric(vertical: 16),
                            child: Text(
                              'Belum ada trigger aksi. Tambah email/webhook tujuan saat switch expired.',
                              style: TextStyle(color: Colors.grey),
                            ),
                          )
                        else
                          ...controller.triggers.map(
                            (trig) => _buildTriggerTile(context, trig, controller),
                          ),
                      ],
                    ),
                  ),
                ),
    );
  }

  Widget _buildTriggerTile(
    BuildContext context,
    TriggerModel trig,
    SwitchController controller,
  ) {
    return Card(
      child: ListTile(
        leading: Icon(
          trig.type == 'EMAIL'
              ? Icons.email
              : trig.type == 'WEBHOOK'
                  ? Icons.webhook
                  : Icons.chat,
          color: Colors.deepOrange,
        ),
        title: Text(trig.target),
        subtitle: Text('Tipe: ${trig.type}'),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Switch(
              value: trig.isEnabled,
              onChanged: (val) {
                controller.toggleTrigger(widget.switchId, trig.id, val);
              },
            ),
            IconButton(
              icon: const Icon(Icons.delete, color: Colors.red),
              onPressed: () {
                controller.deleteTrigger(widget.switchId, trig.id);
              },
            ),
          ],
        ),
      ),
    );
  }
}
