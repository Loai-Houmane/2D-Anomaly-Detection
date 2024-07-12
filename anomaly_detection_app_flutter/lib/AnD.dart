import 'package:flutter/material.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class AnD extends StatefulWidget {
  @override
  _ImageUploadPageState createState() => _ImageUploadPageState();
}

class _ImageUploadPageState extends State<AnD> {
  File? _image; // Make _image nullable
  final picker = ImagePicker();
  bool _isLoading = false;
  String type = "";
  Image? _heatMap; // Make _heatMap nullable

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    super.dispose();
  }

  Future getImage(ImageSource source) async {
    final pickedFile = await picker.pickImage(source: source);

    setState(() {
      if (pickedFile != null) {
        _image = File(pickedFile.path);
      } else {
        print('No image selected.');
      }
    });
  }

  Future<String?> _getSavedIP() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getString(
        'saved_ip'); // This will return null if 'saved_ip' is not set
  }

  Future uploadImage() async {
    setState(() {
      _isLoading = true; // Start loading
    });
    // Assuming _getSavedIP() is an async method returning a Future<String?>.
    String? savedIP = await _getSavedIP();
    // Use the saved IP if available; otherwise, use the fallback IP 'server ip'.
    String ip = savedIP ?? 'put your server IP here';
    var request = http.MultipartRequest(
        'POST',
        Uri.parse(
            'http://$ip:5000/anomaly'));
    request.files.add(await http.MultipartFile.fromPath('file', _image!.path));
    var res = await request.send();

    // Get the response as a stream and convert it to bytes
    var responseData = await res.stream.toBytes();

    // Convert the bytes to an image
    var heatMap = Image.memory(responseData);

    setState(() {
      _heatMap = heatMap;
      _isLoading = false; // End loading
    });
  }

  void showImageSourceActionSheet(BuildContext context) {
    showModalBottomSheet(
        context: context,
        builder: (BuildContext bc) {
          return SafeArea(
            child: Container(
              child: Wrap(
                children: <Widget>[
                  ListTile(
                    leading: Icon(Icons.photo_library),
                    title: Text('Photo Library'),
                    onTap: () {
                      getImage(ImageSource.gallery);
                      Navigator.of(context).pop();
                    },
                  ),
                  ListTile(
                    leading: Icon(Icons.photo_camera),
                    title: Text('Camera'),
                    onTap: () {
                      getImage(ImageSource.camera);
                      Navigator.of(context).pop();
                    },
                  ),
                ],
              ),
            ),
          );
        });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Color.fromRGBO(31, 44, 52, 1),
        title: Text('Anomaly Detection',style: TextStyle(color: Colors.white),),
        iconTheme: IconThemeData(color: Colors.white),
      ),
      body: Container(
        color: Color.fromRGBO(31, 44, 52, 1),
        child: Column(
          children: <Widget>[
            Expanded(
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.max,
                  children: <Widget>[
                    SizedBox(
                      height: 20,
                    ),
                    _image == null
                        ? GestureDetector(
                            onTap: () => showImageSourceActionSheet(context),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: <Widget>[
                                Icon(
                                  Icons.image,
                                  size: MediaQuery.of(context).size.width - 100,
                                  color: Colors.grey,
                                ),
                                SizedBox(height: 10),
                              ],
                            ),
                          )
                        : GestureDetector(
                            onTap: () => showImageSourceActionSheet(context),
                            child: Container(
                              width: 300, // Ensure a non-zero width
                              height: 300, // Ensure a non-zero height
                              child: FittedBox(
                                child: Image(image: FileImage(_image!)),
                                fit: BoxFit.fill,
                              ),
                            ),
                          ),
                    SizedBox(
                      height: 10,
                    ),
                    _isLoading
                        ? CircularProgressIndicator() // Show loading indicator when loading
                        : ElevatedButton.icon(
                            icon: Icon(Icons.scanner,
                                color: Colors.white), // Use the scanner icon
                            label: Text(
                              'Detect Anomaly',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                              ),
                            ),
                            style: ButtonStyle(
                              backgroundColor: MaterialStateProperty.all(
                                Colors.tealAccent.withOpacity(0.08),
                              ),
                              padding: MaterialStateProperty.all(
                                  EdgeInsets.symmetric(
                                      horizontal: 20, vertical: 10)),
                              shape: MaterialStateProperty.all(
                                  RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(10))),
                            ),
                            onPressed: _isLoading
                                ? null
                                : uploadImage // Disable the button when loading
                            ),
                    SizedBox(
                      height: 10,
                    ),
                    Container(
                      width: 300,
                      height: 300,
                      // color: Colors.red,
                      child: _heatMap == null
                          ? Icon(
                              Icons.image,
                              size: 300,
                              // size: MediaQuery.of(context).size.width - 100,
                              color: Colors.grey,
                            )
                          : FittedBox(
                              child: Image(image: _heatMap!.image),
                              // size: Size(300, 300),
                              fit: BoxFit.fill,
                            ),
                    )
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
