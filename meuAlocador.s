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
    str7: .string "\n API de Heap por Mihael Scofield e Vinicius Oliveira \n"

.macro output string_pointer
movq $1, %rax
movq $1, %rdi
movq \string_pointer, %rsi
movq $1, %rdx
syscall
.endm



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

    # movq $str7, %rdi
    # call printf
    output $str7
    
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
# bloco         : 16(%rbp)
# tam_novo      : -8(%rbp)
# num_bytesAUX  : -16(%rbp)
# blocoAUX      : -24(%rbp)
# bloco         : -32(%rbp)
liberaMem:
    ## Como todo inicio de procedimento indica, devemos fazer o seguinte
    pushq %rbp
    movq %rsp, %rbp
    subq $32, %rsp
    movq %rdi, -32(%rbp)

    ## Liberacao propriamente dita
    movq -32(%rbp), %rax      # %rax = void* bloco
    subq $16, %rax          # Volta 2 enderecos, isto eh, 16 bytes com rax
    movq $0, (%rax)         # libera o bloco

    ## Verificacao para juncao de blocos livres
    ## primeiro caso, olhar apenas o bloco da frente
    movq -32(%rbp), %rax
    subq $8, %rax           # // Pega endereco heapHipotetica[bloco - 1]
    movq (%rax), %rax
    movq %rax, -8(%rbp)     # // tamNovo = heapHipotetica[bloco -1];
    movq %rax, -16(%rbp)    # // num_bytesAUX = heapHipotetica[bloco - 1];
    movq -32(%rbp), %rax      # %rax = bloco
    addq -16(%rbp), %rax    # %rax = %rax + num_bytesAUX
    addq $16, %rax          # %rax = %rax + 2 enderecos
    movq %rax, -24(%rbp)    # // blocoAUX = bloco + num_bytesAUX + 2
    movq $12, %rax          
    movq $0, %rdi           
    syscall                 
    cmpq %rax, -24(%rbp)
    jge segundoCasoLiberaMem # // blocoAUX >= brk
    movq -24(%rbp), %rax    # %rax = blocoAUX
    subq $16, %rax          # pega o endereco da variavel de "liberdade" do blocoAUX, 2 enderecos atras
    movq $0, %rbx
    cmpq %rbx, (%rax)
    jne segundoCasoLiberaMem # // heapHipotetica[blocoAUX - 2] != 0)
    movq -24(%rbp), %rax
    subq $8, %rax           # %rax = blocoAUX - 1 endereco
    addq $16, (%rax)         # heapHipotetica[blocoAUX - 1] + 2 enderecos
    movq (%rax), %rbx
    addq %rbx, -8(%rbp)    # // tamNovo = tamNovo + heapHipotetica[blocoAUX - 1] + 2
    movq -24(%rbp), %rax
    subq $8, %rax
    movq $0, (%rax)           # // heapHipotetica[blocoAUX - 1] = 0; // "Merge"
    jmp segundoCasoLiberaMem
## segundo caso, olhamos o bloco de tras
segundoCasoLiberaMem:
    movq -32(%rbp), %rax
    subq $8, %rax
    movq -8(%rbp), %rbx     # // heapHipotetica[bloco - 1] = tamNovo;
    movq %rbx, (%rax)
    ## // naturalmente, so comecamos isso se nao estivermos ja no bloco inicial
    movq topoInicialHeap, %rax
    addq $16, %rax
    cmpq %rax, -32(%rbp)
    je fimLiberaMem         # // bloco == topoInicialHeap + 2
    ## como nao sei como chegar la, comecemos do inicio e andamos ate esbarrar no atual
    movq %rax, -24(%rbp)    # // blocoAUX = topoInicialHeap + 2;
    jmp whileLiberaMem
whileLiberaMem:
    movq -24(%rbp), %rax    # %rax = blocoAUX
    subq $8, %rax           # %rax = blocoAUX - 1byte
    movq (%rax), %rbx
    movq %rbx, -16(%rbp)  # // num_bytesAUX = heapHipotetica[blocoAUX - 1];
    addq $16, -16(%rbp)     # num_bytesAUX = num_bytesAUX + 2
    movq -16(%rbp), %rax
    addq %rax, -24(%rbp)    # // blocoAUX = blocoAUX + num_bytesAUX + 2; 
    movq -24(%rbp), %rax
    cmpq -32(%rbp), %rax
    jne whileLiberaMem      # // while(blocoAUX != bloco)
    # fora do whileLiberaMem
    # quero voltar para o bloco anterior
    movq -16(%rbp), %rax
    addq $16, %rax           # // num_bytesAUX + 2
    subq %rax, -24(%rbp)    # // blocoAUX = blocoAUX - (num_bytesAUX + 2);
    movq -24(%rbp), %rax
    subq $16, %rax          # blocoAUX - 2 bytes
    movq (%rax), %rax
    movq $0, %rbx
    cmpq %rbx, %rax     
    jne fimLiberaMem        # // heapHipotetica[blocoAUX - 2] != 0
    # // caso o bloco anterior esteja livre, ele se torna o "bloco" referencia
    movq -24(%rbp), %rax
    subq $8, %rax
    movq (%rax), %rax
    addq $16, %rax
    addq %rax, -8(%rbp)     # // tamNovo = tamNovo + heapHipotetica[blocoAUX - 1] + 2;
    movq -24(%rbp), %rax
    subq $8, %rax
    movq -8(%rbp), %rbx
    movq %rbx, (%rax)   # // heapHipotetica[blocoAUX - 1] = tamNovo;
    movq -32(%rbp), %rax
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
# num_bytes     : 16(%rbp)
# flag          : -8(%rbp)
# num_bytesAUX  : -16(%rbp)
busca:
    ## Como todo inicio de procedimento indica, devemos fazer o seguinte
    pushq %rbp
    movq %rsp, %rbp

    ## Inicio da funcao
    subq $16, %rsp         # // int num_bytesAUX;
    movq enderecoInicialBusca, %rax
    movq %rax, enderecoBusca
    jmp whileBusca
whileBusca:
    ## /* Pula para proximo bloco */
    movq enderecoBusca, %rax # -------mudei aki para enderecoBusca
    subq $8, %rax
    movq (%rax), %rax
    movq %rax, -16(%rbp)   # // num_bytesAUX = heapHipotetica[enderecoBusca - 1]; // pega a quantidade de indices a pular
    movq enderecoBusca, %rax
    movq -16(%rbp), %rbx
    addq %rbx, %rax        
    addq $16, %rax
    movq %rax, enderecoBusca # // enderecoBusca = enderecoBusca + num_bytesAUX + 2;

    # /* Verifica se deve voltar ao inicio */
    movq $12, %rax          
    movq $0, %rdi           
    syscall
    cmpq %rax, enderecoBusca
    jle elseWhileBusca1    # // if(enderecoBusca <= brk)
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
    cmpq %rbx, %rax
    jne elseWhileBusca2     # // if(heapHipotetica[enderecoBusca - 2] == 0) { // Bloco atual esta livre
    movq enderecoBusca, %rax
    subq $8, %rax
    movq (%rax), %rax # --mudei aki
    movq %rax, -16(%rbp)    # // num_bytesAUX = heapHipotetica[enderecoBusca - 1];
    movq 16(%rbp), %rax # -----mudei aki
    movq -16(%rsp), %rbp # -----mudei aki
    cmpq %rbx, %rax
    jge elseWhileBusca2     # // if (num_bytes >= num_bytesAUX)
    movq $1, -8(%rbp)       # // flag = 1
    jmp elseWhileBusca2
elseWhileBusca2:
    movq -8(%rbp), %rax
    movq $0, %rbx
    cmpq %rbx, %rax
    je andWhileBusca       # // if (flag == 0) -----mudei aki
    jmp whileBusca
andWhileBusca:
    movq enderecoBusca, %rax
    movq enderecoInicialBusca, %rbx
    cmpq %rbx, %rax
    je fimWhileBusca        # // if (enderecoBusca == enderecoInicialBusca)
    jmp whileBusca          # Condicao do while nao foi satisfeita, volta para cima
fimWhileBusca:
    movq -8(%rbp), %rax
    movq $0, %rbx
    cmpq %rbx, %rax
    je fimBuscaRet0     # if (flag == 0)
    movq enderecoBusca, %rax
    movq enderecoInicialBusca, %rbx
    cmpq %rbx, %rax
    je fimBuscaRet0             # // if (enderecoBusca == enderecoInicialBusca)
    jmp fimBusca
fimBuscaRet0:
    movq $0, enderecoBusca
    jmp fimBusca
fimBusca:
    ## Como todo fim de procedimento indica, devemos fazer o seguinte
    movq enderecoBusca, %rax # return enderecoBusca
    addq $16, %rsp
    popq %rbp
    ret


## Aloca um bloco na memoria
## int alocaBloco(int enderecoBloco, int num_bytes)
# enderecoBloco : 24(%rbp)
# num_bytes     : 16(%rbp)
alocaBloco:
    ## Como todo inicio de procedimento indica, devemos fazer o seguinte
    pushq %rbp
    movq %rsp, %rbp

    ## Funcao propriamente dita
    movq 24(%rbp), %rax
    subq $16, %rax
    
    # movq (%rax), %rax
    movq $1, (%rax) # // heapHipotetica[enderecoBloco - 2] = 1;
    movq 24(%rbp), %rax
    subq $8, %rax
    # movq (%rax), %rax
    movq 16(%rbp), %rbx
    movq %rbx, (%rax) # // heapHipotetica[enderecoBloco - 1] = num_bytes;
    movq 24(%rbp), %rax # ----- mudei aki para 24(%rbp)
    movq %rax, enderecoInicialBusca # // enderecoInicialBusca = enderecoBloco;
## Como todo fim de procedimento indica, devemos fazer o seguinte
    popq %rbp
    ret 

## 1. Procura um bloco livre com tamanho maximo maior ou igual a num_bytes
## 2. Se encontrar, indica que o bloco esta ocupado e retorna o endereco inicial do bloco
## 3. Se nao encontrar, abre espaco para um novo bloco usando syscall brk, indica que o bloco esta ocupado, e retorna o endereco inicial do bloco
## viud& alocamMem(int num_bytes)
# novoEndereco       : -8(%rbp)
# num_bytesAUX       : -16(%rbp)
# num_bytes          : -24(%rbp)
alocaMem:
    ## Como todo inicio de procedimento indica, devemos fazer o seguinte    
    pushq %rbp
    movq %rsp, %rbp
    subq $24, %rsp
    movq %rdi, -24(%rbp) # TE ODEIO
    movq $12, %rax          
    movq $0, %rdi           
    syscall
    movq topoInicialHeap, %rbx
    cmpq %rbx, %rax
    je ifAlocaMem1 # // if(brk == topoInicialHeap)
    jmp continuaAlocaMem # // else
ifAlocaMem1:
    movq $12, %rax # inversao do codigo para nao dar segfault          
    movq $0, %rdi
    syscall
    movq -24(%rbp), %rbx
    addq $16, %rbx
    addq %rax, %rbx
    movq %rbx, %rcx # //brk = brk + num_bytes + 2
    movq $12, %rax          
    movq %rcx, %rdi 
    syscall
    movq topoInicialHeap, %rcx
    addq $16, %rcx
    pushq %rcx # empilha o topo + 2
    pushq -24(%rbp) # empilha parametro num_bytes
    call alocaBloco # // alocaBloco(2, num_bytes)
    addq $16, %rsp # libera espaco dos parametros
    jmp fimAlocaMem
    
continuaAlocaMem:
    pushq -24(%rbp) 
    call busca
    addq $8, %rsp # desempilha
    movq %rax, -8(%rbp) # // int novoEndereco = busca(num_bytes)
    movq $0, %rax
    cmpq %rax, -8(%rbp) # // if (novoEndereco == 0)
    je elseAlocaMem1
    movq -8(%rbp), %rax
    subq $8, %rax
    movq (%rax), %rax # --------mudei aki
    movq %rax, -16(%rbp) # // int num_bytesAUX = heapHipotetica[novoEndereco - 1]
    pushq -8(%rbp)
    pushq -24(%rbp)
    call alocaBloco # // alocaBloco(novoEndereco, num_bytes)
    addq $16, %rsp
    movq -16(%rbp), %rax
    cmpq -24(%rbp), %rax
    je fimAlocaMem # // if(num_bytesAUX == num_bytes)
    movq -16(%rbp), %rax
    addq $16, %rax
    addq -8(%rbp), %rax
    pushq %rax
    movq -16(%rbp), %rax
    subq -24(%rbp), %rax
    pushq %rax
    call alocaBloco
    addq $16, %rsp
    jmp fimAlocaMem

elseAlocaMem1:
    movq $12, %rax # inversao do codigo para nao dar segfault          
    movq $0, %rdi 
    syscall
    movq -24(%rbp), %rbx
    addq $16, %rbx
    addq %rax, %rbx
    movq %rbx, %rcx # //brk = brk + num_bytes + 2
    movq $12, %rax          
    movq %rcx, %rdi 
    syscall
    pushq %rax
    pushq -24(%rbp)
    call alocaBloco # // alocaBloco(brk + 2, num_bytes)
    addq $16, %rsp # desempilha
    jmp fimAlocaMem 

    ## Como todo fim de procedimento indica, devemos fazer o seguinte
fimAlocaMem:
    movq enderecoInicialBusca, %rax
    addq $24, %rsp
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
    subq $40, %rsp
    movq topoInicialHeap, %rax
    addq $16, %rax
    movq %rax, -32(%rbp)        # // enderecoAtual = topoInicialHeap + 2
    movq $12, %rax
    movq $0, %rdi           
    syscall
    movq topoInicialHeap, %rbx
    cmpq %rbx, %rax
    je elseImprimeMapa1         # // if (brk == topoInicialHeap), isto eh, ela esta vazia
    jmp whileImprimeMapa1
whileImprimeMapa1:
    movq -32(%rbp), %rax
    subq $16, %rax
    # movq (%rax), %rax
    movq %rax, -8(%rbp)         # // flag = heapHipotetica[enderecoAtual - 2];
    movq $0, (%rax)
    movq -8(%rbp), %rbx
    cmpq %rax, %rbx
    je ifNegativoImpimeMapa     # // if (flag == 0)
    jmp ifPositivoImprimeMapa   # esse eh o else, caso flag == 1

ifNegativoImpimeMapa:
    movq $0, -24(%rbp)   # // positividade = '-'; --------mudei aki (criei temporaria)
    jmp continuacaoImprimeMapa # ------mudei aki
ifPositivoImprimeMapa:
    movq $1, -24(%rbp) # -------mudei aki (criei temporaria)
    jmp continuacaoImprimeMapa # // positividade = '+';   -------mudei aki

continuacaoImprimeMapa:
    movq -32(%rbp), %rax
    subq $8, %rax
    movq (%rax), %rax
    movq %rax, -16(%rbp)        # // num_bytesAtual = heapHipotetica[enderecoAtual - 1];
    movq $0, %rax
    movq %rax, -40(%rbp)        # // i = 0;    
    # movq $str5, %rdi            # // printf("##")
    # call printf
    output $str5
    jmp whileImprimeMapa2
whileImprimeMapa2:
    movq $0, %rax
    cmpq -24(%rbp), %rax
    je imprimeNegativo
    jmp imprimePositivo

imprimeNegativo:
    # movq $str3, %rdi
    # call printf                 # // printf ("%c", positividade);
    output $str3
    jmp whileImprimeMapa3

imprimePositivo:
    # movq $str4, %rdi
    # call printf                 # // printf ("%c", positividade);
    output $str4
    jmp whileImprimeMapa3

whileImprimeMapa3:
    movq $8, %rax
    addq %rax, -40(%rbp)        # // i += 1 endereco
    movq -40(%rbp), %rax
    movq -16(%rbp), %rbx
    cmpq %rbx, %rax
    jl whileImprimeMapa2        # // if(i < num_bytesAtual)
    jmp fimWhileImprimeMapa2
fimWhileImprimeMapa2:
    movq -32(%rbp), %rax
    movq -16(%rbp), %rbx
    movq $16, %rcx
    addq %rax, %rcx
    addq %rbx, %rcx
    movq %rcx, -32(%rbp) # // enderecoAtual = enderecoAtual + num_bytesAtual + 2; // + 2 para pularmos o controle da frente  ------mudei aki
    movq -32(%rbp), %rbx
    movq $12, %rax          
    movq $0, %rdi           
    syscall
    cmpq %rbx, %rax
    jl whileImprimeMapa1 # // if enderecoAtual < brk
    jmp finalImprimeMapa  

elseImprimeMapa1:
    # movq $str2, %rbx
    # movq %rbx, %rdi
    # call printf
    output $str2
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
