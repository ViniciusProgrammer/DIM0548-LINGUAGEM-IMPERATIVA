#include <stdio.h>
#include <stdlib.h>
#include <string.h>

typedef struct { int numerador; int denominador; } rational_t;


int mdc(int a, int b)
{
if(!((a<0))) goto L1;
a = -(a);
L1:;
if(!((b<0))) goto L2;
b = -(b);
L2:;
if(!((b==0))) goto L3;
return a;
L3:;
return mdc(b, a%b);
}

rational_t criar_racional(int a, int b)
{
rational_t resultado;
int divisor;
if(!((b==0))) goto L4;
resultado.numerador = 0;
resultado.denominador = 1;
return resultado;
L4:;
divisor = mdc(a, b);
resultado.numerador = a/divisor;
resultado.denominador = b/divisor;
if(!((resultado.denominador<0))) goto L5;
resultado.numerador = -(resultado.numerador);
resultado.denominador = -(resultado.denominador);
L5:;
return resultado;
}

int racionais_iguais(rational_t r1, rational_t r2)
{
return r1.numerador*r2.denominador==r2.numerador*r1.denominador;
}

rational_t somar_racionais(rational_t r1, rational_t r2)
{
return criar_racional(r1.numerador*r2.denominador+r1.denominador*r2.numerador, r1.denominador*r2.denominador);
}

rational_t negar_racional(rational_t r)
{
return criar_racional(-(r.numerador), r.denominador);
}

rational_t subtrair_racionais(rational_t r1, rational_t r2)
{
return criar_racional(r1.numerador*r2.denominador-r1.denominador*r2.numerador, r1.denominador*r2.denominador);
}

rational_t multiplicar_racionais(rational_t r1, rational_t r2)
{
return criar_racional(r1.numerador*r2.numerador, r1.denominador*r2.denominador);
}

rational_t inverso_racional(rational_t r)
{
if(!((r.numerador==0))) goto L6;
return criar_racional(0, 1);
L6:;
return criar_racional(r.denominador, r.numerador);
}

rational_t dividir_racionais(rational_t r1, rational_t r2)
{
if(!((r2.numerador==0))) goto L7;
return criar_racional(0, 1);
L7:;
return multiplicar_racionais(r1, inverso_racional(r2));
}

void imprimir_racional(char* rotulo, rational_t r)
{
printf("%s\n", rotulo);
printf("%d\n", (int)(r.numerador));
printf("%s\n", "/");
printf("%d\n", (int)(r.denominador));
printf("%s\n", "");
}

int main(void)
{
rational_t a = criar_racional(1, 2);
rational_t b = criar_racional(3, 4);
printf("%s\n", "Racionais criados:");
imprimir_racional("a = ", a);
imprimir_racional("b = ", b);
printf("%s\n", "a == b? ");
if((racionais_iguais(a, b)==1)) goto L8;
goto L9;
L8:;
printf("%s\n", "Verdadeiro");
goto L10;
L9:;
printf("%s\n", "Falso");
L10:;
printf("%s\n", "");
imprimir_racional("Soma = ", somar_racionais(a, b));
imprimir_racional("Negacao de a = ", negar_racional(a));
imprimir_racional("Subtracao = ", subtrair_racionais(a, b));
imprimir_racional("Produto = ", multiplicar_racionais(a, b));
imprimir_racional("Inverso de a = ", inverso_racional(a));
imprimir_racional("Divisao = ", dividir_racionais(a, b));
return 0;
}
