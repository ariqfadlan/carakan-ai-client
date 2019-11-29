import 'dart:io';
import 'package:dio/dio.dart';
import 'package:toast/toast.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter_splash_screen/flutter_splash_screen.dart';


void main() => runApp(MainApp());

class MainApp extends StatefulWidget {
  @override
  _MainAppState createState() => _MainAppState();
}
class _MainAppState extends State<MainApp> {
  @override
  void initState(){
    super.initState();
    hideScreen();
  }

  Future<void> hideScreen() async {
    Future.delayed(Duration(milliseconds: 100), () {
      FlutterSplashScreen.hide();
    });
  }
  final ThemeData iOSTheme = new ThemeData(
    primarySwatch: Colors.lightBlue,
    primaryColor: Colors.grey[100],
    primaryColorBrightness: Brightness.light,
  );
  final ThemeData androidTheme = new ThemeData(
    primarySwatch: Colors.lightBlue,
    accentColor: Colors.blueAccent,
  );

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'carakan.ai',
      theme: defaultTargetPlatform == TargetPlatform.iOS
        ? iOSTheme
        : androidTheme,
      home: InputImage(),
    );
  }
}

class InputImage extends StatefulWidget {
  @override
  State<StatefulWidget> createState() {
    return _InputImage();
  }
}

class _InputImage extends State<InputImage> {
  File _imageFile;
  bool _isUploading = false; 
  String url = 'http://127.0.0.1:8080/upload';

  void _getImage(BuildContext context, ImageSource source) async {
    File image = await ImagePicker.pickImage(source: source);

    setState(() {
      _imageFile = image;
    });

    Navigator.pop(context);
  }

   Future<Response> _uploadImage(File image) async {

    Dio dio = new Dio();
    FormData fdata = FormData();
    fdata.files.add(MapEntry(("file"), await MultipartFile.fromFile(image.path)));
    var uploadUrl = url;
    var response = dio.post(uploadUrl, data:fdata, options: Options(
    method: 'POST',
    responseType: ResponseType.json
    ));
    
    return response;
  }

  void _startUploading() async {
    setState(() {
      _isUploading = true;
    });
    _buildUploadBtn();
    Response response;
    bool isConnected = true;
    try {
      response = await _uploadImage(_imageFile);
    // } on DioError {
    //   print('connection error');
    //   isConnected = false;
    } catch (e) {
      print(e);
    }

    if (!isConnected) {
      Toast.show("Periksa kembali koneksi internet Anda.", context, duration: Toast.LENGTH_LONG, gravity: Toast.BOTTOM);
      setState(() {
        _isUploading = false;
      });
    } else if (response == null || response.statusCode != 200) {
      Toast.show("Mohon coba kembali beberapa saat lagi", context, duration: Toast.LENGTH_LONG, gravity: Toast.BOTTOM);
      setState(() {
        _isUploading = false;
      });
    } else  {
      Map result = response.data;
      final String finalResult = result['prediction'];
      _showPredictionDialog(context, finalResult);
    }

  }

  void _resetState() {
    setState(() {
      _isUploading = false;
      _imageFile = null;
    });
  }

  void _openImagePickerModal(BuildContext context) {
    final flatButtonColor = Theme.of(context).primaryColorDark;
    print('Image picker modal called');
    showModalBottomSheet(
      context: context,
      builder: (BuildContext context) {
        return Container(
          height: 150.0,
          padding: EdgeInsets.all(10.0),
          child: Column(
            children: <Widget>[
              Text(
                'Masukan aksara Jawa Anda:'
              ),
              SizedBox(
                height: 10.0,
              ),
              FlatButton(
                textColor: flatButtonColor,
                child: Text('Buka Kamera'),
                onPressed: () {
                  _getImage(context, ImageSource.camera);
                },
              ),
              FlatButton(
                textColor: flatButtonColor,
                child: Text('Dari Galeri'),
                onPressed: () {
                  _getImage(context, ImageSource.gallery);
                },
              )
            ],
          ),
        );
      },
    );
  }
 
  Widget _buildUploadBtn() {
    Widget btnWidget = Container();
      double imageViewWidth = MediaQuery.of(context).size.height;

    if (_isUploading) {
      btnWidget = Container(
        margin: EdgeInsets.only(top: imageViewWidth / 30),
        child: CircularProgressIndicator()
      );
    } else if (!_isUploading && _imageFile != null) {
      btnWidget = Container(
        margin: EdgeInsets.only(top: imageViewWidth / 30),
        child: RaisedButton(
          child: Text('Unggah'),
          onPressed: () {
            _startUploading();
          },
          color: Colors.blueAccent,
          textColor:  Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10)
          ),
        ),
      );
    }
    return btnWidget;
  }

  Future<void> _showPredictionDialog(BuildContext context, String prediction) {
    return showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Hasil Prediksi', textAlign: TextAlign.center),
          content: Text('$prediction', textAlign: TextAlign.center),
          actions: <Widget>[
            new FlatButton(
              child: Text('Tutup'),
              onPressed: () {
                Navigator.of(context).pop();
                _resetState();
              }
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('carakan.ai'),
      ),
      body: Column(
        children: <Widget>[
          Padding(
            padding: const EdgeInsets.only(
              top: 10.0,
              left: 10.0,
              right: 10.0
            ),
            child: OutlineButton(
              onPressed: () => _openImagePickerModal(context),
              borderSide: BorderSide(
                color: Theme.of(context).accentColor, width: 1.0
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  Icon(Icons.camera_alt),
                  SizedBox(
                    width: 5.0,
                  ),
                  Text('Pilih Gambar'),
                ],
              ),
            ),
          ),
          _imageFile == null 
          ? Text('')
          : Image.file(
            _imageFile,
            fit: BoxFit.cover,
            height: MediaQuery.of(context).size.height * 2 / 3,
            alignment: Alignment.topCenter,
            width: MediaQuery.of(context).size.width,
          ),
          _buildUploadBtn(),
        ],
      ),
    );
    
  }
}
