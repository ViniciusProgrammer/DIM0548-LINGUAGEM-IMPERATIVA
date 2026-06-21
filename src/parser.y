%{
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include "../tabela/tabela_simbolos.h"
#include "../lib/labels.h"
#include "../lib/record.h"

extern int yylex();
extern int linha_atual;
extern int coluna_atual;
extern char* yytext;

void yyerror(const char *s);

/* Saída gerada */
FILE * yyout;

/* Concatena até 5 strings em uma nova string alocada */
char * cat(char *s1, char *s2, char *s3, char *s4, char *s5);

static char * c_includes =
    "#include <stdio.h>\n"
    "#include <stdlib.h>\n"
    "#include <string.h>\n\n";
%}

%define parse.error verbose

/* Valor semântico: código gerado + tipo inferido */
%union {
    char       * sValue;
    struct record * rec;   /* rec->code = código C ; rec->opt1 = tipo */
}

/* ── Tokens sem valor ── */
%token SE SENAO FIM_SE ENQUANTO FIM_ENQUANTO REPETIR ATE INICIO FIM
%token PROCEDIMENTO FUNCAO RETORNE MODIFICADOR_REF MAIN
%token CONSTANTE
%token ESCREVER LER
%token OP_SOMA OP_SUBTRACAO OP_MULTIPLICACAO OP_DIVISAO OP_MODULO
%token SINAL_IGUALDADE OP_MAIOR OP_MENOR OP_LOGICO_E OP_LOGICO_OU
%token OP_LOGICO_NAO OP_IGUAL OP_DIFERENTE OP_MAIOR_IGUAL OP_MENOR_IGUAL
%token SETA_RETORNO OP_ATRIB_SOMA OP_ATRIB_SUB OP_ATRIB_MUL OP_ATRIB_DIV
%token PONTO_E_VIRGULA VIRGULA DOIS_PONTOS
%token ABRE_PARENTESES FECHA_PARENTESES ABRE_COLCHETES FECHA_COLCHETES ABRE_CHAVES FECHA_CHAVES

/* ── Tokens com valor de string ── */
%token <sValue> IDENTIFICADOR
%token <sValue> LITERAL_BOOLEANO LITERAL_REAL LITERAL_INTEIRO LITERAL_TEXTO
%token <sValue> TIPO_INTEIRO TIPO_REAL TIPO_TEXTO TIPO_BOOLEANO

/* ── Tipos não-terminais que carregam record ── */
%type <rec> program subprograms subprogram main_program
%type <rec> param_list_opt param_list param
%type <rec> block stmts stmt
%type <rec> decl assign if_stmt loop_stmt return_stmt io_stmt call_stmt
%type <rec> expr logical_or logical_and equality relational additive
%type <rec> multiplicative unary primary call_expr var constant
%type <rec> arg_list_opt arg_list
%type <sValue> type sub_type return_type_opt ref_opt assign_op

%start program

%%

program
    : subprograms main_program
      {
          char * s = cat(c_includes, $1->code, "\n", $2->code, "");
          fprintf(yyout, "%s", s);
          free(s);
          freeRecord($1);
          freeRecord($2);
      }
    ;

subprograms
    : %empty                    { $$ = createRecord("", ""); }
    | subprograms subprogram    {
          char * s = cat($1->code, "\n", $2->code, "", "");
          freeRecord($1); freeRecord($2);
          $$ = createRecord(s, ""); free(s);
      }
    ;

subprogram
    : sub_type IDENTIFICADOR
      ABRE_PARENTESES param_list_opt FECHA_PARENTESES
      return_type_opt
      {
          /* Registra função no escopo global antes de entrar no escopo dela */
          VarType rt = type_from_string($6 ? $6 : "vazio");
          sym_insert($2, rt, 1, rt);
          scope_push($2, rt);
      }
      block
      {
          /* ret_c: tipo C de retorno */
          char * ret_c = $6 ? $6 : "void";
          /* assinatura: "tipo nome(params)" */
          char * sig  = cat(ret_c, " ", $2, "(", $4->code);
          char * body = cat(sig, ")\n{\n", $8->code, "}\n", "");
          free(sig);
          free($2); free($6);
          freeRecord($4); freeRecord($8);
          $$ = createRecord(body, "");
          free(body);
          scope_pop();
      }
    ;

sub_type
    : PROCEDIMENTO  { $$ = "void"; }
    | FUNCAO        { $$ = ""; }   /* tipo virá do return_type_opt */
    ;

return_type_opt
    : %empty            { $$ = NULL; }
    | SETA_RETORNO type { $$ = $2;   }
    ;

/* ── Parâmetros ── */

param_list_opt
    : %empty        { $$ = createRecord("", ""); }
    | param_list    { $$ = $1; }
    ;

param_list
    : param                         { $$ = $1; }
    | param_list VIRGULA param      {
          char * s = cat($1->code, ", ", $3->code, "", "");
          freeRecord($1); freeRecord($3);
          $$ = createRecord(s, ""); free(s);
      }
    ;

param
    : ref_opt IDENTIFICADOR DOIS_PONTOS type array_param_opt
      {
          /* ref_opt: "" ou "*" ; array_param_opt ignorado na geração básica */
          char * decl = cat($4, " ", $1, $2, "");
          sym_insert($2, type_from_string($4), 0, TYPE_VOID);
          free($1); free($2); free($4);
          $$ = createRecord(decl, ""); free(decl);
      }
    ;

ref_opt
    : %empty            { $$ = strdup(""); }
    | MODIFICADOR_REF   { $$ = strdup("*"); }
    ;

array_param_opt
    : %empty
    | ABRE_COLCHETES FECHA_COLCHETES
    ;

/* ── Tipos ── */

type
    : TIPO_INTEIRO  { $$ = strdup("int");    }
    | TIPO_REAL     { $$ = strdup("float");  }
    | TIPO_TEXTO    { $$ = strdup("char*");  }
    | TIPO_BOOLEANO { $$ = strdup("int");    }
    ;

main_program
    : PROCEDIMENTO MAIN ABRE_PARENTESES FECHA_PARENTESES
      { scope_push("main", TYPE_VOID); }
      block
      {
          char * s = cat("int main(void)\n{\n", $6->code, "return 0;\n}\n", "", "");
          freeRecord($6);
          $$ = createRecord(s, "");
          free(s);
          scope_pop();
      }
    ;

block
    : INICIO stmts FIM                      { $$ = $2; }
    | ABRE_CHAVES stmts FECHA_CHAVES        { $$ = $2; }
    ;

stmts
    : %empty            { $$ = createRecord("", ""); }
    | stmts stmt stmt_end_opt
      {
          char * s = cat($1->code, $2->code, "", "", "");
          freeRecord($1); freeRecord($2);
          $$ = createRecord(s, ""); free(s);
      }
    ;

stmt_end_opt
    : %empty
    | PONTO_E_VIRGULA
    ;

stmt
    : decl          { $$ = $1; }
    | assign        { $$ = $1; }
    | call_stmt     { $$ = $1; }
    | if_stmt       { $$ = $1; }
    | loop_stmt     { $$ = $1; }
    | return_stmt   { $$ = $1; }
    | io_stmt       { $$ = $1; }
    ;

decl
    : IDENTIFICADOR DOIS_PONTOS type array_decl_opt assign_init_opt
      {
          if (!sym_insert($1, type_from_string($3), 0, TYPE_VOID))
              fprintf(stderr, "[ERRO SEMANTICO] Linha %d: '%s' ja declarado\n", linha_atual, $1);
          char * s = cat($3, " ", $1, $5 ? $5 : "", ";\n");
          free($1); free($3); free($5);
          $$ = createRecord(s, ""); free(s);
      }
    | CONSTANTE IDENTIFICADOR DOIS_PONTOS type assign_init_opt
      {
          if (!sym_insert($2, type_from_string($4), 0, TYPE_VOID))
              fprintf(stderr, "[ERRO SEMANTICO] Linha %d: '%s' ja declarado\n", linha_atual, $2);
          char * s = cat("const ", $4, " ", $2, $5 ? $5 : "");
          char * s2 = cat(s, ";\n", "", "", "");
          free(s); free($2); free($4); free($5);
          $$ = createRecord(s2, ""); free(s2);
      }
    ;

array_decl_opt
    : %empty
    | ABRE_COLCHETES constant FECHA_COLCHETES
    ;

assign_init_opt
    : %empty                    { $$ = NULL; }
    | SINAL_IGUALDADE expr      {
          char * s = cat(" = ", $2->code, "", "", "");
          char * opt = strdup($2->opt1);
          freeRecord($2);
          $$ = s;
          (void)opt; free(opt);
      }
    ;

assign
    : var assign_op expr
      {
          /* Verificação de tipo */
          Symbol * sym = sym_lookup($1->opt1);
          if (!sym)
              fprintf(stderr, "[ERRO SEMANTICO] Linha %d: '%s' nao declarado\n", linha_atual, $1->opt1);
          else if (!types_compatible(sym->type, type_from_string($3->opt1)) &&
                   type_from_string($3->opt1) != TYPE_UNKNOWN)
              fprintf(stderr, "[ERRO SEMANTICO] Linha %d: tipos incompativeis em '%s'\n", linha_atual, $1->opt1);

          char * s = cat($1->code, $2, $3->code, ";\n", "");
          freeRecord($1); free($2); freeRecord($3);
          $$ = createRecord(s, ""); free(s);
      }
    ;

assign_op
    : SINAL_IGUALDADE   { $$ = strdup(" = ");  }
    | OP_ATRIB_SOMA     { $$ = strdup(" += "); }
    | OP_ATRIB_SUB      { $$ = strdup(" -= "); }
    | OP_ATRIB_MUL      { $$ = strdup(" *= "); }
    | OP_ATRIB_DIV      { $$ = strdup(" /= "); }
    ;

call_stmt
    : call_expr PONTO_E_VIRGULA
      {
          char * s = cat($1->code, ";\n", "", "", "");
          freeRecord($1);
          $$ = createRecord(s, ""); free(s);
      }
    | call_expr
      {
          char * s = cat($1->code, ";\n", "", "", "");
          freeRecord($1);
          $$ = createRecord(s, ""); free(s);
      }
    ;

call_expr
    : IDENTIFICADOR ABRE_PARENTESES arg_list_opt FECHA_PARENTESES
      {
          Symbol * sym = sym_lookup($1);
          if (!sym || !sym->is_function)
              fprintf(stderr, "[ERRO SEMANTICO] Linha %d: '%s' nao e funcao declarada\n", linha_atual, $1);
          char * ret_t = sym ? strdup(type_name(sym->return_type)) : strdup("desconhecido");
          char * s = cat($1, "(", $3->code, ")", "");
          free($1); freeRecord($3);
          $$ = createRecord(s, ret_t);
          free(s); free(ret_t);
      }
    ;

arg_list_opt
    : %empty        { $$ = createRecord("", ""); }
    | arg_list      { $$ = $1; }
    ;

arg_list
    : expr
      { $$ = $1; }
    | arg_list VIRGULA expr
      {
          char * s = cat($1->code, ", ", $3->code, "", "");
          freeRecord($1); freeRecord($3);
          $$ = createRecord(s, ""); free(s);
      }
    ;

if_stmt
    : SE condition block_start stmts FIM_SE
      {
          int lf = new_label();
          char lfs[32]; sprintf(lfs, "L%d", lf);
          char * test = cat("if(!(", $2->code, ")) goto ", lfs, ";\n");
          char * body = cat($4->code, lfs, ":;\n", "", "");
          char * s    = cat(test, body, "", "", "");
          free(test); free(body);
          freeRecord($2); freeRecord($4);
          $$ = createRecord(s, ""); free(s);
      }
    | SE condition block_start stmts SENAO block FIM_SE
      {
          int lt = new_label();
          int lf = new_label();
          int le = new_label();
          char lts[32], lfs[32], les[32];
          sprintf(lts, "L%d", lt);
          sprintf(lfs, "L%d", lf);
          sprintf(les, "L%d", le);
          char * t1 = cat("if(", $2->code, ") goto ", lts, ";\n");
          char * t2 = cat(t1, "goto ", lfs, ";\n", "");
          char * t3 = cat(t2, lts, ":;\n", $4->code, "");
          char * t4 = cat(t3, "goto ", les, ";\n", "");
          char * t5 = cat(t4, lfs, ":;\n", $6->code, "");
          char * s  = cat(t5, les, ":;\n", "", "");
          free(t1); free(t2); free(t3); free(t4); free(t5);
          freeRecord($2); freeRecord($4); freeRecord($6);
          $$ = createRecord(s, ""); free(s);
      }
    ;

condition
    : expr  { $$ = $1; }
    ;

block_start
    : INICIO
    | ABRE_CHAVES
    ;

loop_stmt
    : ENQUANTO condition block_start stmts loop_end
      {
          int ls = new_label();
          int le = new_label();
          char lss[32], les[32];
          sprintf(lss, "L%d", ls);
          sprintf(les, "L%d", le);
          char * t1 = cat(lss, ":;\n", "if(!(", $2->code, ")) goto ");
          char * t2 = cat(t1, les, ";\n", $4->code, "");
          char * s  = cat(t2, "goto ", lss, ";\n", "");
          char * s2 = cat(s, les, ":;\n", "", "");
          free(t1); free(t2); free(s);
          freeRecord($2); freeRecord($4);
          $$ = createRecord(s2, ""); free(s2);
      }
    | REPETIR stmts ATE condition
      {
          /* do-while equivalente: Ls: body; if(!cond) goto Ls; */
          int ls = new_label();
          char lss[32]; sprintf(lss, "L%d", ls);
          char * t1 = cat(lss, ":;\n", $2->code, "", "");
          char * s  = cat(t1, "if(!(", $4->code, ")) goto ", lss);
          char * s2 = cat(s, ";\n", "", "", "");
          free(t1); free(s);
          freeRecord($2); freeRecord($4);
          $$ = createRecord(s2, ""); free(s2);
      }
    ;

loop_end
    : FIM_ENQUANTO
    | FECHA_CHAVES
    ;

return_stmt
    : RETORNE expr
      {
          ScopeEntry * top = scope_top();
          if (top) {
              VarType et = type_from_string($2->opt1);
              if (et != TYPE_UNKNOWN && !types_compatible(top->return_type, et))
                  fprintf(stderr, "[ERRO SEMANTICO] Linha %d: tipo de retorno incompativel\n", linha_atual);
          }
          char * s = cat("return ", $2->code, ";\n", "", "");
          freeRecord($2);
          $$ = createRecord(s, ""); free(s);
      }
    ;

io_stmt
    : ESCREVER ABRE_PARENTESES expr FECHA_PARENTESES PONTO_E_VIRGULA
      {
          char * s;
          VarType et = type_from_string($3->opt1);
          if ($3->code[0] == '"')
              s = cat("printf(\"%s\\n\", ", $3->code, ");\n", "", "");
          else if (et == TYPE_FLOAT)
              s = cat("printf(\"%f\\n\", (double)(", $3->code, "));\n", "", "");
          else if (et == TYPE_STRING)
              s = cat("printf(\"%s\\n\", ", $3->code, ");\n", "", "");
          else
              s = cat("printf(\"%d\\n\", (int)(", $3->code, "));\n", "", "");
          freeRecord($3);
          $$ = createRecord(s, ""); free(s);
      }
    | ESCREVER ABRE_PARENTESES expr FECHA_PARENTESES
      {
          char * s;
          VarType et = type_from_string($3->opt1);
          if ($3->code[0] == '"')
              s = cat("printf(\"%s\\n\", ", $3->code, ");\n", "", "");
          else if (et == TYPE_FLOAT)
              s = cat("printf(\"%f\\n\", (double)(", $3->code, "));\n", "", "");
          else
              s = cat("printf(\"%d\\n\", (int)(", $3->code, "));\n", "", "");
          freeRecord($3);
          $$ = createRecord(s, ""); free(s);
      }
    | LER ABRE_PARENTESES var FECHA_PARENTESES PONTO_E_VIRGULA
      {
          Symbol * sym = sym_lookup($3->opt1);
          char fmt[8] = "%d";
          if (sym) {
              if (sym->type == TYPE_FLOAT)  strcpy(fmt, "%f");
              if (sym->type == TYPE_STRING) strcpy(fmt, "%s");
          }
          char fmtlit[16]; sprintf(fmtlit, "\"%s\"", fmt);
          char * s = cat("scanf(", fmtlit, ", &", $3->code, ");\n");
          freeRecord($3);
          $$ = createRecord(s, ""); free(s);
      }
    | LER ABRE_PARENTESES var FECHA_PARENTESES
      {
          Symbol * sym = sym_lookup($3->opt1);
          char fmt[8] = "%d";
          if (sym) {
              if (sym->type == TYPE_FLOAT)  strcpy(fmt, "%f");
              if (sym->type == TYPE_STRING) strcpy(fmt, "%s");
          }
          char fmtlit[16]; sprintf(fmtlit, "\"%s\"", fmt);
          char * s = cat("scanf(", fmtlit, ", &", $3->code, ");\n");
          freeRecord($3);
          $$ = createRecord(s, ""); free(s);
      }
    ;

expr        : logical_or    { $$ = $1; } ;

logical_or
    : logical_or OP_LOGICO_OU logical_and
      { char*s=cat($1->code,"||",$3->code,"",""); freeRecord($1);freeRecord($3); $$=createRecord(s,"int");free(s); }
    | logical_and   { $$ = $1; }
    ;

logical_and
    : logical_and OP_LOGICO_E equality
      { char*s=cat($1->code,"&&",$3->code,"",""); freeRecord($1);freeRecord($3); $$=createRecord(s,"int");free(s); }
    | equality      { $$ = $1; }
    ;

equality
    : equality OP_IGUAL relational
      { char*s=cat($1->code,"==",$3->code,"",""); freeRecord($1);freeRecord($3); $$=createRecord(s,"int");free(s); }
    | equality OP_DIFERENTE relational
      { char*s=cat($1->code,"!=",$3->code,"",""); freeRecord($1);freeRecord($3); $$=createRecord(s,"int");free(s); }
    | relational    { $$ = $1; }
    ;

relational
    : relational OP_MENOR additive
      { char*s=cat($1->code,"<",$3->code,"",""); freeRecord($1);freeRecord($3); $$=createRecord(s,"int");free(s); }
    | relational OP_MAIOR additive
      { char*s=cat($1->code,">",$3->code,"",""); freeRecord($1);freeRecord($3); $$=createRecord(s,"int");free(s); }
    | relational OP_MENOR_IGUAL additive
      { char*s=cat($1->code,"<=",$3->code,"",""); freeRecord($1);freeRecord($3); $$=createRecord(s,"int");free(s); }
    | relational OP_MAIOR_IGUAL additive
      { char*s=cat($1->code,">=",$3->code,"",""); freeRecord($1);freeRecord($3); $$=createRecord(s,"int");free(s); }
    | additive      { $$ = $1; }
    ;

additive
    : additive OP_SOMA multiplicative
      {
          VarType t = (type_from_string($1->opt1)==TYPE_FLOAT || type_from_string($3->opt1)==TYPE_FLOAT) ? TYPE_FLOAT : TYPE_INT;
          char*s=cat($1->code,"+",$3->code,"",""); freeRecord($1);freeRecord($3); $$=createRecord(s,type_name(t));free(s);
      }
    | additive OP_SUBTRACAO multiplicative
      {
          VarType t = (type_from_string($1->opt1)==TYPE_FLOAT || type_from_string($3->opt1)==TYPE_FLOAT) ? TYPE_FLOAT : TYPE_INT;
          char*s=cat($1->code,"-",$3->code,"",""); freeRecord($1);freeRecord($3); $$=createRecord(s,type_name(t));free(s);
      }
    | multiplicative    { $$ = $1; }
    ;

multiplicative
    : multiplicative OP_MULTIPLICACAO unary
      {
          VarType t = (type_from_string($1->opt1)==TYPE_FLOAT || type_from_string($3->opt1)==TYPE_FLOAT) ? TYPE_FLOAT : TYPE_INT;
          char*s=cat($1->code,"*",$3->code,"",""); freeRecord($1);freeRecord($3); $$=createRecord(s,type_name(t));free(s);
      }
    | multiplicative OP_DIVISAO unary
      { char*s=cat($1->code,"/",$3->code,"",""); freeRecord($1);freeRecord($3); $$=createRecord(s,"float");free(s); }
    | multiplicative OP_MODULO unary
      { char*s=cat($1->code,"%",$3->code,"",""); freeRecord($1);freeRecord($3); $$=createRecord(s,"int");free(s); }
    | unary     { $$ = $1; }
    ;

unary
    : OP_LOGICO_NAO unary
      { char*s=cat("!(",$2->code,")","",""); char*o=strdup($2->opt1); freeRecord($2); $$=createRecord(s,o);free(s);free(o); }
    | OP_SUBTRACAO unary
      { char*s=cat("-(",$2->code,")","",""); char*o=strdup($2->opt1); freeRecord($2); $$=createRecord(s,o);free(s);free(o); }
    | OP_SOMA unary
      { $$ = $2; }
    | primary   { $$ = $1; }
    ;

primary
    : var       { $$ = $1; }
    | constant  { $$ = $1; }
    | call_expr { $$ = $1; }
    | ABRE_PARENTESES expr FECHA_PARENTESES
      { char*s=cat("(",$2->code,")","",""); char*o=strdup($2->opt1); freeRecord($2); $$=createRecord(s,o);free(s);free(o); }
    ;

var
    : IDENTIFICADOR
      {
          Symbol * sym = sym_lookup($1);
          if (!sym)
              fprintf(stderr, "[ERRO SEMANTICO] Linha %d: '%s' nao declarado\n", linha_atual, $1);
          char * t = sym ? strdup(type_name(sym->type)) : strdup("desconhecido");
          $$ = createRecord($1, $1);   /* opt1 guarda o nome para lookup posterior */
          /* reuse: code = nome C, opt1 = nome para lookup */
          free(t); free($1);
      }
    | IDENTIFICADOR ABRE_COLCHETES expr FECHA_COLCHETES
      {
          char * s = cat($1, "[", $3->code, "]", "");
          freeRecord($3);
          $$ = createRecord(s, $1);
          free(s); free($1);
      }
    ;

constant
    : LITERAL_INTEIRO   { $$ = createRecord($1, "int");   free($1); }
    | LITERAL_REAL      { $$ = createRecord($1, "float"); free($1); }
    | LITERAL_TEXTO     { $$ = createRecord($1, "char*"); free($1); }
    | LITERAL_BOOLEANO  { $$ = createRecord($1, "int");   free($1); }
    ;

%%

void yyerror(const char *s) {
    fprintf(stderr, "[ERRO SINTATICO] Linha %d, Coluna %d: %s proximo a '%s'\n",
            linha_atual, coluna_atual, s, yytext);
}

char * cat(char *s1, char *s2, char *s3, char *s4, char *s5) {
    if (!s1) s1 = ""; if (!s2) s2 = "";
    if (!s3) s3 = ""; if (!s4) s4 = ""; if (!s5) s5 = "";
    int tam = strlen(s1)+strlen(s2)+strlen(s3)+strlen(s4)+strlen(s5)+1;
    char * out = malloc(tam);
    if (!out) { fprintf(stderr, "Sem memoria\n"); exit(1); }
    sprintf(out, "%s%s%s%s%s", s1, s2, s3, s4, s5);
    return out;
}

int main(int argc, char ** argv) {
    if (argc != 3) {
        fprintf(stderr, "Uso: ./compiler entrada.edu saida.c\n");
        return 1;
    }

    FILE * fin = fopen(argv[1], "r");
    if (!fin) { perror(argv[1]); return 1; }

    yyout = fopen(argv[2], "w");
    if (!yyout) { perror(argv[2]); return 1; }

    extern FILE * yyin;
    yyin = fin;

    symtable_init();
    labels_init();
    scope_push("global", TYPE_VOID);

    int result = yyparse();

    symtable_free();
    fclose(fin);
    fclose(yyout);

    if (result == 0)
        printf("[SUCESSO] Codigo C gerado em: %s\n", argv[2]);
    else
        printf("[FALHA] Erros encontrados.\n");

    return result;
}