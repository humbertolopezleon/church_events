/// Plurales correctos: «1 iglesia», «2 iglesias». Con [zero] se evita escribir «0» en una frase
/// (Atkinson Hyperlegible dibuja el cero con una barra): «Nadie inscrito todavía».
String plural(int n, String one, String many, {String? zero}) {
  if (n == 0 && zero != null) return zero;
  return '$n ${n == 1 ? one : many}';
}

/// Solo la palabra concordada con [n] («persona»/«personas»), para frases como «${n} … sin hospedaje».
String pluralWord(int n, String one, String many) => n == 1 ? one : many;

/// Verbo/adjetivo en singular o plural: «queda»/«quedan», «inscrita»/«inscritas».
String agree(int n, String one, String many) => n == 1 ? one : many;
