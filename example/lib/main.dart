import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_pdf_reader/pdf_reader.dart';

import 'package:path_provider/path_provider.dart';

void main() {
  runApp(MaterialApp(
    title: 'Plugin example app',
    home: MyApp(),
  ));
}

class MyApp extends StatefulWidget {
  @override
  _MyAppState createState() => new _MyAppState();
}

class _MyAppState extends State<MyApp> {
  String pathPDF = "";
  String url = "http://africau.edu/images/default/sample.pdf";

  @override
  void initState() {
    super.initState();
    createFileOfPdfUrl().then((f) {
      setState(() {
        pathPDF = f.path;
        print(pathPDF);
      });
    });
  }

  Future<File> createFileOfPdfUrl() async {
    final filename = url.substring(url.lastIndexOf("/") + 1);
    var request = await HttpClient().getUrl(Uri.parse(url));
    var response = await request.close();
    var bytes = await consolidateHttpClientResponseBytes(response);
    String dir = (await getApplicationDocumentsDirectory()).path;
    File file = new File('$dir/$filename');
    await file.writeAsBytes(bytes);
    return file;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Plugin example app')),
      body: Center(
        child: TextButton(
          child: Text("Open PDF"),
          onPressed: () =>
//              PDFViewerPlugin().launchFromNetwork(url)
              Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => PDFScreen(pathPDF)),
          ),
        ),
      ),
    );
  }
}

class PDFScreen extends StatelessWidget {
  final String pathPDF;

  PDFScreen(this.pathPDF);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Document"),
        actions: <Widget>[
          IconButton(
            icon: Icon(Icons.share),
            onPressed: () {},
          ),
        ],
      ),
      body: Column(
        children: [
          // SizedBox(height: 100,),
          Expanded(
              child: PDFReader.fromNetwork(
            "http://conorlastowka.com/book/CitationNeededBook-Sample.pdf",
          )),
        ],
      ),
    );
  }
}
