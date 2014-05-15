Característica: Funciones Básicas de Calculadora
  In order to check I've written the Calculator class correctly
  As a developer I want to check some basic operations
  So that I can have confidence in my Calculator class.

  Antecedentes:
    Dado a usable "Calculator" class

  Escenario: First Key Press on the Display
    Dado a new Calculator object
    Y having pressed 1
    Entonces the display should show 1

  Escenario: Several Key Presses on the Display
    Dada a new Calculator object
    Y having pressed 1 and 2 and 3 and . and 5 and 0
    Entonces the display should show 123.50

  Escenario: Pressing Clear Wipes the Display
    Dada a new Calculator object
    Y having pressed 1 and 2 and 3
    Y having pressed C
    Entonces the display should show 0

  Escenario: Add as you go
    Dado a new Calculator object
    Y having pressed 1 and 2 and 3 and + and 4 and 5 and 6 and +
    Entonces the display should show 579

  Escenario: Basic arithmetic
    Dado a new Calculator object
    Y having keyed <first>
    Y having keyed <operator>
    Y having keyed <second>
    Y having pressed =
    Entonces the display should show <result>
    Ejemplos:
      | first | operator | second | result |
      | 5.0   | +        | 5.0    | 10     |
      | 6     | /        | 3      | 2      |
      | 10    | *        | 7.550  | 75.5   |
      | 3     | -        | 10     | -7     |

  Escenario: Separation of calculations
    Dado a new Calculator object
    Y having successfully performed the following calculations
      | first | operator | second | result |
      | 0.5   | +        | 0.1    | 0.6    |
      | 0.01  | /        | 0.01   | 1      |
      | 10    | *        | 1      | 10     |
    Y having pressed 3
    Entonces the display should show 3

  Escenario: Ticker Tape
    Dado a new Calculator object
    Y having entered the following sequence
      """
      1 + 2 + 3 + 4 + 5 + 6 -
      100
      * 13 \=\=\= + 2 =
      """
    Entonces the display should show -1025