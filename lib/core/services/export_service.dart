import 'dart:io';
import 'package:excel/excel.dart';
import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import '../../data/models/transaction.dart';
import '../../data/models/spending_plan.dart';
import '../utils/web_file_saver.dart';
import '../utils/currency_formatter.dart';

class ExportService {
  static Future<void> exportTransactionsToCsv(
      List<Transaction> transactions) async {
    // Keep existing CSV export for simplicity or basic users
    final excel = Excel.createExcel();
    final sheet = excel['Transações'];
    excel.delete('Sheet1');

    sheet.appendRow([
      TextCellValue('Data'),
      TextCellValue('Descrição'),
      TextCellValue('Categoria'),
      TextCellValue('Tipo'),
      TextCellValue('Valor'),
      TextCellValue('Status'),
      TextCellValue('Pagamento'),
      TextCellValue('Notas')
    ]);

    final dateFormat = DateFormat('dd/MM/yyyy');

    for (var t in transactions) {
      sheet.appendRow([
        TextCellValue(dateFormat.format(t.date)),
        TextCellValue(t.description),
        TextCellValue(t.category),
        TextCellValue(t.type),
        DoubleCellValue(t.amount),
        TextCellValue(t.paymentStatus),
        TextCellValue(t.paymentMethod ?? ''),
        TextCellValue(t.notes ?? '')
      ]);
    }

    final bytes = excel.save();
    if (bytes == null) return;

    final String fileName =
        'Monifly_Transacoes_${DateFormat('yyyyMMdd_HHmm').format(DateTime.now())}.xlsx';

    if (kIsWeb) {
      saveBytesWeb(Uint8List.fromList(bytes), fileName);
    } else {
      await _shareBytesMobile(Uint8List.fromList(bytes), fileName);
    }
  }

  static Future<void> exportFullReport({
    required Map<String, double> summary,
    required Map<String, double> expenseByCategory,
    required MonthlyReport? report,
    required List<Transaction> transactions,
  }) async {
    final excel = Excel.createExcel();
    excel.delete('Sheet1');

    // 1. Tab: Resumo
    final resumo = excel['Resumo'];
    resumo.appendRow([TextCellValue('RESUMO MENSAL'), TextCellValue('')]);
    resumo.appendRow([TextCellValue('Métrica'), TextCellValue('Valor')]);
    resumo.appendRow([TextCellValue('Receitas'), DoubleCellValue(summary['income'] ?? 0)]);
    resumo.appendRow([TextCellValue('Despesas'), DoubleCellValue(summary['expense'] ?? 0)]);
    resumo.appendRow([TextCellValue('Investido'), DoubleCellValue(summary['investmentIn'] ?? 0)]);
    resumo.appendRow([TextCellValue('Saldo'), DoubleCellValue(summary['balance'] ?? 0)]);
    
    // 2. Tab: Categorias
    final categorias = excel['Categorias'];
    categorias.appendRow([TextCellValue('GASTOS POR CATEGORIA')]);
    categorias.appendRow([TextCellValue('Categoria'), TextCellValue('Valor Gasto')]);
    expenseByCategory.forEach((cat, val) {
      categorias.appendRow([TextCellValue(cat), DoubleCellValue(val)]);
    });

    // 3. Tab: Planejado
    if (report != null) {
      final planejado = excel['Planejado'];
      planejado.appendRow([TextCellValue('PLANEJADO VS REAL')]);
      planejado.appendRow([
        TextCellValue('Categoria'),
        TextCellValue('Previsto'),
        TextCellValue('Real'),
        TextCellValue('Diferença'),
        TextCellValue('Status')
      ]);
      for (var cat in report.categories) {
        planejado.appendRow([
          TextCellValue(cat.category),
          DoubleCellValue(cat.planned),
          DoubleCellValue(cat.actual),
          DoubleCellValue(cat.difference),
          TextCellValue(cat.status)
        ]);
      }
    }

    // 4. Tab: Evolução (Detail)
    final evolucao = excel['Movimentações'];
    evolucao.appendRow([
      TextCellValue('Data'),
      TextCellValue('Descrição'),
      TextCellValue('Categoria'),
      TextCellValue('Valor'),
      TextCellValue('Tipo')
    ]);
    final dateFormat = DateFormat('dd/MM/yyyy');
    for (var t in transactions) {
      evolucao.appendRow([
        TextCellValue(dateFormat.format(t.date)),
        TextCellValue(t.description),
        TextCellValue(t.category),
        DoubleCellValue(t.amount),
        TextCellValue(t.type)
      ]);
    }

    final bytes = excel.save();
    if (bytes == null) return;

    final String fileName =
        'Monifly_Relatorio_Completo_${DateFormat('yyyyMMdd_HHmm').format(DateTime.now())}.xlsx';

    if (kIsWeb) {
      saveBytesWeb(Uint8List.fromList(bytes), fileName);
    } else {
      await _shareBytesMobile(Uint8List.fromList(bytes), fileName);
    }
  }

  static Future<void> _shareBytesMobile(Uint8List bytes, String fileName) async {
    final directory = await getTemporaryDirectory();
    final path = "${directory.path}/$fileName";
    final file = File(path);
    await file.writeAsBytes(bytes);

    await Share.shareXFiles([XFile(path)],
        text: 'Exportação Premium Monifly');
  }
}
