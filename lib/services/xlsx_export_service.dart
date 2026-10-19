import 'dart:typed_data';

import 'package:excel_plus/excel_plus.dart';

import '../models/expense.dart';

class XlsxExportService {
  Uint8List generate(
    List<Expense> expenses,
    String currencySymbol,
  ) {
    final workbook = Excel.createExcel();
    workbook.rename('Sheet1', 'Expenses');

    final sheet = workbook['Expenses'];

    // Export-only column names. The app's Expense model remains unchanged.
    const headers = [
      'S.No',
      'Date',
      'Time',
      'Category',
      'Message',
      'Amount',
      'Currency',
      'Notes',
    ];

    final headerStyle = CellStyle(
      bold: true,
      fontSize: 12,
      backgroundColorHex: ExcelColor.fromHexString('#E9EDFF'),
      horizontalAlign: HorizontalAlign.Center,
      verticalAlign: VerticalAlign.Center,
    );

    // Keep Date and Time as real Excel date/time values rather than plain text.
    // This makes sorting in Excel work chronologically.
    final dateStyle = CellStyle(
      numberFormat: CustomDateTimeNumFormat(formatCode: 'dd-mm-yyyy'),
      horizontalAlign: HorizontalAlign.Center,
      verticalAlign: VerticalAlign.Center,
    );

    final timeStyle = CellStyle(
      numberFormat: CustomDateTimeNumFormat(formatCode: 'hh:mm:ss'),
      horizontalAlign: HorizontalAlign.Center,
      verticalAlign: VerticalAlign.Center,
    );

    for (var column = 0; column < headers.length; column++) {
      sheet.updateCell(
        CellIndex.indexByColumnRow(
          columnIndex: column,
          rowIndex: 0,
        ),
        TextCellValue(headers[column]),
        cellStyle: headerStyle,
      );
    }

    for (var rowIndex = 0; rowIndex < expenses.length; rowIndex++) {
      final expense = expenses[rowIndex];
      final excelRow = rowIndex + 1;
      final date = expense.timestamp;

      sheet.updateCell(
        CellIndex.indexByColumnRow(
          columnIndex: 0,
          rowIndex: excelRow,
        ),
        IntCellValue(rowIndex + 1),
      );

      sheet.updateCell(
        CellIndex.indexByColumnRow(
          columnIndex: 1,
          rowIndex: excelRow,
        ),
        DateCellValue(
          year: date.year,
          month: date.month,
          day: date.day,
        ),
        cellStyle: dateStyle,
      );

      sheet.updateCell(
        CellIndex.indexByColumnRow(
          columnIndex: 2,
          rowIndex: excelRow,
        ),
        TimeCellValue(
          hour: date.hour,
          minute: date.minute,
          second: date.second,
        ),
        cellStyle: timeStyle,
      );

      sheet.updateCell(
        CellIndex.indexByColumnRow(
          columnIndex: 3,
          rowIndex: excelRow,
        ),
        TextCellValue(expense.category),
      );

      // "Message" is export-only. The Flutter model still uses expense.title.
      sheet.updateCell(
        CellIndex.indexByColumnRow(
          columnIndex: 4,
          rowIndex: excelRow,
        ),
        TextCellValue(expense.title),
      );

      sheet.updateCell(
        CellIndex.indexByColumnRow(
          columnIndex: 5,
          rowIndex: excelRow,
        ),
        DoubleCellValue(expense.amount),
      );

      sheet.updateCell(
        CellIndex.indexByColumnRow(
          columnIndex: 6,
          rowIndex: excelRow,
        ),
        TextCellValue(currencySymbol),
      );

      sheet.updateCell(
        CellIndex.indexByColumnRow(
          columnIndex: 7,
          rowIndex: excelRow,
        ),
        TextCellValue(expense.note),
      );
    }

    // Date and Time are separate columns, with widths sized for their formats.
    sheet.setColumnWidth(0, 8);
    sheet.setColumnWidth(1, 14);
    sheet.setColumnWidth(2, 12);
    sheet.setColumnWidth(3, 18);
    sheet.setColumnWidth(4, 28);
    sheet.setColumnWidth(5, 15);
    sheet.setColumnWidth(6, 12);
    sheet.setColumnWidth(7, 40);
    sheet.freezePanes(rows: 1);

    final bytes = workbook.save();

    if (bytes == null || bytes.isEmpty) {
      throw StateError('Unable to create XLSX workbook.');
    }

    return Uint8List.fromList(bytes);
  }
}
