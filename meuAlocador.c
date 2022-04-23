#include <stdio.h>
#include <stdlib.h>

int64_t* topoInicialHeap;
int64_t* heap;
int64_t* enderecoInicialBusca;
int64_t* enderecoBusca;

int64_t iniciaAlocador() {
    heap = malloc(sizeof(int64_t) * 10000);
    topoInicialHeap = heap;
    printf("\n %p \n", topoInicialHeap);
}

int64_t finalizaAlocador() {
    heap = topoInicialHeap;
}

int liberaMem(int64_t* bloco) {
    bloco = bloco - 2;
    *bloco = 0;
}

int64_t* busca(int num_bytes) {
    int flag = 0;    
    int num_bytesAUX;
    
    enderecoBusca = enderecoInicialBusca;
    do {
        // Pula para próximo bloco
        num_bytesAUX = *(enderecoBusca) - 1;
        enderecoBusca = enderecoBusca + num_bytesAUX;

        // Verifica se deve voltar ao inicio
        if(enderecoBusca > heap) {
            enderecoBusca = topoInicialHeap + 2;
        }

        // Investiga bloco atual
        num_bytes = *(enderecoBusca) - 2;
        if(num_bytes == 0) { // Bloco atual esta livre
            num_bytes = *(enderecoBusca) - 1;
            if(num_bytesAUX >= num_bytes) {
                flag = 1;
            }
        }
    } while ((flag == 0) && (*enderecoBusca =! *enderecoInicialBusca));

    if((flag == 0) || (enderecoBusca == enderecoInicialBusca)) {
        return 0;      
    }
    return enderecoBusca;
}

int64_t* alocaMem(int num_bytes) {
    // Alocacao no primeiro caso
    if(heap == topoInicialHeap) {
        *heap = 1;
        heap = heap + 1;
        *heap = num_bytes;
        heap = heap + 1;
        enderecoInicialBusca = heap;
        heap = heap + num_bytes;
        return enderecoInicialBusca; // retorna ultima posicao encontrada
    } 
    // Heap nao esta vazia, iremos buscar
    else {
        int64_t* novoEndereco = busca(num_bytes);
        // Encontrou um bloco elegivel na busca e o trata
        if (novoEndereco != 0) {
            int num_bytesAUX = *(novoEndereco - 1);
            *(novoEndereco - 2) = 1;
            *(novoEndereco - 1) = num_bytes;
            // Verifica se ha a necessidade de "repartir" o bloco atual
            if(num_bytesAUX != num_bytes) {
                novoEndereco = novoEndereco + num_bytes + 2;
                *(novoEndereco - 2) = 0;
                *(novoEndereco - 1) = num_bytesAUX - num_bytes;
            }
        }
        // nao encontrou, aumenta a heap
        else {
            *heap = 1;
            heap = heap + 1;
            *heap = num_bytes;
            heap = heap + 1;
            enderecoInicialBusca = heap;
            heap = heap + num_bytes;
            return enderecoInicialBusca; // retorna ultima posicao encontrada
        }
    }
}

int64_t imprimeMapa() {
    int flag, num_bytesAtual;
    char positividade;
    int64_t* enderecoAtual = topoInicialHeap; // iniciamos no topo sempre
    
    while(*enderecoAtual != *heap) {
        // Descubro se a ocupação do bloco atual
        flag = *(topoInicialHeap);
        if (flag == 0) {
            positividade = '-';
        }
         else {
            positividade = '+';
        }
        num_bytesAtual = *(enderecoAtual + 1);
        printf("##");
        for (int i = 0; i < num_bytesAtual; i++) {
            printf("%c", positividade);
        }
        enderecoAtual = enderecoAtual + num_bytesAtual + 1; // + 1 para pularmos o controle da frente
    }

}

int64_t main() {
    printf("\n Olá BRK! É PRA FICAR PARADA OUVIU? \n");

    int64_t *a, *b;
    iniciaAlocador();
    imprimeMapa();

    a = alocaMem(240);
    imprimeMapa();
    b = alocaMem(50);
    imprimeMapa();
    liberaMem(a);
    imprimeMapa();
    a = alocaMem(50);
    imprimeMapa();

    finalizaAlocador();
}