#include <stdio.h>

extern void iniciaAlocador();
extern void finalizaAlocador();
extern void liberaMem(long int* bloco);
extern long int* alocaMem(int num_bytes);
extern void imprimeMapa();

int main() {
    printf("\n API de Heap por Mihael Scofield e Vinicius Oliveira \n");

    iniciaAlocador();
    imprimeMapa(0);

    long int* a = alocaMem(10);
    imprimeMapa(1);

    long int* b = alocaMem(5);
    imprimeMapa(2);

    long int* c = alocaMem(1);
    imprimeMapa(3);

    liberaMem(b);
    imprimeMapa(4);

    b = alocaMem(5);
    imprimeMapa(5);

    printf("\n");
    finalizaAlocador();
}