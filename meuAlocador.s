# Mihael Scofield de Azevedo - msa18 - GRR20182621
# Vinicius Oliveira de Santos - vods18 - ?????????????????

.section .data
    topoInicialHeap: .quad 0
    enderecoInicialBusca: .quad 0
    enderecoBusca: .quad 0
    str1: .string "\n Valor da BRK: %p \n"
    str2: .string "\n heap vazia \n"
    str3: .string "-"
    str4: .string "+"
    str5: .string "##"
    str6: .string "%c"
    
.section .text
.globl iniciaAlocador
.globl finalizaAlocador
.globl liberaMem
.globl alocaMem
.globl imprimeMapa
.globl busca
.globl alocaBloco

## Executa Syscall brk para obter o endereco do topo corrente da heap e o armazena em uma variavel global, topoInicialHeap
iniciaAlocador:
    ## Como todo inicio de procedimento indica, devemos fazer o seguinte
    pushq %rbp          # empilha %rbp
    movq %rsp, %rbp     # faz %rbp apontar para novo RA
    # Aqui entraria o subq $valor, %rsp para as variaveis
    
    ## Encontremos nossa brk
    movq $12, %rax             # indicar que usaremos syscall brk
    movq $0, %rdi              # Para garantir que rdi fique zerada
    syscall                    # Como %rdi esta zerada, %rax agora possui o endereco da brk
    movq %rax, topoInicialHeap # topoInicialHeap = brk;           
    
    ## Como todo fim de procedimento indica, devemos fazer o seguinte
    # Aqui entraria addq $valor, %rsp, para liberar os espacos alocados de variaveis
    popq %rbp
    ret

## Executa Syscall brk para restaurar o valor original da heap contido em topoInicialHeap
finalizaAlocador:
    ## Como todo inicio de procedimento indica, devemos fazer o seguinte
    pushq %rbp
    movq %rsp, %rbp

    ## Resetando a brk
    movq $12, %rax   
    movq topoInicialHeap, %rdi # seta heap no valor de topoInicialHeap
    syscall     

    ## Como todo fim de procedimento indica, devemos fazer o seguinte
    popq %rbp
    ret

## Indica que o bloco esta livre
## liberaMem(void* bloco)
# bloco         : 8(%rbp)
# tam_novo      : -8(%rbp)
# num_bytesAUX  : -16(%rbp)
# blocoAUX      : -24(%rbp)
liberaMem:
    ## Como todo inicio de procedimento indica, devemos fazer o seguinte
    pushq %rbp
    movq %rsp, %rbp

    ## Liberacao propriamente dita
    movq 8(%rbp), %rax      # %rax = void* bloco
    subq $16, %rax          # Volta 2 enderecos, isto eh, 16 bytes com rax
    movq $0, (%rax)         # libera o bloco

    ## Verificacao para juncao de blocos livres
    ## primeiro caso, olhar apenas o bloco da frente
    subq $8, %rsp           # // int tamNovo; 
    movq 8(%rbp), %rax
    subq $8, %rax           # // Pega endereco heapHipotetica[bloco - 1]
    movq %rax, -8(%rbp)     # // tamNovo = heapHipotetica[bloco -1];
    subq $16, %rsp          # // int num_bytesAUX
    movq %rax, -16(%rbp)    # // num_bytesAUX = heapHipotetica[bloco - 1];
    subq $24, %rsp          # // int blocoAUX
    movq 8(%rbp), %rax       # %rax = bloco
    addq -16(%rbp), %rax     # %rax = %rax + num_bytesAUX
    addq $2, %rax           # %rax = %rax + 2
    movq %rax, -24(%rbp)    # // blocoAUX = bloco + num_bytesAUX + 2
    movq $12, %rax          
    movq $0, %rdi           
    syscall                 
    cmpq -24(%rbp), %rax
    jg segundoCasoLiberaMem # // blocoAUX >= brk
    movq -24(%rbp), %rax    # %rax = blocoAUX
    subq $16, %rax          # pega o endereco da variavel de "liberdade" do blocoAUX, 2 enderecos abaixo
    movq $0, %rbx
    cmpq (%rax), %rbx       
    jne segundoCasoLiberaMem # // heapHipotetica[blocoAUX - 2] != 0)
    movq -24(%rbp), %rax
    subq $8, %rax           # %rax = blocoAUX - 1 endereco
    addq $2, (%rax)         # heapHipotetica[blocoAUX - 1] + 2
    movq (%rax), %rbx
    addq %rbx, -8(%rbp)    # // tamNovo = tamNovo + heapHipotetica[blocoAUX - 1] + 2
    movq -24(%rbp), %rax
    subq $8, %rax
    movq $0, %rax           # // heapHipotetica[blocoAUX - 1] = 0; // "Merge"
    jmp segundoCasoLiberaMem
## segundo caso, olhamos o bloco de tras
segundoCasoLiberaMem:
    movq 8(%rbp), %rax
    subq $8, %rax
    movq -8(%rbp), %rax     # // heapHipotetica[bloco - 1] = tamNovo;
    ## // naturalmente, so comecamos isso se nao estivermos ja no bloco inicial
    movq topoInicialHeap, %rax
    addq $2, %rax
    cmpq 8(%rbp), %rax 
    je fimLiberaMem         # // bloco == topoInicialHeap + 2
    ## como nao sei como chegar la, comecemos do inicio e andamos ate esbarrar no atual
    movq %rax, -24(%rbp)    # // blocoAUX = topoInicialHeap + 2;
    jmp whileLiberaMem
whileLiberaMem:
    movq -24(%rbp), %rax    # %rax = blocoAUX
    subq $8, %rax           # %rax = blocoAUX - 1byte
    movq %rax, -16(%rbp)  # // num_bytesAUX = heapHipotetica[blocoAUX - 1];
    addq $2, -16(%rbp)      # num_bytesAUX = num_bytesAUX + 2
    movq -16(%rbp), %rax
    addq %rax, -24(%rbp)    # // blocoAUX = blocoAUX + num_bytesAUX + 2; 
    movq -24(%rbp), %rax
    cmpq %rax, 8(%rbp)
    jne whileLiberaMem      # // while(blocoAUX != bloco)
    # fora do whileLiberaMem
    # quero voltar para o bloco anterior
    movq -16(%rbp), %rax
    addq $2, %rax           # // num_bytesAUX + 2
    subq %rax, -24(%rbp)    # // blocoAUX = blocoAUX - (num_bytesAUX + 2);
    movq -24(%rbp), %rax
    subq $16, %rax          # blocoAUX - 2 bytes
    movq $0, %rbx
    cmpq %rax, %rbx         
    jne fimLiberaMem        # // heapHipotetica[blocoAUX - 2] != 0
    # // caso o bloco anterior esteja livre, ele se torna o "bloco" referencia
    movq -24(%rbp), %rax
    subq $8, %rax
    movq (%rax), %rax
    addq $16, %rax
    addq %rax, -8(%rbp)     # // tamNovo = tamNovo + heapHipotetica[blocoAUX - 1] + 2;
    movq -24(%rbp), %rax
    subq $8, %rax
    movq -8(%rbp), %rax   # // heapHipotetica[blocoAUX - 1] = tamNovo;
    movq 8(%rbp), %rax
    subq $8, %rax
    movq $0, (%rax)         # // "Merge"
    jmp fimLiberaMem
## Como todo fim de procedimento indica, devemos fazer o seguinte
fimLiberaMem:   
    addq $24, %rsp # libera a memoria alocada na stack para as variaveis locais
    popq %rbp
    ret



## Busca bloco para alocacao
## int busca(int num_bytes)
# num_bytes     : 8(%rbp)
# flag          : -8(%rbp)
# num_bytesAUX  : -16(%rbp)
busca:
    ## Como todo inicio de procedimento indica, devemos fazer o seguinte
    pushq %rbp
    movq %rsp, %rbp

    ## Inicio da funcao
    subq $8, %rsp          # // int flag = 0;
    subq $16, %rsp         # // int num_bytesAUX;
    movq enderecoInicialBusca, %rax
    movq %rax, enderecoBusca
    jmp whileBusca
whileBusca:
    ## /* Pula para proximo bloco */
    movq endereco, %rax
    subq $8, %rax
    movq (%rax), %rax
    movq -16(%rbp), %rax   # // num_bytesAUX = heapHipotetica[enderecoBusca - 1]; // pega a quantidade de indices a pular
    movq enderecoBusca, %rax
    movq -16(%rbp), %rbx
    addq %rbx, %rax        
    addq $16, %rax
    movq %rax, enderecoBusca # // enderecoBusca = enderecoBusca + num_bytesAUX + 2;

    # /* Verifica se deve voltar ao inicio */
    movq $12, %rax          
    movq $0, %rdi           
    syscall
    cmpq enderecoBusca, %rax
    jle ifWhileBusca1
    movq topoInicialHeap, %rax
    addq $16, %rax
    movq %rax, enderecoBusca
    jmp elseWhileBusca1
elseWhileBusca1:
    ## /* Investiga bloco atual */
    # // Verifica se bloco atual esta livre, reaproveitando num_bytes
    movq enderecoBusca, %rax
    subq $16, %rax
    movq (%rax), %rax
    movq $0, %rbx
    cmpq %rax, %rbx
    jne elseWhileBusca2     # // if(heapHipotetica[enderecoBusca - 2] == 0) { // Bloco atual esta livre
    movq enderecoBusca, %rax
    subq $8, %rax
    movq(%rax), %rax
    movq %rax, -16(%rbp)    # // num_bytesAUX = heapHipotetica[enderecoBusca - 1];
    movq 8(rbp), %rax
    movq -16(rsp), %rbp
    cmpq %rax, %rbp
    jge elseWhileBusca2     # // if (num_bytes <= num_bytesAUX)
    movq $1, -8(%rbp)       # // flag = 1
    jmp elseWhileBusca2
elseWhileBusca2:
    movq -8(%rbp), %rax
    movq $0, %rbx
    cmpq %rax, %rbx
    je andWhileBusca:       # // if (flag == 0)
    jmp whileBusca
andWhileBusca:
    movq enderecoBusca, %rax
    movq enderecoInicialBusca, %rbx
    cmpq %rax, %rbx
    je fimWhileBusca        # // if (enderecoBusca == enderecoInicialBusca)
    jmp whileBusca          # Condicao do while nao foi satisfeita, volta para cima
fimWhileBusca:
    movq -8(%rbp), %rax
    movq $0, %rbx
    cmpq %rax, %rbx
    je fimBusca             # if (flag == 0)
    movq enderecoBusca, %rax
    movq enderecoInicialBusca, %rbx
    cmpq %rax, %rbx
    je fimBusca             # // if (enderecoBusca == enderecoInicialBusca)
    movq $0, enderecoBusca # // return 0
    jmp fimBusca
fimBusca:
    ## Como todo fim de procedimento indica, devemos fazer o seguinte
    movq enderecoBusca, %rax
    addq $16, %rsp
    popq %rbp
    ret


## Aloca um bloco na memoria
## int alocaBloco(int enderecoBloco, int num_bytes)
# enderecoBloco : 8(%rbp)
# num_bytes     : 16(%rbp)
alocaBloco:
    ## Como todo inicio de procedimento indica, devemos fazer o seguinte
    pushq %rbp
    movq %rsp, %rbp

    ## Funcao propriamente dita
    movq 8(%rbp), %rax
    subq $16, %rax
    movq (%rax), %rax
    movq $1, %rax # // heapHipotetica[enderecoBloco - 2] = 1;
    movq 8(%rbp), %rax
    subq $8, %rax
    movq (%rax), %rax
    movq 16(%rbp), %rbx
    movq %rbx, %rax # // heapHipotetica[enderecoBloco - 1] = num_bytes;
    movq enderecoBloco, %rax
    movq %rax, enderecoInicialBusca # // enderecoInicialBusca = enderecoBloco;
## Como todo fim de procedimento indica, devemos fazer o seguinte
    popq %rbp
    ret 

## 1. Procura um bloco livre com tamanho maximo maior ou igual a num_bytes
## 2. Se encontrar, indica que o bloco esta ocupado e retorna o endereco inicial do bloco
## 3. Se nao encontrar, abre espaco para um novo bloco usando syscall brk, indica que o bloco esta ocupado, e retorna o endereco inicial do bloco
## viud& alocamMem(int num_bytes)
# num_byte           : 8(%rbp)
# novoEndereco       : -8(%rbp)
# num_bytesAUX       : -16(%rbp)
alocaMem:
    ## Como todo inicio de procedimento indica, devemos fazer o seguinte
    
    pushq %rbp
    movq %rsp, %rbp
    movq $12, %rax          
    movq $0, %rdi           
    syscall
    movq topoInicialHeap, %rbx
    cmpq %rax, %rbx
    je ifAlocaMem1 # // if(brk == topoInicialHeap)
    jmp continuaAlocaMem # // else
ifAlocaMem1:
    movq $12, %rax # inversao do codigo para nao dar segfault          
    movq $0, %rdi 
    syscall
    movq 8(%rbp), %rbx
    addq $16, %rbx
    addq %rax, %rbx
    movq %rbx, %rcx # //brk = brk + num_bytes + 2
    pushq $16 # empilha parametro 2
    pushq 8(%rbp) # empilha parametro num_bytes
    call alocaBloco # // alocaBloco(2, num_bytes)
    addq $8, %rsp # libera espaco dos parametros
    movq $12, %rax          
    movq %rcx, %rdi 
    syscall
continuaAlocaMem:
    pushq 8(%rbp) 
    call busca
    addq $8, %rsp # desempilha
    subq $8, %rsp 
    movq %rax, -8(%rbp) # // int novoEndereco = busca(num_bytes)
    movq $0, %rax
    cmpq -8(%rbp), %rax # // if (novoEndereco == 0)
    je elseAlocaMem1
    subq $8, %rsp
    movq -8(%rbp), %rax
    subq $8, %rax
    movq (%rax), rax
    movq %rax, -16(%rbp) # // int num_bytesAUX = heapHipotetica[novoEndereco - 1]
    pushq -8(%rbp)
    pushq 8(%rbp)
    call alocaBloco # // alocaBloco(novoEndereco, num_bytes)
    addq $16, %rsp
    movq -16(%rbp), %rax
    cmpq %rax, 8(%rbp)
    je fimAlocaMem # // if(num_bytesAUX != num_bytes)



elseAlocaMem1:
    movq $12, %rax # inversao do codigo para nao dar segfault          
    movq $0, %rdi 
    syscall
    movq 8(%rbp), %rbx
    addq $16, %rbx
    addq %rax, %rbx
    movq %rbx, %rcx # //brk = brk + num_bytes + 2
    movq $12, %rax # inversao do codigo para nao dar segfault          
    movq $0, %rdi 
    syscall
    pushq %rax
    pushq 8(%rbp)
    call alocaBloco # // alocaBloco(brk + 2, num_bytes)
    addq $16, %rsp # desempilha
    jmp fimAlocaMem 

    ## Como todo fim de procedimento indica, devemos fazer o seguinte
fimAlocaMem:
    addq $8, %rsp # ******************ALOCAR NO COMEÇO BOIOLA
    movq enderecoInicialBusca, %rax
    popq %rbp
    ret


## imprime um mapa da memoria da regiao da heap.
## Cada byte da parte gerencial do no eh impresso com "#"
## Se o bloco estiver livre, imprime os caracteres dele com "-", caso contrario, com "+"
# flag           : -8(%rbp)
# num_bytesAtual : -16(%rbp)
# positividade   : -24(%rbp)
# enderecoAtual  : -32(%rbp)
# i              : -40(%rbp)
imprimeMapa:
    ## Como todo inicio de procedimento indica, devemos fazer o seguinte
    pushq %rbp
    movq %rsp, %rbp

    ## Funcao propriamente dita
    subq $32, %rsp
    movq topoInicialHeap, %rax
    addq $16, %rax
    movq %rax, -32(%rbp)        # // enderecoAtual = topoInicialHeap + 2
    movq $12, %rax
    movq $0, %rdi           
    syscall
    movq $0, %rbx
    cmpq %rax, %rbx
    je elseImprimeMapa1         # // if (brk == 0)
    jmp whileImprimeMapa1
whileImprimeMapa1:
    movq -32(%rbp), %rax
    subq $16, %rax
    movq (%rax), %rax
    movq %rax, -8(%rbp)         # // flag = heapHipotetica[enderecoAtual - 2];
    movq $0, %rax
    cmpq -8(%rbp), %rax
    je ifNegativoImpimeMapa     # // if (flag == 0)
    jmp ifPositivoImprimeMapa   # esse eh o else, caso flag == 1

ifNegativoImpimeMapa:
    movq str3, movq -24(%rbp)   # // positividade = '-';
    jmp continuacaoImprimeMapa:
ifPositivoImprimeMapa:
    movq str4, movq -24(%rbp)
    jmp continuacaoImprimeMapa: # // positividade = '+';

continuacaoImprimeMapa:
    movq -32(%rbp), %rax
    subq $8, %rax
    movq (%rax), %rax
    movq %rax, -16(%rbp)        # // num_bytesAtual = heapHipotetica[enderecoAtual - 1];
    movq %str1, %rdi            # // printf("##")
    call printf
    movq $0, %rax
    movq %rax, -40(%rbp)        # // i = 0;    
    jmp whileImprimeMapa2
whileImprimeMapa2:
    movq $str6, %rdi
    movq -24(%rbp), %rsi
    call printf                 # // printf ("%c", positividade);
    movq $1, %rax
    addq %rax, -40(%rbp)
    movq -40(%rbp), %rax
    movq -32(%rbp), %rbx
    cmpq %rax, %rbx
    jl whileImprimeMapa2        # // if(i < num_bytesAtual)
    jmp fimWhileImprimeMapa2
fimWhileImprimeMapa2:
    movq -32(%rbp), %rax
    movq -16(%rbp), %rbx
    movq $16, %rcx
    addq %rax, %rcx
    addq %rbx, %rcx
    movq %rcx, -32(%rbp) // enderecoAtual = enderecoAtual + num_bytesAtual + 2; // + 2 para pularmos o controle da frente
    movq -32(%rbp), %rbx
    movq $12, %rax          
    movq $0, %rdi           
    syscall
    cmpq %rbx, %rax
    jl whileImprimeMapa1 # // if enderecoAtual < brk
    jmp finalImprimeMapa  

elseImprimeMapa1:
    movq $str2, %rdi
    call printf
    jmp finalImprimeMapa
    
    ## Como todo fim de procedimento indica, devemos fazer o seguinte
finalImprimeMapa:
    addq $40, %rsp
    popq %rbp
    ret



###################################
#       Cemitério de ideias       #
###################################

# movq $str1, %rdi
# movq topoInicialHeap, %rsi
# call printf
