import 'package:flutter_test/flutter_test.dart';
import 'package:lembur/features/settings/domain/user_profile.dart';
import 'package:lembur/features/settings/presentation/settings_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

const completeProfile = UserProfile(
  name: 'Budi Pratama',
  workerNumber: 'PTC-001',
);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() => SharedPreferences.setMockInitialValues({}));

  test('Every profile field is required, including whitespace-only values', () {
    expect(completeProfile.isComplete, isTrue);
    final missing = [
      completeProfile.copyWith(name: ' '),
      completeProfile.copyWith(workerNumber: ''),
      completeProfile.copyWith(company: ''),
      completeProfile.copyWith(function: ' '),
      completeProfile.copyWith(placement: ''),
      completeProfile.copyWith(jobType: ''),
      completeProfile.copyWith(location: ''),
      completeProfile.copyWith(costBearer: ''),
    ];
    for (final profile in missing) {
      expect(profile.isComplete, isFalse);
      expect(profile.missingRequiredFields, hasLength(1));
    }
  });

  test(
    'Complete profile still requires explicit signatory confirmation',
    () async {
      final settings = SettingsProvider();
      expect(settings.documentsReady, isFalse);
      await settings.load();
      await settings.saveProfile(completeProfile);
      expect(settings.signatoryDataComplete, isTrue);
      expect(settings.documentsReady, isFalse);
      expect(await settings.confirmSignatories(), isTrue);
      expect(settings.documentsReady, isTrue);
    },
  );

  test(
    'Readiness survives a restart and is lost when a profile field is removed',
    () async {
      final settings = SettingsProvider();
      await settings.load();
      await settings.saveProfile(completeProfile);
      await settings.confirmSignatories();
      final reopened = SettingsProvider();
      await reopened.load();
      expect(reopened.documentsReady, isTrue);
      await reopened.saveProfile(completeProfile.copyWith(location: ' '));
      expect(reopened.documentsReady, isFalse);
    },
  );

  test(
    'Changing any signatory name or position invalidates persisted confirmation',
    () async {
      final settings = SettingsProvider();
      await settings.load();
      await settings.saveProfile(completeProfile);
      for (final change in <Future<void> Function()>[
        () => settings.updateSignatory(0, 'Andi Wijaya'),
        () => settings.updateApproverPosition(0, 'AFT Manager'),
        () => settings.savePtcManager(
          name: 'Pejabat Baru',
          position: 'Manager PTC',
        ),
      ]) {
        await settings.confirmSignatories();
        await change();
        expect(settings.documentsReady, isFalse);
        final reopened = SettingsProvider();
        await reopened.load();
        expect(reopened.signatoriesConfirmed, isFalse);
      }
    },
  );

  test(
    'Optional slots can be blank, but placeholders cannot be confirmed',
    () async {
      final settings = SettingsProvider();
      await settings.load();
      await settings.updateSignatory(1, '');
      expect(await settings.confirmSignatories(), isTrue);
      await settings.updateSignatory(2, 'Nama Penandatangan 3');
      expect(await settings.confirmSignatories(), isFalse);
      expect(settings.availableSignatories, ['Joni Herawan']);
      await settings.updateSignatory(2, '');
      await settings.updateSignatory(0, '');
      expect(await settings.confirmSignatories(), isFalse);
    },
  );

  test(
    'At least one AFT position and a valid PTC name and position are required',
    () async {
      final settings = SettingsProvider();
      await settings.load();
      await settings.updateApproverPosition(0, '');
      await settings.updateApproverPosition(1, '');
      expect(await settings.confirmSignatories(), isFalse);
      await settings.updateApproverPosition(0, 'AFT Manager');
      await settings.savePtcManager(name: '', position: 'Manager');
      expect(await settings.confirmSignatories(), isFalse);
      await settings.savePtcManager(name: 'Ricky Roy Sagita', position: '');
      expect(await settings.confirmSignatories(), isFalse);
    },
  );

  test(
    'Legacy profile and names are preserved but placeholder slots need no fake names',
    () async {
      SharedPreferences.setMockInitialValues({
        'profile_name': 'Pekerja Lama',
        'profile_worker_number': '001',
        'signatory_names': [
          'Nama Asli',
          'Nama Penandatangan 2',
          'Nama Penandatangan 3',
          '',
        ],
      });
      final settings = SettingsProvider();
      await settings.load();
      expect(settings.profile.name, 'Pekerja Lama');
      expect(settings.availableSignatories, ['Nama Asli']);
      expect(settings.documentsReady, isFalse);
      await settings.confirmSignatories();
      expect(settings.documentsReady, isTrue);
    },
  );
}
