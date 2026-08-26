import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_sms_inbox/flutter_sms_inbox.dart';
import 'package:imrpo/core/models/parsed_financial_entry.dart';
import 'package:imrpo/core/services/currency_preferences.dart';
import 'package:imrpo/core/services/service_locator.dart';
import 'package:imrpo/core/services/transaction_text_parser.dart';
import 'package:permission_handler/permission_handler.dart';

class SmsMessageItem {
  final String id;
  final String sender;
  final String body;
  final DateTime date;
  final ParsedFinancialEntry parsed;

  const SmsMessageItem({
    required this.id,
    required this.sender,
    required this.body,
    required this.date,
    required this.parsed,
  });

  /// Sender / bank short code shown in lists and form title (not message body).
  String get header => sender.trim();

  SmsMessageItem copyWith({
    ParsedFinancialEntry? parsed,
    DateTime? date,
  }) {
    return SmsMessageItem(
      id: id,
      sender: sender,
      body: body,
      date: date ?? this.date,
      parsed: parsed ?? this.parsed,
    );
  }

  SmsMessageItem withType(FinancialEntryType type) {
    return copyWith(parsed: parsed.copyWith(type: type));
  }

  /// Merchant, person, or bank name — never a hotline like 19123.
  String displayTitle(String fallbackLabel) {
    return TransactionTextParser.resolveSmsTitle(
          parsedTitle: parsed.title,
          body: parsed.rawText.isNotEmpty ? parsed.rawText : body,
          sender: header,
        ) ??
        fallbackLabel;
  }

  /// Bank sender line (hidden when it is only a hotline number).
  String? get displaySubtitle {
    final title = TransactionTextParser.resolveSmsTitle(
      parsedTitle: parsed.title,
      body: parsed.rawText.isNotEmpty ? parsed.rawText : body,
      sender: header,
    );
    if (title == null || header.isEmpty) return null;
    if (TransactionTextParser.isPhoneOrHotline(header)) return null;
    if (header == title) return null;
    return header;
  }
}

class SmsPageResult {
  final List<SmsMessageItem> items;
  final int nextRawStart;
  final bool hasMore;
  final int rawScanned;

  const SmsPageResult({
    required this.items,
    required this.nextRawStart,
    required this.hasMore,
    this.rawScanned = 0,
  });
}

class SmsImportService {
  /// Max financial SMS kept in Smart Import list (prevents OOM).
  static const maxDisplayedMessages = 120;

  /// Financial messages returned per UI page (after scanning raw inbox).
  static const defaultPageSize = 30;

  /// Raw inbox rows fetched per query call.
  static const _rawBatchSize = 80;

  /// Cap raw rows scanned per load call (avoids ANR on huge inboxes).
  static const _maxRawScanPerCall = 400;

  /// On first refresh, scan enough inbox depth without blocking the UI.
  static const _initialMaxRawScan = 500;

  /// Yield to the UI thread while parsing large raw batches.
  static const _parseYieldEvery = 40;

  bool get isSupported => !kIsWeb && Platform.isAndroid;

  Future<bool> requestPermission() async {
    if (!isSupported) return false;
    final status = await Permission.sms.request();
    return status.isGranted;
  }

  Future<bool> hasPermission() async {
    if (!isSupported) return false;
    return Permission.sms.isGranted;
  }

  /// Loads the next page of parsed financial SMS (scans many raw messages per call).
  Future<SmsPageResult> loadFinancialMessagesPage({
    int rawStart = 0,
    int pageSize = defaultPageSize,
    int? maxRawScan,
  }) async {
    if (!isSupported) {
      return const SmsPageResult(items: [], nextRawStart: 0, hasMore: false);
    }

    final granted = await hasPermission() || await requestPermission();
    if (!granted) {
      return const SmsPageResult(items: [], nextRawStart: 0, hasMore: false);
    }

    final scanLimit = maxRawScan ?? _maxRawScanPerCall;
    final query = SmsQuery();
    final items = <SmsMessageItem>[];
    final seenIds = <String>{};
    var offset = rawStart;
    var hasMoreRaw = true;
    var rawScanned = 0;

    while (items.length < pageSize && hasMoreRaw && rawScanned < scanLimit) {
      final remainingScan = scanLimit - rawScanned;
      final batchCount =
          remainingScan < _rawBatchSize ? remainingScan : _rawBatchSize;

      List<SmsMessage> batch;
      try {
        batch = await _queryInbox(
          query,
          start: offset,
          count: batchCount,
        );
      } catch (e, st) {
        debugPrint('SmsImportService.querySms failed: $e\n$st');
        hasMoreRaw = false;
        break;
      }

      if (batch.isEmpty) {
        hasMoreRaw = false;
        break;
      }

      final batchStart = offset;
      offset += batch.length;
      rawScanned += batch.length;
      if (batch.length < batchCount) {
        hasMoreRaw = false;
      }

      for (var i = 0; i < batch.length; i++) {
        if (i > 0 && i % _parseYieldEvery == 0) {
          await Future<void>.delayed(Duration.zero);
        }
        final msg = batch[i];
        final item = _mapMessage(msg, batchStart + i);
        if (item == null) continue;
        if (!seenIds.add(item.id)) continue;
        items.add(item);
        if (items.length >= pageSize) break;
      }
    }

    items.sort(_compareItemsByDateDesc);

    return SmsPageResult(
      items: items,
      nextRawStart: offset,
      hasMore: hasMoreRaw,
      rawScanned: rawScanned,
    );
  }

  /// First load: gather more financial messages by scanning further back in inbox.
  Future<SmsPageResult> loadInitialFinancialMessages({
    int targetCount = 40,
  }) async {
    return loadFinancialMessagesPage(
      rawStart: 0,
      pageSize: targetCount,
      maxRawScan: _initialMaxRawScan,
    );
  }

  Future<List<SmsMessage>> _queryInbox(
    SmsQuery query, {
    required int start,
    required int count,
  }) async {
    try {
      return await query.querySms(
        kinds: const [SmsQueryKind.inbox],
        start: start,
        count: count,
      );
    } catch (e, st) {
      debugPrint('SmsImportService.querySms retrying: $e\n$st');
      await Future<void>.delayed(const Duration(milliseconds: 200));
      return query.querySms(
        kinds: const [SmsQueryKind.inbox],
        start: start,
        count: count,
      );
    }
  }

  SmsMessageItem? _mapMessage(SmsMessage msg, int fallbackIndex) {
    final body = msg.body ?? '';
    if (body.trim().isEmpty) return null;

    final header = _normalizeSender(msg.address);
    final smsDate = _messageDate(msg);
    final parsed = TransactionTextParser.parseSms(
      body,
      defaultCurrencyCode: getIt<CurrencyPreferences>().displayCode,
      smsReceivedAt: smsDate,
      sender: header.isEmpty ? null : header,
    );
    if (parsed == null) return null;

    final transactionDate = parsed.date ?? smsDate;
    final titleBody =
        parsed.rawText.trim().isNotEmpty ? parsed.rawText : body;
    final enriched = parsed.copyWith(
      date: transactionDate,
      title: TransactionTextParser.resolveSmsTitle(
        parsedTitle: parsed.title,
        body: titleBody,
        sender: header,
      ),
    );

    return SmsMessageItem(
      id: _messageId(msg, fallbackIndex),
      sender: header,
      body: body,
      date: transactionDate,
      parsed: enriched,
    );
  }

  static DateTime _messageDate(SmsMessage msg) {
    return msg.date ?? msg.dateSent ?? DateTime.now();
  }

  static String _normalizeSender(String? address) {
    if (address == null) return '';
    return address
        .replaceAll(RegExp(r'[\u200e\u200f\u202a-\u202e]'), '')
        .trim();
  }

  static int _compareItemsByDateDesc(SmsMessageItem a, SmsMessageItem b) {
    final cmp = b.date.compareTo(a.date);
    if (cmp != 0) return cmp;
    return b.id.compareTo(a.id);
  }

  static String _messageId(SmsMessage msg, int fallbackIndex) {
    if (msg.id != null) return msg.id.toString();
    final body = msg.body ?? '';
    final address = msg.address ?? '';
    final date = msg.date?.millisecondsSinceEpoch ??
        msg.dateSent?.millisecondsSinceEpoch ??
        fallbackIndex;
    return '${address}_${date}_${body.hashCode}_$fallbackIndex';
  }
}
