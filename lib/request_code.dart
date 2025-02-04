import 'dart:async';
import 'package:flutter/material.dart';

import 'request/authorization_request.dart';
import 'model/config.dart';
import 'package:webview_flutter/webview_flutter.dart';

class RequestCode {
  final Config _config;
  final AuthorizationRequest _authorizationRequest;
  WebViewController? _webViewController;
  String? _code;

  RequestCode(Config config)
      : _config = config,
        _authorizationRequest = AuthorizationRequest(config);

  Future<String?> requestCode() async {
    _code = null;
    final urlParams = _constructUrlParams();
    var webView = WebView(
      initialUrl: '${_authorizationRequest.url}?$urlParams',
      javascriptMode: JavascriptMode.unrestricted,
      navigationDelegate: _navigationDelegate,
      onWebViewCreated: (controller) => _webViewController = controller,
      onPageFinished: (String url) => _onPageFinished(url),
    );

    await _config.navigatorKey.currentState!.push(MaterialPageRoute(
        builder: (context) => Scaffold(
              body: SafeArea(child: webView),
            )));
    return _code;
  }

  void _onPageFinished(String url) {
    if (_webViewController != null && _config.onUrlChanged != null) {
      _config.onUrlChanged!(_webViewController!, Uri.parse(url));
    }
  }

  FutureOr<NavigationDecision> _navigationDelegate(NavigationRequest request) {
    var startOfUrl = 'https://';
    var url = request.url;
    var modifiedUrl;

    if (url.contains(startOfUrl, 1)) {
      // then the url is doubled up
      // find the index of the actual start
      var index = url.indexOf(startOfUrl, 1);

      // make new url
      modifiedUrl = url.substring(index);
      _webViewController?.loadUrl(modifiedUrl);
      return NavigationDecision.prevent;
    }
    else {
      modifiedUrl = url;
    }
    var uri = Uri.parse(modifiedUrl);

    if (uri.toString().startsWith(_config.redirectUri)) {
      if (uri.queryParameters['error'] != null) {
        _config.navigatorKey.currentState!.pop();
      }

      if (uri.queryParameters['code'] != null) {
        _code = uri.queryParameters['code'];
        _config.navigatorKey.currentState!.pop();
      }
    }

    return NavigationDecision.navigate;
  }

  Future<void> clearCookies() async {
    await CookieManager().clearCookies();
  }

  String _constructUrlParams() =>
      _mapToQueryParams(_authorizationRequest.parameters);

  String _mapToQueryParams(Map<String, String> params) {
    final queryParams = <String>[];
    params.forEach((String key, String value) =>
        queryParams.add('$key=${Uri.encodeQueryComponent(value)}'));
    return queryParams.join('&');
  }
}
