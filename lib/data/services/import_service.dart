import 'dart:convert';
import 'dart:typed_data';
import 'package:csv/csv.dart';
import 'package:uuid/uuid.dart';
import 'package:intl/intl.dart';
import '../models/transaction.dart';
import '../../core/constants/app_constants.dart';

class ImportService {
  /// Detects file type and parses accordingly
  static Future<List<Transaction>> parseFile({
    required String fileName,
    required Uint8List bytes,
    required String userId,
    List<Transaction> existingTransactions = const [],
  }) async {
    final extension = fileName.split('.').last.toLowerCase();
    
    if (extension == 'ofx') {
      return _parseOFX(bytes, userId, existingTransactions);
    } else if (extension == 'csv') {
      return _parseCSV(bytes, userId, existingTransactions);
    } else {
      throw Exception('Formato de arquivo não suportado: $extension');
    }
  }

  static List<Transaction> _parseOFX(
    Uint8List bytes,
    String userId,
    List<Transaction> existing,
  ) {
    // OFX is SGML-based but usually has a visible XML part
    // We'll extract the XML part between <OFX> and </OFX> or use a more relaxed regex-based approach
    final content = utf8.decode(bytes, allowMalformed: true);
    final transactions = <Transaction>[];

    // Simple regex to find STMTTRN blocks
    final transRegex = RegExp(r'<STMTTRN>([\s\S]*?)</STMTTRN>');
    final matches = transRegex.allMatches(content);

    for (var match in matches) {
      final block = match.group(1)!;
      
      // ignore: unused_local_variable
      final type = _getTagValue(block, 'TRNTYPE');
      final dateStr = _getTagValue(block, 'DTPOSTED'); // YYYYMMDD
      final amountStr = _getTagValue(block, 'TRNAMT');
      final memo = _getTagValue(block, 'MEMO') ?? _getTagValue(block, 'NAME') ?? '';

      if (dateStr == null || amountStr == null) continue;

      final date = DateTime.parse('${dateStr.substring(0, 4)}-${dateStr.substring(4, 6)}-${dateStr.substring(6, 8)}');
      final amount = _parseAmount(amountStr);

      final isIncome = amount > 0;
      final suggestedCat = _suggestCategory(memo);
      final isInvestmentCat = suggestedCat != 'outros' && AppConstants.investmentCategories.any((c) => c['key'] == suggestedCat);
      
      String transType = isIncome ? AppConstants.typeIncome : AppConstants.typeExpense;
      if (isInvestmentCat) {
        transType = isIncome ? AppConstants.typeInvestmentOut : AppConstants.typeInvestmentIn;
      }


      transactions.add(Transaction(
        id: const Uuid().v4(),
        userId: userId,
        description: memo.trim(),
        amount: amount.abs(),
        date: date,
        type: transType,

        category: suggestedCat,

        paymentStatus: AppConstants.statusPaid,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ));
    }

    return transactions;
  }

  static List<Transaction> _parseCSV(
    Uint8List bytes,
    String userId,
    List<Transaction> existing,
  ) {
    final content = utf8.decode(bytes, allowMalformed: true);
    final rows = const CsvToListConverter(fieldDelimiter: ';', eol: '\n').convert(content);
    
    // If ';' didn't work, try ','
    var processedRows = rows;
    if (rows.isNotEmpty && rows[0].length == 1) {
      processedRows = const CsvToListConverter(fieldDelimiter: ',', eol: '\n').convert(content);
    }

    if (processedRows.isEmpty) return [];

    final transactions = <Transaction>[];
    final headers = processedRows[0].map((e) => e.toString().toLowerCase()).toList();
    
    // Check for common header indexes
    int dateIdx = -1, descIdx = -1, amountIdx = -1;

    // Detect headers (Itaú, Nubank, Inter, etc.)
    for (int i = 0; i < headers.length; i++) {
      final h = headers[i];
      if (h.contains('data')) dateIdx = i;
      if (h.contains('descri') || h.contains('lança') || h.contains('item')) descIdx = i;
      if (h.contains('valor') || h.contains('montante')) amountIdx = i;
    }

    if (dateIdx == -1 || amountIdx == -1) {
      // Try fallback for headerless or unusual files
      return []; 
    }

    for (int i = 1; i < processedRows.length; i++) {
      final row = processedRows[i];
      if (row.length <= dateIdx || row.length <= amountIdx) continue;

      final rawDate = row[dateIdx].toString();
      final rawDesc = descIdx != -1 ? row[descIdx].toString() : '';
      final rawAmount = row[amountIdx].toString();

      if (rawDate.isEmpty || rawAmount.isEmpty) continue;

      DateTime? date;
      // Common Brazilian formats: DD/MM/YYYY or YYYY-MM-DD
      try {
        if (rawDate.contains('/')) {
           final parts = rawDate.split('/');
           if (parts[0].length == 4) { // YYYY/MM/DD
             date = DateTime.parse(rawDate.replaceAll('/', '-'));
           } else { // DD/MM/YYYY
             date = DateFormat('dd/MM/yyyy').parse(rawDate);
           }
        } else {
           date = DateTime.parse(rawDate);
        }
      } catch (_) { continue; }

      final amount = _parseAmount(rawAmount);
      if (amount == 0) continue;

      final isIncome = amount > 0;
      final suggestedCat = _suggestCategory(rawDesc);
      final isInvestmentCat = suggestedCat != 'outros' && AppConstants.investmentCategories.any((c) => c['key'] == suggestedCat);
      
      String transType = isIncome ? AppConstants.typeIncome : AppConstants.typeExpense;
      if (isInvestmentCat) {
        transType = isIncome ? AppConstants.typeInvestmentOut : AppConstants.typeInvestmentIn;
      }


      transactions.add(Transaction(
        id: const Uuid().v4(),
        userId: userId,
        description: rawDesc.trim(),
        amount: amount.abs(),
        date: date,
        type: transType,

        category: suggestedCat,

        paymentStatus: AppConstants.statusPaid,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ));
    }

    return transactions;
  }

  static double _parseAmount(String val) {
    // Remove symbols and spaces
    var s = val.replaceAll(RegExp(r'[R$ \u00A0]'), '');
    
    // Check if it's English format (1,000.00) or Brazilian (1.000,00)
    // If it has both , and .
    if (s.contains('.') && s.contains(',')) {
      if (s.indexOf('.') < s.indexOf(',')) {
        // 1.000,00 -> BR
        s = s.replaceAll('.', '').replaceAll(',', '.');
      } else {
        // 1,000.00 -> EN
        s = s.replaceAll(',', '');
      }
    } else if (s.contains(',')) {
      // 1000,00 or 1,50 -> treat as BR
      s = s.replaceAll(',', '.');
    }
    // Else it probably has only . or nothing (1000.00 or 1000)
    
    return double.tryParse(s) ?? 0;
  }

  static String? _getTagValue(String block, String tag) {
    final reg = RegExp('<$tag>(.*)');
    final match = reg.firstMatch(block);
    return match?.group(1)?.trim();
  }

  static String _suggestCategory(String description) {
    final desc = description.toUpperCase();
    
    // Investments
    if (desc.contains('CDB') || desc.contains('RDB') || desc.contains('LCA') || desc.contains('LCI')) return 'cdb';
    if (desc.contains('TESOURO')) return 'tesouro';
    if (desc.contains('ACOES') || desc.contains('AÇÕES') || desc.contains('BOLSA') || desc.contains('HOME BROKER')) return 'acoes';
    if (desc.contains('CRIPT') || desc.contains('BITCOIN') || desc.contains('BINANCE')) return 'cripto';
    if (desc.contains('FII ') || desc.contains('FUNDO IMOB')) return 'fii';
    if (desc.contains('POUPANCA') || desc.contains('POUPANÇA')) return 'poupanca';
    if (desc.contains('PREVIDENCIA') || desc.contains('PREVIDÊNCIA')) return 'previdencia';
    if (desc.contains('RESGATE') || desc.contains('APLICACAO') || desc.contains('APLICAÇÃO') || desc.contains('INVEST') || desc.contains('FUNDO') || desc.contains('COFRINHO')) return 'cdb'; // Default to CDB for generic investments

    // Transportation
    if (desc.contains('UBER') || desc.contains('99APP') || desc.contains('INDRI') || desc.contains('POSTO') || desc.contains('SHELL') || desc.contains('IPIRANGA') || desc.contains('ESTACIONAMENTO') || desc.contains('PEDAGIO') || desc.contains('METRO') || desc.contains('CONCUR') || desc.contains('BUS')) return 'transporte';
    
    // Food & Groceries
    if (desc.contains('IFOOD') || desc.contains('RAPPI') || desc.contains('RESTAURANTE') || desc.contains('LANCHONETE') || desc.contains('PADARIA') || desc.contains('CAFÉ') || desc.contains('MERCADO') || desc.contains('SUPERMERCADO') || desc.contains('EXTRA') || desc.contains('CARREFOUR') || desc.contains('PÃO DE AÇÚCAR') || desc.contains('ASSAI') || desc.contains('ATACADAO') || desc.contains('CONVENIENCIA') || desc.contains('AÇOUGUE') || desc.contains('HORTIFRUTI')) return 'alimentacao';
    
    // Subscriptions
    if (desc.contains('NETFLIX') || desc.contains('SPOTIFY') || desc.contains('PRIME VIDEO') || desc.contains('DISNEY') || desc.contains('HBO') || desc.contains('GAMES') || desc.contains('STEAM') || desc.contains('PLAYSTATION') || desc.contains('XBOX') || desc.contains('YOUTUBE') || desc.contains('APPLE')) return 'assinaturas';
    
    // Housing & Utilities
    if (desc.contains('CONDOMINIO') || desc.contains('ALUGUEL') || desc.contains('CPFL') || desc.contains('SABESP') || desc.contains('ENEL') || desc.contains('LUZ') || desc.contains('AGUA') || desc.contains('INTERNET') || desc.contains('VIVO') || desc.contains('CLARO') || desc.contains('TIM') || desc.contains('GÁS')) return 'moradia';
    
    // Health
    if (desc.contains('FARMACIA') || desc.contains('DROGASIL') || desc.contains('PAGUEMENOS') || desc.contains('DROGARAIA') || desc.contains('HOSPITAL') || desc.contains('MEDICO') || desc.contains('LABORATORIO') || desc.contains('DENTISTA') || desc.contains('PLANO DE SAUDE') || desc.contains('UNIMED') || desc.contains('ODONTO')) return 'saude';
    
    // Shopping
    if (desc.contains('LOJA') || desc.contains('MERCADO LIVRE') || desc.contains('AMAZON') || desc.contains('SHOPEE') || desc.contains('MAGALU') || desc.contains('CASAS BAHIA') || desc.contains('AMERICANAS') || desc.contains('RENNER') || desc.contains('C&A') || desc.contains('ZATTINI') || desc.contains('ALIEXPRESS') || desc.contains('SHEIN')) return 'compras';
    
    // Income
    if (desc.contains('SALARIO') || desc.contains('PGTO SALARIO') || desc.contains('HONORARIOS') || desc.contains('PROVENTOS') || desc.contains('REMUNERACAO') || desc.contains('RENDIMENTO')) return 'salario';
    
    // General Boletos / Bills / Transfers
    if (desc.contains('PAGTO COBRANCA') || desc.contains('PAGTO TITULO') || desc.contains('BOLETO') || desc.contains('FATURA') || desc.contains('PAGAMENTO')) return 'boletos';
    
    // PIX / Transfers usually default to outros if no other keyword matches
    if (desc.contains('PIX') || desc.contains('TRANSFERENCIA') || desc.contains('TED') || desc.contains('DOC')) return 'outros';
    
    return 'outros';
  }


  /// Checks if a transaction is a possible duplicate
  static bool isPossibleDuplicate(Transaction t, List<Transaction> existing) {
    return existing.any((e) =>
        e.amount == t.amount &&
        e.date.day == t.date.day &&
        e.date.month == t.date.month &&
        e.date.year == t.date.year &&
        e.description.toLowerCase() == t.description.toLowerCase());
  }
}
