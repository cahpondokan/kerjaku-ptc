import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:lembur/app/theme/app_colors.dart';
import 'package:lembur/features/duty/domain/duty_entry.dart';
import 'package:lembur/features/duty/presentation/duty_provider.dart';
import 'package:lembur/features/duty/presentation/duty_widgets.dart';
import 'package:lembur/features/settings/presentation/profile_completion_card.dart';
import 'package:lembur/features/settings/presentation/settings_provider.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';

class DutyFormPage extends StatefulWidget {
  const DutyFormPage({super.key, this.editId});
  final String? editId;
  @override
  State<DutyFormPage> createState() => _DutyFormPageState();
}

class _DutyFormPageState extends State<DutyFormPage> {
  final _form = GlobalKey<FormState>();
  final _scroll = ScrollController();
  final _fields = <String, TextEditingController>{
    for (final key in DutyEntry.fieldLimits.keys) key: TextEditingController(),
  };
  late final String _id = widget.editId ?? const Uuid().v4();
  DateTime _date = DateUtils.dateOnly(DateTime.now());
  DateTime _created = DateTime.now();
  DateTime? _start, _return;
  bool _initialized = false,
      _dirty = false,
      _allowPop = false,
      _reviewed = false;
  int _step = 0;
  String? _error;

  String _value(String key) => _fields[key]!.text.trim();

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final provider = context.watch<DutyProvider>();
    final settings = context.watch<SettingsProvider>();
    if (_initialized || !provider.loaded || !settings.loaded) return;
    final saved = provider.byId(widget.editId);
    if (widget.editId != null && saved == null) return;
    if (saved != null) {
      final map = saved.toMap();
      for (final key in _fields.keys) {
        _fields[key]!.text = map[key] as String;
      }
      _date = saved.requestDate;
      _created = saved.createdAt;
      _start = saved.startDate;
      _return = saved.returnDate;
    } else {
      _copyProfile(settings);
      _fields['transport']!.text = 'Umum';
      final recent = provider.entries.firstOrNull;
      _fields['request_place']!.text = recent?.requestPlace ?? '';
      _fields['origin']!.text = recent?.origin ?? '';
      _fields['signer_name']!.text =
          settings.availableSignatories.contains(recent?.signerName)
              ? recent!.signerName
              : settings.availableSignatories.firstOrNull ?? '';
      _fields['signer_position']!.text =
          settings.availableApproverPositions.contains(recent?.signerPosition)
              ? recent!.signerPosition
              : settings.availableApproverPositions.firstOrNull ?? '';
    }
    _initialized = true;
  }

  void _copyProfile(SettingsProvider settings) {
    final profile = settings.profile;
    final values = {
      'applicant_name': profile.name,
      'worker_number': profile.workerNumber,
      'placement': profile.placement,
      'job_type': profile.jobType,
      'recipient': profile.company,
      'cost_bearer': profile.costBearer,
    };
    for (final entry in values.entries) {
      _fields[entry.key]!.text = entry.value;
    }
  }

  @override
  void dispose() {
    for (final field in _fields.values) {
      field.dispose();
    }
    _scroll.dispose();
    super.dispose();
  }

  DutyEntry _entry({required bool draft}) => DutyEntry(
    id: _id,
    requestDate: _date,
    createdAt: _created,
    updatedAt: DateTime.now(),
    serial: _value('serial'),
    recipient: _value('recipient'),
    applicantName: _value('applicant_name'),
    workerNumber: _value('worker_number'),
    placement: _value('placement'),
    jobType: _value('job_type'),
    origin: _value('origin'),
    destination: _value('destination'),
    startDate: _start,
    returnDate: _return,
    purpose: _value('purpose'),
    transport: _value('transport'),
    costBearer: _value('cost_bearer'),
    requestPlace: _value('request_place'),
    signerName: _value('signer_name'),
    signerPosition: _value('signer_position'),
    isDraft: draft,
  );

  void _changed() {
    setState(() {
      _dirty = true;
      _reviewed = false;
      _error = null;
    });
  }

  Widget _field(
    String key,
    String label, {
    int lines = 1,
    bool required = true,
  }) => Padding(
    padding: const EdgeInsets.only(bottom: 14),
    child: TextFormField(
      key: ValueKey('duty-$key'),
      controller: _fields[key],
      minLines: lines,
      maxLines: lines == 1 ? 1 : lines + 1,
      maxLength: DutyEntry.fieldLimits[key],
      keyboardType: key == 'serial' ? TextInputType.number : null,
      inputFormatters:
          key == 'serial' ? [FilteringTextInputFormatter.digitsOnly] : null,
      decoration: InputDecoration(
        labelText: label,
        alignLabelWithHint: true,
        counterText: '',
        hintText: key == 'serial' ? 'Diisi admin' : null,
      ),
      onChanged: (_) => _changed(),
      validator:
          (value) =>
              required && (value == null || value.trim().isEmpty)
                  ? 'Wajib diisi.'
                  : null,
    ),
  );

  Widget _signerField(String key, String label, List<String> options) {
    final value = _value(key);
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: DropdownButtonFormField<String>(
        key: ValueKey('duty-$key-${options.join('|')}'),
        value: options.contains(value) ? value : null,
        isExpanded: true,
        isDense: false,
        itemHeight: null,
        decoration: InputDecoration(
          labelText: label,
          hintText: 'Pilih dari Profil',
        ),
        selectedItemBuilder:
            (context) =>
                options
                    .map(
                      (v) => Align(
                        alignment: Alignment.centerLeft,
                        heightFactor: 1,
                        child: Text(v, style: const TextStyle(fontSize: 13)),
                      ),
                    )
                    .toList(),
        items:
            options
                .map(
                  (v) => DropdownMenuItem(
                    value: v,
                    child: Text(v, style: const TextStyle(fontSize: 13)),
                  ),
                )
                .toList(),
        onChanged: (v) {
          _fields[key]!.text = v ?? '';
          _changed();
        },
        validator:
            (v) =>
                v == null || !options.contains(v)
                    ? 'Pilih dari daftar di Profil.'
                    : null,
      ),
    );
  }

  Future<void> _profile() async {
    await context.push('/settings');
    if (!mounted) return;
    if (widget.editId == null) {
      _copyProfile(context.read<SettingsProvider>());
      _changed();
    }
  }

  List<Widget> _stepWidgets(SettingsProvider settings) => switch (_step) {
    0 => [
      DutySection(
        title: 'Data pekerja',
        action: TextButton(onPressed: _profile, child: const Text('Profil')),
        children: [
          const Text(
            'Terisi dari Profil Anda',
            style: TextStyle(color: AppColors.textSecondary),
          ),
          DutyFact('Nama', _value('applicant_name')),
          DutyFact('No. ID Card', _value('worker_number')),
          DutyFact('Bagian / Penempatan', _value('placement')),
          DutyFact('Jenis Pekerjaan', _value('job_type')),
          if (widget.editId != null)
            TextButton(
              onPressed: () {
                _copyProfile(settings);
                _changed();
              },
              child: const Text('Perbarui isian dari Profil'),
            ),
        ],
      ),
      DutySection(
        title: 'Tujuan surat',
        children: [_field('recipient', 'Kepada', lines: 2)],
      ),
      DutySection(
        title: 'Nomor surat',
        children: [
          _field('serial', 'Nomor urut (opsional)', required: false),
          const Text(
            'Kosongkan untuk diisi dengan pena setelah dicetak.',
            style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
          ),
          const SizedBox(height: 14),
          const Text(
            'Bulan & tahun otomatis',
            style: TextStyle(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 8),
          Text(
            DutyEntry.numberFor(_date, _value('serial')),
            key: const ValueKey('duty-letter-number'),
            style: const TextStyle(
              color: AppColors.primary,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Mengikuti tanggal surat: ${dutyDate(_date)}',
            style: const TextStyle(
              fontSize: 12,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
      const Text('Tanggal dan penandatangan dipilih pada langkah terakhir.'),
    ],
    1 => [
      DutySection(
        title: 'Rincian perjalanan',
        children: [
          const Text('Perjalanan dinas dalam negeri'),
          const SizedBox(height: 14),
          _field('origin', 'Dari / Asal'),
          _field('destination', 'Tempat / Tujuan'),
        ],
      ),
      DutySection(
        title: 'Tanggal perjalanan',
        children: [
          _dateButton(
            'Terhitung mulai',
            _start,
            (v) => _start = v,
            'duty-start',
          ),
          const SizedBox(height: 10),
          _dateButton(
            'Kembali tanggal',
            _return,
            (v) => _return = v,
            'duty-return',
          ),
          const SizedBox(height: 10),
          if (_entry(draft: true).calendarDays case final days?)
            Text(
              days < 1
                  ? 'Tanggal kembali harus setelah atau sama dengan tanggal mulai.'
                  : '$days hari kalender · termasuk tanggal mulai dan kembali',
              style: TextStyle(
                color: days < 1 ? AppColors.danger : AppColors.primary,
              ),
            ),
        ],
      ),
      DutySection(
        title: 'Keperluan & biaya',
        children: [
          _field('purpose', 'Keperluan', lines: 3),
          _field('transport', 'Berkendaraan'),
          _field('cost_bearer', 'Biaya ditanggung oleh', lines: 2),
          const Text(
            'Penanggung biaya terisi dari Profil dan dapat diubah untuk surat ini.',
            style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
          ),
        ],
      ),
    ],
    _ => [
      DutySection(
        title: 'Tanggal & tempat surat',
        children: [
          _field('request_place', 'Tempat surat'),
          _dateButton(
            'Tanggal surat',
            _date,
            (v) => _date = v,
            'duty-request-date',
          ),
          const SizedBox(height: 10),
          Text(
            DutyEntry.numberFor(_date, _value('serial')),
            key: const ValueKey('duty-letter-number'),
            style: const TextStyle(
              color: AppColors.primary,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
      DutySection(
        title: 'Penandatangan',
        action: TextButton(onPressed: _profile, child: const Text('Profil')),
        children: [
          const Text(
            'Menggunakan daftar penandatangan yang sudah ada.',
            style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
          ),
          const SizedBox(height: 14),
          _signerField(
            'signer_name',
            'Nama penandatangan',
            settings.availableSignatories,
          ),
          _signerField(
            'signer_position',
            'Jabatan',
            settings.availableApproverPositions,
          ),
          const Text('Nama dan jabatan dicetak pada surat.'),
        ],
      ),
      DutySection(
        title: 'Periksa kembali',
        children: [
          DutyFact('Pekerja', _value('applicant_name')),
          DutyFact(
            'Perjalanan',
            '${_value('origin')} → ${_value('destination')}',
          ),
          DutyFact('Tanggal', dutyRange(_entry(draft: true))),
          DutyFact('Keperluan', _value('purpose')),
          DutyFact('Berkendaraan', _value('transport')),
          DutyFact('Biaya ditanggung oleh', _value('cost_bearer')),
        ],
      ),
      CheckboxListTile(
        key: const ValueKey('duty-reviewed'),
        contentPadding: EdgeInsets.zero,
        controlAffinity: ListTileControlAffinity.leading,
        title: const Text('Data surat sudah saya periksa'),
        value: _reviewed,
        onChanged:
            (v) => setState(() {
              _reviewed = v ?? false;
              _dirty = true;
            }),
      ),
      const Text(
        'Ruang tanda tangan tersedia pada surat cetak.',
        style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
      ),
    ],
  };

  Widget _dateButton(
    String label,
    DateTime? value,
    void Function(DateTime) assign,
    String key,
  ) => OutlinedButton.icon(
    key: ValueKey(key),
    onPressed: () async {
      final picked = await showDatePicker(
        context: context,
        initialDate: value ?? _date,
        firstDate: DateTime(2000),
        lastDate: DateTime(2100, 12, 31),
        helpText: label,
        cancelText: 'Batal',
        confirmText: 'Pilih',
      );
      if (picked != null && mounted) {
        assign(DateUtils.dateOnly(picked));
        _changed();
      }
    },
    icon: const Icon(Icons.calendar_month_outlined),
    label: Text('$label: ${dutyDate(value)}'),
  );

  void _advance() {
    if (!_form.currentState!.validate()) return;
    if (_step == 1) {
      if (_start == null || _return == null || _return!.isBefore(_start!)) {
        setState(() => _error = 'Pilih tanggal mulai dan kembali yang valid.');
        return;
      }
    }
    setState(() {
      _step++;
      _error = null;
    });
    if (_scroll.hasClients) _scroll.jumpTo(0);
  }

  Future<void> _save({required bool draft}) async {
    final settings = context.read<SettingsProvider>();
    final provider = context.read<DutyProvider>();
    if (!draft) {
      if (!_form.currentState!.validate()) return;
      if (!settings.documentsReady) {
        setState(
          () => _error = 'Lengkapi Profil dan konfirmasi penandatangan.',
        );
        return;
      }
      if (!settings.availableSignatories.contains(_value('signer_name')) ||
          !settings.availableApproverPositions.contains(
            _value('signer_position'),
          )) {
        setState(
          () =>
              _error = 'Pilih ulang penandatangan dan jabatannya dari Profil.',
        );
        return;
      }
      if (!_reviewed) {
        setState(() => _error = 'Centang bahwa data surat sudah diperiksa.');
        return;
      }
    }
    try {
      await provider.save(_entry(draft: draft));
      if (!mounted) return;
      setState(() {
        _allowPop = true;
        _dirty = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            draft ? 'Draf berhasil disimpan.' : 'Surat berhasil disimpan.',
          ),
        ),
      );
      context.pushReplacement(
        draft ? '/duty/detail/$_id' : '/duty/preview/$_id',
      );
    } catch (error) {
      if (mounted) {
        setState(
          () =>
              _error =
                  error is StateError
                      ? error.message.toString()
                      : 'Surat belum tersimpan. Coba lagi.',
        );
      }
    }
  }

  Future<void> _leave() async {
    if (context.read<DutyProvider>().saving) return;
    final choice = await showDialog<String>(
      context: context,
      builder:
          (ctx) => AlertDialog(
            title: const Text('Simpan perubahan?'),
            content: const Text(
              'Simpan sebagai draf agar dapat dilanjutkan kembali.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, 'cancel'),
                child: const Text('Kembali'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(ctx, 'discard'),
                child: const Text('Buang perubahan'),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(ctx, 'save'),
                child: const Text('Simpan draf'),
              ),
            ],
          ),
    );
    if (!mounted) return;
    if (choice == 'save') {
      await _save(draft: true);
    }
    if (choice == 'discard') {
      setState(() => _allowPop = true);
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) context.pop();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<DutyProvider>();
    final settings = context.watch<SettingsProvider>();
    final missing =
        provider.loaded &&
        widget.editId != null &&
        provider.byId(widget.editId) == null;
    return PopScope(
      canPop: _allowPop || (!_dirty && !provider.saving),
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) _leave();
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(
            widget.editId == null ? 'Buat Surat Dinas' : 'Edit Surat Dinas',
          ),
          actions: [
            TextButton(
              onPressed:
                  !_initialized || provider.saving || missing
                      ? null
                      : () => _save(draft: true),
              child: const Text('Simpan draf', style: TextStyle(fontSize: 12)),
            ),
          ],
        ),
        body:
            missing
                ? const Center(child: Text('Surat tidak ditemukan.'))
                : !_initialized
                ? Center(
                  child:
                      provider.error == null
                          ? const CircularProgressIndicator()
                          : TextButton(
                            onPressed: provider.load,
                            child: const Text('Muat ulang surat dinas'),
                          ),
                )
                : AbsorbPointer(
                  absorbing: provider.saving,
                  child: Column(
                    children: [
                      Padding(
                        padding: const EdgeInsets.fromLTRB(18, 8, 18, 14),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: List.generate(
                            3,
                            (i) => Expanded(
                              child: Column(
                                children: [
                                  CircleAvatar(
                                    radius: 17,
                                    backgroundColor:
                                        i <= _step
                                            ? AppColors.primary
                                            : AppColors.primaryLight,
                                    child:
                                        i < _step
                                            ? const Icon(
                                              Icons.check,
                                              color: Colors.white,
                                              size: 18,
                                            )
                                            : Text(
                                              '${i + 1}',
                                              style: const TextStyle(
                                                color: Colors.white,
                                              ),
                                            ),
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    ['Data surat', 'Perjalanan', 'Tinjau'][i],
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w700,
                                      color:
                                          i == _step
                                              ? AppColors.primary
                                              : AppColors.textSecondary,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                      if (provider.saving) const LinearProgressIndicator(),
                      Expanded(
                        child: Form(
                          key: _form,
                          child: ListView(
                            controller: _scroll,
                            padding: const EdgeInsets.fromLTRB(18, 8, 18, 24),
                            children: [
                              if (!settings.documentsReady) ...[
                                ProfileCompletionCard(onComplete: _profile),
                                const SizedBox(height: 18),
                              ],
                              ..._stepWidgets(settings),
                              if (_error != null)
                                Padding(
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 14,
                                  ),
                                  child: Text(
                                    _error!,
                                    key: const ValueKey('duty-error'),
                                    style: const TextStyle(
                                      color: AppColors.danger,
                                    ),
                                  ),
                                ),
                              const SizedBox(height: 20),
                              Row(
                                children: [
                                  if (_step > 0) ...[
                                    Expanded(
                                      child: OutlinedButton(
                                        onPressed: () {
                                          setState(() {
                                            _step--;
                                            _error = null;
                                          });
                                          if (_scroll.hasClients) {
                                            _scroll.jumpTo(0);
                                          }
                                        },
                                        child: const Text('Kembali'),
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                  ],
                                  Expanded(
                                    flex: 2,
                                    child: FilledButton(
                                      key: const ValueKey('duty-next'),
                                      onPressed:
                                          _step == 2
                                              ? () => _save(draft: false)
                                              : _advance,
                                      child: Text(
                                        _step == 0
                                            ? 'Lanjut: Perjalanan'
                                            : _step == 1
                                            ? 'Lanjut: Tinjau'
                                            : 'Simpan & lihat PDF',
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 24),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
      ),
    );
  }
}
