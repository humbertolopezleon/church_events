import 'package:flutter/services.dart';

/// Solo dígitos (edad, capacidad, cantidades, topes). [maxLength] limita cuántos.
List<TextInputFormatter> digitsOnly([int maxLength = 4]) => [
      FilteringTextInputFormatter.digitsOnly,
      LengthLimitingTextInputFormatter(maxLength),
    ];

/// Teléfono: dígitos, espacios y los signos habituales (+ - ( )).
List<TextInputFormatter> phoneChars([int maxLength = 20]) => [
      FilteringTextInputFormatter.allow(RegExp(r'[0-9 +\-()]')),
      LengthLimitingTextInputFormatter(maxLength),
    ];

/// Número con decimales (coma o punto): dígitos y un solo separador.
List<TextInputFormatter> decimalOnly([int maxLength = 5]) => [
      FilteringTextInputFormatter.allow(RegExp(r'[0-9]*[.,]?[0-9]*')),
      LengthLimitingTextInputFormatter(maxLength),
    ];
