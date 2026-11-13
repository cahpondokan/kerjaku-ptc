import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:lembur/app/theme/app_colors.dart';
import 'package:lembur/core/widgets/neumorphic_card.dart';
import 'package:lembur/features/duty/presentation/duty_provider.dart';
import 'package:lembur/features/duty/presentation/duty_widgets.dart';
import 'package:provider/provider.dart';

class DutyPage extends StatefulWidget {
  const DutyPage({super.key});
  @override
  State<DutyPage> createState() => _DutyPageState();
}

class _DutyPageState extends State<DutyPage> {
  String _query = '';
  int _filter = 0;
  int? _year;
  @override
  Widget build(BuildContext context) {
    final provider = context.watch<DutyProvider>();
    final all = provider.entries;
    final years =
        all.map((e) => e.requestDate.year).toSet().toList()
          ..sort((a, b) => b.compareTo(a));
    if (_year != null && !years.contains(_year)) _year = null;
    final visible =
        all
            .where(
              (e) =>
                  (_year == null || e.requestDate.year == _year) &&
                  (_filter == 0 || (_filter == 1 ? e.isDraft : !e.isDraft)) &&
                  '${e.origin} ${e.destination} ${e.purpose} ${e.applicantName} ${e.letterNumber}'
                      .toLowerCase()
                      .contains(_query.toLowerCase()),
            )
            .toList();
    return Scaffold(
      appBar: AppBar(title: const Text('Surat Dinas')),
      bottomNavigationBar: SafeArea(
        minimum: const EdgeInsets.all(18),
        child: FilledButton.icon(
          onPressed: provider.loaded ? () => context.push('/duty/form') : null,
          icon: const Icon(Icons.add),
          label: const Text('Buat surat dinas'),
        ),
      ),
      body:
          !provider.loaded
              ? Center(
                child:
                    provider.error == null
                        ? const CircularProgressIndicator()
                        : TextButton(
                          onPressed: provider.load,
                          child: const Text('Muat ulang surat dinas'),
                        ),
              )
              : RefreshIndicator(
                onRefresh: provider.load,
                child: ListView(
                  padding: const EdgeInsets.all(18),
                  children: [
                    const Text(
                      'Kelola permintaan perjalanan dinas',
                      style: TextStyle(color: AppColors.textSecondary),
                    ),
                    const SizedBox(height: 18),
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF3C8BFA), AppColors.primary],
                        ),
                        borderRadius: BorderRadius.circular(22),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Surat dinas Anda',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w800,
                              fontSize: 18,
                            ),
                          ),
                          const SizedBox(height: 20),
                          Row(
                            children: [
                              _count(all.length, 'Total'),
                              _count(
                                all.where((e) => e.isDraft).length,
                                'Draf',
                              ),
                              _count(
                                all.where((e) => !e.isDraft).length,
                                'Tersimpan',
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                    TextField(
                      decoration: const InputDecoration(
                        hintText: 'Cari tujuan atau keperluan',
                        prefixIcon: Icon(Icons.search),
                      ),
                      onChanged: (v) => setState(() => _query = v),
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<int?>(
                      value: _year,
                      isExpanded: true,
                      isDense: false,
                      itemHeight: null,
                      decoration: const InputDecoration(
                        labelText: 'Tahun surat',
                      ),
                      items: [
                        const DropdownMenuItem<int?>(
                          value: null,
                          child: Text('Semua tahun'),
                        ),
                        for (final y in years)
                          DropdownMenuItem(value: y, child: Text('$y')),
                      ],
                      onChanged: (v) => setState(() => _year = v),
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      children: List.generate(
                        3,
                        (i) => ChoiceChip(
                          label: Text(['Semua', 'Draf', 'Tersimpan'][i]),
                          selected: _filter == i,
                          onSelected: (_) => setState(() => _filter = i),
                        ),
                      ),
                    ),
                    const SizedBox(height: 18),
                    if (provider.error != null)
                      Text(
                        provider.error!,
                        style: const TextStyle(color: AppColors.danger),
                      ),
                    if (visible.isEmpty)
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 36),
                        child: Text(
                          'Belum ada surat yang sesuai. Tekan Buat surat dinas untuk memulai.',
                          textAlign: TextAlign.center,
                        ),
                      ),
                    for (final entry in visible)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 16),
                        child: NeumorphicCard(
                          onTap:
                              () => context.push(
                                entry.isDraft
                                    ? '/duty/form?editId=${entry.id}'
                                    : '/duty/detail/${entry.id}',
                              ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Icon(
                                    Icons.work_outline_rounded,
                                    color: AppColors.primary,
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Text(
                                      '${entry.origin.isEmpty ? 'Asal' : entry.origin} → ${entry.destination.isEmpty ? 'Tujuan' : entry.destination}',
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w800,
                                        fontSize: 17,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  DutyStatus(draft: entry.isDraft),
                                ],
                              ),
                              const SizedBox(height: 14),
                              Text(
                                dutyRange(entry),
                                style: const TextStyle(
                                  color: AppColors.textSecondary,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                entry.purpose.isEmpty
                                    ? 'Keperluan belum diisi'
                                    : entry.purpose,
                              ),
                              const Divider(height: 28),
                              Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      entry.isDraft
                                          ? 'Lanjutkan pengisian'
                                          : entry.applicantName,
                                    ),
                                  ),
                                  const Icon(Icons.chevron_right_rounded),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                  ],
                ),
              ),
    );
  }

  Widget _count(int number, String label) => Expanded(
    child: Column(
      children: [
        Text(
          '$number',
          style: const TextStyle(
            color: Colors.white,
            fontSize: 28,
            fontWeight: FontWeight.w900,
          ),
        ),
        Text(label, style: const TextStyle(color: Colors.white)),
      ],
    ),
  );
}
