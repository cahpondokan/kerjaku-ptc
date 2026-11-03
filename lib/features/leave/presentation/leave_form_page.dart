import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:lembur/app/theme/app_colors.dart';
import 'package:lembur/core/widgets/neumorphic_card.dart';
import 'package:lembur/features/leave/domain/leave_calculator.dart';
import 'package:lembur/features/leave/domain/leave_entry.dart';
import 'package:lembur/features/leave/presentation/leave_holiday_dialog.dart';
import 'package:lembur/features/leave/presentation/leave_initial_balance_card.dart';
import 'package:lembur/features/leave/presentation/leave_provider.dart';
import 'package:lembur/features/settings/presentation/profile_completion_card.dart';
import 'package:lembur/features/settings/presentation/settings_provider.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';

class LeaveFormPage extends StatefulWidget {
  const LeaveFormPage({super.key, this.editId});
  final String? editId;
  @override
  State<LeaveFormPage> createState() => _LeaveFormPageState();
}

class _LeaveFormPageState extends State<LeaveFormPage> {
  final _form = GlobalKey<FormState>();
  final _reason = TextEditingController();
  final _address = TextEditingController();
  late final String _id = widget.editId ?? const Uuid().v4();
  DateTime _start = DateUtils.dateOnly(DateTime.now());
  DateTime _end = DateUtils.dateOnly(DateTime.now());
  DateTime _requestDate = DateUtils.dateOnly(DateTime.now());
  String? _aftName;
  String? _aftPosition;
  bool _initialized = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final leave = context.watch<LeaveProvider>();
    final settings = context.watch<SettingsProvider>();
    if (_initialized || !leave.loaded || !settings.loaded) return;
    final entry = leave.byId(widget.editId);
    if (widget.editId != null && entry == null) return;
    if (entry != null) {
      _start = entry.startDate;
      _end = entry.endDate;
      _requestDate = entry.requestDate;
    } else {
      if (!LeaveCalculator.isWorkday(_start)) {
        _start = LeaveCalculator.returnDate(_start);
      }
      _end = _start;
    }
    _reason.text = entry?.reason ?? leave.defaults.reason;
    _address.text = entry?.address ?? leave.defaults.address;
    _aftName =
        entry?.aftName ??
        (settings.availableSignatories.contains(leave.defaults.aftName)
            ? leave.defaults.aftName
            : settings.availableSignatories.firstOrNull);
    _aftPosition =
        entry?.aftPosition ??
        (settings.availableApproverPositions.contains(
              leave.defaults.aftPosition,
            )
            ? leave.defaults.aftPosition
            : settings.availableApproverPositions.firstOrNull);
    _initialized = true;
  }

  @override
  void dispose() {
    _reason.dispose();
    _address.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final leave = context.watch<LeaveProvider>();
    final settings = context.watch<SettingsProvider>();
    final days = LeaveCalculator.workingDays(_start, _end);
    final calendarReady = LeaveCalculator.calendarError(_start, _end) == null;
    final dateError = leave.validateDates(_start, _end, exceptId: _id);
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.editId == null ? 'Buat Surat Cuti' : 'Ubah Surat Cuti',
        ),
      ),
      body:
          !leave.loaded || !settings.loaded
              ? Center(
                child:
                    leave.error == null
                        ? const CircularProgressIndicator()
                        : TextButton(
                          onPressed: leave.load,
                          child: const Text('Muat ulang data cuti'),
                        ),
              )
              : !settings.documentsReady
              ? ListView(
                padding: const EdgeInsets.all(20),
                children: [
                  ProfileCompletionCard(
                    onComplete: () => context.push('/settings'),
                  ),
                ],
              )
              : !_initialized
              ? const Center(child: Text('Surat cuti tidak ditemukan.'))
              : Form(
                key: _form,
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        settings.profile.name,
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'No. pekerja ${settings.profile.workerNumber}',
                        style: const TextStyle(color: AppColors.textSecondary),
                      ),
                      const SizedBox(height: 20),
                      const Text(
                        'Pilih tanggal cuti',
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 10),
                      OutlinedButton.icon(
                        key: const ValueKey('leave-dates'),
                        onPressed: leave.saving ? null : _pickDates,
                        icon: const Icon(Icons.date_range_rounded),
                        label: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          child: Text(
                            '${_format(_start)} – ${_format(_end)}',
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      NeumorphicCard(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              calendarReady
                                  ? '$days hari kerja'
                                  : 'Perlu kalender libur',
                              key: const ValueKey('leave-days'),
                              style: const TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.w900,
                                color: AppColors.primary,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              calendarReady
                                  ? 'Masuk kembali: ${_format(LeaveCalculator.returnDate(_end))}'
                                  : 'Masuk kembali: menunggu kalender libur',
                              key: const ValueKey('leave-return'),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              calendarReady
                                  ? 'Sisa setelah surat ini: ${leave.remaining(_start.year, exceptId: _id) - days} dari 12 hari'
                                  : 'Sisa cuti dihitung setelah kalender tersedia.',
                              key: const ValueKey('leave-remaining'),
                            ),
                            const SizedBox(height: 12),
                            const Text(
                              'Tanggal awal dan akhir ikut dihitung jika hari kerja. Sabtu, Minggu, libur nasional, dan cuti bersama dilewati.',
                              style: TextStyle(
                                fontSize: 12,
                                color: AppColors.textSecondary,
                              ),
                            ),
                            TextButton(
                              onPressed:
                                  () => showLeaveHolidays(context, _start.year),
                              child: Text('Lihat hari libur ${_start.year}'),
                            ),
                            if (dateError != null) ...[
                              const SizedBox(height: 10),
                              Text(
                                dateError,
                                style: const TextStyle(color: Colors.red),
                              ),
                            ],
                          ],
                        ),
                      ),
                      const SizedBox(height: 18),
                      LeaveInitialBalanceCard(year: _start.year),
                      const SizedBox(height: 18),
                      OutlinedButton.icon(
                        onPressed: leave.saving ? null : _pickRequestDate,
                        icon: const Icon(Icons.edit_calendar_outlined),
                        label: Text('Tanggal surat: ${_format(_requestDate)}'),
                      ),
                      const SizedBox(height: 20),
                      const Text(
                        'Isi surat',
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 6),
                      const Text(
                        'Alasan, alamat, dan pilihan penandatangan disimpan untuk surat berikutnya.',
                        style: TextStyle(
                          fontSize: 12,
                          color: AppColors.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _reason,
                        enabled: !leave.saving,
                        minLines: 2,
                        maxLines: 4,
                        maxLength: 300,
                        decoration: const InputDecoration(
                          labelText: 'Alasan cuti',
                          hintText: 'Contoh: Acara keluarga',
                        ),
                        validator: _required,
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _address,
                        enabled: !leave.saving,
                        minLines: 2,
                        maxLines: 4,
                        maxLength: 250,
                        decoration: const InputDecoration(
                          labelText: 'Alamat selama cuti',
                        ),
                        validator: _required,
                      ),
                      const SizedBox(height: 18),
                      DropdownButtonFormField<String>(
                        value:
                            settings.availableSignatories.contains(_aftName)
                                ? _aftName
                                : null,
                        isExpanded: true,
                        decoration: const InputDecoration(
                          labelText: 'Mengetahui / User',
                        ),
                        items: [
                          for (final name in settings.availableSignatories)
                            DropdownMenuItem(
                              value: name,
                              child: Text(
                                name,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                        ],
                        onChanged:
                            leave.saving
                                ? null
                                : (value) => setState(() => _aftName = value),
                        validator: _required,
                      ),
                      const SizedBox(height: 16),
                      DropdownButtonFormField<String>(
                        value:
                            settings.availableApproverPositions.contains(
                                  _aftPosition,
                                )
                                ? _aftPosition
                                : null,
                        isExpanded: true,
                        decoration: const InputDecoration(
                          labelText: 'Jabatan User',
                        ),
                        items: [
                          for (final role
                              in settings.availableApproverPositions)
                            DropdownMenuItem(
                              value: role,
                              child: Text(
                                role,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                        ],
                        onChanged:
                            leave.saving
                                ? null
                                : (value) =>
                                    setState(() => _aftPosition = value),
                        validator: _required,
                      ),
                      const SizedBox(height: 18),
                      NeumorphicCard(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Menyetujui / PTC',
                              style: TextStyle(fontWeight: FontWeight.w800),
                            ),
                            const SizedBox(height: 8),
                            Text(settings.ptcManagerName),
                            Text(settings.ptcManagerPosition),
                            TextButton(
                              onPressed:
                                  leave.saving
                                      ? null
                                      : () => context.push('/settings'),
                              child: const Text('Ubah di Profil'),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),
                      const Text(
                        'Di PDF, cuti yang sudah diambil hanya mencakup pemakaian sebelum surat ini. Sisa cuti = 12 − cuti sebelumnya − lama cuti ini. Menyimpan surat mencatat pemakaian cuti.',
                        style: TextStyle(
                          fontSize: 12,
                          color: AppColors.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 12),
                      FilledButton.icon(
                        key: const ValueKey('save-leave'),
                        onPressed:
                            leave.saving || dateError != null ? null : _save,
                        icon: const Icon(Icons.save_outlined),
                        label: Text(
                          leave.saving ? 'Menyimpan…' : 'Simpan & lihat PDF',
                        ),
                      ),
                      const SizedBox(height: 20),
                    ],
                  ),
                ),
              ),
    );
  }

  String _format(DateTime date) =>
      DateFormat('dd MMM yyyy', 'id_ID').format(date);
  String? _required(String? value) =>
      value == null || value.trim().isEmpty ? 'Wajib diisi.' : null;

  Future<void> _pickDates() async {
    final range = await showDateRangePicker(
      context: context,
      initialDateRange: DateTimeRange(start: _start, end: _end),
      firstDate: DateTime(2000),
      lastDate: DateTime(2100, 12, 31),
      helpText: 'PILIH AWAL DAN AKHIR CUTI',
      saveText: 'Pilih',
      confirmText: 'Pilih',
      cancelText: 'Batal',
      fieldStartLabelText: 'Tanggal awal',
      fieldEndLabelText: 'Tanggal akhir',
    );
    if (range != null && mounted) {
      setState(() {
        _start = range.start;
        _end = range.end;
      });
    }
  }

  Future<void> _pickRequestDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _requestDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100, 12, 31),
      helpText: 'TANGGAL SURAT',
      confirmText: 'Pilih',
      cancelText: 'Batal',
    );
    if (date != null && mounted) setState(() => _requestDate = date);
  }

  Future<void> _save() async {
    final settings = context.read<SettingsProvider>();
    final leave = context.read<LeaveProvider>();
    if (!settings.documentsReady ||
        leave.saving ||
        !_form.currentState!.validate()) {
      return;
    }
    if (!settings.availableSignatories.contains(_aftName) ||
        !settings.availableApproverPositions.contains(_aftPosition)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Pilih ulang penandatangan dan jabatannya.'),
        ),
      );
      return;
    }
    final entry = LeaveEntry(
      id: _id,
      startDate: _start,
      endDate: _end,
      requestDate: _requestDate,
      reason: _reason.text.trim(),
      address: _address.text.trim(),
      applicantName: settings.profile.name.trim(),
      workerNumber: settings.profile.workerNumber.trim(),
      aftName: _aftName!,
      aftPosition: _aftPosition!,
      managerName: settings.ptcManagerName,
      managerPosition: settings.ptcManagerPosition,
    );
    try {
      await leave.save(entry);
      if (mounted) context.pushReplacement('/leave/preview/$_id');
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              error is StateError
                  ? error.message.toString()
                  : 'Surat belum tersimpan. Coba lagi.',
            ),
          ),
        );
      }
    }
  }
}
