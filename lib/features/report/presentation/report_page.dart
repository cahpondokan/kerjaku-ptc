import 'dart:io';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:lembur/app/theme/app_colors.dart';
import 'package:lembur/core/utils/date_formatter.dart';
import 'package:lembur/core/utils/duration_calculator.dart';
import 'package:lembur/core/widgets/app_empty_state.dart';
import 'package:lembur/core/widgets/neumorphic_button.dart';
import 'package:lembur/core/widgets/neumorphic_card.dart';
import 'package:lembur/features/overtime/domain/overtime_entry.dart';
import 'package:lembur/features/overtime/presentation/overtime_provider.dart';
import 'package:lembur/features/overtime/presentation/overtime_pay_summary.dart';
import 'package:lembur/features/report/data/report_export_service.dart';
import 'package:lembur/features/report/data/whatsapp_share_service.dart';
import 'package:lembur/features/settings/domain/user_profile.dart';
import 'package:lembur/features/settings/presentation/settings_provider.dart';
import 'package:lembur/features/settings/presentation/profile_completion_card.dart';
import 'package:printing/printing.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';

class ReportPage extends StatefulWidget {
  const ReportPage({super.key});

  @override
  State<ReportPage> createState() => _ReportPageState();
}

class _ReportPageState extends State<ReportPage> {
  final _exportService = ReportExportService();
  final _whatsAppService = WhatsAppShareService();

  DateTime _month = DateTime(DateTime.now().year, DateTime.now().month);
  bool _busy = false;

  @override
  Widget build(BuildContext context) {
    final overtime = context.watch<OvertimeProvider>();
    final entries = overtime.forMonth(_month);
    final settings = context.watch<SettingsProvider>();
    if (!settings.documentsReady) {
      return Scaffold(
        appBar: AppBar(title: const Text('Rekap Lembur')),
        body: ListView(
          padding: const EdgeInsets.all(18),
          children: [
            ProfileCompletionCard(onComplete: () => context.go('/settings')),
            const SizedBox(height: 18),
            const Text(
              'Pembuatan PDF, Excel, dan berbagi dokumen dibuka setelah seluruh data wajib siap.',
            ),
          ],
        ),
      );
    }
    final actual = entries.fold<double>(
      0,
      (sum, item) => sum + item.actualHours,
    );
    final converted = entries.fold<double>(
      0,
      (sum, item) => sum + item.convertedHours,
    );

    return Scaffold(
      appBar: AppBar(title: const Text('Rekap Lembur')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(18, 10, 18, 30),
          children: [
            NeumorphicCard(
              onTap: _busy ? null : _selectMonth,
              child: Row(
                children: [
                  const Icon(
                    Icons.calendar_month_rounded,
                    color: AppColors.primary,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      AppDateFormatter.month(_month),
                      style: const TextStyle(fontWeight: FontWeight.w900),
                    ),
                  ),
                  const Icon(Icons.keyboard_arrow_down_rounded),
                ],
              ),
            ),
            const SizedBox(height: 22),
            NeumorphicCard(
              child: Row(
                children: [
                  Expanded(
                    child: _ReportValue(
                      label: 'Data',
                      value: '${entries.length}',
                    ),
                  ),
                  Expanded(
                    child: _ReportValue(
                      label: 'Jam nyata',
                      value: DurationCalculator.displayHours(actual),
                    ),
                  ),
                  Expanded(
                    child: _ReportValue(
                      label: 'Konversi',
                      value: DurationCalculator.displayHours(converted),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 22),
            OvertimePaySummary(
              entries: entries,
              loading: overtime.loading,
              error: overtime.error,
            ),
            const SizedBox(height: 22),
            if (entries.isEmpty)
              const NeumorphicCard(
                child: AppEmptyState(
                  title: 'Belum dapat membuat rekap',
                  message:
                      'Tambahkan data lembur pada bulan ini terlebih dahulu.',
                ),
              )
            else if (!_entriesHaveSignatories(entries))
              NeumorphicCard(
                child: Column(
                  children: [
                    const Text(
                      'Periksa penandatangan pada catatan lembur',
                      style: TextStyle(fontWeight: FontWeight.w800),
                    ),
                    const SizedBox(height: 10),
                    const Text(
                      'Ada catatan dengan nama contoh atau jabatan kosong. Edit catatan tersebut sebelum membuat rekap.',
                    ),
                    TextButton(
                      onPressed: () => context.go('/history'),
                      child: const Text('Periksa riwayat'),
                    ),
                  ],
                ),
              )
            else ...[
              NeumorphicButton(
                label: _busy ? 'Memproses...' : 'Pratinjau / Cetak PDF SPKL',
                icon: Icons.picture_as_pdf_rounded,
                onPressed:
                    _busy
                        ? null
                        : () => _previewPdf(
                          entries,
                          settings.profile,
                          settings.ptcManagerName,
                          settings.ptcManagerPosition,
                        ),
              ),
              const SizedBox(height: 15),
              NeumorphicButton(
                label: _busy ? 'Memproses...' : 'Buat Excel Rekap',
                icon: Icons.table_view_rounded,
                primary: false,
                onPressed:
                    _busy
                        ? null
                        : () => _createExcel(entries, settings.profile),
              ),
              const SizedBox(height: 15),
              NeumorphicButton(
                label: _busy ? 'Memproses...' : 'Kirim ke WhatsApp Admin',
                icon: Icons.chat_rounded,
                onPressed:
                    _busy
                        ? null
                        : () => _sendToAdmin(
                          entries,
                          settings.profile,
                          settings.adminWhatsApp,
                          settings.ptcManagerName,
                          settings.ptcManagerPosition,
                        ),
              ),
              const SizedBox(height: 15),
              NeumorphicButton(
                label: _busy ? 'Memproses...' : 'Bagikan PDF + Excel',
                icon: Icons.share_rounded,
                primary: false,
                onPressed:
                    _busy
                        ? null
                        : () => _shareAll(
                          entries,
                          settings.profile,
                          settings.ptcManagerName,
                          settings.ptcManagerPosition,
                        ),
              ),
              const SizedBox(height: 16),
              NeumorphicCard(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(
                      Icons.info_outline_rounded,
                      color: AppColors.primary,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Setiap baris lembur dibuat menjadi satu halaman PDF. '
                        'Hanya nomor urut SPKL yang dikosongkan; tahun dokumen '
                        'mengikuti tahun tanggal lembur. Logo Pertamina Patra Niaga '
                        'dan PTC dicetak otomatis pada PDF.',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Future<void> _selectMonth() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _month,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
      helpText: 'Pilih bulan rekap',
    );
    if (date != null) {
      setState(() => _month = DateTime(date.year, date.month));
    }
  }

  Future<void> _previewPdf(
    List<OvertimeEntry> entries,
    UserProfile profile,
    String ptcManagerName,
    String ptcManagerPosition,
  ) async {
    if (!_validateRequirements(entries)) {
      return;
    }

    await _runBusy(() async {
      final file = await _exportService.createSpklPdf(
        entries: entries,
        profile: profile,
        month: _month,
        ptcManagerName: ptcManagerName,
        ptcManagerPosition: ptcManagerPosition,
      );
      await Printing.layoutPdf(
        name: file.path.split(Platform.pathSeparator).last,
        onLayout: (_) => file.readAsBytes(),
      );
    });
  }

  Future<void> _createExcel(
    List<OvertimeEntry> entries,
    UserProfile profile,
  ) async {
    if (!_validateRequirements(entries)) {
      return;
    }

    await _runBusy(() async {
      final file = await _exportService.createExcelReport(
        entries: entries,
        profile: profile,
        month: _month,
      );
      if (!mounted) {
        return;
      }
      await _showFileCreated(file);
    });
  }

  Future<void> _shareAll(
    List<OvertimeEntry> entries,
    UserProfile profile,
    String ptcManagerName,
    String ptcManagerPosition,
  ) async {
    if (!_validateRequirements(entries)) {
      return;
    }

    await _runBusy(() async {
      final reports = await _exportService.createAll(
        entries: entries,
        profile: profile,
        month: _month,
        ptcManagerName: ptcManagerName,
        ptcManagerPosition: ptcManagerPosition,
      );
      await SharePlus.instance.share(
        ShareParams(
          files: reports.all.map((file) => XFile(file.path)).toList(),
          text:
              'Dokumen lembur ${profile.name} periode ${AppDateFormatter.month(_month)}.',
          subject: 'Dokumen Lembur PTC',
          title: 'Bagikan dokumen lembur',
        ),
      );
    });
  }

  Future<void> _sendToAdmin(
    List<OvertimeEntry> entries,
    UserProfile profile,
    String adminNumber,
    String ptcManagerName,
    String ptcManagerPosition,
  ) async {
    if (!_validateRequirements(entries)) {
      return;
    }
    if (!WhatsAppShareService.isValidNumber(adminNumber)) {
      _showMessage(
        'Nomor WhatsApp admin belum diisi atau tidak valid. '
        'Silakan isi dari halaman Profil.',
      );
      return;
    }

    await _runBusy(() async {
      final reports = await _exportService.createAll(
        entries: entries,
        profile: profile,
        month: _month,
        ptcManagerName: ptcManagerName,
        ptcManagerPosition: ptcManagerPosition,
      );
      final message =
          'Assalamu’alaikum, berikut dokumen lembur ${profile.name} '
          'periode ${AppDateFormatter.month(_month)}. '
          'Terlampir PDF SPKL dan rekap Excel.';
      final outcome = await _whatsAppService.shareFilesToAdmin(
        files: reports.all,
        adminNumber: adminNumber,
        message: message,
      );

      if (!mounted) {
        return;
      }
      if (outcome == WhatsAppShareOutcome.directWhatsApp) {
        _showMessage(
          'WhatsApp dibuka ke admin dengan file siap dikirim. '
          'Periksa lalu tekan tombol Kirim di WhatsApp.',
        );
      } else {
        _showMessage(
          'Panel berbagi dibuka. Pilih WhatsApp lalu pilih admin '
          '(+${WhatsAppShareService.normalizeNumber(adminNumber)}).',
        );
      }
    });
  }

  bool _entriesHaveSignatories(List<OvertimeEntry> entries) => entries.every(
    (entry) =>
        SettingsProvider.isValidSignatory(entry.approverName) &&
        entry.approverPosition.trim().isNotEmpty,
  );

  bool _validateRequirements(List<OvertimeEntry> entries) {
    if (!context.read<SettingsProvider>().documentsReady) {
      _showMessage(
        'Lengkapi profil dan konfirmasi penandatangan terlebih dahulu pada Profil.',
      );
      return false;
    }
    if (!_entriesHaveSignatories(entries)) {
      _showMessage(
        'Periksa nama dan jabatan penandatangan pada riwayat lembur.',
      );
      return false;
    }
    return true;
  }

  Future<void> _runBusy(Future<void> Function() action) async {
    setState(() => _busy = true);
    try {
      await action();
    } catch (error) {
      if (mounted) {
        _showMessage('Proses gagal: $error');
      }
    } finally {
      if (mounted) {
        setState(() => _busy = false);
      }
    }
  }

  Future<void> _showFileCreated(File file) async {
    await showDialog<void>(
      context: context,
      builder:
          (dialogContext) => AlertDialog(
            title: const Text('Excel berhasil dibuat'),
            content: SelectableText('File tersimpan di:\n${file.path}'),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(dialogContext).pop(),
                child: const Text('Tutup'),
              ),
              FilledButton.icon(
                onPressed: () async {
                  await SharePlus.instance.share(
                    ShareParams(
                      files: [XFile(file.path)],
                      text:
                          'Rekap lembur periode ${AppDateFormatter.month(_month)}.',
                      title: 'Bagikan Excel rekap',
                    ),
                  );
                },
                icon: const Icon(Icons.share_rounded),
                label: const Text('Bagikan'),
              ),
            ],
          ),
    );
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }
}

class _ReportValue extends StatelessWidget {
  const _ReportValue({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w900,
            color: AppColors.primaryDark,
          ),
        ),
        const SizedBox(height: 4),
        Text(label, style: Theme.of(context).textTheme.bodySmall),
      ],
    );
  }
}
