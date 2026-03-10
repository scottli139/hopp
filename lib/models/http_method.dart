enum HttpMethod {
  get('GET'),
  post('POST'),
  put('PUT'),
  delete('DELETE'),
  patch('PATCH'),
  head('HEAD'),
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
