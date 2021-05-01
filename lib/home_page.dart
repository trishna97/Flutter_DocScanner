import 'dart:io';
import 'package:flushbar/flushbar.dart';
import 'package:image_picker/image_picker.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import 'main.dart';

class HomePage extends StatefulWidget {
  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final picker = ImagePicker();
  final pdf = pw.Document();
  List<File> _image = [];

  getImageFile(ImageSource source) async {
    //Clicking or Picking from Gallery

    final pickedFile = await picker.getImage(source: source);
    setState(() {
      if (pickedFile != null) {
        _image.add(File(pickedFile.path));
      } else {
        print('No image selected');
      }
    });

    //Cropping the image
    final image = await picker.getImage(source: source);
    //var image = await ImagePicker.pickImage(source: source);
    File croppedFile = await ImageCropper.cropImage(
      sourcePath: image.path,
      ratioX: 1.0,
      ratioY: 1.0,
      maxWidth: 512,
      maxHeight: 512,
    );

    //Compress the image

    // ignore: unused_local_variable
    var result = await FlutterImageCompress.compressAndGetFile(
      croppedFile.path,
      croppedFile.path,
      quality: 50,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Scanner App"),
      ),
      body: _image != null
          ? ListView.builder(
              itemCount: _image.length,
              itemBuilder: (context, index) => Container(
                  height: 400,
                  width: 200,
                  child: Image.file(
                    _image[index],
                  )),
            )
          : Container(),
      floatingActionButton: Row(
        children: <Widget>[
          FloatingActionButton.extended(
            label: Text("Camera"),
            onPressed: () => getImageFile(ImageSource.camera),
            heroTag: UniqueKey(),
            icon: Icon(Icons.camera),
          ),
          SizedBox(
            width: 10,
          ),
          FloatingActionButton.extended(
            label: Text("Gallery"),
            onPressed: () => getImageFile(ImageSource.gallery),
            heroTag: UniqueKey(),
            icon: Icon(Icons.photo_library),
          ),
          FloatingActionButton.extended(
              label: Text("Create Pdf"),
              heroTag: UniqueKey(),
              icon: Icon(Icons.picture_as_pdf),
              onPressed: () async {
                createPDF();
                await savePDF();
              })
        ],
      ),
    );
  }

  List<File> buildImage() => _image;

  createPDF() async {
    for (var img in _image) {
      final image = pw.MemoryImage(img.readAsBytesSync());

      pdf.addPage(pw.Page(
          pageFormat: PdfPageFormat.a4,
          build: (pw.Context contex) {
            return pw.Center(child: pw.Image(image));
          }));
    }
  }

  savePDF() async {
    try {
      final String dir = (await getApplicationDocumentsDirectory()).path;
      final String path = '$dir/customPDF.pdf';
      final File file = File(path);
      await file.writeAsBytes(await pdf.save());
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => PdfViewer(path: path),
        ),
      );
      showPrintedMessage('success', 'saved to documents');
    } catch (e) {
      showPrintedMessage('error', e.toString());
    }
  }

  showPrintedMessage(String title, String msg) {
    Flushbar(
      title: title,
      message: msg,
      duration: Duration(seconds: 10),
      icon: Icon(
        Icons.info_rounded,
        color: Colors.blueGrey,
      ),
    )..show(context);
  }
}
