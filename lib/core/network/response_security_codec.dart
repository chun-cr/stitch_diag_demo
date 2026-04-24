import 'dart:convert';
import 'dart:math' as math;
import 'dart:typed_data';

class ResponseSecurityCodec {
  ResponseSecurityCodec._();

  static const String _secretHex = '6b07c3e4286d4bcca0f681bb2842ac86';

  static final Uint8List _key = Uint8List.fromList(_decodeHex(_secretHex));
  static final Uint8List _iv = Uint8List.fromList(
    _decodeHex(_md5Hex('$_secretHex${_md5Hex(_secretHex)}')),
  );

  static dynamic decryptJsonPayload(String payload) {
    final normalizedPayload = _normalizeBase64(payload);
    if (normalizedPayload.isEmpty) {
      return null;
    }

    final encryptedBytes = base64Decode(normalizedPayload);
    final decryptedBytes = _Aes128CbcPkcs7().decrypt(
      encryptedBytes,
      key: _key,
      iv: _iv,
    );
    return jsonDecode(utf8.decode(decryptedBytes));
  }

  static String _normalizeBase64(String value) {
    final compact = value.trim().replaceAll('\r', '').replaceAll('\n', '');
    if (compact.isEmpty) {
      return '';
    }

    final padded = switch (compact.length % 4) {
      2 => '$compact==',
      3 => '$compact=',
      _ => compact,
    };
    return padded.replaceAll('-', '+').replaceAll('_', '/');
  }
}

class _Aes128CbcPkcs7 {
  Uint8List decrypt(
    Uint8List ciphertext, {
    required Uint8List key,
    required Uint8List iv,
  }) {
    if (key.length != 16) {
      throw ArgumentError.value(key.length, 'key', 'AES-128 requires 16 bytes');
    }
    if (iv.length != 16) {
      throw ArgumentError.value(
        iv.length,
        'iv',
        'CBC mode requires 16-byte IV',
      );
    }
    if (ciphertext.isNotEmpty && ciphertext.length % 16 != 0) {
      throw const FormatException(
        'Encrypted payload length must be a multiple of 16 bytes.',
      );
    }
    if (ciphertext.isEmpty) {
      return Uint8List(0);
    }

    final expandedKey = _expandKey(key);
    final output = BytesBuilder(copy: false);
    var previousBlock = Uint8List.fromList(iv);

    for (var offset = 0; offset < ciphertext.length; offset += 16) {
      final cipherBlock = Uint8List.sublistView(
        ciphertext,
        offset,
        offset + 16,
      );
      final decryptedBlock = _decryptBlock(cipherBlock, expandedKey);
      for (var index = 0; index < decryptedBlock.length; index += 1) {
        decryptedBlock[index] ^= previousBlock[index];
      }
      output.add(decryptedBlock);
      previousBlock = Uint8List.fromList(cipherBlock);
    }

    return _removePkcs7Padding(output.takeBytes());
  }

  Uint8List _decryptBlock(Uint8List input, Uint8List expandedKey) {
    final state = Uint8List.fromList(input);

    _addRoundKey(state, expandedKey, 10);
    for (var round = 9; round >= 1; round -= 1) {
      _invShiftRows(state);
      _invSubBytes(state);
      _addRoundKey(state, expandedKey, round);
      _invMixColumns(state);
    }
    _invShiftRows(state);
    _invSubBytes(state);
    _addRoundKey(state, expandedKey, 0);

    return state;
  }

  void _addRoundKey(Uint8List state, Uint8List expandedKey, int round) {
    final start = round * 16;
    for (var index = 0; index < 16; index += 1) {
      state[index] ^= expandedKey[start + index];
    }
  }

  void _invSubBytes(Uint8List state) {
    for (var index = 0; index < state.length; index += 1) {
      state[index] = _inverseSBox[state[index]];
    }
  }

  void _invShiftRows(Uint8List state) {
    final snapshot = Uint8List.fromList(state);

    state[0] = snapshot[0];
    state[4] = snapshot[4];
    state[8] = snapshot[8];
    state[12] = snapshot[12];

    state[1] = snapshot[13];
    state[5] = snapshot[1];
    state[9] = snapshot[5];
    state[13] = snapshot[9];

    state[2] = snapshot[10];
    state[6] = snapshot[14];
    state[10] = snapshot[2];
    state[14] = snapshot[6];

    state[3] = snapshot[7];
    state[7] = snapshot[11];
    state[11] = snapshot[15];
    state[15] = snapshot[3];
  }

  void _invMixColumns(Uint8List state) {
    for (var column = 0; column < 4; column += 1) {
      final start = column * 4;
      final a0 = state[start];
      final a1 = state[start + 1];
      final a2 = state[start + 2];
      final a3 = state[start + 3];

      state[start] =
          _gmul(a0, 0x0e) ^ _gmul(a1, 0x0b) ^ _gmul(a2, 0x0d) ^ _gmul(a3, 0x09);
      state[start + 1] =
          _gmul(a0, 0x09) ^ _gmul(a1, 0x0e) ^ _gmul(a2, 0x0b) ^ _gmul(a3, 0x0d);
      state[start + 2] =
          _gmul(a0, 0x0d) ^ _gmul(a1, 0x09) ^ _gmul(a2, 0x0e) ^ _gmul(a3, 0x0b);
      state[start + 3] =
          _gmul(a0, 0x0b) ^ _gmul(a1, 0x0d) ^ _gmul(a2, 0x09) ^ _gmul(a3, 0x0e);
    }
  }

  int _gmul(int left, int right) {
    var a = left;
    var b = right;
    var product = 0;

    for (var index = 0; index < 8; index += 1) {
      if ((b & 1) != 0) {
        product ^= a;
      }
      final highBitSet = (a & 0x80) != 0;
      a = (a << 1) & 0xff;
      if (highBitSet) {
        a ^= 0x1b;
      }
      b >>= 1;
    }

    return product;
  }

  Uint8List _expandKey(Uint8List key) {
    final expandedKey = Uint8List(176);
    expandedKey.setRange(0, key.length, key);

    final temp = Uint8List(4);
    var bytesGenerated = key.length;
    var rconIndex = 1;

    while (bytesGenerated < expandedKey.length) {
      temp.setRange(0, temp.length, expandedKey, bytesGenerated - 4);

      if (bytesGenerated % key.length == 0) {
        _rotateWord(temp);
        _substituteWord(temp);
        temp[0] ^= _roundConstants[rconIndex];
        rconIndex += 1;
      }

      for (var index = 0; index < 4; index += 1) {
        expandedKey[bytesGenerated] =
            expandedKey[bytesGenerated - key.length] ^ temp[index];
        bytesGenerated += 1;
      }
    }

    return expandedKey;
  }

  void _rotateWord(Uint8List word) {
    final first = word[0];
    word[0] = word[1];
    word[1] = word[2];
    word[2] = word[3];
    word[3] = first;
  }

  void _substituteWord(Uint8List word) {
    for (var index = 0; index < word.length; index += 1) {
      word[index] = _sBox[word[index]];
    }
  }

  Uint8List _removePkcs7Padding(Uint8List bytes) {
    if (bytes.isEmpty) {
      return bytes;
    }

    final paddingLength = bytes.last;
    if (paddingLength < 1 ||
        paddingLength > 16 ||
        paddingLength > bytes.length) {
      throw const FormatException('Invalid PKCS7 padding length.');
    }

    for (
      var index = bytes.length - paddingLength;
      index < bytes.length;
      index += 1
    ) {
      if (bytes[index] != paddingLength) {
        throw const FormatException('Invalid PKCS7 padding bytes.');
      }
    }

    return Uint8List.sublistView(bytes, 0, bytes.length - paddingLength);
  }
}

List<int> _decodeHex(String value) {
  if (value.length.isOdd) {
    throw const FormatException(
      'Hex string must contain an even number of characters.',
    );
  }

  final bytes = <int>[];
  for (var index = 0; index < value.length; index += 2) {
    bytes.add(int.parse(value.substring(index, index + 2), radix: 16));
  }
  return bytes;
}

String _md5Hex(String value) {
  final input = Uint8List.fromList(utf8.encode(value));
  final bitLength = input.length * 8;
  final paddedLength = (((input.length + 8) >> 6) + 1) * 64;
  final message = Uint8List(paddedLength);
  message.setRange(0, input.length, input);
  message[input.length] = 0x80;

  var length = bitLength;
  for (var index = 0; index < 8; index += 1) {
    message[message.length - 8 + index] = length & 0xff;
    length >>= 8;
  }

  var a0 = 0x67452301;
  var b0 = 0xefcdab89;
  var c0 = 0x98badcfe;
  var d0 = 0x10325476;

  final words = Uint32List(16);
  for (var offset = 0; offset < message.length; offset += 64) {
    for (var index = 0; index < 16; index += 1) {
      final wordOffset = offset + (index * 4);
      words[index] =
          message[wordOffset] |
          (message[wordOffset + 1] << 8) |
          (message[wordOffset + 2] << 16) |
          (message[wordOffset + 3] << 24);
    }

    var a = a0;
    var b = b0;
    var c = c0;
    var d = d0;

    for (var index = 0; index < 64; index += 1) {
      late int f;
      late int g;
      if (index < 16) {
        f = (b & c) | ((~b) & d);
        g = index;
      } else if (index < 32) {
        f = (d & b) | ((~d) & c);
        g = (5 * index + 1) % 16;
      } else if (index < 48) {
        f = b ^ c ^ d;
        g = (3 * index + 5) % 16;
      } else {
        f = c ^ (b | (~d));
        g = (7 * index) % 16;
      }

      final rotated = _leftRotate(
        (a + f + _md5Constants[index] + words[g]) & 0xffffffff,
        _md5ShiftAmounts[index],
      );
      final nextB = (b + rotated) & 0xffffffff;

      a = d;
      d = c;
      c = b;
      b = nextB;
    }

    a0 = (a0 + a) & 0xffffffff;
    b0 = (b0 + b) & 0xffffffff;
    c0 = (c0 + c) & 0xffffffff;
    d0 = (d0 + d) & 0xffffffff;
  }

  final digest = Uint8List(16)
    ..setRange(0, 4, _wordToLittleEndianBytes(a0))
    ..setRange(4, 8, _wordToLittleEndianBytes(b0))
    ..setRange(8, 12, _wordToLittleEndianBytes(c0))
    ..setRange(12, 16, _wordToLittleEndianBytes(d0));

  final buffer = StringBuffer();
  for (final byte in digest) {
    buffer.write(byte.toRadixString(16).padLeft(2, '0'));
  }
  return buffer.toString();
}

int _leftRotate(int value, int shift) {
  final normalized = value & 0xffffffff;
  return ((normalized << shift) | (normalized >> (32 - shift))) & 0xffffffff;
}

List<int> _wordToLittleEndianBytes(int value) {
  return <int>[
    value & 0xff,
    (value >> 8) & 0xff,
    (value >> 16) & 0xff,
    (value >> 24) & 0xff,
  ];
}

const List<int> _roundConstants = <int>[
  0x00,
  0x01,
  0x02,
  0x04,
  0x08,
  0x10,
  0x20,
  0x40,
  0x80,
  0x1b,
  0x36,
];

final List<int> _md5Constants = List<int>.generate(
  64,
  (index) => (math.sin(index + 1).abs() * 4294967296).floor() & 0xffffffff,
  growable: false,
);

const List<int> _md5ShiftAmounts = <int>[
  7,
  12,
  17,
  22,
  7,
  12,
  17,
  22,
  7,
  12,
  17,
  22,
  7,
  12,
  17,
  22,
  5,
  9,
  14,
  20,
  5,
  9,
  14,
  20,
  5,
  9,
  14,
  20,
  5,
  9,
  14,
  20,
  4,
  11,
  16,
  23,
  4,
  11,
  16,
  23,
  4,
  11,
  16,
  23,
  4,
  11,
  16,
  23,
  6,
  10,
  15,
  21,
  6,
  10,
  15,
  21,
  6,
  10,
  15,
  21,
  6,
  10,
  15,
  21,
];

const List<int> _sBox = <int>[
  0x63,
  0x7c,
  0x77,
  0x7b,
  0xf2,
  0x6b,
  0x6f,
  0xc5,
  0x30,
  0x01,
  0x67,
  0x2b,
  0xfe,
  0xd7,
  0xab,
  0x76,
  0xca,
  0x82,
  0xc9,
  0x7d,
  0xfa,
  0x59,
  0x47,
  0xf0,
  0xad,
  0xd4,
  0xa2,
  0xaf,
  0x9c,
  0xa4,
  0x72,
  0xc0,
  0xb7,
  0xfd,
  0x93,
  0x26,
  0x36,
  0x3f,
  0xf7,
  0xcc,
  0x34,
  0xa5,
  0xe5,
  0xf1,
  0x71,
  0xd8,
  0x31,
  0x15,
  0x04,
  0xc7,
  0x23,
  0xc3,
  0x18,
  0x96,
  0x05,
  0x9a,
  0x07,
  0x12,
  0x80,
  0xe2,
  0xeb,
  0x27,
  0xb2,
  0x75,
  0x09,
  0x83,
  0x2c,
  0x1a,
  0x1b,
  0x6e,
  0x5a,
  0xa0,
  0x52,
  0x3b,
  0xd6,
  0xb3,
  0x29,
  0xe3,
  0x2f,
  0x84,
  0x53,
  0xd1,
  0x00,
  0xed,
  0x20,
  0xfc,
  0xb1,
  0x5b,
  0x6a,
  0xcb,
  0xbe,
  0x39,
  0x4a,
  0x4c,
  0x58,
  0xcf,
  0xd0,
  0xef,
  0xaa,
  0xfb,
  0x43,
  0x4d,
  0x33,
  0x85,
  0x45,
  0xf9,
  0x02,
  0x7f,
  0x50,
  0x3c,
  0x9f,
  0xa8,
  0x51,
  0xa3,
  0x40,
  0x8f,
  0x92,
  0x9d,
  0x38,
  0xf5,
  0xbc,
  0xb6,
  0xda,
  0x21,
  0x10,
  0xff,
  0xf3,
  0xd2,
  0xcd,
  0x0c,
  0x13,
  0xec,
  0x5f,
  0x97,
  0x44,
  0x17,
  0xc4,
  0xa7,
  0x7e,
  0x3d,
  0x64,
  0x5d,
  0x19,
  0x73,
  0x60,
  0x81,
  0x4f,
  0xdc,
  0x22,
  0x2a,
  0x90,
  0x88,
  0x46,
  0xee,
  0xb8,
  0x14,
  0xde,
  0x5e,
  0x0b,
  0xdb,
  0xe0,
  0x32,
  0x3a,
  0x0a,
  0x49,
  0x06,
  0x24,
  0x5c,
  0xc2,
  0xd3,
  0xac,
  0x62,
  0x91,
  0x95,
  0xe4,
  0x79,
  0xe7,
  0xc8,
  0x37,
  0x6d,
  0x8d,
  0xd5,
  0x4e,
  0xa9,
  0x6c,
  0x56,
  0xf4,
  0xea,
  0x65,
  0x7a,
  0xae,
  0x08,
  0xba,
  0x78,
  0x25,
  0x2e,
  0x1c,
  0xa6,
  0xb4,
  0xc6,
  0xe8,
  0xdd,
  0x74,
  0x1f,
  0x4b,
  0xbd,
  0x8b,
  0x8a,
  0x70,
  0x3e,
  0xb5,
  0x66,
  0x48,
  0x03,
  0xf6,
  0x0e,
  0x61,
  0x35,
  0x57,
  0xb9,
  0x86,
  0xc1,
  0x1d,
  0x9e,
  0xe1,
  0xf8,
  0x98,
  0x11,
  0x69,
  0xd9,
  0x8e,
  0x94,
  0x9b,
  0x1e,
  0x87,
  0xe9,
  0xce,
  0x55,
  0x28,
  0xdf,
  0x8c,
  0xa1,
  0x89,
  0x0d,
  0xbf,
  0xe6,
  0x42,
  0x68,
  0x41,
  0x99,
  0x2d,
  0x0f,
  0xb0,
  0x54,
  0xbb,
  0x16,
];

const List<int> _inverseSBox = <int>[
  0x52,
  0x09,
  0x6a,
  0xd5,
  0x30,
  0x36,
  0xa5,
  0x38,
  0xbf,
  0x40,
  0xa3,
  0x9e,
  0x81,
  0xf3,
  0xd7,
  0xfb,
  0x7c,
  0xe3,
  0x39,
  0x82,
  0x9b,
  0x2f,
  0xff,
  0x87,
  0x34,
  0x8e,
  0x43,
  0x44,
  0xc4,
  0xde,
  0xe9,
  0xcb,
  0x54,
  0x7b,
  0x94,
  0x32,
  0xa6,
  0xc2,
  0x23,
  0x3d,
  0xee,
  0x4c,
  0x95,
  0x0b,
  0x42,
  0xfa,
  0xc3,
  0x4e,
  0x08,
  0x2e,
  0xa1,
  0x66,
  0x28,
  0xd9,
  0x24,
  0xb2,
  0x76,
  0x5b,
  0xa2,
  0x49,
  0x6d,
  0x8b,
  0xd1,
  0x25,
  0x72,
  0xf8,
  0xf6,
  0x64,
  0x86,
  0x68,
  0x98,
  0x16,
  0xd4,
  0xa4,
  0x5c,
  0xcc,
  0x5d,
  0x65,
  0xb6,
  0x92,
  0x6c,
  0x70,
  0x48,
  0x50,
  0xfd,
  0xed,
  0xb9,
  0xda,
  0x5e,
  0x15,
  0x46,
  0x57,
  0xa7,
  0x8d,
  0x9d,
  0x84,
  0x90,
  0xd8,
  0xab,
  0x00,
  0x8c,
  0xbc,
  0xd3,
  0x0a,
  0xf7,
  0xe4,
  0x58,
  0x05,
  0xb8,
  0xb3,
  0x45,
  0x06,
  0xd0,
  0x2c,
  0x1e,
  0x8f,
  0xca,
  0x3f,
  0x0f,
  0x02,
  0xc1,
  0xaf,
  0xbd,
  0x03,
  0x01,
  0x13,
  0x8a,
  0x6b,
  0x3a,
  0x91,
  0x11,
  0x41,
  0x4f,
  0x67,
  0xdc,
  0xea,
  0x97,
  0xf2,
  0xcf,
  0xce,
  0xf0,
  0xb4,
  0xe6,
  0x73,
  0x96,
  0xac,
  0x74,
  0x22,
  0xe7,
  0xad,
  0x35,
  0x85,
  0xe2,
  0xf9,
  0x37,
  0xe8,
  0x1c,
  0x75,
  0xdf,
  0x6e,
  0x47,
  0xf1,
  0x1a,
  0x71,
  0x1d,
  0x29,
  0xc5,
  0x89,
  0x6f,
  0xb7,
  0x62,
  0x0e,
  0xaa,
  0x18,
  0xbe,
  0x1b,
  0xfc,
  0x56,
  0x3e,
  0x4b,
  0xc6,
  0xd2,
  0x79,
  0x20,
  0x9a,
  0xdb,
  0xc0,
  0xfe,
  0x78,
  0xcd,
  0x5a,
  0xf4,
  0x1f,
  0xdd,
  0xa8,
  0x33,
  0x88,
  0x07,
  0xc7,
  0x31,
  0xb1,
  0x12,
  0x10,
  0x59,
  0x27,
  0x80,
  0xec,
  0x5f,
  0x60,
  0x51,
  0x7f,
  0xa9,
  0x19,
  0xb5,
  0x4a,
  0x0d,
  0x2d,
  0xe5,
  0x7a,
  0x9f,
  0x93,
  0xc9,
  0x9c,
  0xef,
  0xa0,
  0xe0,
  0x3b,
  0x4d,
  0xae,
  0x2a,
  0xf5,
  0xb0,
  0xc8,
  0xeb,
  0xbb,
  0x3c,
  0x83,
  0x53,
  0x99,
  0x61,
  0x17,
  0x2b,
  0x04,
  0x7e,
  0xba,
  0x77,
  0xd6,
  0x26,
  0xe1,
  0x69,
  0x14,
  0x63,
  0x55,
  0x21,
  0x0c,
  0x7d,
];
