import 'package:musheet_server/server.dart';

/// Entry point for the MuSheet Serverpod server
void main(List<String> args) async {
  await Server.start(args);
}