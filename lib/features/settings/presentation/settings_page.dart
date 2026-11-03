import 'package:flutter/material.dart';
import 'package:lembur/app/theme/app_colors.dart';
import 'package:lembur/core/constants/app_constants.dart';
import 'package:lembur/core/widgets/neumorphic_card.dart';
import 'package:lembur/features/settings/domain/user_profile.dart';
import 'package:lembur/features/settings/presentation/settings_provider.dart';
import 'package:lembur/features/settings/presentation/salary_settings_card.dart';
import 'package:lembur/features/settings/presentation/backup_restore_card.dart';
import 'package:provider/provider.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsProvider>();
    final profile = settings.profile;
    if (!settings.loaded) {
      return const Center(child: CircularProgressIndicator());
    }

    return SafeArea(
      bottom: false,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(18, 18, 18, 125),
        children: [
          Text(
            'Profil & pengaturan',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 5),
          Text(
            'Data tetap disimpan lokal dan dipakai otomatis pada dokumen.',
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SizedBox(height: 23),
          NeumorphicCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      settings.documentsReady
                          ? Icons.verified_rounded
                          : Icons.lock_rounded,
                      color:
                          settings.documentsReady
                              ? AppColors.success
                              : AppColors.warning,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        settings.documentsReady
                            ? 'Data siap digunakan'
                            : 'Lengkapi data wajib',
                        style: const TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 16,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Text(
                  profile.isComplete
                      ? 'Profil pekerja lengkap.'
                      : 'Belum diisi: ${profile.missingRequiredFields.join(', ')}.',
                ),
                const SizedBox(height: 6),
                Text(
                  settings.signatoriesConfirmed
                      ? 'Penandatangan sudah dikonfirmasi.'
                      : 'Periksa daftar nama dan jabatan di bawah, lalu konfirmasi penandatangan.',
                ),
                if (!profile.isComplete) ...[
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      onPressed: () => _editProfile(context, profile),
                      icon: const Icon(Icons.person_outline_rounded),
                      label: const Text('Isi profil pekerja'),
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 23),
          const _SectionLabel('PROFIL & PEKERJAAN'),
          const SizedBox(height: 9),
          NeumorphicCard(
            onTap: () => _editProfile(context, profile),
            child: Row(
              children: [
                const _IconBox(icon: Icons.person_rounded),
                const SizedBox(width: 13),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        profile.name.isEmpty
                            ? 'Profil pengguna belum lengkap'
                            : profile.name,
                        style: const TextStyle(fontWeight: FontWeight.w900),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        profile.workerNumber.isEmpty
                            ? 'Tekan untuk mengisi data'
                            : '${profile.workerNumber} • ${profile.function}',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
                const Icon(Icons.chevron_right_rounded),
              ],
            ),
          ),
          const SizedBox(height: 17),
          NeumorphicCard(
            onTap: () => _editProfile(context, profile),
            child: Row(
              children: [
                const _IconBox(icon: Icons.business_rounded),
                const SizedBox(width: 13),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Data pekerjaan tetap',
                        style: TextStyle(fontWeight: FontWeight.w900),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${profile.placement}\n${profile.jobType}',
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
                const Icon(Icons.chevron_right_rounded),
              ],
            ),
          ),
          const SizedBox(height: 26),
          const SalarySettingsCard(),
          const SizedBox(height: 26),
          const _SectionLabel('ADMIN WHATSAPP'),
          const SizedBox(height: 9),
          NeumorphicCard(
            onTap: () => _editAdminWhatsApp(context, settings.adminWhatsApp),
            child: Row(
              children: [
                const _IconBox(icon: Icons.chat_rounded),
                const SizedBox(width: 13),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Nomor WhatsApp admin',
                        style: TextStyle(fontWeight: FontWeight.w900),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        settings.adminWhatsApp.isEmpty
                            ? 'Belum diatur • tekan untuk mengisi'
                            : '+${settings.adminWhatsApp}',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
                const Icon(Icons.chevron_right_rounded),
              ],
            ),
          ),
          const SizedBox(height: 26),
          const _SectionLabel('PEJABAT PTC'),
          const SizedBox(height: 9),
          NeumorphicCard(
            onTap:
                () => _editPtcManager(
                  context,
                  settings.ptcManagerName,
                  settings.ptcManagerPosition,
                ),
            child: Row(
              children: [
                const _IconBox(icon: Icons.badge_rounded),
                const SizedBox(width: 13),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        settings.ptcManagerName,
                        style: const TextStyle(fontWeight: FontWeight.w900),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        settings.ptcManagerPosition,
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
                const Icon(Icons.chevron_right_rounded),
              ],
            ),
          ),
          const SizedBox(height: 26),
          const _SectionLabel('DAFTAR PENANDATANGAN AFT'),
          const SizedBox(height: 9),
          NeumorphicCard(
            child: Column(
              children: List.generate(4, (index) {
                final name = settings.signatories[index];
                return Column(
                  children: [
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: CircleAvatar(
                        backgroundColor: AppColors.primary.withAlpha(26),
                        child: Text(
                          '${index + 1}',
                          style: const TextStyle(
                            color: AppColors.primaryDark,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),
                      title: Text(name.isEmpty ? 'Kosong · opsional' : name),
                      trailing: IconButton(
                        tooltip: 'Ubah nama',
                        icon: const Icon(
                          Icons.edit_rounded,
                          color: AppColors.primary,
                        ),
                        onPressed: () => _editSignatory(context, index, name),
                      ),
                    ),
                    if (index < 3) const Divider(height: 1),
                  ],
                );
              }),
            ),
          ),
          const SizedBox(height: 26),
          const _SectionLabel('JABATAN PENANDATANGAN AFT'),
          const SizedBox(height: 9),
          NeumorphicCard(
            child: Column(
              children: [
                for (
                  var index = 0;
                  index < settings.approverPositions.length;
                  index++
                )
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(
                      settings.approverPositions[index].isEmpty
                          ? 'Kosong · opsional'
                          : settings.approverPositions[index],
                    ),
                    trailing: const Icon(
                      Icons.edit_rounded,
                      color: AppColors.primary,
                    ),
                    onTap:
                        () => _editApproverPosition(
                          context,
                          index,
                          settings.approverPositions[index],
                        ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          NeumorphicCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Konfirmasi penandatangan',
                  style: TextStyle(fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Pastikan nama dan jabatan pejabat PTC serta penandatangan AFT sudah sesuai. '
                  'Isi minimal satu nama dan satu jabatan AFT; slot yang tidak digunakan boleh dikosongkan.',
                ),
                const SizedBox(height: 14),
                if (!settings.signatoryDataComplete)
                  const Padding(
                    padding: EdgeInsets.only(bottom: 10),
                    child: Text(
                      'Lengkapi nama dan jabatan yang valid sebelum mengonfirmasi.',
                      style: TextStyle(color: AppColors.warning),
                    ),
                  ),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    key: const ValueKey('confirm-signatories'),
                    onPressed:
                        settings.signatoryDataComplete &&
                                !settings.signatoriesConfirmed
                            ? () => _confirmSignatories(context, settings)
                            : null,
                    icon: Icon(
                      settings.signatoriesConfirmed
                          ? Icons.verified_rounded
                          : Icons.check_rounded,
                    ),
                    label: Text(
                      settings.signatoriesConfirmed
                          ? 'Sudah dikonfirmasi'
                          : 'Nama & jabatan sudah sesuai',
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Konfirmasi perlu diulang setelah nama atau jabatan diubah.',
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 26),
          const _SectionLabel('DATA & KEAMANAN'),
          const SizedBox(height: 9),
          const BackupRestoreCard(),
          const SizedBox(height: 17),
          const NeumorphicCard(
            child: _SettingRow(
              icon: Icons.info_rounded,
              title: 'Tentang aplikasi',
              subtitle:
                  '${AppConstants.appName} ${AppConstants.appVersion} • Offline',
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _confirmSignatories(
    BuildContext context,
    SettingsProvider settings,
  ) async {
    final success = await settings.confirmSignatories();
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          success
              ? 'Daftar penandatangan dikonfirmasi.'
              : 'Konfirmasi belum tersimpan. Periksa data dan coba lagi.',
        ),
      ),
    );
  }

  Future<void> _editApproverPosition(
    BuildContext context,
    int index,
    String initialValue,
  ) async {
    final value = await showDialog<String>(
      context: context,
      builder:
          (_) => _EditSignatoryDialog(
            index: index,
            initialName: initialValue,
            position: true,
          ),
    );
    if (value == null || !context.mounted) return;
    await context.read<SettingsProvider>().updateApproverPosition(index, value);
  }

  Future<void> _editSignatory(
    BuildContext context,
    int index,
    String initialName,
  ) async {
    final value = await showDialog<String>(
      context: context,
      builder:
          (_) => _EditSignatoryDialog(index: index, initialName: initialName),
    );

    if (value == null || !context.mounted) {
      return;
    }

    await context.read<SettingsProvider>().updateSignatory(index, value);
  }

  Future<void> _editProfile(BuildContext context, UserProfile profile) async {
    final result = await showDialog<UserProfile>(
      context: context,
      builder: (_) => _EditProfileDialog(profile: profile),
    );

    if (result == null || !context.mounted) {
      return;
    }

    await context.read<SettingsProvider>().saveProfile(result);
  }

  Future<void> _editAdminWhatsApp(
    BuildContext context,
    String initialNumber,
  ) async {
    final result = await showDialog<String>(
      context: context,
      builder: (_) => _EditAdminWhatsAppDialog(initialNumber: initialNumber),
    );

    if (result == null || !context.mounted) {
      return;
    }

    await context.read<SettingsProvider>().saveAdminWhatsApp(result);
  }

  Future<void> _editPtcManager(
    BuildContext context,
    String initialName,
    String initialPosition,
  ) async {
    final result = await showDialog<_PtcManagerData>(
      context: context,
      builder:
          (_) => _EditPtcManagerDialog(
            initialName: initialName,
            initialPosition: initialPosition,
          ),
    );

    if (result == null || !context.mounted) {
      return;
    }

    await context.read<SettingsProvider>().savePtcManager(
      name: result.name,
      position: result.position,
    );
  }
}

class _PtcManagerData {
  const _PtcManagerData({required this.name, required this.position});

  final String name;
  final String position;
}

class _EditPtcManagerDialog extends StatefulWidget {
  const _EditPtcManagerDialog({
    required this.initialName,
    required this.initialPosition,
  });

  final String initialName;
  final String initialPosition;

  @override
  State<_EditPtcManagerDialog> createState() => _EditPtcManagerDialogState();
}

class _EditPtcManagerDialogState extends State<_EditPtcManagerDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _positionController;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.initialName);
    _positionController = TextEditingController(text: widget.initialPosition);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _positionController.dispose();
    super.dispose();
  }

  void _save() {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    Navigator.of(context).pop(
      _PtcManagerData(
        name: _nameController.text.trim(),
        position: _positionController.text.trim(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Pejabat PTC'),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextFormField(
              controller: _nameController,
              autofocus: true,
              textCapitalization: TextCapitalization.words,
              decoration: const InputDecoration(
                labelText: 'Nama pejabat PTC',
                prefixIcon: Icon(Icons.person_rounded),
              ),
              validator: (value) {
                if (!SettingsProvider.isValidSignatory(value ?? '')) {
                  return 'Isi nama pejabat yang sesuai.';
                }
                return null;
              },
            ),
            const SizedBox(height: 14),
            TextFormField(
              controller: _positionController,
              textCapitalization: TextCapitalization.words,
              textInputAction: TextInputAction.done,
              onFieldSubmitted: (_) => _save(),
              decoration: const InputDecoration(
                labelText: 'Jabatan pejabat PTC',
                prefixIcon: Icon(Icons.badge_rounded),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Jabatan pejabat wajib diisi.';
                }
                return null;
              },
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Batal'),
        ),
        FilledButton(onPressed: _save, child: const Text('Simpan')),
      ],
    );
  }
}

class _EditSignatoryDialog extends StatefulWidget {
  const _EditSignatoryDialog({
    required this.index,
    required this.initialName,
    this.position = false,
  });

  final int index;
  final String initialName;
  final bool position;

  @override
  State<_EditSignatoryDialog> createState() => _EditSignatoryDialogState();
}

class _EditSignatoryDialogState extends State<_EditSignatoryDialog> {
  late final TextEditingController _controller;
  final _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialName);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _save() {
    if (!_formKey.currentState!.validate()) return;
    Navigator.of(context).pop(_controller.text.trim());
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(
        '${widget.position ? 'Jabatan' : 'Nama'} penandatangan ${widget.index + 1}',
      ),
      content: Form(
        key: _formKey,
        child: TextFormField(
          controller: _controller,
          autofocus: true,
          textInputAction: TextInputAction.done,
          onFieldSubmitted: (_) => _save(),
          decoration: InputDecoration(
            labelText: widget.position ? 'Jabatan' : 'Nama lengkap',
            helperText: 'Boleh kosong jika tidak digunakan.',
          ),
          validator: (value) {
            if (!widget.position &&
                (value ?? '').trim().isNotEmpty &&
                !SettingsProvider.isValidSignatory(value!)) {
              return 'Isi nama yang sesuai, bukan nama contoh.';
            }
            return null;
          },
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Batal'),
        ),
        FilledButton(onPressed: _save, child: const Text('Simpan')),
      ],
    );
  }
}

class _EditAdminWhatsAppDialog extends StatefulWidget {
  const _EditAdminWhatsAppDialog({required this.initialNumber});

  final String initialNumber;

  @override
  State<_EditAdminWhatsAppDialog> createState() =>
      _EditAdminWhatsAppDialogState();
}

class _EditAdminWhatsAppDialogState extends State<_EditAdminWhatsAppDialog> {
  late final TextEditingController _controller;
  final _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialNumber);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _save() {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    Navigator.of(context).pop(_controller.text);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Nomor WhatsApp admin'),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextFormField(
              controller: _controller,
              autofocus: true,
              keyboardType: TextInputType.phone,
              textInputAction: TextInputAction.done,
              onFieldSubmitted: (_) => _save(),
              decoration: const InputDecoration(
                labelText: 'Nomor WhatsApp',
                hintText: 'Contoh: 081234567890',
                prefixIcon: Icon(Icons.chat_rounded),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Nomor WhatsApp wajib diisi.';
                }
                if (!SettingsProvider.isValidWhatsAppNumber(value)) {
                  return 'Nomor WhatsApp tidak valid.';
                }
                return null;
              },
            ),
            const SizedBox(height: 10),
            Text(
              'Nomor 08... akan otomatis disimpan dalam format 62...',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Batal'),
        ),
        FilledButton(onPressed: _save, child: const Text('Simpan')),
      ],
    );
  }
}

class _EditProfileDialog extends StatefulWidget {
  const _EditProfileDialog({required this.profile});

  final UserProfile profile;

  @override
  State<_EditProfileDialog> createState() => _EditProfileDialogState();
}

class _EditProfileDialogState extends State<_EditProfileDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _workerController;
  late final TextEditingController _companyController;
  late final TextEditingController _functionController;
  late final TextEditingController _placementController;
  late final TextEditingController _jobTypeController;
  late final TextEditingController _locationController;
  late final TextEditingController _costBearerController;

  @override
  void initState() {
    super.initState();
    final profile = widget.profile;
    _nameController = TextEditingController(text: profile.name);
    _workerController = TextEditingController(text: profile.workerNumber);
    _companyController = TextEditingController(text: profile.company);
    _functionController = TextEditingController(text: profile.function);
    _placementController = TextEditingController(text: profile.placement);
    _jobTypeController = TextEditingController(text: profile.jobType);
    _locationController = TextEditingController(text: profile.location);
    _costBearerController = TextEditingController(text: profile.costBearer);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _workerController.dispose();
    _companyController.dispose();
    _functionController.dispose();
    _placementController.dispose();
    _jobTypeController.dispose();
    _locationController.dispose();
    _costBearerController.dispose();
    super.dispose();
  }

  void _save() {
    if (!_formKey.currentState!.validate()) return;
    Navigator.of(context).pop(
      UserProfile(
        name: _nameController.text.trim(),
        workerNumber: _workerController.text.trim(),
        company: _companyController.text.trim(),
        function: _functionController.text.trim(),
        placement: _placementController.text.trim(),
        jobType: _jobTypeController.text.trim(),
        location: _locationController.text.trim(),
        costBearer: _costBearerController.text.trim(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Dialog.fullscreen(
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Profil & Data Tetap'),
          leading: IconButton(
            icon: const Icon(Icons.close_rounded),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ),
        body: SafeArea(
          top: false,
          child: Form(
            key: _formKey,
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Padding(
                    padding: EdgeInsets.only(bottom: 18),
                    child: Text(
                      'Semua kolom wajib diisi agar dokumen memuat data pekerja yang lengkap.',
                    ),
                  ),
                  _ProfileField(
                    controller: _nameController,
                    label: 'Nama pekerja',
                  ),
                  _ProfileField(
                    controller: _workerController,
                    label: 'Nomor pekerja',
                  ),
                  _ProfileField(
                    controller: _companyController,
                    label: 'Nama perusahaan',
                  ),
                  _ProfileField(
                    controller: _functionController,
                    label: 'Fungsi/bagian',
                  ),
                  _ProfileField(
                    controller: _placementController,
                    label: 'Penempatan',
                  ),
                  _ProfileField(
                    controller: _jobTypeController,
                    label: 'Jenis pekerjaan',
                  ),
                  _ProfileField(
                    controller: _locationController,
                    label: 'Lokasi',
                  ),
                  _ProfileField(
                    controller: _costBearerController,
                    label: 'Penanggung biaya',
                  ),
                  const SizedBox(height: 8),
                  FilledButton.icon(
                    onPressed: _save,
                    icon: const Icon(Icons.save_rounded),
                    label: const Padding(
                      padding: EdgeInsets.symmetric(vertical: 13),
                      child: Text('Simpan Profil'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ProfileField extends StatelessWidget {
  const _ProfileField({required this.controller, required this.label});

  final TextEditingController controller;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: TextFormField(
        controller: controller,
        decoration: InputDecoration(labelText: label),
        autovalidateMode: AutovalidateMode.onUserInteraction,
        validator:
            (value) =>
                (value ?? '').trim().isEmpty ? '$label wajib diisi.' : null,
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 11,
        letterSpacing: 0.8,
        fontWeight: FontWeight.w900,
        color: AppColors.textSecondary,
      ),
    );
  }
}

class _IconBox extends StatelessWidget {
  const _IconBox({required this.icon});

  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 45,
      height: 45,
      decoration: BoxDecoration(
        color: AppColors.primary.withAlpha(26),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Icon(icon, color: AppColors.primary),
    );
  }
}

class _SettingRow extends StatelessWidget {
  const _SettingRow({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  final IconData icon;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _IconBox(icon: icon),
        const SizedBox(width: 13),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: const TextStyle(fontWeight: FontWeight.w900)),
              const SizedBox(height: 4),
              Text(subtitle, style: Theme.of(context).textTheme.bodySmall),
            ],
          ),
        ),
        const Icon(Icons.chevron_right_rounded),
      ],
    );
  }
}
