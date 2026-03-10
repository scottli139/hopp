import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:hive/hive.dart';

part 'key_value_pair.freezed.dart';
part 'key_value_pair.g.dart';

@freezed
@HiveType(typeId: 1)
class KeyValuePair with _$KeyValuePair {
  const factory KeyValuePair({
    @HiveField(0) required String id,
    @HiveField(1) required String key,
    @HiveField(2) required String value,
    @HiveField(3) @Default(true) bool enabled,
  }) = _KeyValuePair;

  factory KeyValuePair.fromJson(Map<String, dynamic> json) =>
      _$KeyValuePairFromJson(json);

  factory KeyValuePair.empty() => KeyValuePair(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        key: '',
        value: '',
        enabled: true,
      );
}
