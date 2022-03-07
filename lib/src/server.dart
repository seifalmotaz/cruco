library cruco.server;

import 'dart:io';
import 'dart:mirrors';

import 'router/router.dart';

Future<void> serve([String host = '127.0.0.1', int port = 5000]) async {
  CrucoServer server = CrucoServer(host, port);
  LibraryMirror mirror = currentMirrorSystem().isolate.rootLibrary;
  server.addLib(mirror.simpleName, null, mirror);
  await server.serve();
}

class CrucoServer extends Router {
  String host;
  int port;
  bool customErrs;
  CrucoServer([
    this.host = '127.0.0.1',
    this.port = 5000,
    this.customErrs = false,
  ]);

  late HttpServer _httpServer;

  serve([String? _host, int? _port]) async {
    _httpServer = await HttpServer.bind(_host ?? host, _port ?? port);
    // adding error routes like (404, 500, ..etc)
    if (!customErrs) addLib(#cruco.router);
    // start server listen
    print('Server running on http://$host:$port');
    await for (HttpRequest request in _httpServer) {
      // var bodyHandler = request.transform(HttpBodyHandler());

      // get the request handler
      TypeRoute route = matchLib(request.uri.path, request.method);
      await route.execute(request);
      // Linkee linkee = match(request.uri.path, request.method);
      // check the hendler type
      // direct method handler
      // if (linkee is LinkeeMethod) {
      // await methodHandeler(linkee, request);
      // close response and goto next request
      request.response.close();
      // continue;
      // }
    }
  }

  // Future methodHandeler(LinkeeMethod linkee, HttpRequest request) async {
  //   late Map resBody;
  //   CrucoRequest req = CrucoRequest(
  //     request.headers.contentType!,
  //     jsonDecode(await utf8.decodeStream(request)),
  //   );
  //   if (linkee.isAsync) {
  //     resBody = await linkee.on(req);
  //   } else {
  //     resBody = linkee.on(req);
  //   }
  //   if (resBody is MapResponse) {
  //     // set basic response info (headers, statusCode, ..etc)
  //     request.response.headers.set("Content-type", "application/json");
  //     request.response.statusCode = resBody[#status] ?? 200;
  //     // set the main response body
  //     request.response.write(jsonEncode(resBody[#body]));
  //   } else {
  //     // set the main response body
  //     resBody.removeWhere((key, value) => key is Symbol);
  //     request.response.write(jsonEncode(resBody));
  //   }
  // }
}
