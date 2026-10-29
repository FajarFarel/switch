import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../app/routes.dart';
import '../auth/auth_controller.dart';
import '../switches/switch_controller.dart';
import '../../models/switch_model.dart';
import '../../app/colors.dart';

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
                validator: (v) =>
                    v == null || v.trim().isEmpty ? 'Wajib diisi' : null,
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
                style: const TextStyle(
                  color: AppColors.textMuted,
                  fontSize: 12,
                ),
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
      case 'GRACE':
        return Colors.yellow;
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
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        backgroundColor: AppColors.panelRaised,
        foregroundColor: AppColors.text,
        elevation: 0,
        centerTitle: false,
        titleSpacing: 16,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              "Andhika's Switch",
              style: TextStyle(
                fontSize: 18,
                color: AppColors.text,
                fontWeight: FontWeight.w600,
              ),
            ),
            if (user != null)
              Text(
                'Halo, ${user.username}',
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.normal,
                  color: AppColors.textMuted,
                ),
              ),
          ],
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: GestureDetector(
              onTap: () async {
                await authController.logout();
                if (context.mounted) {
                  context.go(AppRoutes.login);
                }
              },
              child: Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: AppColors.red,
                  shape: BoxShape.circle,
                  border: Border.all(color: AppColors.redDim, width: 1),
                ),
                child: Center(
                  child: Image.asset(
                    'assets/logoutrounded.png',
                    width: 34,
                    height: 34,
                    fit: BoxFit.contain,
                  ),
                ),
              ),
            ),
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
                      'Belum ada switch.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.grey, fontSize: 16),
                    ),
                  ),
                ],
              )
            : LayoutBuilder(
                builder: (context, constraints) {
                  final width = constraints.maxWidth;

                  final crossAxisCount = width >= 900
                      ? 4
                      : width >= 600
                      ? 3
                      : width >= 350
                      ? 2
                      : 1;

                  return GridView.builder(
                    padding: const EdgeInsets.all(16),
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: crossAxisCount,
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12,
                      childAspectRatio: 1,
                    ),
                    itemCount: switchController.switches.length,
                    itemBuilder: (context, index) {
                      final item = switchController.switches[index];
                      return _buildSwitchCard(context, item, switchController);
                    },
                  );
                },
              ),
      ),
    );
  }

  String _getRemainingTime(dynamic deadline) {
    if (deadline == null) return '--';

    final date = DateTime.tryParse(deadline.toString());
    if (date == null) return '--';

    final remaining = date.difference(DateTime.now());

    if (remaining.isNegative || remaining.inSeconds == 0) {
      return 'Waktu habis';
    }

    final days = remaining.inDays;
    final hours = remaining.inHours % 24;
    final minutes = remaining.inMinutes % 60;
    final seconds = remaining.inSeconds % 60;

    if (days > 0) {
      return '${days}h ${hours}j';
    }
    if (remaining.inHours > 0) {
      return '${remaining.inHours}j ${minutes}m';
    }
    if (remaining.inMinutes > 0) {
      return '${remaining.inMinutes}m ${seconds}d';
    }

    return '${seconds} detik';
  }

  Widget _buildSwitchCard(
    BuildContext context,
    SwitchModel item,
    SwitchController controller,
  ) {
    final statusColor = _getStatusColor(item.status);

    return Card(
      margin: EdgeInsets.zero,
      elevation: 0,
      color: AppColors.panel,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
        side: const BorderSide(color: AppColors.border, width: 1),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => _showSwitchPopup(context, item, controller),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                item.name,
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: AppColors.text,
                ),
              ),
              const SizedBox(height: 8),

              Text(
                'Sisa waktu',
                style: const TextStyle(
                  fontSize: 12,
                  color: AppColors.textMuted,
                ),
              ),
              const SizedBox(height: 3),

              Text(
                _getRemainingTime(item.nextDeadlineAt),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 13, color: AppColors.text),
              ),
              const SizedBox(height: 12),

              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: statusColor),
                ),
                child: Text(
                  item.status,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: statusColor,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showSwitchPopup(
    BuildContext context,
    SwitchModel item,
    SwitchController controller,
  ) {
    final statusColor = _getStatusColor(item.status);

    showDialog(
      context: context,
      builder: (dialogContext) {
        return Dialog(
          backgroundColor: AppColors.panel,
          insetPadding: const EdgeInsets.symmetric(horizontal: 24),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: const BorderSide(color: AppColors.border),
          ),
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(22),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          item.name,
                          style: const TextStyle(
                            fontSize: 30,
                            fontWeight: FontWeight.w700,
                            color: AppColors.text,
                          ),
                        ),
                      ),
                      IconButton(
                        onPressed: () => Navigator.pop(dialogContext),
                        icon: const Icon(
                          Icons.close,
                          color: AppColors.textMuted,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 20),

                  const Text(
                    'Deskripsi',
                    style: TextStyle(fontSize: 14, color: AppColors.textMuted),
                  ),
                  const SizedBox(height: 8),

                  Text(
                    'Switch keamanan untuk memantau check-in '
                    'secara berkala.',
                    style: const TextStyle(fontSize: 14, color: AppColors.text),
                  ),

                  const SizedBox(height: 20),

                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: AppColors.panelRaised,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Expanded(
                              child: Text(
                                'Status',
                                style: TextStyle(
                                  color: AppColors.textMuted,
                                  fontSize: 13,
                                ),
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 5,
                              ),
                              decoration: BoxDecoration(
                                color: statusColor.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(color: statusColor),
                              ),
                              child: Text(
                                item.status,
                                style: TextStyle(
                                  color: statusColor,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 18),

                        const Text(
                          'Sisa waktu',
                          style: TextStyle(
                            color: AppColors.textMuted,
                            fontSize: 13,
                          ),
                        ),
                        const SizedBox(height: 5),

                        Text(
                          _getRemainingTime(item.nextDeadlineAt),
                          style: const TextStyle(
                            color: AppColors.text,
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                          ),
                        ),

                        const SizedBox(height: 18),

                        _popupInfoRow(
                          'Waktu interval',
                          '${item.checkinInterval} menit',
                        ),
                        const SizedBox(height: 12),
                        _popupInfoRow(
                          'Grace period',
                          '${item.gracePeriod} menit',
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 22),

                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton.icon(
                      onPressed: item.status.toUpperCase() != 'ARMED'
                          ? null
                          : () async {
                              final messenger = ScaffoldMessenger.of(context);

                              final ok = await controller.checkinSwitch(
                                item.id,
                              );

                              if (!mounted) return;

                              if (dialogContext.mounted) {
                                Navigator.pop(dialogContext);
                              }

                              messenger.showSnackBar(
                                SnackBar(
                                  content: Text(
                                    ok
                                        ? 'Waktu switch berhasil direset'
                                        : (controller.errorMessage ??
                                              'Gagal mereset waktu'),
                                  ),
                                ),
                              );
                            },
                      icon: const Icon(Icons.refresh_rounded),
                      label: const Text('Reset'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.red,
                        foregroundColor: AppColors.text,
                        disabledBackgroundColor: AppColors.panelRaised,
                        disabledForegroundColor: AppColors.textDim,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _popupInfoRow(String label, String value) {
    return Row(
      children: [
        Expanded(
          child: Text(
            label,
            style: const TextStyle(color: AppColors.textMuted, fontSize: 13),
          ),
        ),
        Text(
          value,
          style: const TextStyle(
            color: AppColors.text,
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}
