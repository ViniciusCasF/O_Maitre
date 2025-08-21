import 'package:flutter/cupertino.dart';

// Linha de cada informação em baixo da janela dos produtos
Widget textoLinha(String label, double value, {bool isTotal = false}) {

  final style = TextStyle(

    // Se for total o texto vai ser tamanho 18, caso não, 16
    fontSize: ((){
      if(isTotal){
        return 18.0;
      }
      else{
        return 16.0;
      }
    })(),

    // Se for total o texto vai estar em negrito, caso não, ele vai estar normal
    fontWeight: ((){
      if(isTotal){
        return FontWeight.bold;
      }
      else{
        return FontWeight.w500;
      }
    })(),
  );

  return Padding(
    padding: const EdgeInsets.symmetric(vertical: 6),
    child: Row(
      children: [
        Expanded(child: Text(label, style: style)),
        Text('R\$ ${value.toStringAsFixed(2)}', style: style),
      ],
    ),
  );
}