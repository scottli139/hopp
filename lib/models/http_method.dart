import 'package:hive/hive.dart';

part 'http_method.g.dart';

@HiveType(typeId: 10)
enum HttpMethod {
  @HiveField(0)
  get('GET'),
  @HiveField(1)
  post('POST'),
  @HiveField(2)
  put('PUT'),
  @HiveField(3)
  delete('DELETE'),
  @HiveField(4)
  patch('PATCH'),
  @HiveField(5)
  head('HEAD'),
  @HiveField(6)
  options('OPTIONS');

  final String value;
  const HttpMethod(this.value);

  static HttpMethod fromString(String value) {
    return HttpMethod.values.firstWhere(
      (e) => e.value.toUpperCase() == value.toUpperCase(),
      orElse: () => HttpMethod.get,
    );
  }

  @override
  String toString() => value;
}
