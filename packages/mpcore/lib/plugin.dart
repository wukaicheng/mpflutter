part of './mpcore.dart';

abstract class MPPlugin {
  dynamic encodeElement(Element element);
  void onClientMessage(Map message) {}
}
