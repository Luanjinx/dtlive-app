@JS()
library;

import 'dart:js_interop';

@JS('window.jsOpenTab')
external JSPromise<JSString> jsOpenTab(JSString url, JSString target);
