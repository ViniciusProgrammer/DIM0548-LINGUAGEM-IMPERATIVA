# DIM0548-LINGUAGEM-IMPARATIVA

Analisador léxico desenvolvido para a disciplina de **DIM0548 - Engenharia de Linguagens**. O analisador identifica palavras reservadas, tipos, variáveis e captura erros léxicos com mensagens amigáveis.

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

## 💻 Como Testar
Para rodar o analisador usando o arquivo de teste:

```bash
./analisador_lexico < testes/teste.edu
```