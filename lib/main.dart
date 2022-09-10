//import required libraries
import 'dart:async';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:gallery_saver/gallery_saver.dart';
import 'package:image_picker/image_picker.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:flutter/services.dart';
import 'package:pytorch_mobile/pytorch_mobile.dart';
import 'package:pytorch_mobile/model.dart';
import 'package:pytorch_mobile/enums/dtype.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';


void main() => runApp(new App());

class App extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: MyApp(),
      debugShowCheckedModeBanner: false,
    );
  }
}

class MyApp extends StatefulWidget {
  @override
  _MyAppState createState() => new _MyAppState();
}

class _MyAppState extends State<MyApp> {
  File? _image;
  String? _outputs;

  @override
  Widget build(BuildContext context) {
    double width = MediaQuery.of(context).size.width;
    double height = MediaQuery.of(context).size.height;
    return Scaffold(
      appBar: AppBar(
        title: Text('Insect Classifier',
            style:
                TextStyle(color: Colors.yellow, fontWeight: FontWeight.bold)),
        centerTitle: true,
        backgroundColor: Colors.red,
      ),
      body: Column(
        children: [
          if (_image != null)
            Container(
                margin: EdgeInsets.all(8),
                child: Center(
                    child: Image.file(
                  _image!,
                  width: width * 0.9,
                  height: height * 0.4,
                  fit: BoxFit.fill,
                )))
          else
            Container(
              margin: EdgeInsets.all(8),
              child: Center(
                child: Text('No Image Selected!',
                    style: TextStyle(
                        color: Colors.black, fontWeight: FontWeight.bold)),
              ),
            ),
          SingleChildScrollView(
            child:  _outputs != null
                  ?   Card(
                        color: Colors.red,
                        child: Container(
                          margin: EdgeInsets.all(8),
                          child: Text(
                            "$_outputs",
                            style: TextStyle(
                                color: Colors.yellow,
                                fontWeight: FontWeight.bold),
                          ),
                        ),
                      ) : Padding(padding:EdgeInsets.all(0)),
                    ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _optiondialogbox,
        backgroundColor: Colors.red,
        child: Icon(Icons.image),
      ),
    );
  }

  //camera method
  Future<void> _optiondialogbox() {
    return showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            backgroundColor: Colors.red,
            content: SingleChildScrollView(
              child: ListBody(
                children: <Widget>[
                  GestureDetector(
                    child: Center(child:Text(
                      "Take Photo",
                      style: TextStyle(color: Colors.yellow, fontSize: 20.0),
                    ),
                    ),
                    onTap: openCamera,
                  ),
                  Divider(
                      color: Colors.black
                  ),
                  GestureDetector(
                    child: Center(child: Text(
                      "Select Photo",
                      style: TextStyle(color: Colors.yellow, fontSize: 20.0),
                    ),
                    ),
                    onTap: openGallery,
                  ),
                  _image != null ?
                  Divider(
                      color: Colors.black
                  ):Padding(padding:EdgeInsets.all(0)),
                  _image != null ?
                  GestureDetector(
                    child: Center(child: Text(
                      "Save image",
                      style: TextStyle(color: Colors.yellow, fontSize: 20.0),
                    ),
                    ),
                    onTap: saveImage,
                  ):Padding(padding:EdgeInsets.all(0))
                ],
              ),
            ),
          );
        });
  }

  Future openCamera() async {
    final image = await ImagePicker().pickImage(source: ImageSource.camera);
    if (image != null) {
      cropImage(image.path);
    } else {
      return;
    }
    Navigator.of(context).pop();
  }

  Future openGallery() async {
    final image = await ImagePicker().pickImage(source: ImageSource.gallery);
    if (image != null) {
      cropImage(image.path);
    } else {
      return;
    }
    Navigator.of(context).pop();
  }

  Future cropImage(filePath) async {
    final croppedImage = await ImageCropper().cropImage(
      sourcePath: filePath, aspectRatioPresets: [
      CropAspectRatioPreset.square,
      CropAspectRatioPreset.ratio3x2,
      CropAspectRatioPreset.original,
      CropAspectRatioPreset.ratio4x3,
      CropAspectRatioPreset.ratio16x9
    ],
      uiSettings: [
        AndroidUiSettings(
            toolbarTitle: 'Cropper',
            toolbarColor: Colors.deepOrange,
            toolbarWidgetColor: Colors.white,
            initAspectRatio: CropAspectRatioPreset.original,
            lockAspectRatio: false),
        IOSUiSettings(
          title: 'Cropper',
        ),
      ],
    );
    if(croppedImage != null){
      setState((){
        _outputs = null;
        _image = File(croppedImage.path);
      });
      apiCall();
    } else {
      return;
    }
  }
  apiCall() async {
    var postUri = Uri.parse("https://loadedmodel-m27iguyanq-uc.a.run.app/predict");

    Map<String, String> headers = {"Content-type": "multipart/form-data"};

    http.MultipartRequest request = new http.MultipartRequest("POST", postUri);

    http.MultipartFile multipartFile = await http.MultipartFile.fromPath(
        'file', _image!.path);

    request.files.add(multipartFile);

    request.headers.addAll(headers);

    final response = await request.send();

    if(response.statusCode==200){
      final responseData = await response.stream.toBytes();

      final result = String.fromCharCodes(responseData);

      final parsedJson = jsonDecode(result);

      final prediction = parsedJson['prediction'];

      setState(() {
        _outputs = prediction;
      });
    }
  }

  Future saveImage() async {
    GallerySaver.saveImage(_image!.path);
    Navigator.of(context).pop();
  }
}
