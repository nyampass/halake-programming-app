import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:webview_flutter/webview_flutter.dart';

void main() => runApp(MaterialApp(home: WebViewExample()));

class WebViewExample extends StatefulWidget {
  @override
  _WebViewExampleState createState() => _WebViewExampleState();
}

class _WebViewExampleState extends State<WebViewExample> {
  final Completer<WebViewController> _controller =
      Completer<WebViewController>();

  @override
  void initState() {
    super.initState();
    if (Platform.isAndroid) WebView.platform = SurfaceAndroidWebView();
  }

  Future<String> initialize() async {
    final prefs = await SharedPreferences.getInstance();
    final url = prefs.getString("url") ?? 'https://halake.com/';
    _controller.future.then((value) => value.loadUrl(url));

    return url;
  }

  late WebViewController _webViewController;

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
        future: initialize(),
        builder: (BuildContext context, AsyncSnapshot<String> snapshot) {
          if (!snapshot.hasData) {
            return CircularProgressIndicator();
          }

          return Scaffold(
              backgroundColor: Colors.black,
              body: GestureDetector(
                  onHorizontalDragUpdate: (updateDetails) {},
                  child: Stack(children: [
                    WebView(
                        javascriptMode: JavascriptMode.unrestricted,
                        onWebViewCreated:
                            (WebViewController webViewController) {
                          _webViewController = webViewController;
                          _controller.complete(webViewController);
                        },
                        navigationDelegate: (NavigationRequest request) {
                          return NavigationDecision.navigate;
                        },
                        gestureNavigationEnabled: false,
                        onPageFinished: (_) {
                          // ignore: deprecated_member_use
                          _webViewController.evaluateJavascript(
                              'document.addEventListener("contextmenu", event => event.preventDefault());');
                        }),
                    Align(
                        alignment: Alignment.bottomLeft,
                        child: Container(
                          child: NavigationControls(
                              snapshot.data!, _controller.future),
                        ))
                  ])));
        });
  }
}

// ignore: must_be_immutable
class NavigationControls extends StatelessWidget {
  NavigationControls(this.url, this._webViewControllerFuture);

  final Future<WebViewController> _webViewControllerFuture;
  String url;

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<WebViewController>(
      future: _webViewControllerFuture,
      builder:
          (BuildContext context, AsyncSnapshot<WebViewController> snapshot) {
        final bool webViewReady =
            snapshot.connectionState == ConnectionState.done;
        final controller = snapshot.data;

        return Container(
            padding: EdgeInsets.all(16),
            child: Row(
              children: <Widget>[
                IconButton(
                  icon: const Icon(Icons.replay),
                  onPressed: !webViewReady
                      ? null
                      : () {
                          controller?.reload();
                        },
                ),
                IconButton(
                  icon: const Icon(Icons.settings),
                  onPressed: !webViewReady
                      ? null
                      : () {
                          showDialog(
                              context: context,
                              builder: (context) {
                                return AlertDialog(
                                  title: Text('URL'),
                                  content: TextField(
                                    controller:
                                        TextEditingController(text: url),
                                    onChanged: (v) => this.url = v,
                                    decoration:
                                        InputDecoration(hintText: "URLを入力"),
                                  ),
                                  actions: <Widget>[
                                    TextButton(
                                      child: Text('OK',
                                          style: TextStyle(
                                            color: Colors.blue,
                                          )),
                                      onPressed: () async {
                                        Navigator.pop(context);
                                        final prefs = await SharedPreferences
                                            .getInstance();
                                        await prefs.setString("url", url);
                                        controller?.loadUrl(url);
                                      },
                                    ),
                                  ],
                                );
                              });
                        },
                )
              ],
            ));
      },
    );
  }
}
