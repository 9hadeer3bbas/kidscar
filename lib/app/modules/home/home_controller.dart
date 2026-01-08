import 'package:get/get.dart';

class HomeController extends GetxController {
  // Add your state variables and methods here
  final count = 0.obs;

  void increment() => count.value++;
}
