import 'package:flutter/material.dart';
import 'package:lembur/app/theme/app_colors.dart';
import 'package:lembur/features/settings/presentation/settings_provider.dart';
import 'package:provider/provider.dart';

/// One reminder per launch or return from the background, never per navigation.
class ProfileReminder extends StatefulWidget {
  const ProfileReminder({
    required this.navigatorKey,
    required this.onComplete,
    required this.child,
    super.key,
  });
  final GlobalKey<NavigatorState> navigatorKey;
  final VoidCallback onComplete;
  final Widget child;

  @override
  State<ProfileReminder> createState() => _ProfileReminderState();
}

class _ProfileReminderState extends State<ProfileReminder>
    with WidgetsBindingObserver {
  bool _pending = true;
  bool _scheduled = false;
  bool _visible = false;
  bool _backgrounded = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.hidden) {
      _backgrounded = true;
    } else if (state == AppLifecycleState.resumed && _backgrounded) {
      _backgrounded = false;
      if (!_visible) _pending = true;
      _scheduleReminder();
    }
  }

  void _scheduleReminder() {
    final settings = context.read<SettingsProvider>();
    if (!_pending || _scheduled || _visible || !settings.loaded) return;
    if (settings.documentsReady) {
      _pending = false;
      return;
    }
    _scheduled = true;
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      _scheduled = false;
      if (!mounted || !_pending || _visible) return;
      if (context.read<SettingsProvider>().documentsReady) {
        _pending = false;
        return;
      }
      final dialogContext = widget.navigatorKey.currentState?.overlay?.context;
      if (dialogContext == null) return;
      _pending = false;
      _visible = true;
      final complete = await showDialog<bool>(
        context: dialogContext,
        barrierDismissible: false,
        builder: (_) => const ProfileReminderDialog(),
      );
      _visible = false;
      if (mounted && complete == true) widget.onComplete();
    });
    WidgetsBinding.instance.ensureVisualUpdate();
  }

  @override
  Widget build(BuildContext context) {
    context.watch<SettingsProvider>();
    _scheduleReminder();
    return widget.child;
  }
}

class ProfileReminderDialog extends StatelessWidget {
  const ProfileReminderDialog({super.key});

  @override
  Widget build(BuildContext context) => AlertDialog(
    backgroundColor: const Color(0xFFF8FBFF),
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
    icon: const Icon(
      Icons.assignment_ind_outlined,
      size: 42,
      color: AppColors.primary,
    ),
    title: const Text(
      'Lengkapi data terlebih dahulu',
      textAlign: TextAlign.center,
    ),
    content: SingleChildScrollView(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Data ini dipakai pada rekap lembur dan surat cuti.'),
          const SizedBox(height: 20),
          const Text(
            'Profil pekerja',
            style: TextStyle(fontWeight: FontWeight.w800),
          ),
          const Text('Isi nama, nomor pekerja, dan data pekerjaan.'),
          const SizedBox(height: 16),
          const Text(
            'Daftar penandatangan',
            style: TextStyle(fontWeight: FontWeight.w800),
          ),
          const Text(
            'Periksa nama serta jabatan. Ubah jika belum sesuai, lalu konfirmasi.',
          ),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFFFF7E9),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Text(
              'Pengingat muncul setiap aplikasi dibuka sampai data wajib lengkap.',
              style: TextStyle(fontSize: 12, color: AppColors.warning),
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Lengkapi sekarang'),
            ),
          ),
          Center(
            child: TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Nanti'),
            ),
          ),
          const Center(
            child: Text(
              'Pembuatan dokumen tetap terkunci.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 11, color: AppColors.textSecondary),
            ),
          ),
        ],
      ),
    ),
  );
}
