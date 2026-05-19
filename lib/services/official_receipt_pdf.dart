import 'dart:typed_data';

import 'package:flutter/material.dart' show Offset, Rect, Size;
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart' show PdfPageFormat;
import 'package:printing/printing.dart';
import 'package:syncfusion_flutter_pdf/pdf.dart';

import '../data/database.dart';

/// St. Peter's Parish–style official receipt as A4 PDF (Kanisani Hub sample).
///
/// PDF generation uses [Syncfusion Flutter PDF](https://pub.dev/packages/syncfusion_flutter_pdf)
/// (community or commercial license applies). Printing uses the `printing` package.
class OfficialReceiptPdf {
  OfficialReceiptPdf._();

  static final PdfColor _teal = PdfColor(0, 90, 113); // #005a71
  static final PdfColor _textGray = PdfColor(107, 114, 128);
  static final PdfColor _headerBg = PdfColor(
    234,
    237,
    255,
  ); // surface-container-low
  static final PdfColor _outlineVariant = PdfColor(190, 200, 205);
  static final PdfColor _rowDivider = PdfColor(210, 218, 223);
  static final PdfColor _ink = PdfColor(26, 26, 26);
  static final PdfColor _titleGray = PdfColor(209, 213, 219);

  static PdfPen _penHeaderBorder() => PdfPen(_outlineVariant, width: 0.6);
  static PdfPen _penRowBorder() => PdfPen(_rowDivider, width: 0.4);

  /// Opens the system print / save-as-PDF sheet with a fixed A4 layout.
  static Future<void> showPrintDialog(User user) async {
    // Build inside [onLayout] so each print session gets a fresh PDF. Reusing
    // pre-built bytes or Syncfusion fonts across runs can cause null failures
    // when the dialog is opened a second time.
    await Printing.layoutPdf(
      name: 'official_receipt.pdf',
      format: PdfPageFormat.a4,
      dynamicLayout: false,
      onLayout: (_) => buildPdf(user),
    );
  }

  /// Builds a single A4 page as PDF bytes (Syncfusion).
  static Future<Uint8List> buildPdf(User user) async {
    final issued = DateTime.now();
    final displayName = user.name.trim().isEmpty
        ? user.email.split('@').first
        : user.name.trim();
    final receivedFrom = displayName.toUpperCase();
    final memberId = 'PAR-${user.id.toString().padLeft(4, '0')}-M';
    final receiptSuffix = ((88421 + user.id * 97) % 100000).toString().padLeft(
      5,
      '0',
    );
    final receiptNo = '#RCP-${issued.year}-$receiptSuffix';
    final dateStr = DateFormat.yMMMMd().format(issued);
    final printedStr = DateFormat("MMMM d, yyyy | HH:mm:ss").format(issued);
    final monthName = DateFormat.MMMM().format(issued);
    final fonts = _ReceiptFonts();

    final document = PdfDocument();
    try {
      document.pageSettings.size = PdfPageSize.a4;
      document.pageSettings.margins.all = 56;
      final page = document.pages.add();
      final g = page.graphics;
      final Size client = page.getClientSize();
      final double w = client.width;

      var y = 0.0;
      const leftBlockW = 320.0;
      const logo = 52.0;

      g.drawRectangle(
        bounds: Rect.fromLTWH(0, y, logo, logo),
        brush: PdfSolidBrush(_teal),
      );
      g.drawString(
        '+',
        PdfStandardFont(PdfFontFamily.helvetica, 28, style: PdfFontStyle.bold),
        brush: PdfBrushes.white,
        bounds: Rect.fromLTWH(0, y + 8, logo, logo),
        format: PdfStringFormat(alignment: PdfTextAlignment.center),
      );

      var tx = logo + 14;
      g.drawString(
        "ST. PETER'S PARISH",
        fonts.bold18,
        brush: PdfSolidBrush(_teal),
        bounds: Rect.fromLTWH(tx, y, leftBlockW - tx, 22),
      );
      y += 24;
      g.drawString(
        'Diocese of Metropolitan Heights',
        fonts.regular9,
        brush: PdfSolidBrush(_textGray),
        bounds: Rect.fromLTWH(tx, y, w, 14),
      );
      y += 12;
      g.drawString(
        '124 Church Road, West District, 40221',
        fonts.regular9,
        brush: PdfSolidBrush(_textGray),
        bounds: Rect.fromLTWH(tx, y, w, 14),
      );
      y += 12;
      g.drawString(
        'Tel: +1 (555) 902-3341 | stpeters.hub@diocese.org',
        fonts.regular9,
        brush: PdfSolidBrush(_textGray),
        bounds: Rect.fromLTWH(tx, y, w, 14),
      );

      const rightColW = 200.0;
      final rightX = w - rightColW;
      var ry = 0.0;
      g.drawString(
        'OFFICIAL RECEIPT',
        fonts.bold20,
        brush: PdfSolidBrush(_titleGray),
        bounds: Rect.fromLTWH(rightX, ry, rightColW, 26),
        format: PdfStringFormat(alignment: PdfTextAlignment.right),
      );
      ry += 28;
      g.drawRectangle(
        bounds: Rect.fromLTWH(rightX, ry, rightColW, 44),
        pen: PdfPen(_outlineVariant, width: 0.5),
        brush: PdfSolidBrush(PdfColor(242, 243, 255)),
      );
      g.drawString(
        'RECEIPT NO.',
        fonts.bold8,
        brush: PdfSolidBrush(_textGray),
        bounds: Rect.fromLTWH(rightX + 8, ry + 6, rightColW - 16, 12),
        format: PdfStringFormat(alignment: PdfTextAlignment.right),
      );
      g.drawString(
        receiptNo,
        fonts.bold11,
        brush: PdfSolidBrush(_teal),
        bounds: Rect.fromLTWH(rightX + 8, ry + 20, rightColW - 16, 18),
        format: PdfStringFormat(alignment: PdfTextAlignment.right),
      );

      y = logo + 28;
      g.drawLine(PdfPen(_teal, width: 2.5), Offset(0, y), Offset(w, y));
      y += 18;

      final mid = w * 0.5;
      g.drawLine(
        PdfPen(_outlineVariant, width: 1.5),
        Offset(0, y),
        Offset(0, y + 52),
      );
      g.drawLine(
        PdfPen(_outlineVariant, width: 1.5),
        Offset(mid, y),
        Offset(mid, y + 52),
      );
      g.drawString(
        'DATE OF ISSUE',
        fonts.bold8,
        brush: PdfSolidBrush(_textGray),
        bounds: Rect.fromLTWH(12, y, mid - 20, 12),
      );
      g.drawString(
        'RECEIVED FROM',
        fonts.bold8,
        brush: PdfSolidBrush(_textGray),
        bounds: Rect.fromLTWH(mid + 12, y, mid - 12, 12),
      );
      y += 14;
      g.drawString(
        dateStr,
        fonts.regular11,
        brush: PdfSolidBrush(_ink),
        bounds: Rect.fromLTWH(12, y, mid - 20, 16),
      );
      g.drawString(
        receivedFrom,
        fonts.bold11,
        brush: PdfSolidBrush(_ink),
        bounds: Rect.fromLTWH(mid + 12, y, mid - 12, 18),
      );
      y += 18;
      g.drawString(
        'Member ID: $memberId',
        fonts.regular9,
        brush: PdfSolidBrush(_textGray),
        bounds: Rect.fromLTWH(mid + 12, y, mid - 12, 14),
      );
      y += 36;

      y = _drawLineItemsTable(
        g,
        fonts,
        y,
        w,
        monthName: monthName,
        year: issued.year,
      );
      y += 16;

      g.drawRectangle(
        bounds: Rect.fromLTWH(0, y, w, 56),
        pen: PdfPen(_outlineVariant, width: 0.5),
        brush: PdfSolidBrush(PdfColor(255, 255, 255)),
      );
      g.drawString(
        'AMOUNT IN WORDS',
        fonts.bold8,
        brush: PdfSolidBrush(_textGray),
        bounds: Rect.fromLTWH(12, y + 8, w - 24, 12),
      );
      g.drawString(
        'One Thousand, Seven Hundred and Fifty Dollars Only.',
        fonts.italic12,
        brush: PdfSolidBrush(_ink),
        bounds: Rect.fromLTWH(12, y + 22, w - 24, 28),
      );
      y += 80;

      final footerTop = client.height - 72;
      if (y > footerTop - 48) {
        // y = footerTop - 48;
      }
      g.drawLine(
        PdfPen(_ink, width: 0.75),
        Offset(w * 0.25, y),
        Offset(w * 0.75, y),
      );
      y += 8;
      g.drawString(
        'ISSUED BY',
        fonts.bold8,
        brush: PdfSolidBrush(_textGray),
        bounds: Rect.fromLTWH(0, y, w, 12),
        format: PdfStringFormat(alignment: PdfTextAlignment.center),
      );
      y += 12;
      g.drawString(
        'Accounts Department',
        fonts.regular9,
        brush: PdfSolidBrush(_textGray),
        bounds: Rect.fromLTWH(0, y, w, 12),
        format: PdfStringFormat(alignment: PdfTextAlignment.center),
      );

      final footY = client.height - 36;
      g.drawString(
        'Generated by Kanisani Hub',
        fonts.regular8,
        brush: PdfSolidBrush(_textGray),
        bounds: Rect.fromLTWH(0, footY, w * 0.28, 12),
      );
      g.drawString(
        "St. Peter's Parish is a registered 501(c)(3) non-profit organization. "
        'All donations are tax-deductible.',
        fonts.italic7_5,
        brush: PdfSolidBrush(_textGray),
        bounds: Rect.fromLTWH(w * 0.26, footY, w * 0.48, 24),
        format: PdfStringFormat(alignment: PdfTextAlignment.center),
      );
      g.drawString(
        'Printed on: $printedStr',
        fonts.regular8,
        brush: PdfSolidBrush(_textGray),
        bounds: Rect.fromLTWH(w * 0.72, footY, w * 0.28, 12),
        format: PdfStringFormat(alignment: PdfTextAlignment.right),
      );

      final List<int> bytes = await document.save();
      return Uint8List.fromList(bytes);
    } finally {
      document.dispose();
    }
  }

  /// Line-items table matching the receipt screenshot (open layout, lavender header).
  static double _drawLineItemsTable(
    PdfGraphics g,
    _ReceiptFonts fonts,
    double y,
    double tableWidth, {
    required String monthName,
    required int year,
  }) {
    const padH = 14.0;
    const headerH = 30.0;
    const rowH = 36.0;
    const totalH = 52.0;

    final colDescW = tableWidth * 0.50;
    final colCatW = tableWidth * 0.30;
    final colAmtW = tableWidth * 0.20;
    final colCatX = colDescW;
    final colAmtX = colDescW + colCatW;

    // Header bar — lavender fill, top & bottom border only
    g.drawRectangle(
      bounds: Rect.fromLTWH(0, y, tableWidth, headerH),
      brush: PdfSolidBrush(_headerBg),
    );
    g.drawLine(_penHeaderBorder(), Offset(0, y), Offset(tableWidth, y));
    g.drawLine(
      _penHeaderBorder(),
      Offset(0, y + headerH),
      Offset(tableWidth, y + headerH),
    );
    _drawTableHeaderCell(
      g,
      fonts,
      'DESCRIPTION',
      Rect.fromLTWH(padH, y, colDescW - padH, headerH),
      PdfTextAlignment.left,
    );
    _drawTableHeaderCell(
      g,
      fonts,
      'CATEGORY',
      Rect.fromLTWH(colCatX, y, colCatW, headerH),
      PdfTextAlignment.right,
    );
    _drawTableHeaderCell(
      g,
      fonts,
      'AMOUNT',
      Rect.fromLTWH(colAmtX, y, colAmtW - padH, headerH),
      PdfTextAlignment.right,
    );

    var rowY = y + headerH;

    // Row 1 — bold description
    _drawTableDataRow(
      g,
      fonts,
      rowY,
      tableWidth,
      rowH,
      description: 'Monthly Tithe - $monthName $year',
      category: 'General Fund',
      amount: '\$1,250.00',
      descriptionBold: true,
    );
    rowY += rowH;

    // Row 2 — regular description
    _drawTableDataRow(
      g,
      fonts,
      rowY,
      tableWidth,
      rowH,
      description: 'Building Project Contribution',
      category: 'Capital Campaign',
      amount: '\$500.00',
      descriptionBold: false,
    );
    rowY += rowH;

    // Total row — label in category column, amount with double teal underline
    g.drawString(
      'TOTAL AMOUNT',
      fonts.bold9,
      brush: PdfSolidBrush(_textGray),
      bounds: Rect.fromLTWH(colCatX, rowY + 14, colCatW, 16),
      format: PdfStringFormat(alignment: PdfTextAlignment.right),
    );
    const totalAmount = '\$1,750.00';
    final amountBounds = Rect.fromLTWH(colAmtX, rowY + 8, colAmtW - padH, 28);
    g.drawString(
      totalAmount,
      fonts.bold22,
      brush: PdfSolidBrush(_teal),
      bounds: amountBounds,
      format: PdfStringFormat(alignment: PdfTextAlignment.right),
    );
    final underlineY = rowY + totalH - 10;
    final underlineLeft = colAmtX + 4;
    final underlineRight = tableWidth - padH;
    final doubleLine = PdfPen(_teal, width: 2.2);
    g.drawLine(
      doubleLine,
      Offset(underlineLeft, underlineY),
      Offset(underlineRight, underlineY),
    );
    g.drawLine(
      doubleLine,
      Offset(underlineLeft, underlineY + 3.5),
      Offset(underlineRight, underlineY + 3.5),
    );

    return rowY + totalH;
  }

  static void _drawTableHeaderCell(
    PdfGraphics g,
    _ReceiptFonts fonts,
    String label,
    Rect bounds,
    PdfTextAlignment align,
  ) {
    g.drawString(
      label,
      fonts.bold8,
      brush: PdfSolidBrush(_textGray),
      bounds: bounds,
      format: PdfStringFormat(
        alignment: align,
        lineAlignment: PdfVerticalAlignment.middle,
      ),
    );
  }

  static void _drawTableDataRow(
    PdfGraphics g,
    _ReceiptFonts fonts,
    double rowY,
    double tableWidth,
    double rowH, {
    required String description,
    required String category,
    required String amount,
    required bool descriptionBold,
  }) {
    const padH = 14.0;
    final colDescW = tableWidth * 0.50;
    final colCatW = tableWidth * 0.30;
    final colAmtW = tableWidth * 0.20;
    final colCatX = colDescW;
    final colAmtX = colDescW + colCatW;

    g.drawString(
      description,
      descriptionBold ? fonts.bold10 : fonts.regular10,
      brush: PdfSolidBrush(_ink),
      bounds: Rect.fromLTWH(padH, rowY, colDescW - padH, rowH),
      format: PdfStringFormat(
        alignment: PdfTextAlignment.left,
        lineAlignment: PdfVerticalAlignment.middle,
      ),
    );
    g.drawString(
      category,
      fonts.regular10,
      brush: PdfSolidBrush(_textGray),
      bounds: Rect.fromLTWH(colCatX, rowY, colCatW, rowH),
      format: PdfStringFormat(
        alignment: PdfTextAlignment.right,
        lineAlignment: PdfVerticalAlignment.middle,
      ),
    );
    g.drawString(
      amount,
      fonts.regular10,
      brush: PdfSolidBrush(_ink),
      bounds: Rect.fromLTWH(colAmtX, rowY, colAmtW - padH, rowH),
      format: PdfStringFormat(
        alignment: PdfTextAlignment.right,
        lineAlignment: PdfVerticalAlignment.middle,
      ),
    );

    // Light horizontal rule under each data row (no vertical borders)
    g.drawLine(
      _penRowBorder(),
      Offset(0, rowY + rowH),
      Offset(tableWidth, rowY + rowH),
    );
  }
}

/// Fresh standard fonts for each PDF build (safe to use with one [PdfDocument]).
class _ReceiptFonts {
  _ReceiptFonts()
    : bold18 = PdfStandardFont(
        PdfFontFamily.helvetica,
        18,
        style: PdfFontStyle.bold,
      ),
      bold20 = PdfStandardFont(
        PdfFontFamily.helvetica,
        20,
        style: PdfFontStyle.bold,
      ),
      bold22 = PdfStandardFont(
        PdfFontFamily.helvetica,
        22,
        style: PdfFontStyle.bold,
      ),
      bold11 = PdfStandardFont(
        PdfFontFamily.helvetica,
        11,
        style: PdfFontStyle.bold,
      ),
      bold10 = PdfStandardFont(
        PdfFontFamily.helvetica,
        10,
        style: PdfFontStyle.bold,
      ),
      bold9 = PdfStandardFont(
        PdfFontFamily.helvetica,
        9,
        style: PdfFontStyle.bold,
      ),
      bold8 = PdfStandardFont(
        PdfFontFamily.helvetica,
        8,
        style: PdfFontStyle.bold,
      ),
      regular11 = PdfStandardFont(PdfFontFamily.helvetica, 11),
      regular10 = PdfStandardFont(PdfFontFamily.helvetica, 10),
      regular9 = PdfStandardFont(PdfFontFamily.helvetica, 9),
      regular8 = PdfStandardFont(PdfFontFamily.helvetica, 8),
      italic12 = PdfStandardFont(
        PdfFontFamily.timesRoman,
        12,
        style: PdfFontStyle.italic,
      ),
      italic7_5 = PdfStandardFont(
        PdfFontFamily.helvetica,
        7.5,
        style: PdfFontStyle.italic,
      );

  final PdfFont bold18;
  final PdfFont bold20;
  final PdfFont bold22;
  final PdfFont bold11;
  final PdfFont bold10;
  final PdfFont bold9;
  final PdfFont bold8;
  final PdfFont regular11;
  final PdfFont regular10;
  final PdfFont regular9;
  final PdfFont regular8;
  final PdfFont italic12;
  final PdfFont italic7_5;
}
