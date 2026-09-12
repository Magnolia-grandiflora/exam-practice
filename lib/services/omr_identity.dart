import 'dart:convert';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';

import '../domain/models.dart';

class OmrPayload {
  const OmrPayload({
    required this.version,
    required this.paperToken,
    required this.layout,
    required this.questions,
    required this.bankId,
    required this.catalogVersion,
    required this.questionPositions,
    required this.checksum,
  });

  final int version;
  final String paperToken;
  final String layout;
  final int questions;
  final String bankId;
  final int catalogVersion;
  final List<int> questionPositions;
  final String checksum;

  Map<String, Object?> toJson() => <String, Object?>{
    'v': version,
    'paper_token': paperToken,
    'layout': layout,
    'questions': questions,
    'bank_id': bankId,
    'catalog_version': catalogVersion,
    'question_order': OmrIdentity.encodePositions(questionPositions),
    'checksum': checksum,
  };
}

class OmrIdentity {
  const OmrIdentity._();

  static const layout = 'a4-omr-v4';
  static const pageWidth = 2100;
  static const pageHeight = 2970;
  static const groupSize = 20;
  static const tableTopMm = 56.0;
  static const rowHeightMm = 6.4;
  static const numberColumnWidthMm = 8.0;

  /// 四个嵌套方框的中心，坐标基于完整 2100×2970 A4 页面。
  /// CSS 内容框有 9mm 页边距，故定位点的内容框坐标须加上该页边距。
  /// bridge 用同一份模板数据将实拍图透视校正回这个坐标系。
  static const markerCenters = <List<int>>[
    [150, 155],
    [1950, 155],
    [150, 2725],
    [1950, 2725],
  ];

  static double tableWidthMm(int groups) => groups <= 3 ? groups * 50.0 : 180.0;

  static double groupWidthMm(int groups) => tableWidthMm(groups) / groups;

  static OmrPayload forAttempt(
    PaperAttempt attempt, {
    required int catalogVersion,
    required List<int> questionPositions,
  }) {
    if (questionPositions.length != attempt.questions.length) {
      throw const FormatException('答题卡题目顺序数量不一致');
    }
    final encodedOrder = encodePositions(questionPositions);
    final digest = sha256.convert(
      utf8.encode(
        '$layout|${attempt.paperId}|${attempt.attemptId}|${attempt.bankId}|$catalogVersion|$encodedOrder',
      ),
    );
    final paperToken = base64Url
        .encode(digest.bytes)
        .replaceAll('=', '')
        .substring(0, 32);
    return _signedPayload(
      paperToken: paperToken,
      questions: attempt.questions.length,
      bankId: attempt.bankId,
      catalogVersion: catalogVersion,
      encodedOrder: encodedOrder,
    );
  }

  static OmrPayload parseAndValidate(String text) {
    final decoded = jsonDecode(text);
    if (decoded is! Map) throw const FormatException('二维码内容不是有效对象');
    final json = decoded.cast<String, Object?>();
    final version = (json['v'] as num?)?.toInt();
    final paperToken = json['paper_token']?.toString() ?? '';
    final parsedLayout = json['layout']?.toString() ?? '';
    final questions = (json['questions'] as num?)?.toInt();
    final bankId = json['bank_id']?.toString() ?? '';
    final catalogVersion = (json['catalog_version'] as num?)?.toInt();
    final encodedOrder = json['question_order']?.toString() ?? '';
    final checksum = json['checksum']?.toString() ?? '';
    if (version != 1 || paperToken.length != 32) {
      throw const FormatException('二维码版本或试卷标识无效');
    }
    if (parsedLayout != layout) {
      throw FormatException('答题卡模板不匹配：需要 $layout');
    }
    if (questions == null || questions < 1 || questions > 100) {
      throw const FormatException('二维码题量必须在 1—100 之间');
    }
    if (bankId.isEmpty ||
        bankId.length > 200 ||
        catalogVersion == null ||
        catalogVersion < 1) {
      throw const FormatException('二维码题库信息无效');
    }
    final positions = decodePositions(encodedOrder, questions);
    if (positions.toSet().length != positions.length) {
      throw const FormatException('二维码题目顺序包含重复项');
    }
    final expected = _signedPayload(
      paperToken: paperToken,
      questions: questions,
      bankId: bankId,
      catalogVersion: catalogVersion,
      encodedOrder: encodedOrder,
    ).checksum;
    if (checksum != expected) throw const FormatException('二维码校验失败');
    return OmrPayload(
      version: version!,
      paperToken: paperToken,
      layout: parsedLayout,
      questions: questions,
      bankId: bankId,
      catalogVersion: catalogVersion,
      questionPositions: positions,
      checksum: checksum,
    );
  }

  static OmrPayload _signedPayload({
    required String paperToken,
    required int questions,
    required String bankId,
    required int catalogVersion,
    required String encodedOrder,
  }) {
    final unsigned = <String, Object?>{
      'v': 1,
      'paper_token': paperToken,
      'layout': layout,
      'questions': questions,
      'bank_id': bankId,
      'catalog_version': catalogVersion,
      'question_order': encodedOrder,
    };
    final checksum = sha256
        .convert(utf8.encode(jsonEncode(unsigned)))
        .toString()
        .substring(0, 16);
    return OmrPayload(
      version: 1,
      paperToken: paperToken,
      layout: layout,
      questions: questions,
      bankId: bankId,
      catalogVersion: catalogVersion,
      questionPositions: decodePositions(encodedOrder, questions),
      checksum: checksum,
    );
  }

  static String encodePositions(List<int> positions) {
    final bytes = BytesBuilder(copy: false);
    for (final position in positions) {
      if (position < 0) throw const FormatException('题目序号不能为负数');
      var value = position;
      do {
        var byte = value & 0x7f;
        value >>= 7;
        if (value > 0) byte |= 0x80;
        bytes.addByte(byte);
      } while (value > 0);
    }
    return base64Url.encode(bytes.takeBytes()).replaceAll('=', '');
  }

  static List<int> decodePositions(String encoded, int expectedCount) {
    Uint8List bytes;
    try {
      bytes = base64Url.decode(base64Url.normalize(encoded));
    } on FormatException {
      throw const FormatException('二维码题目顺序编码无效');
    }
    final result = <int>[];
    var value = 0;
    var shift = 0;
    for (final byte in bytes) {
      value |= (byte & 0x7f) << shift;
      if ((byte & 0x80) == 0) {
        result.add(value);
        value = 0;
        shift = 0;
      } else {
        shift += 7;
        if (shift > 28) throw const FormatException('二维码题目序号过大');
      }
    }
    if (shift != 0 || result.length != expectedCount) {
      throw const FormatException('二维码题目顺序数量不一致');
    }
    return List.unmodifiable(result);
  }
}
