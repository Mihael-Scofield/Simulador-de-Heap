#!/bin/bash
rm meuAlocador.o programa.o
as meuAlocador.s -o meuAlocador.o -g
gcc -g -c programa.c -o programa.o
gcc -static programa.o meuAlocador.o -o avalia 
# ld meuAlocador.o programa.o -o executavel -dynamic-linker /lib/x86_64-linux-gnu/ld-linux-x86-64.so.2 \
# /usr/lib/x86_64-linux-gnu/crt1.o /usr/lib/x86_64-linux-gnu/crti.o \
# /usr/lib/x86_64-linux-gnu/crtn.o -lc
