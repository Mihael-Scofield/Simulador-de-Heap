# Mihael Scofield de Azevedo - msa18 - GRR20182621
# Vinicius Oliveira de Santos - vods18 - ?????????????????

.section .data
    topoInicialHeap: .quad 0
    enderecoInicialBusca: .quad 0
    enderecoBusca: .quad 0
    str1: .string "\n Valor da BRK: %p \n"
    
.section .text
.globl iniciaAlocador
.globl finalizaAlocador
.globl liberaMem
.globl alocaMem
.globl imprimeMapa

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
# tam_novo      : -8(%rsp)
# num_bytesAUX  : -16(%rsp)
# blocoAUX      : -24(%rsp)
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
    movq %rax, -8(%rsp)     # // tamNovo = heapHipotetica[bloco -1];
    subq $16, %rsp          # // int num_bytesAUX
    movq %rax, -16(%rsp)    # // num_bytesAUX = heapHipotetica[bloco - 1];
    subq $24, %rsp          # // int blocoAUX
    movq 8(%rbp), %rax       # %rax = bloco
    addq -16(%rsp), %rax     # %rax = %rax + num_bytesAUX
    addq $2, %rax           # %rax = %rax + 2
    movq %rax, -24(%rsp)    # // blocoAUX = bloco + num_bytesAUX + 2
    movq $12, %rax          
    movq $0, %rdi           
    syscall                 
    cmpq -24(%rsp), %rax
    jg segundoCasoLiberaMem # // blocoAUX >= brk
    movq -24(%rsp), %rax    # %rax = blocoAUX
    subq $16, %rax          # pega o endereco da variavel de "liberdade" do blocoAUX, 2 enderecos abaixo
    movq $0, %rbx
    cmpq (%rax), %rbx       
    jne segundoCasoLiberaMem # // heapHipotetica[blocoAUX - 2] != 0)
    movq -24(%rsp), %rax
    subq $8, %rax           # %rax = blocoAUX - 1 endereco
    addq $2, (%rax)         # heapHipotetica[blocoAUX - 1] + 2
    movq (%rax), %rbx
    addq %rbx, -8(%rsp)    # // tamNovo = tamNovo + heapHipotetica[blocoAUX - 1] + 2
    movq -24(%rsp), %rax
    subq $8, %rax
    movq $0, %rax           # // heapHipotetica[blocoAUX - 1] = 0; // "Merge"
    jmp segundoCasoLiberaMem
## segundo caso, olhamos o bloco de tras
segundoCasoLiberaMem:
    movq 8(%rbp), %rax
    subq $8, %rax
    movq -8(%rsp), %rax     # // heapHipotetica[bloco - 1] = tamNovo;
    ## // naturalmente, so comecamos isso se nao estivermos ja no bloco inicial
    movq topoInicialHeap, %rax
    addq $2, %rax
    cmpq 8(%rbp), %rax 
    je fimLiberaMem         # // bloco == topoInicialHeap + 2
    ## como nao sei como chegar la, comecemos do inicio e andamos ate esbarrar no atual
    movq %rax, -24(%rsp)    # // blocoAUX = topoInicialHeap + 2;
    jmp whileLiberaMem
whileLiberaMem:
    movq -24(%rsp), %rax    # %rax = blocoAUX
    subq $8, %rax           # %rax = blocoAUX - 1byte
    movq %rax, -16(%rsp)  # // num_bytesAUX = heapHipotetica[blocoAUX - 1];
    addq $2, -16(%rsp)      # num_bytesAUX = num_bytesAUX + 2
    movq -16(%rsp), %rax
    addq %rax, -24(%rsp)    # // blocoAUX = blocoAUX + num_bytesAUX + 2; 
    movq -24(%rsp), %rax
    cmpq %rax, 8(%rbp)
    jne whileLiberaMem      # // while(blocoAUX != bloco)
    # fora do whileLiberaMem
    # quero voltar para o bloco anterior
    movq -16(%rsp), %rax
    addq $2, %rax           # // num_bytesAUX + 2
    subq %rax, -24(%rsp)    # // blocoAUX = blocoAUX - (num_bytesAUX + 2);
    movq -24(%rsp), %rax
    subq $16, %rax          # blocoAUX - 2 bytes
    movq $0, %rbx
    cmpq %rax, %rbx         
    jne fimLiberaMem        # // heapHipotetica[blocoAUX - 2] != 0
    # // caso o bloco anterior esteja livre, ele se torna o "bloco" referencia
    movq -24(%rsp), %rax
    subq $8, %rax
    movq (%rax), %rax
    addq $16, %rax
    addq %rax, -8(%rsp)     # // tamNovo = tamNovo + heapHipotetica[blocoAUX - 1] + 2;
    movq -24(%rsp), %rax
    subq $8, %rax
    movq -8(%rsp), %rax   # // heapHipotetica[blocoAUX - 1] = tamNovo;
    movq 8(%rbp), %rax
    subq $8, %rax
    movq $0, (%rax)         # // "Merge"
    jmp fimLiberaMem
## Como todo fim de procedimento indica, devemos fazer o seguinte
fimLiberaMem:   
    addq $24, %rsp # libera a memoria alocada na stack para as variaveis locais
    popq %rbp
    ret


## 1. Procura um bloco livre com tamanho maximo maior ou igual a num_bytes
## 2. Se encontrar, indica que o bloco esta ocupado e retorna o endereco inicial do bloco
## 3. Se nao encontrar, abre espaco para um novo bloco usando syscall brk, indica que o bloco esta ocupado, e retorna o endereco inicial do bloco
## viud& alocamMem(int num_bytes)
alocaMem:
    ## Como todo inicio de procedimento indica, devemos fazer o seguinte
    pushq %rbp
    movq %rsp, %rbp



    ## Como todo fim de procedimento indica, devemos fazer o seguinte
    popq %rbp
    ret


## imprime um mapa da memoria da regiao da heap.
## Cada byte da parte gerencial do no eh impresso com "#"
## Se o bloco estiver livre, imprime os caracteres dele com "-", caso contrario, com "+"
imprimeMapa:
    ## Como todo inicio de procedimento indica, devemos fazer o seguinte
    pushq %rbp
    movq %rsp, %rbp



    ## Como todo fim de procedimento indica, devemos fazer o seguinte
    popq %rbp
    ret



###################################
#       Cemitério de ideias       #
###################################

# movq $str1, %rdi
# movq topoInicialHeap, %rsi
# call printf
