#!/bin/bash
rm meuAlocador.o programa.o
as meuAlocador.s -o meuAlocador.o -g
gcc -g -c programa.c -o programa.o
gcc -static programa.o meuAlocador.o -o executavel
./executavel