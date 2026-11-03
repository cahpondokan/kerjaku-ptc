import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:lembur/features/leave/data/leave_pdf_service.dart';
import 'package:lembur/features/leave/domain/leave_calculator.dart';
import 'package:lembur/features/leave/presentation/leave_provider.dart';
import 'package:lembur/features/settings/presentation/profile_completion_card.dart';
import 'package:lembur/features/settings/presentation/settings_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:printing/printing.dart';
import 'package:provider/provider.dart';

class LeavePreviewPage extends StatelessWidget {
  const LeavePreviewPage({super.key, required this.id});
  final String id;
  @override
  Widget build(BuildContext context) {
    final leave = context.watch<LeaveProvider>();
    final ready = context.watch<SettingsProvider>().documentsReady;
    final entry = leave.byId(id);
    final dateError =
        entry == null
            ? null
            : LeaveCalculator.validateRange(entry.startDate, entry.endDate);
    return Scaffold(
      appBar: AppBar(title: const Text('PDF Surat Cuti')),
      body:
          !ready
              ? ListView(
                padding: const EdgeInsets.all(20),
                children: [
                  ProfileCompletionCard(
                    onComplete: () => context.push('/settings'),
                  ),
                ],
              )
              : !leave.loaded
              ? Center(
                child:
                    leave.error == null
                        ? const CircularProgressIndicator()
                        : TextButton(
                          onPressed: leave.load,
                          child: const Text('Muat ulang data cuti'),
                        ),
              )
              : entry == null
              ? const Center(child: Text('Surat cuti tidak ditemukan.'))
              : dateError != null
              ? Padding(
                padding: const EdgeInsets.all(20),
                child: Text(dateError),
              )
              : PdfPreview(
                key: ValueKey('${entry.toMap()}-${leave.usedBefore(entry)}'),
                pdfFileName:
                    'Surat_Cuti_${entry.year}_${entry.startDate.month}_${entry.startDate.day}.pdf',
                initialPageFormat: PdfPageFormat.a4.landscape,
                canChangeOrientation: false,
                canChangePageFormat: false,
                canDebug: false,
                build: (_) {
                  if (!context.read<SettingsProvider>().documentsReady) {
                    throw StateError(
                      'Lengkapi profil dan konfirmasi penandatangan.',
                    );
                  }
                  return LeavePdfService().build(
                    entry: entry,
                    usedBeforeCurrent: leave.usedBefore(entry),
                  );
                },
              ),
    );
  }
}
