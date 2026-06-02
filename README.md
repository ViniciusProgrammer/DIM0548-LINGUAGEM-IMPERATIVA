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
O script automatiza a geração do analisador sintático pelo Bison, do analisador léxico pelo Flex e realiza a compilação final gerando o executável ./analisador_sintatico.

O script usa `-lfl` para linkar a biblioteca do Flex e `-Wall` para ativar avisos de compilação.

## 💻 Como Testar
```bash
# Testar com o algoritmo QuickSort (Sintaxe Válida)
./analisador_sintatico < testes/quicksort.edu

# Testar com arquivo contendo erros para verificar a captura (Sintaxe Inválida)
./analisador_sintatico < testes/quicksortERRO.edu

# Testar validação de laços, condicionais e tipos gerais
./analisador_sintatico < testes/testes.edu
```

## ✅ Código de Saída
O executável processa o arquivo e imprime o resultado da análise diretamente no terminal (retornando o código de status `0` para sucesso e `1` para falha).

Exemplo de saída com sucesso (Sintaxe Correta):
```bash
Iniciando analise sintatica...

[SUCESSO] Analise sintatica concluida!
```

Exemplo de saída com falha (Erro Sintático):
```bash
Iniciando analise sintatica...
[ERRO SINTATICO] Linha 4, Coluna 9: syntax error proximo a 'Inteiro'

[FALHA] Foram encontrados erros sintaticos no codigo.
```