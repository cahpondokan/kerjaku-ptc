/// Indonesian national holidays and collective leave from the official SKB.
/// Sources and update instructions: docs/LEAVE_CALENDAR.md.
/// Both kinds are excluded according to the user's leave policy.
abstract final class LeaveHolidays {
  static const firstYear = 2025;
  static const lastYear = 2027;
  static bool covers(int year) => year >= firstYear && year <= lastYear;

  // Integer yyyyMMdd keys keep matching independent of time zone/time of day.
  static int _key(DateTime day) => day.year * 10000 + day.month * 100 + day.day;
  static String? name(DateTime day) =>
      national[_key(day)] ?? collective[_key(day)];
  static bool isHoliday(DateTime day) => name(day) != null;
  static bool isCollective(DateTime day) => collective.containsKey(_key(day));

  static List<DateTime> datesForYear(int year) =>
      [...national.keys, ...collective.keys]
          .where((key) => key ~/ 10000 == year)
          .map((key) => DateTime(key ~/ 10000, key ~/ 100 % 100, key % 100))
          .toList()
        ..sort();

  static const national = <int, String>{
    20250101: 'Tahun Baru',
    20250127: 'Isra Mikraj',
    20250129: 'Imlek',
    20250329: 'Nyepi',
    20250331: 'Idul Fitri',
    20250401: 'Idul Fitri',
    20250418: 'Wafat Yesus Kristus',
    20250420: 'Paskah',
    20250501: 'Hari Buruh',
    20250512: 'Waisak',
    20250529: 'Kenaikan Yesus Kristus',
    20250601: 'Hari Lahir Pancasila',
    20250606: 'Idul Adha',
    20250627: 'Tahun Baru Islam',
    20250817: 'Hari Kemerdekaan',
    20250905: 'Maulid Nabi',
    20251225: 'Natal',
    20260101: 'Tahun Baru',
    20260116: 'Isra Mikraj',
    20260217: 'Imlek',
    20260319: 'Nyepi',
    20260321: 'Idul Fitri',
    20260322: 'Idul Fitri',
    20260403: 'Wafat Yesus Kristus',
    20260405: 'Paskah',
    20260501: 'Hari Buruh',
    20260514: 'Kenaikan Yesus Kristus',
    20260527: 'Idul Adha',
    20260531: 'Waisak',
    20260601: 'Hari Lahir Pancasila',
    20260616: 'Tahun Baru Islam',
    20260817: 'Hari Kemerdekaan',
    20260825: 'Maulid Nabi',
    20261225: 'Natal',
    20270101: 'Tahun Baru',
    20270105: 'Isra Mikraj 1448 H',
    20270206: 'Imlek',
    20270308: 'Nyepi',
    20270310: 'Idul Fitri',
    20270311: 'Idul Fitri',
    20270326: 'Wafat Yesus Kristus',
    20270328: 'Paskah',
    20270501: 'Hari Buruh',
    20270506: 'Kenaikan Yesus Kristus',
    20270517: 'Idul Adha',
    20270520: 'Waisak',
    20270601: 'Hari Lahir Pancasila',
    20270606: 'Tahun Baru Islam',
    20270815: 'Maulid Nabi',
    20270817: 'Hari Kemerdekaan',
    20271225: 'Natal',
    20271226: 'Isra Mikraj 1449 H',
  };

  static const collective = <int, String>{
    20250128: 'Imlek',
    20250328: 'Nyepi',
    20250402: 'Idul Fitri',
    20250403: 'Idul Fitri',
    20250404: 'Idul Fitri',
    20250407: 'Idul Fitri',
    20250513: 'Waisak',
    20250530: 'Kenaikan Yesus Kristus',
    20250609: 'Idul Adha',
    20250818: 'Hari Kemerdekaan', // Amendment dated 7 August 2025.
    20251226: 'Natal',
    20260216: 'Imlek',
    20260318: 'Nyepi',
    20260320: 'Idul Fitri',
    20260323: 'Idul Fitri',
    20260324: 'Idul Fitri',
    20260515: 'Kenaikan Yesus Kristus',
    20260528: 'Idul Adha',
    20261224: 'Natal',
    20270205: 'Imlek',
    20270309: 'Idul Fitri',
    20270312: 'Idul Fitri',
    20270315: 'Idul Fitri',
    20270325: 'Wafat Yesus Kristus',
    20270518: 'Idul Adha',
    20270519: 'Waisak',
    20271224: 'Natal',
  };
}
