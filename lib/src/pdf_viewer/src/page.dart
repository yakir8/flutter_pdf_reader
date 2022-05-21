import 'dart:io';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/painting.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_pdf_reader/src/advanced_network_image/src/zoomable/zoomable_widget.dart';

class PDFPage extends StatefulWidget {
  final String imgPath;
  double initialScale = 1.0;
  double minScale = 1.0;
  double maxScale = 6.0;
  double panLimit = 0.8;
  int zoomSteps = 3;
  Offset initialOffset = Offset.zero;
  Function(double)? onZoomChanged;
  Function(Offset)? onOffsetChanged;
  bool darkMod = false;

  final int num;
  PDFPage(this.imgPath, this.num);

  @override
  _PDFPageState createState() => _PDFPageState();
}

class _PDFPageState extends State<PDFPage> {
  late ImageProvider provider;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _repaint();
  }

  @override
  void didUpdateWidget(PDFPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.imgPath != widget.imgPath) {
      _repaint();
    }
  }

  _repaint() {
    provider = FileImage(File(widget.imgPath));
    final resolver = provider.resolve(createLocalImageConfiguration(context));
    resolver.addListener(ImageStreamListener((imgInfo, alreadyPainted) {
      if (!alreadyPainted) setState(() {});
    }));
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: null,
      child: ZoomableWidget(
        initialOffset: widget.initialOffset,
        initialScale: widget.initialScale,
        onZoomChanged: widget.onZoomChanged,
        onOffsetChanged: widget.onOffsetChanged,
        zoomSteps: widget.zoomSteps,
        minScale: widget.minScale,
        panLimit: widget.panLimit,
        maxScale: widget.maxScale,
        child: widget.darkMod ?
        Container(
          padding: EdgeInsets.only(right: 25),
          child: Image(image: provider, color: Colors.grey[350],
            colorBlendMode: BlendMode.difference,),) :
        Container(
          padding: EdgeInsets.only(right: 25),
          child: Image(image: provider),
        ),),
    );
  }
  
    @override
  void setState(fn) {
    if(mounted){
      super.setState(fn);
    }
  }
}
