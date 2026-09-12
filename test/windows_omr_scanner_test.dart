import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:personal_exam_app/services/windows_omr_scanner.dart';

void main() {
  const quad = [
    [0.1, 0.1],
    [0.9, 0.1],
    [0.9, 0.9],
    [0.1, 0.9],
  ];

  Map<String, Object?> withGeometry(Map<String, Object?> question) => {
    ...question,
    'bubble_quad': {'A': quad, 'B': quad, 'C': quad, 'D': quad, 'E': quad},
  };

  String output(List<Map<String, Object?>> questions) => jsonEncode({
    'schema_version': 2,
    'layout': 'a4-omr-v4',
    'source_size': {'width': 1280, 'height': 1706},
    'page_quad': quad,
    'questions': questions
        .map(
          (question) => question.containsKey('bubble_quad')
              ? question
              : withGeometry(question),
        )
        .toList(),
  });

  test('adapts the paper OMR qN JSON contract in numeric order', () {
    final result = WindowsOmrScanner.parseOutput(
      output([
        {
          'label': 'q2',
          'selected': ['B', 'D'],
          'confidence': 0.0,
        },
        {
          'label': 'q1',
          'selected': ['A'],
          'confidence': 0.0,
        },
      ]),
      expectedQuestions: 2,
    );
    expect(result.questions.map((question) => question.number), [1, 2]);
    expect(result.questions[1].selected, {'B', 'D'});
  });

  test('rejects malformed, duplicate, and out-of-range paper OMR labels', () {
    expect(
      () => WindowsOmrScanner.parseOutput(
        output([
          {
            'label': 'q1',
            'selected': ['A'],
            'confidence': 0.0,
          },
          {
            'label': 'q1',
            'selected': ['B'],
            'confidence': 0.0,
          },
        ]),
        expectedQuestions: 2,
      ),
      throwsFormatException,
    );
    expect(
      () => WindowsOmrScanner.parseOutput(
        output([
          {
            'label': 'q1',
            'selected': ['A'],
            'confidence': 0.0,
          },
          {
            'label': 'q3',
            'selected': ['B'],
            'confidence': 0.0,
          },
        ]),
        expectedQuestions: 2,
      ),
      throwsFormatException,
    );
    expect(
      () => WindowsOmrScanner.parseOutput(
        output([
          {
            'label': 'q1',
            'selected': ['F'],
            'confidence': 0.0,
          },
          {
            'label': 'q2',
            'selected': ['B'],
            'confidence': 0.0,
          },
        ]),
        expectedQuestions: 2,
      ),
      throwsFormatException,
    );
  });

  test('requires the bridge schema and every expected output row', () {
    expect(
      () => WindowsOmrScanner.parseOutput(
        jsonEncode({'schema_version': 1, 'questions': []}),
        expectedQuestions: 1,
      ),
      throwsFormatException,
    );
    expect(
      () => WindowsOmrScanner.parseOutput(
        output([
          {
            'label': 'q1',
            'selected': ['A'],
            'confidence': 0.0,
          },
        ]),
        expectedQuestions: 2,
      ),
      throwsFormatException,
    );
  });

  test('passes explicit argv and reads the bridge result file', () async {
    final temp = Directory.systemTemp.createTempSync('windows-omr-checker-');
    try {
      final image = File('${temp.path}${Platform.pathSeparator}sheet.PNG')
        ..writeAsBytesSync([1]);
      final template = File(
        '${temp.path}${Platform.pathSeparator}template.json',
      )..writeAsStringSync('{}');
      final executable = File(
        '${temp.path}${Platform.pathSeparator}paper_omr_bridge.exe',
      )..writeAsBytesSync([1]);
      late List<String> argv;
      late String resultDirectoryPath;
      final checker = WindowsOmrScanner(
        executable: executable,
        runner: (path, arguments) async {
          expect(path, executable.path);
          argv = arguments;
          final outputIndex = arguments.indexOf('--output');
          resultDirectoryPath = File(arguments[outputIndex + 1]).parent.path;
          File(arguments[outputIndex + 1]).writeAsStringSync(
            output([
              {
                'label': 'q1',
                'selected': ['C'],
                'confidence': 0.0,
              },
            ]),
          );
          return ProcessResult(123, 0, '{"schema_version":2}', '');
        },
      );
      final result = await checker.check(
        image: image,
        template: template,
        expectedQuestions: 1,
      );
      expect(argv, containsAllInOrder(['--input', image.path, '--template']));
      expect(argv, contains('--output'));
      expect(result.questions.single.selected, {'C'});
      expect(Directory(resultDirectoryPath).existsSync(), isFalse);
    } finally {
      temp.deleteSync(recursive: true);
    }
  });

  test('rejects missing, non-finite, and out-of-range overlay geometry', () {
    final valid = {
      'label': 'q1',
      'selected': ['A'],
      'confidence': 0.0,
      'bubble_quad': {'A': quad, 'B': quad, 'C': quad, 'D': quad},
    };
    expect(
      () =>
          WindowsOmrScanner.parseOutput(output([valid]), expectedQuestions: 1),
      throwsFormatException,
    );
    final invalid = withGeometry({
      'label': 'q1',
      'selected': ['A'],
      'confidence': 0.0,
    });
    (invalid['bubble_quad'] as Map)['A'] = [
      [1.2, 0.0],
      [0.9, 0.1],
      [0.9, 0.9],
      [0.1, 0.9],
    ];
    expect(
      () => WindowsOmrScanner.parseOutput(
        output([invalid]),
        expectedQuestions: 1,
      ),
      throwsFormatException,
    );
  });

  test('fails on bridge nonzero exit, missing output, and timeout', () async {
    final temp = Directory.systemTemp.createTempSync('windows-omr-checker-');
    try {
      final image = File('${temp.path}${Platform.pathSeparator}sheet.jpg')
        ..writeAsBytesSync([1]);
      final template = File(
        '${temp.path}${Platform.pathSeparator}template.json',
      )..writeAsStringSync('{}');
      final executable = File(
        '${temp.path}${Platform.pathSeparator}paper_omr_bridge.exe',
      )..writeAsBytesSync([1]);
      Future<ProcessResult> nonzero(
        String ignoredExecutable,
        List<String> ignoredArguments,
      ) async => ProcessResult(1, 2, '', 'bad image');
      await expectLater(
        WindowsOmrScanner(
          runner: nonzero,
          executable: executable,
        ).check(image: image, template: template, expectedQuestions: 1),
        throwsStateError,
      );
      Future<ProcessResult> noOutput(
        String ignoredExecutable,
        List<String> ignoredArguments,
      ) async => ProcessResult(1, 0, 'no result', '');
      await expectLater(
        WindowsOmrScanner(
          runner: noOutput,
          executable: executable,
        ).check(image: image, template: template, expectedQuestions: 1),
        throwsStateError,
      );
      Future<ProcessResult> delayed(
        String ignoredExecutable,
        List<String> ignoredArguments,
      ) async {
        await Future<void>.delayed(const Duration(milliseconds: 30));
        return ProcessResult(1, 0, '', '');
      }

      await expectLater(
        WindowsOmrScanner(runner: delayed, executable: executable).check(
          image: image,
          template: template,
          expectedQuestions: 1,
          timeout: const Duration(milliseconds: 1),
        ),
        throwsA(isA<TimeoutException>()),
      );
    } finally {
      temp.deleteSync(recursive: true);
    }
  });

  test('terminates the real sidecar process on timeout', () async {
    if (!Platform.isWindows) return;
    final temp = Directory.systemTemp.createTempSync('windows-omr-kill-');
    try {
      final image = File('${temp.path}${Platform.pathSeparator}sheet.jpg')
        ..writeAsBytesSync([1]);
      final template = File(
        '${temp.path}${Platform.pathSeparator}template.json',
      )..writeAsStringSync('{}');
      final marker = File('${temp.path}${Platform.pathSeparator}late.txt');
      final executable = File('${temp.path}${Platform.pathSeparator}slow.bat')
        ..writeAsStringSync(
          '@echo off\r\n'
          'ping -n 3 127.0.0.1 >nul\r\n'
          'echo late>"${marker.path}"\r\n',
        );

      await expectLater(
        WindowsOmrScanner(executable: executable).check(
          image: image,
          template: template,
          expectedQuestions: 1,
          timeout: const Duration(milliseconds: 50),
        ),
        throwsA(isA<TimeoutException>()),
      );
      await Future<void>.delayed(const Duration(seconds: 3));
      expect(marker.existsSync(), isFalse);
    } finally {
      temp.deleteSync(recursive: true);
    }
  });
}
