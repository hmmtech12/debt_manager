import 'dart:convert';

import 'package:file_picker/file_picker.dart';

/// Opens a file picker for .csv files and parses them. Pairs with
/// `ExportService.exportCsv` — expects the same column layout that
/// produces (Person, Type, Original Amount, Currency, Paid, Remaining,
/// Debt Date, Due Date, Status, Notes), with the first row treated as a
/// header and skipped.
class ImportService {
  ImportService._();

  /// Returns null if the person cancels the picker. Throws if the file
  /// can't be read — callers should catch and show an error.
  static Future<List<List<String>>?> pickAndParseCsv() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['csv'],
      withData: true, // ensures `.bytes` is populated on every platform
    );
    if (result == null || result.files.isEmpty) return null;

    final fileBytes = result.files.single.bytes;
    if (fileBytes == null) {
      throw StateError('Could not read the selected file.');
    }
    final content = utf8.decode(fileBytes, allowMalformed: true);
    return _parseCsv(content);
  }

  /// Minimal RFC-4180-style CSV parser — handles quoted fields, escaped
  /// (doubled) quotes inside them, and commas/newlines within quotes.
  /// Mirrors `ExportService._toCsv`'s encoding so round-tripping works.
  static List<List<String>> _parseCsv(String content) {
    final rows = <List<String>>[];
    var field = StringBuffer();
    var row = <String>[];
    var inQuotes = false;
    final len = content.length;
    var i = 0;

    void endField() {
      row.add(field.toString());
      field = StringBuffer();
    }

    void endRow() {
      endField();
      rows.add(row);
      row = [];
    }

    while (i < len) {
      final c = content[i];
      if (inQuotes) {
        if (c == '"') {
          if (i + 1 < len && content[i + 1] == '"') {
            field.write('"');
            i += 2;
          } else {
            inQuotes = false;
            i++;
          }
        } else {
          field.write(c);
          i++;
        }
        continue;
      }

      if (c == '"') {
        inQuotes = true;
        i++;
      } else if (c == ',') {
        endField();
        i++;
      } else if (c == '\r') {
        endRow();
        i += (i + 1 < len && content[i + 1] == '\n') ? 2 : 1;
      } else if (c == '\n') {
        endRow();
        i++;
      } else {
        field.write(c);
        i++;
      }
    }

    if (field.isNotEmpty || row.isNotEmpty) {
      endRow();
    }

    // Drop trailing fully-empty rows (common at end of a file).
    rows.removeWhere((r) => r.length == 1 && r.first.trim().isEmpty);
    return rows;
  }
}
