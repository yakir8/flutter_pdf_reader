import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter_pdf_reader/src/full_pdf_viewer/full_pdf_viewer_plugin.dart';
import 'package:flutter_pdf_reader/src/pdf_viewer/flutter_plugin_pdf_viewer.dart';

class PDFReader extends StatefulWidget {
  final String _path;
  final bool _isLocal;
  final bool darkMod;
  final double initialScale;
  final double minScale;
  final double maxScale;
  final int zoomSteps;
  final Offset initialOffset;
  final bool showPicker;
  final bool showIndicator;
  final bool showNavigation;

  final Function(double)? onZoomChanged;
  final Function(Offset)? onOffsetChanged;

  PDFReader.fromNetwork(String url,
      {this.darkMod = false,
      this.initialScale = 1,
      this.minScale = 1.0,
      this.maxScale = 6.0,
      this.zoomSteps = 3,
      this.initialOffset = const Offset(0, 0),
      this.showPicker = true,
      this.showIndicator = true,
      this.showNavigation = true,
      this.onZoomChanged,
      this.onOffsetChanged})
      : this._path = url,
        this._isLocal = false;

  PDFReader.from(String path,
      {this.darkMod = false,
      this.initialScale = 1,
      this.minScale = 1.0,
      this.maxScale = 6.0,
      this.zoomSteps = 3,
      this.initialOffset = const Offset(0, 0),
      this.showPicker = true,
      this.showIndicator = true,
      this.showNavigation = true,
      this.onZoomChanged,
      this.onOffsetChanged})
      : this._path = path,
        this._isLocal = true;

  @override
  State<StatefulWidget> createState() =>
      _isLocal ? _PDFReaderState() : _PDFReaderNetworkState();

  Future<bool> _isOldAPI() async {
    if (Platform.isIOS) return false;
    DeviceInfoPlugin deviceInfo = DeviceInfoPlugin();
    AndroidDeviceInfo androidInfo = await deviceInfo.androidInfo;
    return (androidInfo.version.sdkInt ?? 0) < 21;
  }
}

class _PDFReaderNetworkState extends State<PDFReader> {
  PDFViewerPlugin _oldPDF = PDFViewerPlugin();

  PDFDocument? document;
  bool _isLoading = true;

  @override
  void initState() {
    widget._isOldAPI().then((value) async {
      if (value)
        _loadPDFForOldAPI();
      else
        document = await PDFDocument.fromURL(widget._path);
      setState(() => _isLoading = value);
    });
    super.initState();
  }

  void _loadPDFForOldAPI() {
    Future.delayed(Duration.zero, () {
      _oldPDF
          .launchFromNetwork(widget._path,
              zoom: widget.initialScale,
              xOffset: widget.initialOffset.dx,
              yOffset: widget.initialOffset.dy,
              nightMode: widget.darkMod,
              rect: Rect.fromLTWH(0.0, 0, 5, 5),
              onZoomChanged: widget.onZoomChanged,
              onOffsetChanged: widget.onOffsetChanged)
          .then((value) => _oldPDF.resize(_getWidetSize()));
    });
  }

  Rect _getWidetSize() {
    RenderBox box = context.findRenderObject() as RenderBox;
    Offset position = box.localToGlobal(Offset.zero); //this is global position
    double height = context.size!.height != double.infinity
        ? context.size!.height
        : MediaQuery.of(context).size.height - position.dy;
    double width = context.size!.width != double.infinity
        ? context.size!.width
        : MediaQuery.of(context).size.width - position.dx;
    return Rect.fromLTWH(position.dx, position.dy, width, height);
  }

  @override
  void dispose() {
    _oldPDF.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return _isLoading
        ? Center(child: CircularProgressIndicator())
        : PDFViewer(
            darkMod: widget.darkMod,
            initialScale: widget.initialScale,
            initialOffset: widget.initialOffset,
            showPicker: widget.showPicker,
            minScale: widget.minScale,
            maxScale: widget.maxScale,
            zoomSteps: widget.zoomSteps,
            showIndicator: widget.showIndicator,
            showNavigation: widget.showNavigation,
            onOffsetChanged: widget.onOffsetChanged,
            onZoomChanged: widget.onZoomChanged,
            document: document!,
          );
  }
}

class _PDFReaderState extends State<PDFReader> {
  PDFViewerPlugin _oldPDF = PDFViewerPlugin();

  PDFDocument? document;
  bool _isLoading = true;

  @override
  void initState() {
    widget._isOldAPI().then((value) async {
      if (value)
        _loadPDFForOldAPI();
      else
        document = await PDFDocument.fromAsset(widget._path);
      setState(() => _isLoading = value);
    });
    super.initState();
  }

  void _loadPDFForOldAPI() {
    Future.delayed(Duration.zero, () {
      _oldPDF
          .launch(widget._path,
              zoom: widget.initialScale,
              xOffset: widget.initialOffset.dx,
              yOffset: widget.initialOffset.dy,
              nightMode: widget.darkMod,
              rect: Rect.fromLTWH(0.0, 0, 5, 5),
              onZoomChanged: widget.onZoomChanged,
              onOffsetChanged: widget.onOffsetChanged)
          .then((value) => _oldPDF.resize(_getWidetSize()));
    });
  }

  Rect _getWidetSize() {
    RenderBox box = context.findRenderObject() as RenderBox;
    Offset position = box.localToGlobal(Offset.zero); //this is global position
    double height = context.size!.height != double.infinity
        ? context.size!.height
        : MediaQuery.of(context).size.height - position.dy;
    double width = context.size!.width != double.infinity
        ? context.size!.width
        : MediaQuery.of(context).size.width - position.dx;
    return Rect.fromLTWH(position.dx, position.dy, width, height);
  }

  @override
  void dispose() {
    _oldPDF.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return _isLoading
        ? Center(child: CircularProgressIndicator())
        : PDFViewer(
            darkMod: widget.darkMod,
            initialScale: widget.initialScale,
            minScale: widget.minScale,
            maxScale: widget.maxScale,
            zoomSteps: widget.zoomSteps,
            initialOffset: widget.initialOffset,
            showPicker: widget.showPicker,
            showIndicator: widget.showIndicator,
            showNavigation: widget.showNavigation,
            onOffsetChanged: widget.onOffsetChanged,
            onZoomChanged: widget.onZoomChanged,
            document: document!,
          );
  }
}
