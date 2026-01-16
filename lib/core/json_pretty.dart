import 'dart:convert';

String prettyJson(Object? data) {
  const encoder = JsonEncoder.withIndent('  ');
  return encoder.convert(data);
}
