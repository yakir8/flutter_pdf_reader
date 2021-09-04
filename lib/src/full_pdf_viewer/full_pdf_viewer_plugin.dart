import 'dart:async';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

enum PDFViewState { shouldStart, startLoad, finishLoad }

class PDFViewerPlugin {
  final _channel = const MethodChannel("com.beninsapps.flutter_pdf_reader");
  final _subscriptionChannel =
      const EventChannel('com.beninsapps.flutter_pdf_reader/listen');
  StreamSubscription<dynamic>? _subscription;
  Function(double)? _onZoomChanged;
  Function(Offset)? _onOffsetChanged;
  static PDFViewerPlugin? _instance;

  factory PDFViewerPlugin() => _instance ??= new PDFViewerPlugin._();

  PDFViewerPlugin._() {
    _channel.setMethodCallHandler(_handleMessages);
  }

  final _onDestroy = new StreamController<Null>.broadcast();

  Stream<Null> get onDestroy => _onDestroy.stream;

  Future<Null> _handleMessages(MethodCall call) async {
    switch (call.method) {
      case 'onDestroy':
        _onDestroy.add(null);
        break;
    }
  }

  Future<Null> launch(String path,
      {Rect? rect,
      bool nightMode = false,
      double zoom = 1.0,
      xOffset = 0.0,
      yOffset = 0.0,
      Function(double)? onZoomChanged,
      Function(Offset)? onOffsetChanged}) async {
    this._onZoomChanged = onZoomChanged;
    this._onOffsetChanged = onOffsetChanged;
    final args = <String, dynamic>{'path': path};
    if (rect != null) {
      args['rect'] = {
        'left': rect.left,
        'top': rect.top,
        'width': rect.width,
        'height': rect.height
      };
    }
    args['nightMode'] = nightMode;
    args['Position'] = {'Zoom': zoom, 'XOffset': xOffset, 'YOffset': yOffset};
    await _channel.invokeMethod('launch', args);
  }

  Future<bool> launchFromNetwork(String path,
      {Rect? rect,
      bool nightMode = false,
      double zoom = 1.0,
      xOffset = 0.0,
      yOffset = 0.0,
      Function(double)? onZoomChanged,
      Function(Offset)? onOffsetChanged}) async {
    _startSubscription();
    this._onZoomChanged = onZoomChanged;
    this._onOffsetChanged = onOffsetChanged;
    final args = <String, dynamic>{'path': path};
    if (rect != null) {
      args['rect'] = {
        'left': rect.left,
        'top': rect.top,
        'width': rect.width,
        'height': rect.height
      };
    }
    args['nightMode'] = nightMode;
    args['Position'] = {'Zoom': zoom, 'XOffset': xOffset, 'YOffset': yOffset};
    return await _channel.invokeMethod('launchFromNetwork', args);
  }

  /// Close the PDFViewer
  /// Will trigger the [onDestroy] event
  Future close() {
    if (_subscription != null) _subscription!.cancel();
    return _channel.invokeMethod('close');
  }

  /// adds the plugin as ActivityResultListener
  /// Only needed and used on Android
  Future registerAcitivityResultListener() =>
      _channel.invokeMethod('registerAcitivityResultListener');

  /// removes the plugin as ActivityResultListener
  /// Only needed and used on Android
  Future removeAcitivityResultListener() =>
      _channel.invokeMethod('removeAcitivityResultListener');

  void _startSubscription() {
    _subscription =
        _subscriptionChannel.receiveBroadcastStream().listen((event) {
      if (event['Zoom'] != null && _onZoomChanged != null)
        _onZoomChanged!(event['Zoom']);
      if (event['XOffset'] != null &&
          event['YOffset'] != null &&
          _onOffsetChanged != null)
        _onOffsetChanged!(Offset(event['XOffset'], event['YOffset']));
    });
  }

  /// Close all Streams
  void dispose() {
    _onDestroy.close();
    _instance = null;
  }

  /// resize PDFViewer
  Future<Null> resize(Rect rect) async {
    final args = {};
    args['rect'] = {
      'left': rect.left,
      'top': rect.top,
      'width': rect.width,
      'height': rect.height
    };
    await _channel.invokeMethod('resize', args);
  }
}
