#include <stdio.h>

extern void iniciaAlocador();
extern void finalizaAlocador();
extern void liberaMem(long int* bloco);
extern long int* alocaMem(int num_bytes);
extern void imprimeMapa();

int main() {
    iniciaAlocador();
    imprimeMapa();

    long int* a = alocaMem(10);
    imprimeMapa();
    printf(" \n chamada 1 \n");

    long int* b = alocaMem(5);
    imprimeMapa();
    printf(" \n chamada 2 \n");

    long int* c = alocaMem(1);
    imprimeMapa();
    printf(" \n chamada 3 \n");

    liberaMem(b);
    imprimeMapa();

    b = alocaMem(5);
    imprimeMapa();

    printf("\n");
    finalizaAlocador();
}