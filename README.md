# DIM0548-LINGUAGEM-IMPERATIVA

Analisador léxico desenvolvido para a disciplina de **DIM0548 - Engenharia de Linguagens**. O analisador identifica palavras reservadas, tipos, variáveis, operadores e captura erros léxicos com mensagens de posição exata (`[L<linha>:C<coluna>]`).

## ⚙️ Pré-requisitos (Linux)
Certifique-se de ter o **Flex** e o **GCC** instalados:
```bash
sudo apt update && sudo apt install flex gcc -y
```

## 🚀 Como Compilar
Na pasta raiz do projeto, dê permissão ao script e execute-o:

```bash
chmod +x compilar.sh
./compilar.sh
```

O script usa `-lfl` para linkar a biblioteca do Flex e `-Wall` para ativar avisos de compilação.

## 💻 Como Testar
```bash
# Testar com o QuickSort
./analisador_lexico < testes/quicksort.edu

# Testar com o arquivo de testes gerais
./analisador_lexico < testes/testes.edu

# Separar tokens (stdout) dos erros léxicos (stderr)
./analisador_lexico < testes/testes.edu > tokens.txt 2> erros.txt
```

## ✅ Código de Saída
O executável retorna `0` se nenhum erro léxico foi encontrado e `1` caso contrário, permitindo uso em pipelines de CI/CD:
```bash
./analisador_lexico < testes/testes.edu && echo "Analise OK"
```
