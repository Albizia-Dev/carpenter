import '../application/command.dart';

abstract interface class CarpenterPageController {
  List<CarpenterCommand<dynamic>> get pageCommands;
  Future<void> refresh();
}
