#include <stdio.h>
#include <stdlib.h>

int topoInicialHeap; // Seria um endereço int64_t, 8 bytes, porém aqui será apenas o índice 0
int enderecoInicialBusca; // para o ponteiro das buscas, utilizaremos a mesma lógica
int enderecoBusca;
int brk; // indice que simula o que seria a o endereco final da "heap"
int64_t* heapHipotetica;

void iniciaAlocador() {
    heapHipotetica = malloc(sizeof(int64_t) * 10000); /// tamanho "estático", apenas para teste
    brk = 0; // Seria o endereco, mas como estamos usando indices é o 0
    topoInicialHeap = brk; 
}

void finalizaAlocador() {
    // brk = topoInicialHeap; // Para liberar o endereço utilizariamos essa linha
    free(heapHipotetica);
}

void liberaMem(int bloco) {
    heapHipotetica[bloco - 2] = 0; // Volta "8 bytes" (2 enderecos) e seta como livre, isto e, 0
}

int busca(int num_bytes) {
    int flag = 0;
    int num_bytesAUX;
    enderecoBusca = enderecoInicialBusca; // considerado que endereco aponta para o bloco[2]
    
    do {
        /* Pula para próximo bloco */
        num_bytesAUX = heapHipotetica[enderecoBusca - 1]; // pega a quantidade de indices a pular
        enderecoBusca = enderecoBusca + num_bytesAUX + 2;

        /* Verifica se deve voltar ao inicio */
        if(enderecoBusca >= brk) {
            enderecoBusca = topoInicialHeap + 2; // + 2 para considerar que bloco comeca em bloco[2]
        }

        /* Investiga bloco atual */
        // Verifica se bloco atual esta livre, reaproveitando num_bytes
        if(heapHipotetica[enderecoBusca - 2] == 0) { // Bloco atual esta livre
            // Verifica agora o tamanho do bloco atual
            num_bytesAUX = heapHipotetica[enderecoBusca - 1];
            if(num_bytes <= num_bytesAUX) {
                flag = 1;
            }
        }
    } while ((flag == 0) && (enderecoBusca != enderecoInicialBusca));

    // caso nao tenha encontrado
    if((flag == 0) || (enderecoBusca == enderecoInicialBusca)) {
        return 0;
    }

    return enderecoBusca;
}

int alocaBloco(int enderecoBloco, int num_bytes) {
    heapHipotetica[enderecoBloco - 2] = 1;
    heapHipotetica[enderecoBloco - 1] = num_bytes;
    enderecoInicialBusca = enderecoBloco;
}

int alocaMem(int num_bytes) {
    /* Heap Vazia */
    if(brk == topoInicialHeap) {
        alocaBloco(2, num_bytes);
        brk = brk + num_bytes + 2;
    } 
    /* Heap nao esta vazia, iremos buscar um bloco vazio >= em tamanho */
    else {
        int novoEndereco = busca(num_bytes);
        /* Caso em que encontrou um bloco elegivel na busca*/
        if (novoEndereco != 0) {
            int num_bytesAUX = heapHipotetica[novoEndereco - 1];
            alocaBloco(novoEndereco, num_bytes);
            // Verifica se ha a necessidade de "repartir" o bloco atual
            if(num_bytesAUX != num_bytes) {
                // Avanca-se ate os blocos de controle da parte dividida, e posiciona os num_bytes que sobraram
                alocaBloco(novoEndereco + num_bytes + 2, num_bytesAUX - num_bytes);
            }
        }
        /* nao encontrou, aumenta a heap */
        else {
            alocaBloco(brk + 2, num_bytes); // + 3 pois quero ignorar o ultimo espaco do ultimo bloco
            brk = brk + num_bytes + 2; 
        }
    }
    return enderecoInicialBusca;
}

int64_t imprimeMapa(int chamada) {
    printf("\n COMECANDO MAPA NUMERO %d \n ", chamada); // DEBUGACAO DE ALUNO
    int flag, num_bytesAtual;
    char positividade;
    int enderecoAtual = topoInicialHeap + 2 ; // iniciamos no bloco do topo sempre
    
    if (brk != 0) {
        while(enderecoAtual < brk) {
            // Descubro se a ocupação do bloco atual
            flag = heapHipotetica[enderecoAtual - 2];
            if (flag == 0) {
                positividade = '-';
            }
             else {
                positividade = '+';
            }
            num_bytesAtual = heapHipotetica[enderecoAtual - 1];
            printf("##");
            for (int i = 0; i < num_bytesAtual; i++) {
                printf("%c", positividade);
            }
            enderecoAtual = enderecoAtual + num_bytesAtual + 2; // + 2 para pularmos o controle da frente
        }
    }
    else  {
        printf("Heap Vazia");
    }
}

int main() {
    printf("\n API de Heap por Mihael Scofield e Vinicius Oliveira \n");

    int a, b;
    iniciaAlocador();
    imprimeMapa(0);

    a = alocaMem(10);
    imprimeMapa(1);

    b = alocaMem(5);
    imprimeMapa(2);

    int c = alocaMem(1);
    imprimeMapa(3);

    liberaMem(b);
    imprimeMapa(4);

    b = alocaMem(5);
    imprimeMapa(5);

    printf("\n");
    finalizaAlocador();
}