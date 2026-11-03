import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:lembur/app/theme/app_colors.dart';
import 'package:lembur/core/utils/date_formatter.dart';
import 'package:lembur/core/utils/duration_calculator.dart';
import 'package:lembur/core/utils/overtime_pay_calculator.dart';
import 'package:lembur/features/settings/presentation/salary_settings_card.dart';
import 'package:lembur/core/widgets/neumorphic_button.dart';
import 'package:lembur/core/widgets/neumorphic_card.dart';
import 'package:lembur/core/widgets/neumorphic_text_field.dart';
import 'package:lembur/features/overtime/domain/overtime_entry.dart';
import 'package:lembur/features/overtime/presentation/overtime_provider.dart';
import 'package:lembur/features/settings/presentation/settings_provider.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';

class OvertimeFormPage extends StatefulWidget {
  const OvertimeFormPage({super.key, this.editId});

  final String? editId;

  @override
  State<OvertimeFormPage> createState() => _OvertimeFormPageState();
}

class _OvertimeFormPageState extends State<OvertimeFormPage> {
  final _formKey = GlobalKey<FormState>();
  final _dateController = TextEditingController();
  final _startController = TextEditingController();
  final _endController = TextEditingController();
  final _workController = TextEditingController();

  DateTime _date = DateTime.now();
  TimeOfDay _start = const TimeOfDay(hour: 16, minute: 0);
  TimeOfDay _end = const TimeOfDay(hour: 19, minute: 0);
  DayType _dayType = DayType.regular;
  String? _approverPosition;
  String? _approverName;
  bool _initialized = false;
  bool _saving = false;
  int? _wageOverrideCents;
  late bool _useProfileWage = widget.editId == null;
  int? _wageBasis(SettingsProvider settings) =>
      _useProfileWage ? settings.salary?.basisCents : _wageOverrideCents;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_initialized) {
      return;
    }

    final entry = context.read<OvertimeProvider>().byId(widget.editId);
    if (entry != null) {
      _wageOverrideCents = entry.monthlyWageBasisCents;
      // Older Lembur records do not have a saved wage basis. Use the profile
      // wage automatically when these entries are edited in KerjaKu PTC.
      _useProfileWage = entry.monthlyWageBasisCents == null;
      _date = entry.overtimeDate;
      _start = _parseTime(entry.startTime);
      _end = _parseTime(entry.endTime);
      _dayType = entry.dayType;
      _workController.text = entry.workDescription;
      _approverPosition = entry.approverPosition;
      _approverName = entry.approverName;
    }

    _syncControllers();
    _initialized = true;
  }

  TimeOfDay _parseTime(String value) {
    final parts = value.split(':');
    return TimeOfDay(hour: int.parse(parts[0]), minute: int.parse(parts[1]));
  }

  String _time(TimeOfDay value) {
    final hour = value.hour.toString().padLeft(2, '0');
    final minute = value.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }

  void _syncControllers() {
    _dateController.text = AppDateFormatter.full(_date);
    _startController.text = _time(_start);
    _endController.text = _time(_end);
  }

  double get _actual => DurationCalculator.actualHours(_start, _end);

  double get _converted => DurationCalculator.convertedHours(_actual, _dayType);

  Future<void> _pickDate() async {
    final value = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );

    if (value != null) {
      setState(() {
        _date = value;
        _syncControllers();
      });
    }
  }

  Future<void> _pickTime(bool start) async {
    final value = await showTimePicker(
      context: context,
      initialTime: start ? _start : _end,
    );

    if (value != null) {
      setState(() {
        if (start) {
          _start = value;
        } else {
          _end = value;
        }
        _syncControllers();
      });
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final settings = context.read<SettingsProvider>();
    final names = _names(settings);
    final selectedName =
        names.contains(_approverName) ? _approverName! : names.first;
    final positions = _positions(settings);
    final selectedPosition =
        positions.contains(_approverPosition)
            ? _approverPosition!
            : positions.first;
    final existing = context.read<OvertimeProvider>().byId(widget.editId);
    final now = DateTime.now();

    final entry = OvertimeEntry(
      id: existing?.id ?? const Uuid().v4(),
      overtimeDate: DateTime(_date.year, _date.month, _date.day),
      startTime: _time(_start),
      endTime: _time(_end),
      actualHours: _actual,
      convertedHours: _converted,
      dayType: _dayType,
      workDescription: _workController.text.trim(),
      approverPosition: selectedPosition,
      approverName: selectedName,
      createdAt: existing?.createdAt ?? now,
      updatedAt: now,
      monthlyWageBasisCents: _wageBasis(settings),
    );

    setState(() => _saving = true);
    try {
      await context.read<OvertimeProvider>().save(entry);
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Data lembur berhasil disimpan.')),
      );
      context.go('/history');
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Data belum tersimpan. Coba lagi.')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _saving = false);
      }
    }
  }

  List<String> _names(SettingsProvider settings) =>
      {
        ...settings.availableSignatories,
        if (_approverName != null &&
            SettingsProvider.isValidSignatory(_approverName!))
          _approverName!,
      }.toList();

  List<String> _positions(SettingsProvider settings) =>
      {
        ...settings.availableApproverPositions,
        if (_approverPosition != null && _approverPosition!.trim().isNotEmpty)
          _approverPosition!,
      }.toList();

  @override
  void dispose() {
    _dateController.dispose();
    _startController.dispose();
    _endController.dispose();
    _workController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsProvider>();
    final basis = _wageBasis(settings);
    final supportedDuration = _dayType != DayType.holiday || _actual <= 12;
    final pay =
        basis == null || !supportedDuration
            ? null
            : OvertimePayCalculator.calculate(
              monthlyBasisCents: basis,
              convertedHours: _converted,
            );
    final signatories = _names(settings);
    final positions = _positions(settings);
    final selectedApproverName =
        signatories.contains(_approverName)
            ? _approverName!
            : signatories.firstOrNull;
    final selectedPosition =
        positions.contains(_approverPosition)
            ? _approverPosition
            : positions.firstOrNull;

    return SafeArea(
      bottom: false,
      child: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(18, 18, 18, 190),
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          children: [
            Text(
              widget.editId == null ? 'Tambah Lembur' : 'Edit Lembur',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 5),
            Text(
              'Jam, konversi, dan estimasi upah dihitung otomatis. Pola 5 hari kerja per minggu.',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 22),
            if (signatories.isEmpty || positions.isEmpty)
              Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: NeumorphicCard(
                  child: Column(
                    children: [
                      const Text(
                        'Isi minimal satu nama dan jabatan penandatangan AFT di Profil.',
                      ),
                      TextButton(
                        onPressed: () => context.go('/settings'),
                        child: const Text('Buka profil'),
                      ),
                    ],
                  ),
                ),
              ),
            NeumorphicCard(
              child: Column(
                children: [
                  NeumorphicTextField(
                    controller: _dateController,
                    label: 'Tanggal lembur',
                    icon: Icons.calendar_month_rounded,
                    readOnly: true,
                    onTap: _pickDate,
                  ),
                  const SizedBox(height: 15),
                  Row(
                    children: [
                      Expanded(
                        child: NeumorphicTextField(
                          controller: _startController,
                          label: 'Jam mulai',
                          icon: Icons.schedule_rounded,
                          readOnly: true,
                          onTap: () => _pickTime(true),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: NeumorphicTextField(
                          controller: _endController,
                          label: 'Jam selesai',
                          icon: Icons.schedule_rounded,
                          readOnly: true,
                          onTap: () => _pickTime(false),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 15),
                  DropdownButtonFormField<DayType>(
                    value: _dayType,
                    isExpanded: true,
                    decoration: const InputDecoration(
                      labelText: 'Jenis hari',
                      prefixIcon: Icon(
                        Icons.today_rounded,
                        color: AppColors.primary,
                      ),
                    ),
                    items:
                        DayType.values
                            .map(
                              (type) => DropdownMenuItem<DayType>(
                                value: type,
                                child: Text(
                                  type.label,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            )
                            .toList(),
                    onChanged: (value) {
                      setState(() {
                        _dayType = value ?? DayType.regular;
                      });
                    },
                  ),
                  const SizedBox(height: 15),
                  NeumorphicTextField(
                    controller: _workController,
                    label: 'Pekerjaan yang dilemburkan',
                    hint: 'Contoh: Perbaikan unit refueller AYN-11',
                    icon: Icons.engineering_rounded,
                    maxLines: 3,
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Pekerjaan wajib diisi.';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 15),
                  DropdownButtonFormField<String>(
                    value: selectedPosition,
                    isExpanded: true,
                    decoration: const InputDecoration(
                      labelText: 'Jabatan penandatangan',
                      prefixIcon: Icon(
                        Icons.badge_rounded,
                        color: AppColors.primary,
                      ),
                    ),
                    items:
                        positions
                            .map(
                              (item) => DropdownMenuItem<String>(
                                value: item,
                                child: Text(
                                  item,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            )
                            .toList(),
                    onChanged: (value) {
                      setState(() {
                        _approverPosition = value;
                      });
                    },
                    validator:
                        (value) =>
                            value == null
                                ? 'Lengkapi jabatan di Profil.'
                                : null,
                  ),
                  const SizedBox(height: 15),
                  DropdownButtonFormField<String>(
                    value: selectedApproverName,
                    validator:
                        (value) =>
                            value == null
                                ? 'Lengkapi penandatangan di Profil.'
                                : null,
                    isExpanded: true,
                    decoration: const InputDecoration(
                      labelText: 'Nama penandatangan',
                      prefixIcon: Icon(
                        Icons.person_rounded,
                        color: AppColors.primary,
                      ),
                    ),
                    items:
                        signatories
                            .map(
                              (item) => DropdownMenuItem<String>(
                                value: item,
                                child: Text(
                                  item,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            )
                            .toList(),
                    onChanged: (value) {
                      setState(() => _approverName = value);
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 22),
            NeumorphicCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Hasil Perhitungan',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 15),
                  Row(
                    children: [
                      Expanded(
                        child: _ResultBox(
                          label: 'Jam nyata',
                          value:
                              '${DurationCalculator.displayHours(_actual)} jam',
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _ResultBox(
                          label: 'Jam konversi',
                          value:
                              '${DurationCalculator.displayHours(_converted)} jam',
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  const Row(
                    children: [
                      Icon(
                        Icons.verified_rounded,
                        size: 18,
                        color: AppColors.success,
                      ),
                      SizedBox(width: 7),
                      Expanded(
                        child: Text(
                          'Konversi untuk pola 5 hari kerja / 40 jam seminggu.',
                          style: TextStyle(
                            color: AppColors.success,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 22),
            NeumorphicCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Estimasi upah lembur',
                    style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    pay == null
                        ? 'Belum dihitung'
                        : OvertimePayCalculator.rupiah(pay),
                    key: const ValueKey('overtime-pay-preview'),
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  if (basis != null) ...[
                    const SizedBox(height: 8),
                    Text(
                      'Dasar upah: ${OvertimePayCalculator.basisLabel(basis)} / bulan',
                    ),
                    Text(
                      '${OvertimePayCalculator.basisLabel(basis)} ÷ 173 × ${OvertimePayCalculator.hours(_converted)} jam konversi',
                    ),
                    Text(
                      _useProfileWage
                          ? 'Menggunakan gaji profil saat ini.'
                          : 'Menggunakan dasar upah yang tersimpan pada catatan ini.',
                      style: const TextStyle(fontSize: 12),
                    ),
                  ] else ...[
                    const SizedBox(height: 8),
                    const Text(
                      'Isi gaji di Profil atau tentukan dasar upah untuk catatan ini.',
                    ),
                  ],
                  if (!supportedDuration)
                    const Text(
                      'Durasi hari libur melebihi 12 jam. Nominal belum dihitung; periksa jam dan ketentuan perusahaan.',
                      style: TextStyle(color: Colors.red),
                    ),
                  if (_dayType == DayType.regular && _actual > 4)
                    const Text(
                      'Periksa durasi: batas umum lembur hari kerja adalah 4 jam per hari.',
                      style: TextStyle(color: Colors.orange),
                    ),
                  const SizedBox(height: 8),
                  const Text(
                    'Bruto sebelum pajak dan potongan. Pembulatan rupiah dilakukan pada hasil akhir tiap catatan.',
                    style: TextStyle(fontSize: 12),
                  ),
                  Wrap(
                    spacing: 8,
                    children: [
                      if (settings.salary == null)
                        TextButton(
                          onPressed:
                              _saving ? null : () => context.push('/settings'),
                          child: const Text('Isi gaji di Profil'),
                        ),
                      if (settings.salary != null && !_useProfileWage)
                        TextButton(
                          key: const ValueKey('use-profile-wage'),
                          onPressed:
                              _saving
                                  ? null
                                  : () =>
                                      setState(() => _useProfileWage = true),
                          child: const Text('Gunakan gaji profil'),
                        ),
                      TextButton(
                        key: const ValueKey('edit-entry-wage'),
                        onPressed:
                            _saving
                                ? null
                                : () async {
                                  final value = await editOvertimeBasis(
                                    context,
                                    basis,
                                  );
                                  if (value != null && mounted) {
                                    setState(() {
                                      _wageOverrideCents = value;
                                      _useProfileWage = false;
                                    });
                                  }
                                },
                        child: const Text('Atur dasar upah catatan'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 22),
            NeumorphicButton(
              label: _saving ? 'Menyimpan...' : 'Simpan Lembur',
              icon: Icons.save_rounded,
              onPressed: _saving ? null : _save,
            ),
          ],
        ),
      ),
    );
  }
}

class _ResultBox extends StatelessWidget {
  const _ResultBox({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.primary.withAlpha(20),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: Theme.of(context).textTheme.bodySmall),
          const SizedBox(height: 5),
          Text(
            value,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w900,
              color: AppColors.primaryDark,
            ),
          ),
        ],
      ),
    );
  }
}
