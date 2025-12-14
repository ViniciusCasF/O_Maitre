
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:appgarcon/Paginas/Pagina_Cardapio.dart';
import 'package:appgarcon/Paginas/Pagina_Conta.dart';
import 'package:appgarcon/Paginas/Pagina_Leitor_Mesa_Garcom.dart';
import 'package:water_drop_nav_bar/water_drop_nav_bar.dart';

// Importa a nova página de pedidos
import 'package:appgarcon/Paginas/Pagina_Pedidos_Garcom.dart';

class MyHomePage extends StatefulWidget {
  const MyHomePage({Key? key}) : super(key: key);

  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  final Color navigationBarColor = Colors.white;
  int selectedIndex = 0;
  late PageController pageController;

  @override
  void initState() {
    super.initState();
    pageController = PageController(initialPage: selectedIndex);
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle(
        systemNavigationBarColor: navigationBarColor,
        systemNavigationBarIconBrightness: Brightness.dark,
      ),
      child: Scaffold(
        body: PageView(
          physics: const NeverScrollableScrollPhysics(),
          controller: pageController,
          children: const <Widget>[
            PaginaCardapio(),
            PaginaLeitorMesaGarcom(),
            PaginaPedidosGarcom(), // <- nova página
          ],
        ),
        bottomNavigationBar: WaterDropNavBar(
          backgroundColor: navigationBarColor,
          waterDropColor: const Color(0xFF448AFF),
          onItemSelected: (int index) {
            setState(() {
              selectedIndex = index;
            });
            pageController.animateToPage(
              selectedIndex,
              duration: const Duration(milliseconds: 400),
              curve: Curves.easeOutQuad,
            );
          },
          selectedIndex: selectedIndex,
          barItems: <BarItem>[
            BarItem(
              filledIcon: Icons.shopping_cart,
              outlinedIcon: Icons.shopping_cart_outlined,
            ),
            BarItem(
              filledIcon: Icons.paid,
              outlinedIcon: Icons.paid_outlined,
            ),
            BarItem(
              filledIcon: Icons.receipt_long,
              outlinedIcon: Icons.receipt_outlined,
            ),
          ],

        ),
      ),
    );
  }
}

