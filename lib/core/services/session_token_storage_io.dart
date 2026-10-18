import 'dart:convert';
import 'dart:ffi';
import 'dart:io';
import 'dart:typed_data';

import 'package:ffi/ffi.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:win32/win32.dart';

class SessionTokenStorage {
  SessionTokenStorage() : _preferences = SharedPreferencesAsync();

  final SharedPreferencesAsync _preferences;
  static const _key = 'rms_session_token';

  Future<String?> read() async {
    final stored = await _preferences.getString(_key);
    if (stored == null || !Platform.isWindows) return stored;
    return utf8.decode(_unprotect(base64Decode(stored)));
  }

  Future<void> write(String token) async {
    final stored = Platform.isWindows
        ? base64Encode(_protect(utf8.encode(token)))
        : token;
    await _preferences.setString(_key, stored);
  }

  Future<void> delete() => _preferences.remove(_key);

  Uint8List _protect(List<int> inputBytes) {
    final input = calloc.allocate<CRYPT_INTEGER_BLOB>(
      sizeOf<CRYPT_INTEGER_BLOB>(),
    );
    final data = calloc.allocate<Uint8>(inputBytes.length);
    final output = calloc.allocate<CRYPT_INTEGER_BLOB>(
      sizeOf<CRYPT_INTEGER_BLOB>(),
    );
    try {
      data.asTypedList(inputBytes.length).setAll(0, inputBytes);
      input.ref
        ..cbData = inputBytes.length
        ..pbData = data;
      if (CryptProtectData(
            input,
            nullptr,
            nullptr,
            nullptr,
            nullptr,
            1,
            output,
          ) ==
          0) {
        throw StateError(
          'Windows DPAPI encryption failed (${GetLastError()}).',
        );
      }
      return Uint8List.fromList(
        output.ref.pbData.asTypedList(output.ref.cbData),
      );
    } finally {
      if (output.ref.pbData != nullptr) LocalFree(output.ref.pbData);
      calloc.free(output);
      calloc.free(data);
      calloc.free(input);
    }
  }

  Uint8List _unprotect(List<int> encryptedBytes) {
    final input = calloc.allocate<CRYPT_INTEGER_BLOB>(
      sizeOf<CRYPT_INTEGER_BLOB>(),
    );
    final data = calloc.allocate<Uint8>(encryptedBytes.length);
    final output = calloc.allocate<CRYPT_INTEGER_BLOB>(
      sizeOf<CRYPT_INTEGER_BLOB>(),
    );
    try {
      data.asTypedList(encryptedBytes.length).setAll(0, encryptedBytes);
      input.ref
        ..cbData = encryptedBytes.length
        ..pbData = data;
      if (CryptUnprotectData(
            input,
            nullptr,
            nullptr,
            nullptr,
            nullptr,
            1,
            output,
          ) ==
          0) {
        throw StateError(
          'Windows DPAPI decryption failed (${GetLastError()}).',
        );
      }
      return Uint8List.fromList(
        output.ref.pbData.asTypedList(output.ref.cbData),
      );
    } finally {
      if (output.ref.pbData != nullptr) LocalFree(output.ref.pbData);
      calloc.free(output);
      calloc.free(data);
      calloc.free(input);
    }
  }
}
