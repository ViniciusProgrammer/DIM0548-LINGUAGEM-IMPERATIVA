# DIM0548-LINGUAGEM-IMPERATIVA
Analisador léxico e sintático desenvolvido para a disciplina de **DIM0548 - Engenharia de Linguagens**. O compilador valida a gramática da linguagem imperativa educacional `.edu`, identifica palavras reservadas, tipos, variáveis, operadores e captura erros com mensagens de posição exata (`[L<linha>:C<coluna>]`).

## ⚙️ Pré-requisitos (Linux)
Certifique-se de ter o **Flex**, **Bison** e o **GCC** instalados. 
Para instalar as dependências, execute:
```bash
sudo apt update && sudo apt install flex gcc -y && sudo apt install bison -y
```

## 🚀 Como Compilar
Na pasta raiz do projeto, dê permissão ao script e execute-o:

```bash
chmod +x compilar.sh
./compilar.sh
```
O script automatiza a geração do analisador sintático pelo Bison, do analisador léxico pelo Flex e realiza a compilação final gerando o executável `./compiler`.

Também é possível executar `make` para gerar o compilador.

## 💻 Como Testar
```bash
# Testar com o algoritmo QuickSort (Sintaxe Válida)
./compiler testes/quicksort.edu /tmp/quicksort.c
gcc /tmp/quicksort.c -o /tmp/quicksort

# Testar arquivo com erros sintáticos
./compiler testes/quicksortERRO.edu /tmp/quicksortERRO.c

# Testar estruturas gerais
./compiler testes/testes.edu /tmp/testes.c
gcc /tmp/testes.c -o /tmp/testes
```

## ✅ Código de Saída
O executável recebe os caminhos de entrada e saída, gera código C e retorna código `0` para sucesso sintático ou `1` para falha.

Exemplo de saída com sucesso (Sintaxe Correta):
```bash
[SUCESSO] Codigo C gerado em: /tmp/testes.c
```

Exemplo de saída com falha (Erro Sintático):
```bash
[ERRO SINTATICO] Linha 4, Coluna 9: syntax error proximo a 'Inteiro'
[FALHA] Erros encontrados.
```
