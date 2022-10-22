// ignore_for_file: non_constant_identifier_names, unnecessary_brace_in_string_interps

import 'dart:async';
import 'dart:io';

import 'package:alfred/alfred.dart';
import 'package:alfred/src/type_handlers/websocket_type_handler.dart';
import 'package:uuid/uuid.dart';

void main() async {
  int port = int.parse(Platform.environment["PORT"] ?? "8080");
  String host = Platform.environment["HOST"] ?? "0.0.0.0";
  final app = Alfred();
  app.all("/", (req, res) {
    return res.send({"@type": "ok"});
  });
  late List<WebSocketData> clients = [];
  app.get('/ws', (req, res) {
    return WebSocketSession(
      onOpen: (ws) {
        bool is_save_socket = clients.saveWebsocket(webSocket: ws);
        if (is_save_socket) {
          ws.send("connected to server hai manies");
        } else {
          ws.send("disconnect");
          ws.close();
          return;
        }
      },
      onClose: (ws) {
        clients.deleteWebSocketByWebsocket(webSocket: ws);
      },
      onMessage: (ws, dynamic data) async {
        try {
          WebSocketData? from_websocket = clients.getWebSocketByWebsocket(webSocket: ws);
          if (from_websocket == null) {
            ws.send("disconnect");
            clients.deleteWebSocketByWebsocket(webSocket: ws);
            return;
          }
          late String message = "from ${from_websocket.socket_id}";
          message += "\nmessage: ${data}";
          clients.broadCast(
            data: message,
            isExceptMe: true,
            ws: ws,
          );
        } catch (e) {
          return ws.send("Error ${e}");
        }
      },
    );
  });

  final server = await app.listen(port, host);

  print('Listening on ${server.port}');
}

class WebSocketData {
  late String socket_id;
  late WebSocket webSocket;
  WebSocketData({
    required this.socket_id,
    required this.webSocket,
  });
}

extension WebSocketDatasExtensions on List<WebSocketData> {
  void broadCastAll(dynamic data) {
    for (var i = 0; i < length; i++) {
      WebSocketData webSocketData = this[i];
      webSocketData.webSocket.send(data);
    }
    return;
  }

  void broadCast({
    required dynamic data,
    bool isExceptMe = false,
    required WebSocket ws,
  }) {
    for (var i = 0; i < length; i++) {
      WebSocketData webSocketData = this[i];
      if (isExceptMe) {
        if (webSocketData.webSocket == ws) {
          continue;
        }
      }
      webSocketData.webSocket.send(data);
    }
    return;
  }

  bool saveWebsocket({required WebSocket webSocket}) {
    try {
      DateTime time_out = DateTime.now().add(Duration(seconds: 10));
      List<String> socket_ids = map((e) => e.socket_id).toList().cast<String>();
      late String socketId = Uuid().v4();
      while (true) {
        if (time_out.isBefore(DateTime.now())) {
          return false;
        }
        if (socket_ids.contains(socketId)) {
          socketId = Uuid().v4();
        } else {
          add(WebSocketData(socket_id: socketId, webSocket: webSocket));
          return true;
        }
      }
    } catch (E) {
      return false;
    }
  }

  bool deleteWebSocketById({
    required String socketId,
  }) {
    for (var i = 0; i < length; i++) {
      // ignore: non_constant_identifier_names
      WebSocketData webSocketData = this[i];
      if (webSocketData.socket_id == socketId) {
        webSocketData.webSocket.close();
        remove(i);
        return true;
      }
    }
    return false;
  }

  bool deleteWebSocketByWebsocket({
    required WebSocket webSocket,
  }) {
    for (var i = 0; i < length; i++) {
      // ignore: non_constant_identifier_names
      WebSocketData webSocketData = this[i];
      if (webSocketData.webSocket == webSocket) {
        webSocketData.webSocket.close();
        remove(i);
        return true;
      }
    }
    return false;
  }

  WebSocketData? getWebSocketByWebsocket({
    required WebSocket webSocket,
  }) {
    for (var i = 0; i < length; i++) {
      WebSocketData webSocketData = this[i];
      if (webSocketData.webSocket == webSocket) {
        return webSocketData;
      }
    }
    return null;
  }
}
