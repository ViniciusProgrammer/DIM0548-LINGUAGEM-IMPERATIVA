%{
#include <stdio.h>
#include <stdlib.h>

extern int yylex();
extern int linha_atual;
extern int coluna_atual;
extern char* yytext;

void yyerror(const char *s);
%}

%define parse.error verbose

%token SE SENAO FIM_SE ENQUANTO FIM_ENQUANTO REPETIR ATE INICIO FIM
%token PROCEDIMENTO FUNCAO RETORNE MODIFICADOR_REF MAIN
%token TIPO_INTEIRO TIPO_REAL TIPO_TEXTO TIPO_BOOLEANO CONSTANTE
%token LITERAL_BOOLEANO LITERAL_REAL LITERAL_INTEIRO LITERAL_TEXTO
%token ESCREVER LER
%token OP_SOMA OP_SUBTRACAO OP_MULTIPLICACAO OP_DIVISAO OP_MODULO
%token SINAL_IGUALDADE OP_MAIOR OP_MENOR OP_LOGICO_E OP_LOGICO_OU
%token OP_LOGICO_NAO OP_IGUAL OP_DIFERENTE OP_MAIOR_IGUAL OP_MENOR_IGUAL
%token SETA_RETORNO OP_ATRIB_SOMA OP_ATRIB_SUB OP_ATRIB_MUL OP_ATRIB_DIV
%token PONTO_E_VIRGULA VIRGULA DOIS_PONTOS
%token ABRE_PARENTESES FECHA_PARENTESES ABRE_COLCHETES FECHA_COLCHETES ABRE_CHAVES FECHA_CHAVES
%token IDENTIFICADOR

%start program

%%

/* Escopo do projeto: exige que subprogramas sejam definidos apenas antes do main */
program
    : subprograms main_program
    ;

subprograms
    : %empty
    | subprograms subprogram
    ;

main_program
    : PROCEDIMENTO MAIN ABRE_PARENTESES FECHA_PARENTESES block
    ;

subprogram
    : sub_type IDENTIFICADOR ABRE_PARENTESES param_list_opt FECHA_PARENTESES return_type_opt block
    ;

sub_type
    : PROCEDIMENTO
    | FUNCAO
    ;

return_type_opt
    : %empty
    | SETA_RETORNO type
    ;

param_list_opt
    : %empty
    | param_list
    ;

param_list
    : param
    | param_list VIRGULA param
    ;

param
    : ref_opt IDENTIFICADOR DOIS_PONTOS type array_param_opt
    ;

ref_opt
    : %empty
    | MODIFICADOR_REF
    ;

array_param_opt
    : %empty
    | ABRE_COLCHETES FECHA_COLCHETES
    ;

type
    : TIPO_INTEIRO
    | TIPO_REAL
    | TIPO_TEXTO
    | TIPO_BOOLEANO
    ;

/* Suporta tanto blocos com inicio/fim oficiais quanto chaves como alternativa léxica */
block
    : INICIO stmts FIM
    | ABRE_CHAVES stmts FECHA_CHAVES
    ;

stmts
    : %empty
    | stmts stmt stmt_end_opt
    ;

stmt_end_opt
    : %empty
    | PONTO_E_VIRGULA
    ;

stmt
    : decl
    | assign
    | call_stmt
    | if_stmt
    | loop_stmt
    | return_stmt
    | io_stmt
    ;

io_stmt
    : ESCREVER ABRE_PARENTESES expr FECHA_PARENTESES
    | LER ABRE_PARENTESES var FECHA_PARENTESES
    ;

decl
    : IDENTIFICADOR DOIS_PONTOS type array_decl_opt assign_init_opt
    | CONSTANTE IDENTIFICADOR DOIS_PONTOS type assign_init_opt
    ;

array_decl_opt
    : %empty
    | ABRE_COLCHETES constant FECHA_COLCHETES
    ;

assign_init_opt
    : %empty
    | SINAL_IGUALDADE expr
    ;

assign
    : var assign_op expr
    ;

assign_op
    : SINAL_IGUALDADE
    | OP_ATRIB_SOMA
    | OP_ATRIB_SUB
    | OP_ATRIB_MUL
    | OP_ATRIB_DIV
    ;

call_stmt
    : call_expr
    ;

call_expr
    : IDENTIFICADOR ABRE_PARENTESES arg_list_opt FECHA_PARENTESES
    ;

arg_list_opt
    : %empty
    | arg_list
    ;

arg_list
    : expr
    | arg_list VIRGULA expr
    ;

if_stmt
    : SE condition block_start stmts else_opt FIM_SE
    ;

else_opt
    : %empty
    | SENAO block
    ;

/* Permite 'se expr' e 'se (expr)', pois parênteses já são avaliados em primary/expr */
condition
    : expr
    ;

/* if/while exigem fechamentos específicos (fim_se/fim_enquanto), sem usar 'fim' genérico */
block_start
    : INICIO
    | ABRE_CHAVES
    ;

loop_stmt
    : ENQUANTO condition block_start stmts loop_end
    | REPETIR stmts ATE condition
    ;

loop_end
    : FIM_ENQUANTO
    | FECHA_CHAVES
    ;

/* 'retorne (expr)' funciona naturalmente pois (expr) é expressão primária */
return_stmt
    : RETORNE expr
    ;

/* Expressões com precedência explícita implementada em cascata (menor para maior) */
expr
    : logical_or
    ;

logical_or
    : logical_or OP_LOGICO_OU logical_and
    | logical_and
    ;

logical_and
    : logical_and OP_LOGICO_E equality
    | equality
    ;

equality
    : equality OP_IGUAL relational
    | equality OP_DIFERENTE relational
    | relational
    ;

relational
    : relational OP_MENOR additive
    | relational OP_MAIOR additive
    | relational OP_MENOR_IGUAL additive
    | relational OP_MAIOR_IGUAL additive
    | additive
    ;

additive
    : additive OP_SOMA multiplicative
    | additive OP_SUBTRACAO multiplicative
    | multiplicative
    ;

multiplicative
    : multiplicative OP_MULTIPLICACAO unary
    | multiplicative OP_DIVISAO unary
    | multiplicative OP_MODULO unary
    | unary
    ;

unary
    : OP_LOGICO_NAO unary
    | OP_SUBTRACAO unary
    | OP_SOMA unary
    | primary
    ;

primary
    : var
    | constant
    | call_expr
    | ABRE_PARENTESES expr FECHA_PARENTESES
    ;

var
    : IDENTIFICADOR
    | IDENTIFICADOR ABRE_COLCHETES expr FECHA_COLCHETES
    ;

constant
    : LITERAL_INTEIRO
    | LITERAL_REAL
    | LITERAL_TEXTO
    | LITERAL_BOOLEANO
    ;

%%

void yyerror(const char *s) {
    fprintf(stderr, "[ERRO SINTATICO] Linha %d, Coluna %d: %s proximo a '%s'\n",
            linha_atual, coluna_atual, s, yytext);
}

int main(void) {
    printf("Iniciando analise sintatica...\n");

    if (yyparse() == 0) {
        printf("\n[SUCESSO] Analise sintatica concluida!\n");
    } else {
        printf("\n[FALHA] Foram encontrados erros sintaticos no codigo.\n");
    }

    return 0;
}