import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lembur/core/widgets/neumorphic_card.dart';
import 'package:lembur/features/duty/presentation/duty_provider.dart';
import 'package:lembur/features/leave/presentation/leave_provider.dart';
import 'package:lembur/features/overtime/presentation/overtime_provider.dart';
import 'package:lembur/features/settings/data/backup_restore_service.dart';
import 'package:lembur/features/settings/presentation/settings_provider.dart';
import 'package:provider/provider.dart';

class BackupRestoreCard extends StatefulWidget {
  const BackupRestoreCard({super.key});

  @override
  State<BackupRestoreCard> createState() => _BackupRestoreCardState();
}

class _BackupRestoreCardState extends State<BackupRestoreCard> {
  static const _backupChannel = MethodChannel(
    'com.niam.ayani.kerjakuptc/backup',
  );
  final _service = BackupRestoreService();
  bool _working = false;

  Future<void> _export() async {
    setState(() => _working = true);
    try {
      final file = await _service.createBackup();
      if (!mounted) return;
      final saved = await _backupChannel.invokeMethod<bool>('saveBackup', {
        'fileName': file.uri.pathSegments.last,
        'bytes': await file.readAsBytes(),
      });
      if (saved == true) _showMessage('Berkas cadangan berhasil disimpan.');
    } catch (error) {
      _showMessage('Cadangan gagal dibuat: $error');
    } finally {
      if (mounted) setState(() => _working = false);
    }
  }

  Future<void> _import() async {
    try {
      final bytes = await _backupChannel.invokeMethod<Uint8List>('pickBackup');
      if (bytes == null || !mounted) return;
      final summary = await _service.inspectBackup(bytes);
      if (!mounted) return;
      final shouldRestore = await showDialog<bool>(
        context: context,
        builder:
            (dialogContext) => AlertDialog(
              title: const Text('Pulihkan cadangan?'),
              content: Text(
                'Berkas berisi ${summary.overtimeCount} catatan lembur dan '
                '${summary.leaveCount} surat cuti'
                '${summary.includesDuty ? ', serta ${summary.dutyCount} surat dinas' : ''}'
                '${summary.includesScans ? ' dan ${summary.scanPageCount} halaman scan' : ''}. '
                'Catatan yang tercakup dalam cadangan dan saldo akan diganti. '
                '${summary.includesDuty ? '' : 'Surat dinas di perangkat ini tetap dipertahankan. '}'
                '${summary.includesScans ? '' : 'Hasil scan beserta surat terkait yang sudah ada tetap dipertahankan. '}'
                'Pengaturan yang tidak ada dalam berkas tetap dipertahankan.',
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogContext, false),
                  child: const Text('Batal'),
                ),
                FilledButton(
                  onPressed: () => Navigator.pop(dialogContext, true),
                  child: const Text('Pulihkan'),
                ),
              ],
            ),
      );
      if (shouldRestore != true || !mounted) return;

      setState(() => _working = true);
      final settings = context.read<SettingsProvider>();
      final overtime = context.read<OvertimeProvider>();
      final leave = context.read<LeaveProvider>();
      final duty = context.read<DutyProvider>();
      final restored = await _service.restoreBackup(bytes);
      await Future.wait([
        settings.load(),
        overtime.load(),
        leave.load(),
        duty.load(),
      ]);
      _showMessage(
        'Pemulihan selesai: ${restored.overtimeCount} lembur dan '
        '${restored.leaveCount} surat cuti'
        '${restored.includesDuty ? ', ${restored.dutyCount} surat dinas' : ''}'
        '${restored.includesScans ? ', ${restored.scanPageCount} halaman scan' : ''}.',
      );
    } catch (error) {
      _showMessage('Impor gagal: $error');
    } finally {
      if (mounted) setState(() => _working = false);
    }
  }

  void _showMessage(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    return NeumorphicCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.backup_rounded),
              SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Cadangkan atau pindahkan data',
                  style: TextStyle(fontWeight: FontWeight.w800),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          const Text(
            'Cadangan mencakup catatan lembur, surat cuti, surat dinas, seluruh gambar scan, profil, dan pengaturan. '
            'Simpan berkas JSON di tempat yang aman.',
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _working ? null : _export,
                  icon: const Icon(Icons.file_upload_outlined),
                  label: const Text('Ekspor'),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: FilledButton.icon(
                  onPressed: _working ? null : _import,
                  icon: const Icon(Icons.file_download_outlined),
                  label: const Text('Impor'),
                ),
              ),
            ],
          ),
          if (_working) ...[
            const SizedBox(height: 12),
            const LinearProgressIndicator(),
          ],
        ],
      ),
    );
  }
}
