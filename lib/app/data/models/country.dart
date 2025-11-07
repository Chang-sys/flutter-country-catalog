class Country {
  final String nameOfficial;
  final Map<String, dynamic>? nativeName;
  final List<dynamic>? altSpellings;
  final String? cca2;
  final String? cca3;
  final Map<String, dynamic>? idd;
  final String? flagPng;
  final Map<String, dynamic> raw;

  Country({
    required this.nameOfficial,
    this.nativeName,
    this.altSpellings,
    this.cca2,
    this.cca3,
    this.idd,
    this.flagPng,
    required this.raw,
  });

  factory Country.fromJson(Map<String, dynamic> json) => Country(
        raw: json,
        nameOfficial: json['name']?['official'] ?? '',
        nativeName: json['name']?['nativeName'],
        altSpellings: json['altSpellings'],
        cca2: json['cca2'],
        cca3: json['cca3'],
        idd: json['idd'],
        flagPng: json['flags']?['png'],
      );

  String get nativeNames =>
      nativeName == null ? '' : nativeName!.values.map((e) => e['official']).join(', ');

  String get altNames =>
      altSpellings == null ? '' : altSpellings!.join(', ');

  String get callingCodes {
    if (idd == null) return '';
    final root = idd!['root'] ?? '';
    final suffixes = idd!['suffixes'] ?? [];
    return suffixes.isEmpty ? root : suffixes.map((s) => '$root$s').join(', ');
  }
}
