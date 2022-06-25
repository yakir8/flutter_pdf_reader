import 'package:flutter/material.dart';

import 'package:numberpicker/numberpicker.dart';
import 'package:flutter_pdf_reader/src/pdf_viewer/flutter_plugin_pdf_viewer.dart';

enum IndicatorPosition { topLeft, topRight, bottomLeft, bottomRight }

class PDFViewer extends StatefulWidget {
  final PDFDocument document;
  final Color indicatorText;
  final Color indicatorBackground;
  final IndicatorPosition indicatorPosition;
  final bool showIndicator;
  final bool showPicker;
  final bool showNavigation;
  final PDFViewerTooltip tooltip;
  final double initialScale;
  final double minScale;
  final double maxScale;
  final double panLimit;
  final int zoomSteps;
  final Offset initialOffset;
  final Function(double)? onZoomChanged;
  final Function(Offset)? onOffsetChanged;
  final bool darkMod;

  PDFViewer(
      {Key? key,
      required this.document,
      this.indicatorText = Colors.white,
      this.indicatorBackground = Colors.black54,
      this.showIndicator = true,
      this.showPicker = true,
      this.showNavigation = true,
      this.tooltip = const PDFViewerTooltip(),
      this.initialOffset = Offset.zero,
      this.initialScale = 1.0,
      this.minScale = 1.0,
      this.maxScale = 6.0,
      this.panLimit = 0.8,
      this.zoomSteps = 3,
      this.darkMod = false,
      this.onZoomChanged,
      this.onOffsetChanged,
      this.indicatorPosition = IndicatorPosition.topRight})
      : super(key: key);

  _PDFViewerState createState() => _PDFViewerState();
}

class _PDFViewerState extends State<PDFViewer> {
  bool _isLoading = true;
  int _pageNumber = 1;
  int _oldPage = 0;
  late PDFPage _page;
  List<PDFPage> _pages = List.empty(growable: true);

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _oldPage = 0;
    _pageNumber = 1;
    _isLoading = true;
    _pages.clear();
    _loadPage();
  }

  @override
  void didUpdateWidget(PDFViewer oldWidget) {
    super.didUpdateWidget(oldWidget);
    _oldPage = 0;
    _pageNumber = 1;
    _isLoading = true;
    _loadPage();
  }

  void _loadPage() async {
    setState(() => _isLoading = true);
    if (_oldPage == 0) {
      _page = await widget.document.get(page: _pageNumber);
      _page.darkMod = widget.darkMod;
      _page.initialScale = widget.initialScale;
      _page.zoomSteps = widget.zoomSteps;
      _page.minScale = widget.minScale;
      _page.maxScale = widget.maxScale;
      _page.panLimit = widget.panLimit;
      _page.initialOffset = widget.initialOffset;
      _page.onZoomChanged = widget.onZoomChanged;
      _page.onOffsetChanged = widget.onOffsetChanged;
      if (this.mounted) setState(() => _isLoading = false);
    } else if (_oldPage != _pageNumber) {
      _oldPage = _pageNumber;
      if (this.mounted) setState(() => _isLoading = true);
      _page = await widget.document.get(page: _pageNumber);
      _page.darkMod = widget.darkMod;
      _page.onZoomChanged = widget.onZoomChanged;
      _page.onOffsetChanged = widget.onOffsetChanged;
      if (this.mounted) setState(() => _isLoading = false);
    }
  }

  Widget _drawIndicator() {
    Widget child = GestureDetector(
        onTap: _pickPage,
        child: Container(
            padding:
                EdgeInsets.only(top: 4.0, left: 16.0, bottom: 4.0, right: 16.0),
            decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(4.0),
                color: widget.indicatorBackground),
            child: Text("$_pageNumber/${widget.document.count}",
                style: TextStyle(
                    color: widget.indicatorText,
                    fontSize: 16.0,
                    fontWeight: FontWeight.w400))));

    switch (widget.indicatorPosition) {
      case IndicatorPosition.topLeft:
        return Positioned(top: 20, left: 20, child: child);
      case IndicatorPosition.topRight:
        return Positioned(top: 20, right: 20, child: child);
      case IndicatorPosition.bottomLeft:
        return Positioned(bottom: 20, left: 20, child: child);
      case IndicatorPosition.bottomRight:
        return Positioned(bottom: 20, right: 20, child: child);
      default:
        return Positioned(top: 20, right: 20, child: child);
    }
  }

  void _pickPage() {
    showDialog<int>(
        context: context,
        builder: (BuildContext context) {
          return Dialog(
              child: _NumberPickerWidget(
                  widget.tooltip, widget.document.count, _pageNumber));
        }).then((dynamic value) {
      if (value != null) {
        _pageNumber = value;
        _loadPage();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: <Widget>[
          _isLoading ? Center(child: CircularProgressIndicator()) : _page,
          (widget.showIndicator && !_isLoading)
              ? _drawIndicator()
              : Container(),
        ],
      ),
      floatingActionButton: widget.showPicker
          ? FloatingActionButton(
              elevation: 4.0,
              tooltip: widget.tooltip.jump,
              child: Icon(Icons.view_carousel),
              onPressed: () {
                _pickPage();
              },
            )
          : null,
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      bottomNavigationBar: (widget.showNavigation || widget.document.count > 1)
          ? BottomAppBar(
              child: new Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  Expanded(
                    child: IconButton(
                      icon: Icon(Icons.first_page),
                      tooltip: widget.tooltip.first,
                      onPressed: () {
                        _pageNumber = 1;
                        _loadPage();
                      },
                    ),
                  ),
                  Expanded(
                    child: IconButton(
                      icon: Icon(Icons.chevron_left),
                      tooltip: widget.tooltip.previous,
                      onPressed: () {
                        _pageNumber--;
                        if (1 > _pageNumber) {
                          _pageNumber = 1;
                        }
                        _loadPage();
                      },
                    ),
                  ),
                  widget.showPicker
                      ? Expanded(child: Text(''))
                      : SizedBox(width: 1),
                  Expanded(
                    child: IconButton(
                      icon: Icon(Icons.chevron_right),
                      tooltip: widget.tooltip.next,
                      onPressed: () {
                        _pageNumber++;
                        if (widget.document.count < _pageNumber) {
                          _pageNumber = widget.document.count;
                        }
                        _loadPage();
                      },
                    ),
                  ),
                  Expanded(
                    child: IconButton(
                      icon: Icon(Icons.last_page),
                      tooltip: widget.tooltip.last,
                      onPressed: () {
                        _pageNumber = widget.document.count;
                        _loadPage();
                      },
                    ),
                  ),
                ],
              ),
            )
          : null,
    );
  }

  @override
  void setState(fn) {
    if (mounted) {
      super.setState(fn);
    }
  }
}

class _NumberPickerWidget extends StatefulWidget {
  final int count;
  final currentValue;
  final PDFViewerTooltip tooltip;

  _NumberPickerWidget(this.tooltip, this.count, this.currentValue);

  @override
  State<StatefulWidget> createState() => _NumberPickerWidgetState();
}

class _NumberPickerWidgetState extends State<_NumberPickerWidget> {
  late int _currentValue = widget.currentValue;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(height: 10),
        Text(widget.tooltip.pick, style: Theme.of(context).textTheme.headline6),
        NumberPicker(
          minValue: 1,
          maxValue: widget.count,
          value: _currentValue,
          haptics: true,
          onChanged: (int value) {
            setState(() => _currentValue = value);
          },
        ),
        Align(
          alignment: Alignment.bottomLeft,
          child: TextButton(child: Text('Done'),onPressed: () {
            Navigator.pop(context,_currentValue);
          }),
        )
      ],
    );
  }
}
