import 'package:flutter/material.dart';

class BarraPesquisa extends StatelessWidget {
  final ValueChanged<String> onChanged;
  final TextEditingController? controller;

  const BarraPesquisa({Key? key, required this.onChanged, this.controller}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(

      // Barra no centro e de tamanho 40
      height: 40,
      alignment: Alignment.center,

      child: TextField(

        controller: controller, // Controla o que é escrito dentro da barra
        onChanged: onChanged, // Callback para chamar sempre que o usuário fizer qualquer alteração no texto
        cursorColor: Color(0xFF448AFF), // Deixa a barra da marcação da escrita azul
        style: const TextStyle(color: Colors.black87), // Estilo do texto dentro da barra

        decoration: InputDecoration(

          hintText: 'Buscar...', // O que vai escrever na barra de busca enquanto o usuário não escrever nada
          filled: false, // Se a barra vai ter uma cor diferente de branco
          fillColor: Color(0xFF448AFF), // Qual cor ela vai ter
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 0), // Centralizar o texto da barra

          // Barra durante a busca
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Color(0xFF448AFF), width: 2),
          ),

          // Barra fora da busca
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Color(0xFF448AFF), width: 2),
          ),

          // Deixa a barra da mesma forma que ela é quando o usuário selecionar ela
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Colors.blue, width: 2 ),
          ),

        ),
      ),
    );
  }
}
