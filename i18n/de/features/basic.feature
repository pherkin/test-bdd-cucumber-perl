# language: de
Funktionalität: Grundlegende Taschenrechnerfunktionen
  Um sicherzustellen, dass ich die Calculator-Klasse korrekt programmiert habe,
  möchte ich als Entwickler einige grundlegende Funktionen prüfen,
  damit ich beruhigt meine Calculator-Klasse verwenden kann.

  Szenario: Anzeige des ersten Tastendrucks
    Gegeben sei ein neues Objekt der Klasse Calculator
    Wenn ich 1 gedrückt habe
    Dann ist auf der Anzeige 1 zu sehen

  Szenario: Anzeige mehrerer Tastendrücke
    Gegeben sei ein neues Objekt der Klasse Calculator
    Wenn ich 1 und 2 und 3 und . und 5 und 0 gedrückt habe
    Dann ist auf der Anzeige 123.50 zu sehen

  Szenario: Taste "C" löscht die Anzeige
    Gegeben sei ein neues Objekt der Klasse Calculator
    Wenn ich 1 und 2 und 3 gedrückt habe
    Wenn ich C gedrückt habe
    Dann ist auf der Anzeige 0 zu sehen

  Szenario: Addition während des Rechnens
    Gegeben sei ein neues Objekt der Klasse Calculator
    Wenn ich 1 und 2 und 3 und + und 4 und 5 und 6 und + gedrückt habe
    Dann ist auf der Anzeige 579 zu sehen

  Szenario: Grundlegende Berechnungen
    Gegeben sei ein neues Objekt der Klasse Calculator
    Wenn die Tasten <first> gedrückt wurden
    Und die Tasten <operator> gedrückt wurden
    Und die Tasten <second> gedrückt wurden
    Und ich = gedrückt habe
    Dann ist auf der Anzeige <result> zu sehen
    Beispiele:
      | first | operator | second | result |
      | 5.0   | +        | 5.0    | 10     |
      | 6     | /        | 3      | 2      |
      | 10    | *        | 7.550  | 75.5   |
      | 3     | -        | 10     | -7     |

  Szenario: Trennung von Berechnungen
    Gegeben sei ein neues Objekt der Klasse Calculator
    Wenn ich erfolgreich folgende Rechnungen durchgeführt habe
      | first | operator | second | result |
      | 0.5   | +        | 0.1    | 0.6    |
      | 0.01  | /        | 0.01   | 1      |
      | 10    | *        | 1      | 10     |
    Und ich 3 gedrückt habe
    Dann ist auf der Anzeige 3 zu sehen

  Szenario: Ticker Tape
    Gegeben sei ein neues Objekt der Klasse Calculator
    Wenn ich folgende Zeichenfolge eingegeben habe
      """
      1 + 2 + 3 + 4 + 5 + 6 -
      100
      * 13 \=\=\= + 2 =
      """
    Dann ist auf der Anzeige -1025 zu sehen

  Szenario: Zahlen als Text eingeben
    Gegeben sei ein neues Objekt der Klasse Calculator
    Wenn die Tasten __THE_NUMBER_FIVE__ gedrückt wurden
    Dann ist auf der Anzeige 5 zu sehen

  Szenario: Zahlen als Text eingeben
    Gegeben sei ein neues Objekt der Klasse Calculator
    Wenn ich folgende Zahlen addiert habe
      | number as word      |
      | __THE_NUMBER_FOUR__ |
      | __THE_NUMBER_FIVE__ |
      | __THE_NUMBER_ONE__  |
    Dann ist auf der Anzeige __THE_NUMBER_TEN__ zu sehen

