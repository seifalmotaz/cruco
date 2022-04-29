library cruky.core.req;

import 'dart:io';
import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'package:cruky/cruky.dart';
import 'package:cruky/src/common/string_converter.dart';
import 'package:mime/mime.dart';

import 'common/query.dart';

/// request manipulating helper
class Request {
  /// native [HttpRequest] class from the stream listener
  final HttpRequest native;

  /// request query
  final QueryParameters query;

  /// request path parameters
  final Map<String, dynamic> path;

  /// native [HttpResponse] class from [HttpRequest]
  HttpResponse get res => native.response;

  /// request method
  String get method => native.method;

  /// request uri
  Uri get uri => native.uri;

  /// request headers content type
  ContentType? get contentType => native.headers.contentType;

  /// request session
  HttpSession get session => native.session;

  /// method to get value fro request headers
  String? headerValue(String i) => native.headers.value(i);

  /// get headers values as map
  Map<String, List<String>> get headers {
    Map<String, List<String>> data = {};
    native.headers.forEach((name, values) {
      data.addAll({name: values});
    });
    return data;
  }

  /// request manipulating helper
  Request({
    required this.path,
    required this.query,
    required this.native,
  });

  /// data that passed from the pipeline/middleware
  final Map<Symbol, Object> parser = {};

  /// covert request body to json/map it can return map or list
  Future json() async {
    String string = await utf8.decodeStream(native);
    var body = string.isEmpty ? {} : jsonDecode(string);
    return body;
  }

  Future<Uint8List> _getBytes(HttpRequest request) {
    return request
        .fold<BytesBuilder>(BytesBuilder(copy: false), (a, b) => a..add(b))
        .then((b) => b.takeBytes());
  }

  /// covert request body to form data
  Future<FormData> form() async {
    var bytes = await _getBytes(native);
    Map<String, List<String>> body = String.fromCharCodes(bytes).splitQuery();
    return FormData(body);
  }

  /// covert request body to multipart form data
  Future<iFormData> iForm() async {
    /// get the fields from multi form fields
    RegExp _matchName = RegExp('name=["|\'](.+)["|\']');
    RegExp _matchFileName = RegExp('filename=["|\'](.+)["|\']');

    final Map<String, String> formFields = {};
    final Map<String, List<FilePart>> formFiles = {};
    Stream<Uint8List> stream;

    var bytes = await _getBytes(native);
    var ctrl = StreamController<Uint8List>()
      ..add(bytes)
      ..close();
    stream = ctrl.stream;

    var parts = MimeMultipartTransformer(contentType!.parameters['boundary']!)
        .bind(stream);

    await for (MimeMultipart part in parts) {
      String headers = part.headers['content-disposition']!;

      /// split headers fields
      List<String> headersFields = headers.split(';');

      /// get the name of form field
      String field = headersFields.firstWhere((e) => _matchName.hasMatch(e));
      RegExpMatch? fieldNameMatch = _matchName.firstMatch(field);

      /// check if the field name exist
      {
        if (fieldNameMatch == null) {
          throw Json({
            "msg": "Cannot find the header name field for the request",
          }, 500);
        }

        if (fieldNameMatch[1] == null) {
          throw Json({
            "msg": "the form field name is empty please "
                "try to put a name for the field",
          }, 500);
        }
      }

      String name = fieldNameMatch[1]!;

      /// check if this part is field or file
      if (!headers.contains('filename=')) {
        /// handle if if it's a field
        formFields[name] = await utf8.decodeStream(part);
        continue;
      }

      /// handle if it's file
      /// get file name from headers
      field = headersFields.firstWhere((e) => _matchFileName.hasMatch(e));
      RegExpMatch? fileNameMatch = _matchFileName.firstMatch(headers);

      /// check if the file name exist
      {
        if (fileNameMatch == null) {
          throw Json({
            "msg": "Cannot find the header name field for the request",
          }, 500);
        }

        if (fileNameMatch[1] == null) {
          throw Json({
            "msg": "the form field name is empty please "
                "try to put a name for the field",
          }, 500);
        }
      }

      String filename = fileNameMatch[1]!;

      /// add the file to formFiles as stream
      Stream<List<int>> streamBytes = part.asBroadcastStream();
      if (formFiles.containsKey(name)) {
        formFiles[name]!.add(FilePart(name, filename, streamBytes));
      } else {
        formFiles[name] = [FilePart(name, filename, streamBytes)];
      }
    }
    return iFormData(formFields, formFiles);
  }
}

/// Map helper to help you conver String values to other types
class MapConverter<T extends Map> {
  final T data;
  MapConverter(this.data);

  /// get the value as string
  String? get(String i) => data[i];

  /// get the value as it is
  dynamic getAny(String i) => data[i];

  /// get value as int
  int? getInt(String i) {
    final _data = data[i];
    if (_data == null) return null;
    return int.tryParse(_data);
  }

  /// get value as double
  double? getDouble(String i) {
    final _data = data[i];
    if (_data == null) return null;
    return double.tryParse(_data);
  }

  /// get value as bool
  bool? getBool(String i) {
    final _data = data[i];
    if (_data == null) return null;
    String ii = _data.toLowerCase();
    if (ii.contains('true')) return true;
    if (ii.contains('false')) return false;
    return null;
  }
}
