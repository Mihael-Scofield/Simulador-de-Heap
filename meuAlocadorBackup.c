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
    /* Liberacao propriamente dita */
    heapHipotetica[bloco - 2] = 0; // Volta "8 bytes" (2 enderecos) e seta como livre, isto e, 0

    /* Verificacao para juntar blocos livres */
    // Primeiro caso, olhar apenas no da frente
    int tamNovo = heapHipotetica[bloco -1];
    int num_bytesAUX = heapHipotetica[bloco - 1];
    int blocoAUX = bloco + num_bytesAUX + 2; // Aponto para o bloco da frente
    if (blocoAUX <= brk) {
        if (heapHipotetica[blocoAUX - 2] == 0) { // novo bloco esta livre
            tamNovo = tamNovo + heapHipotetica[blocoAUX - 1] + 2; // importante + 2, pois sao os controles
            heapHipotetica[blocoAUX - 1] = 0; // "Merge"
        }
    }
    heapHipotetica[bloco - 1] = tamNovo;
    // Segundo caso, olhamos o bloco de tras. 
    // naturalmente, so comecamos isso se nao estivermos ja no bloco inicial
    if (bloco != topoInicialHeap + 2) {
        // como nao sei como chegar la, comecemos do inicio e andamos ate esbarrar no atual
        blocoAUX = topoInicialHeap + 2;
        while(blocoAUX != bloco) {
            num_bytesAUX = heapHipotetica[blocoAUX - 1];
            blocoAUX = blocoAUX + num_bytesAUX + 2; 
        }
        blocoAUX = blocoAUX - (num_bytesAUX + 2); // Volto para o bloco anterior
        // caso o bloco anterior esteja livre, ele se torna o "bloco" referencia
        if (heapHipotetica[blocoAUX - 2] == 0) { 
            tamNovo = tamNovo + heapHipotetica[blocoAUX - 1] + 2;
            heapHipotetica[blocoAUX - 1] = tamNovo;
            heapHipotetica[bloco - 1] = 0; // "Merge"
        } 
    }
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
        brk = brk + num_bytes + 2;
        alocaBloco(2, num_bytes);
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
            int guarda = brk;
            brk = brk + num_bytes + 2; 
            alocaBloco(guarda + 2, num_bytes); // + 3 pois quero ignorar o ultimo espaco do ultimo bloco
        }
    }
    return enderecoInicialBusca;
}

void imprimeMapa() {
    //printf("\n COMECANDO MAPA NUMERO %d \n ", chamada); // DEBUGACAO DE ALUNO
    int flag, num_bytesAtual;
    char positividade;
    int enderecoAtual = topoInicialHeap + 2 ; // iniciamos no bloco do topo sempre
    int i;
    
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
            i = 0;
            while (i < num_bytesAtual) {
                printf("%c", positividade);
                i = i + 1;
            }
            // for (int i = 0; i < num_bytesAtual; i++) {
            //     printf("%c", positividade);
            // }
            enderecoAtual = enderecoAtual + num_bytesAtual + 2; // + 2 para pularmos o controle da frente
        }
    }
    else  {
        printf("Heap Vazia");
    }
    printf("\n");
}

int main() {
    printf("\n API de Heap por Mihael Scofield e Vinicius Oliveira \n");

/*
    int a, b;
    iniciaAlocador();
    imprimeMapa(0);

    a = alocaMem(10);
    imprimeMapa(1);

    b = alocaMem(5);
    imprimeMapa(2);

    int c = alocaMem(1);
    imprimeMapa(3);

    liberaMem(a);
    imprimeMapa(4);

    liberaMem(c);
    imprimeMapa(5);

    liberaMem(b);
    imprimeMapa(6);

    printf("\n");
    finalizaAlocador();*/

    int a,b,c,d,e;

  iniciaAlocador(); 
  imprimeMapa();
  // 0) estado inicial

  a= alocaMem(100);
  imprimeMapa();
  b= alocaMem(130);
  imprimeMapa();
  c= alocaMem(120);
  imprimeMapa();
  d= alocaMem(110);
  imprimeMapa();
  // 1) Espero ver quatro segmentos ocupados

  liberaMem(b);
  imprimeMapa(); 
  liberaMem(d);
  imprimeMapa(); 
  // 2) Espero ver quatro segmentos alternando
  //    ocupados e livres

  b= alocaMem(50);
  imprimeMapa();
  d= alocaMem(90);
  imprimeMapa();
  e= alocaMem(40);
  imprimeMapa();
  // 3) Deduzam
	
  liberaMem(c);
  imprimeMapa(); 
  liberaMem(a);
  imprimeMapa();
  liberaMem(b);
  imprimeMapa();
  liberaMem(d);
  imprimeMapa();
  liberaMem(e);
  imprimeMapa();
   // 4) volta ao estado inicial

  finalizaAlocador();
}