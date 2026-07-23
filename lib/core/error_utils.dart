/// Returns a user-facing message for exceptions from API/network calls.
/// When the device has no internet or the request fails due to connectivity,
/// returns a short "connect to internet" message instead of raw errors.
String userFacingErrorMessage(Object e) {
  final msg = e.toString().toLowerCase();
  final connectionPatterns = [
    'socketexception',
    'failed host lookup',
    'network is unreachable',
    'connection refused',
    'connection reset',
    'timed out',
    'timeout',
    'no internet',
    'socket',
    'connection',
    'network unreachable',
    'errno 111',
    'handshakeexception',
    'os error',
  ];
  final isConnectionError = connectionPatterns.any((p) => msg.contains(p));
  if (isConnectionError) {
    return 'Please connect to the internet and try again';
  }
  return e.toString().replaceFirst(RegExp(r'^Exception:\s*'), '');
}
