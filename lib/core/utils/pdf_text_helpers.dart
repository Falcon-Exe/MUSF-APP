import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

const int pdfLongParagraphChunkSize = 850;

List<pw.Widget> buildPdfTextBlocks(
  String text, {
  double fontSize = 11,
  PdfColor color = PdfColors.grey800,
  double lineSpacing = 1.5,
  pw.TextAlign textAlign = pw.TextAlign.justify,
}) {
  final blocks = text
      .replaceAll('\r\n', '\n')
      .split(RegExp(r'\n{2,}'))
      .expand(splitPdfParagraph)
      .toList();

  if (blocks.isEmpty) {
    return [pw.SizedBox.shrink()];
  }

  return blocks
      .map(
        (block) => pw.Padding(
          padding: const pw.EdgeInsets.only(bottom: 7),
          child: pw.Text(
            block,
            softWrap: true,
            textAlign: textAlign,
            style: pw.TextStyle(
              fontSize: fontSize,
              lineSpacing: lineSpacing,
              color: color,
            ),
          ),
        ),
      )
      .toList();
}

Iterable<String> splitPdfParagraph(String paragraph) sync* {
  final normalized = paragraph.trim();
  if (normalized.isEmpty) return;

  for (var start = 0; start < normalized.length;) {
    var end = start + pdfLongParagraphChunkSize;
    if (end >= normalized.length) {
      yield normalized.substring(start);
      break;
    }

    final boundary = normalized.lastIndexOf(' ', end);
    if (boundary > start + 120) end = boundary;
    yield normalized.substring(start, end).trim();
    start = end;
  }
}

Map<String, List<Map<String, dynamic>>> groupPdfRowsByField(
  Iterable<Map<String, dynamic>> rows,
  String fieldName, {
  String fallback = 'General',
}) {
  final grouped = <String, List<Map<String, dynamic>>>{};
  for (final row in rows) {
    final key = (row[fieldName]?.toString().trim().isNotEmpty == true)
        ? row[fieldName].toString().trim()
        : fallback;
    grouped.putIfAbsent(key, () => []).add(row);
  }
  return grouped;
}
