# language: es
Característica: Prueba simple de Digest.pm
	Como dearrollador planeo usar Digest.pm
	Deseo probar la funcionalidad de Digest.pm
	Para estar seguro de que funciona de forma correcta

Antecedentes:
	Dada la clase "Digest"

Escenario: Verificar MD5
	Dado un objeto Digest usando el algoritmo "MD5"
	Cuando he agregado "prueba" al objeto
	Entonces el resultado en hexadecimal es "c893bad68927b457dbed39460e6afd62"
	Cuando he agregado "prueba" al objeto 
	Y he agregado "texto" al objeto 
	Entonces el resultado en hexadecimal es "faea2ea80591327766b7c9ce591f9460"
	Entonces el resultado en base64 es "1B2M2Y8AsgTpgAmY7PhCfg"
#	This is an intentional comment
#	Entonces el resultado en hexadecimal es "9ee285740e9bbc8c72c8e0fe9e68aa8f"

Escenario: Check SHA-1
	Dado un objeto Digest usando el algoritmo "SHA-1"
	Cuando he agregado "<data>" al objeto
	Entonces el resultado en hexadecimal es "<output>"
Ejemplos:
	| data | output   |
	| test | a94a8fe5ccb19ba61c4c0873d391e987982fbbd3 |
	| devs | 99b48da825c239c6ecd0a54ebfc11552d7ffb56f |
	| nogo | c42910ed3f073231e88fef0b710648684fc0ed28 |

Escenario: MD5 de datos mas largos
	Dado un objeto Digest usando el algoritmo "MD5"
	Cuando he agregado los siguientes datos al objeto
	"""
	Esta es una prueba del funcionamiento de Test::BDD::Cucumber.
	"""
	Entonces el resultado hexadecimal es "00c6fff240d73810685d9b4885018a5d"
