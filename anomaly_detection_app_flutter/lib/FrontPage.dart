import 'package:anomaly_detection_app/AnD.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class FrontPage extends StatefulWidget {
  @override
  _SetTheIP createState() => _SetTheIP();
}

class _SetTheIP extends State<FrontPage> {
  final TextEditingController _ipController = TextEditingController();
  String? savedIP = "";

  @override
  void dispose() {
    _ipController.dispose();
    super.dispose();
  }

  Future<void> _saveIP(String ip) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString('saved_ip', ip);
  }

  Future<String?> _getSavedIP() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getString(
        'saved_ip'); // This will return null if 'saved_ip' is not set
  }

  @override
  void initState() {
    super.initState();
    _getSavedIP().then((ip) {
      setState(() {
        savedIP = ip;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        color: Color.fromRGBO(31, 44, 52, 1),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              // Text(
              //   'Anomaly Detection',
              //   style: TextStyle(
              //     color: Colors.white,
              //     fontSize: 30,
              //   ),
              // ),

              Image.asset('assets/images/image1.png'),

              Container(
                padding: const EdgeInsets.only(left: 30, right: 10),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        style: TextStyle(color: Colors.white),
                        controller: _ipController,
                        decoration: InputDecoration(
                          border: OutlineInputBorder(),
                          
                          labelText: 'Enter the server IP Address',
                        ),
                        onSubmitted: (String value) async {
                          await _saveIP(value);
                        },
                      ),
                    ),
                    IconButton(
                      onPressed: () async {
                        await _saveIP(_ipController.text);
                        Navigator.of(context).push(
                            MaterialPageRoute(builder: (context) => AnD()));
                      },
                      icon: Icon(Icons.arrow_forward),
                    ),
                  ],
                ),
              ),
              SizedBox(height: 20),
              if (savedIP != null &&
                  savedIP!
                      .isNotEmpty) // Check if savedIP is not null and not empty
                ElevatedButton(
                  onPressed: () async {
                    Navigator.of(context)
                        .push(MaterialPageRoute(builder: (context) => AnD()));
                  },
                  child: Text('Continue with the saved IP'),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
