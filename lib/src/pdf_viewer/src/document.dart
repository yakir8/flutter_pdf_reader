import 'dart:async';
import 'dart:io';

import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:flutter_pdf_reader/src/pdf_viewer/src/page.dart';

class PDFDocument {
  static const MethodChannel _channel =
  const MethodChannel('com.beninsapps.flutter_pdf_reader');

  String? _filePath;
  int? _count;

  int get count => _count ?? 0;
  set count(int value) => _count = value;

  /// Load a PDF File from a given File
  ///
  ///
  static Future<PDFDocument> fromFile(File f) async {
    PDFDocument document = PDFDocument();
    document._filePath = f.path;
    try {
      var pageCount =
      await _channel.invokeMethod('getNumberOfPages', {'filePath': f.path});
      document.count = document.count = int.parse(pageCount);
    } catch (e) {
      throw Exception('Error reading PDF!');
    }
    return document;
  }

  /// Load a PDF File from a given URL.
  /// File is saved in cache
  ///
  static Future<PDFDocument> fromURL(String url) async {
    // Download into cache
    File f = await DefaultCacheManager().getSingleFile(url);
    PDFDocument document = PDFDocument();
    document._filePath = f.path;
    try {
      var pageCount =
      await _channel.invokeMethod('getNumberOfPages', {'filePath': f.path});
      document.count = document.count = int.parse(pageCount);
    } catch (e) {
      throw Exception('Error reading PDF!');
    }
    return document;
  }

  /// Load a PDF File from assets folder
  ///
  ///
  static Future<PDFDocument> fromAsset(String asset) async {
    // To open from assets, you can copy them to the app storage folder, and the access them "locally"
    File file;
    try {
      var dir = await getApplicationDocumentsDirectory();
      file = File("${dir.path}/file.pdf");
      var data = await rootBundle.load(asset);
      var bytes = data.buffer.asUint8List();
      await file.writeAsBytes(bytes, flush: true);
    } catch (e) {
      throw Exception('Error parsing asset file!');
    }
    PDFDocument document = PDFDocument();
    document._filePath = file.path;
    try {
      var pageCount = await _channel
          .invokeMethod('getNumberOfPages', {'filePath': file.path});
      document.count = document.count = int.parse(pageCount);
    } catch (e) {
      throw Exception('Error reading PDF!');
    }
    return document;
  }

  /// Load specific page
  ///
  /// [page] defaults to `1` and must be equal or above it
  Future<PDFPage> get({int page = 1}) async {
    assert(page > 0);
    var data = await _channel
        .invokeMethod('getPage', {'filePath': _filePath, 'pageNumber': page});
    return new PDFPage(data, page);
  }

  // Stream all pages
  Stream getAll() {
    return Future.forEach<PDFPage>(Iterable.generate(count), (i) async {
      print(i);
      final data = await _channel
          .invokeMethod('getPage', {'filePath': _filePath, 'pageNumber': i});
      return new PDFPage(data, 1);
    }).asStream();
  }
}