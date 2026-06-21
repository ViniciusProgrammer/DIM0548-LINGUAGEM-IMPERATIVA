#include <stdio.h>
#include <stdlib.h>
#include <string.h>


int main(void)
{
int numero = 42;
float nota = 9.5;
int ativo = 1;
if(!((numero==42))) goto L1;
printf("%s\n", "numero e 42");
L1:;
if(!((nota>=7.0))) goto L2;
printf("%s\n", "Aprovado");
L2:;
L3:;
if(!((numero>0))) goto L4;
numero -= 1;
goto L3;
L4:;
printf("%d\n", (int)(numero));
return 0;
}
