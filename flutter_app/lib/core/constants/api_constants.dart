/// Backend API configuration.
///
/// The ShopSense FastAPI backend. Change [baseUrl] to point at wherever
/// the backend is running:
///
/// * Flutter web build (this build): the backend runs on the same machine,
///   so `http://127.0.0.1:8000` works.
/// * Android emulator: use `http://10.0.2.2:8000` (the emulator's alias
///   for the host machine's loopback).
/// * Physical device: use your machine's LAN IP, e.g.
///   `http://192.168.1.10:8000`, and make sure the backend is started
///   with `--host 0.0.0.0` so it accepts LAN connections.
class ApiConstants {
  static const String baseUrl = 'http://127.0.0.1:8000';

  static const Duration requestTimeout = Duration(seconds: 60);
  static const Duration uploadTimeout = Duration(seconds: 120);
}
