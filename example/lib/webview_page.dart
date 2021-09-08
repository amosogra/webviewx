import 'dart:convert';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:webviewx/webviewx.dart';

import 'helpers.dart';

class WebViewXPage extends StatefulWidget {
  const WebViewXPage({
    Key? key,
  }) : super(key: key);

  @override
  _WebViewXPageState createState() => _WebViewXPageState();
}

class _WebViewXPageState extends State<WebViewXPage> {
  late WebViewXController webviewController;
  final initialContent = '<h4> Contacting payment gateway, please hold... <h2>';
  final executeJsErrorMessage = 'Failed to execute this task because the current content is (probably) URL that allows iframe embedding, on Web.\n\n'
      'A short reason for this is that, when a normal URL is embedded in the iframe, you do not actually own that content so you cant call your custom functions\n'
      '(read the documentation to find out why).';

  int i = 0;

  String data = '';

  Map<String, dynamic> datax = {};

  Size get screenSize => MediaQuery.of(context).size;

  @override
  void initState() {
    super.initState();

    datax = <String, dynamic>{
      "public_key": "FLWPUBK_TEST-3494ab2369da08135c147220937ad2aa-X",
      "tx_ref": "RX1",
      "amount": 100,
      "currency": "NGN",
      "country": "NG",
      "payment_options": " ",
      "customer": {
        "email": "amosogra@gmail.com",
        "phone_number": "08138193856",
        "name": "Flutterwave Developers",
      },
      "customizations": {
        "title": "Maxitag Limited",
        "description": "Payment for items in cart",
        "logo":
            "https://firebasestorage.googleapis.com/v0/b/maxitag-662fa.appspot.com/o/ic_launcher-playstore.png?alt=media&token=bced2549-42a3-478b-abf8-7f05ad196104",
      }
    };
    data = json.encode(datax);
  }

  @override
  void dispose() {
    webviewController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('WebViewX Page'),
      ),
      body: Center(
        child: Container(
          padding: const EdgeInsets.all(10.0),
          child: _buildWebViewX(),/*Column(
            children: <Widget>[
               buildSpace(direction: Axis.vertical, amount: 10.0, flex: false),
              Container(
                padding: const EdgeInsets.only(bottom: 20.0),
                child: Text(
                  'Play around with the buttons below',
                  style: Theme.of(context).textTheme.headline6,
                ),
              ),
              buildSpace(direction: Axis.vertical, amount: 10.0, flex: false),
              Container(
                decoration: BoxDecoration(
                  border: Border.all(width: 0.2),
                ),
                child: _buildWebViewX(),
              ),
              Expanded(
                child: Scrollbar(
                  isAlwaysShown: true,
                  child: SizedBox(
                    width: min(screenSize.width * 0.8, 512),
                    child: ListView(
                      children: _buildButtons(),
                    ),
                  ),
                ),
              ), 
            ],
          ),*/
        ),
      ),
    );
  }

  Widget _buildWebViewX() {
    return WebViewX(
      key: const ValueKey('webviewx'),
      initialContent: initialContent,
      initialSourceType: SourceType.html,
      onWebViewCreated: (controller) => webviewController = controller,
      onPageStarted: (src) => debugPrint('A new page has started loading: $src\n'),
      onPageFinished: (src) async {
        debugPrint('The page has finished loading: $src\n');

        if (i == 0) {
          setState(() {
            i++;
          });
          _setHtmlFromAssets();
          return;
        } else if (i == 1) {
          setState(() {
            i++;
          });
          await webviewController.callJsMethod('makePayment', [data]);
        }
      },
      jsContent: const {
        EmbeddedJsContent(
          js: "function testPlatformIndependentMethod() { console.log('Hi from JS');}",
        ),
        EmbeddedJsContent(
          webJs: "function callPlatformSpecificMethod(msg) { Payment(msg) }",
          mobileJs: "function callPlatformSpecificMethod(msg) { Payment.postMessage(msg) }",
        ),
      },
      dartCallBacks: {
        DartCallback(
          name: 'Payment',
          callBack: (msg) {
            showSnackBar(msg.toString(), context);
            print("This is decoded json: ${json.decode(msg.toString())}");
            print(msg);
          },
        )
      },
      webSpecificParams: const WebSpecificParams(
        printDebugInfo: true,
      ),
      navigationDelegate: (navigation) {
        debugPrint(navigation.content.sourceType.toString());
        return NavigationDecision.navigate;
      },
      //height: screenSize.height / 2,
      //width: min(screenSize.width * 0.8, 1024),
    );
  }

  String get initialHtmlContent => '''
  <!DOCTYPE html>
<html lang="en">

<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Online Payment</title>
</head>

<body>

    <form>
        <script src="https://checkout.flutterwave.com/v3.js"></script>
        <!-- <button type="button" onClick="makePayment('hurayy')">Pay Now</button> -->
    </form>

    <script>
        function makePayment(indata) {
            var datax = JSON.parse(indata);
            FlutterwaveCheckout({
                public_key: datax['public_key'],
                tx_ref: datax['tx_ref'],
                amount: datax['amount'],
                currency: datax['currency'],
                country: datax['country'],
                payment_options: datax['payment_options'],
                customer: {
                    email: datax['customer']['email'],
                    phone_number: datax['customer']['phone_number'],
                    name: datax['customer']['name'],
                },
                customizations: {
                    title: datax['customizations']['title'],
                    description: datax['customizations']['description'],
                    logo: datax['customizations']['logo'],
                },
                callback: function (data) {
                    // specified callback function
                    if (window.Payment !== undefined) {
                        console.log(JSON.stringify(data));
                        callPlatformSpecificMethod(JSON.stringify(data));
                        callPlatformSpecificMethod("Message from window console");
                    } else {
                        console.debug('not running inside a Flutter webview');
                    }
                },
            });
        }
    </script>

</body>

</html>
''';

  void _setUrl() {
    webviewController.loadContent(
      'https://flutter.dev',
      SourceType.url,
    );
  }

  void _setUrlBypass() {
    webviewController.loadContent(
      'https://news.ycombinator.com/',
      SourceType.urlBypass,
    );
  }

  void _setHtml() {
    webviewController.loadContent(initialHtmlContent, SourceType.html);
  }

  void _setHtmlFromAssets() {
    webviewController.loadContent(
      'assets/test.html',
      SourceType.html,
      fromAssets: true,
    );
  }

  Future<void> _goForward() async {
    if (await webviewController.canGoForward()) {
      await webviewController.goForward();
      showSnackBar('Did go forward', context);
    } else {
      showSnackBar('Cannot go forward', context);
    }
  }

  Future<void> _goBack() async {
    if (await webviewController.canGoBack()) {
      await webviewController.goBack();
      showSnackBar('Did go back', context);
    } else {
      showSnackBar('Cannot go back', context);
    }
  }

  void _reload() {
    webviewController.reload();
  }

  void _toggleIgnore() {
    final ignoring = webviewController.ignoresAllGestures;
    webviewController.setIgnoreAllGestures(!ignoring);
    showSnackBar('Ignore events = ${!ignoring}', context);
  }

  Future<void> _evalRawJsInGlobalContext() async {
    try {
      final result = await webviewController.evalRawJavascript(
        '2+2',
        inGlobalContext: true,
      );
      showSnackBar('The result is $result', context);
    } catch (e) {
      showAlertDialog(
        executeJsErrorMessage,
        context,
      );
    }
  }

  Future<void> _callPlatformIndependentJsMethod() async {
    try {
      await webviewController.callJsMethod('testPlatformIndependentMethod', []);
    } catch (e) {
      showAlertDialog(
        executeJsErrorMessage,
        context,
      );
    }
  }

  Future<void> _callPlatformSpecificJsMethod() async {
    try {
      await webviewController.callJsMethod('callPlatformSpecificMethod', ['Hi']);
    } catch (e) {
      showAlertDialog(
        executeJsErrorMessage,
        context,
      );
    }
  }

  Future<void> _getWebviewContent() async {
    try {
      final content = await webviewController.getContent();
      showAlertDialog(content.source, context);
    } catch (e) {
      showAlertDialog('Failed to execute this task.', context);
    }
  }

  Widget buildSpace({
    Axis direction = Axis.horizontal,
    double amount = 0.2,
    bool flex = true,
  }) {
    return flex
        ? Flexible(
            child: FractionallySizedBox(
              widthFactor: direction == Axis.horizontal ? amount : null,
              heightFactor: direction == Axis.vertical ? amount : null,
            ),
          )
        : SizedBox(
            width: direction == Axis.horizontal ? amount : null,
            height: direction == Axis.vertical ? amount : null,
          );
  }

  List<Widget> _buildButtons() {
    return [
      buildSpace(direction: Axis.vertical, flex: false, amount: 20.0),
      Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(child: createButton(onTap: _goBack, text: 'Back')),
          buildSpace(amount: 12, flex: false),
          Expanded(child: createButton(onTap: _goForward, text: 'Forward')),
          buildSpace(amount: 12, flex: false),
          Expanded(child: createButton(onTap: _reload, text: 'Reload')),
        ],
      ),
      buildSpace(direction: Axis.vertical, flex: false, amount: 20.0),
      createButton(
        text: 'Change content to URL that allows iframes embedding\n(https://flutter.dev)',
        onTap: _setUrl,
      ),
      buildSpace(direction: Axis.vertical, flex: false, amount: 20.0),
      createButton(
        text: 'Change content to URL that doesnt allow iframes embedding\n(https://news.ycombinator.com/)',
        onTap: _setUrlBypass,
      ),
      buildSpace(direction: Axis.vertical, flex: false, amount: 20.0),
      createButton(
        text: 'Change content to HTML (hardcoded)',
        onTap: _setHtml,
      ),
      buildSpace(direction: Axis.vertical, flex: false, amount: 20.0),
      createButton(
        text: 'Change content to HTML (from assets)',
        onTap: _setHtmlFromAssets,
      ),
      buildSpace(direction: Axis.vertical, flex: false, amount: 20.0),
      createButton(
        text: 'Toggle on/off ignore any events (click, scroll etc)',
        onTap: _toggleIgnore,
      ),
      buildSpace(direction: Axis.vertical, flex: false, amount: 20.0),
      createButton(
        text: 'Evaluate 2+2 in the global "window" (javascript side)',
        onTap: _evalRawJsInGlobalContext,
      ),
      buildSpace(direction: Axis.vertical, flex: false, amount: 20.0),
      createButton(
        text: 'Call platform independent Js method (console.log)',
        onTap: _callPlatformIndependentJsMethod,
      ),
      buildSpace(direction: Axis.vertical, flex: false, amount: 20.0),
      createButton(
        text: 'Call platform specific Js method, that calls back a Dart function',
        onTap: _callPlatformSpecificJsMethod,
      ),
      buildSpace(direction: Axis.vertical, flex: false, amount: 20.0),
      createButton(
        text: 'Show current webview content',
        onTap: _getWebviewContent,
      ),
    ];
  }
}
