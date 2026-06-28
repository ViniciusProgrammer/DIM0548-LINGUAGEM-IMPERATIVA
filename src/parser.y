%{
#include <stdio.h>
#include <stdlib.h>
#include <stdarg.h>
#include <string.h>
#include "../tabela/tabela_simbolos.h"
#include "../lib/labels.h"
#include "../lib/record.h"

extern int yylex();
extern int linha_atual;
extern int coluna_atual;
extern int erros_lexicos;
extern char* yytext;
extern FILE * yyout;

void yyerror(const char *s);
void semantic_error(const char *format, ...);
char * get_base_name(const char * name);
char * generate_write_code(struct record * expression, int append_newline);
int publish_output(FILE * source, const char * output_path);

int erros_semanticos = 0;
int erros_sintaticos = 0;
char * current_user_type = NULL;

/* Saída gerada */

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
%token CONSTANTE TIPO
%token ESCREVER ESCREVER_SEM_QUEBRA LER
%token OP_SOMA OP_SUBTRACAO OP_MULTIPLICACAO OP_DIVISAO OP_MODULO
%token SINAL_IGUALDADE OP_MAIOR OP_MENOR OP_LOGICO_E OP_LOGICO_OU
%token OP_LOGICO_NAO OP_IGUAL OP_DIFERENTE OP_MAIOR_IGUAL OP_MENOR_IGUAL
%token SETA_RETORNO OP_ATRIB_SOMA OP_ATRIB_SUB OP_ATRIB_MUL OP_ATRIB_DIV
%token PONTO_E_VIRGULA VIRGULA DOIS_PONTOS
%token ABRE_PARENTESES FECHA_PARENTESES ABRE_COLCHETES FECHA_COLCHETES PONTO

/* ── Tokens com valor de string ── */
%token <sValue> IDENTIFICADOR
%token <sValue> LITERAL_BOOLEANO LITERAL_REAL LITERAL_INTEIRO LITERAL_TEXTO
%token <sValue> TIPO_INTEIRO TIPO_REAL TIPO_TEXTO TIPO_BOOLEANO

/* ── Tipos não-terminais que carregam record ── */
%type <rec> program type_declarations type_declaration field_declarations field_declaration
%type <rec> subprograms subprogram main_program
%type <rec> param_list_opt param_list param
%type <rec> block stmts stmt
%type <rec> decl assign if_stmt loop_stmt return_stmt io_stmt call_stmt
%type <rec> expr logical_or logical_and equality relational additive
%type <rec> multiplicative unary primary call_expr var constant
%type <rec> arg_list_opt arg_list condition
%type <sValue> type sub_type return_type_opt ref_opt assign_op assign_init_opt array_decl_opt

%start program

%%

program
    : type_declarations subprograms main_program
      {
          char * prefix = cat(c_includes, $1->code, "\n", $2->code, "\n");
          char * s = cat(prefix, $3->code, "", "", "");
          fprintf(yyout, "%s", s);
          free(prefix); free(s);
          freeRecord($1);
          freeRecord($2);
          freeRecord($3);
      }
    ;

type_declarations
    : %empty
      { $$ = createRecord("", ""); }
    | type_declarations type_declaration
      {
          char * s = cat($1->code, "\n", $2->code, "", "");
          freeRecord($1); freeRecord($2);
          $$ = createRecord(s, ""); free(s);
      }
    ;

type_declaration
    : TIPO IDENTIFICADOR
      {
          if (!user_type_insert($2))
              semantic_error("Linha %d: tipo '%s' ja declarado", linha_atual, $2);
          free(current_user_type);
          current_user_type = strdup($2);
      }
      INICIO field_declarations FIM
      {
          char * body = cat("typedef struct {\n", $5->code, "} ", $2, ";\n");
          $$ = createRecord(body, "");
          free(body); freeRecord($5); free($2);
          free(current_user_type);
          current_user_type = NULL;
      }
    ;

field_declarations
    : %empty
      { $$ = createRecord("", ""); }
    | field_declarations field_declaration
      {
          char * s = cat($1->code, $2->code, "", "", "");
          freeRecord($1); freeRecord($2);
          $$ = createRecord(s, ""); free(s);
      }
    ;

field_declaration
    : IDENTIFICADOR DOIS_PONTOS type stmt_end_opt
      {
          VarType field_type = type_from_string($3);
          if (current_user_type && strcmp(current_user_type, $3) == 0)
              semantic_error("Linha %d: tipo recursivo '%s' nao e permitido", linha_atual, $3);
          if (!user_type_add_field(current_user_type, $1, field_type, $3))
              semantic_error("Linha %d: campo '%s' ja declarado em '%s'",
                             linha_atual, $1, current_user_type ? current_user_type : "");
          char * s = cat("    ", $3, " ", $1, ";\n");
          $$ = createRecord(s, "");
          free(s); free($1); free($3);
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
      {
          if (!sym_insert($2, TYPE_UNKNOWN, 1, TYPE_UNKNOWN))
              semantic_error("Linha %d: subprograma '%s' ja declarado", linha_atual, $2);
          scope_push($2, TYPE_UNKNOWN);
      }
      ABRE_PARENTESES param_list_opt FECHA_PARENTESES
      return_type_opt
      {
          const char * return_name = $7 ? $7 : "void";
          VarType return_type = type_from_string(return_name);
          sym_set_function_return($2, return_type, return_name);
          scope_set_return_type(return_type, return_name);
      }
      block
      {
          /* ret_c: tipo C de retorno */
          char * ret_c = $7 ? $7 : "void";
          /* assinatura: "tipo nome(params)" */
          char * sig  = cat(ret_c, " ", $2, "(", $5->code);
          char * body = cat(sig, ")\n{\n", $9->code, "}\n", "");
          free(sig);
          free($2); free($7);
          freeRecord($5); freeRecord($9);
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
          if (!sym_insert($2, type_from_string($4), 0, TYPE_VOID))
              semantic_error("Linha %d: parametro '%s' ja declarado", linha_atual, $2);
          else
              sym_set_declared_type($2, $4);
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
    | IDENTIFICADOR {
          if (!user_type_lookup($1))
              semantic_error("Linha %d: tipo '%s' nao declarado", linha_atual, $1);
          $$ = $1;
      }
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
              semantic_error("Linha %d: '%s' ja declarado", linha_atual, $1);
          else
              sym_set_declared_type($1, $3);
          char * declaration = cat($3, " ", $1, $4, "");
          char * s = cat(declaration, $5 ? $5 : "", ";\n", "", "");
          free(declaration);
          free($1); free($3); free($4); free($5);
          $$ = createRecord(s, ""); free(s);
      }
    | CONSTANTE IDENTIFICADOR DOIS_PONTOS type assign_init_opt
      {
          if (!sym_insert($2, type_from_string($4), 0, TYPE_VOID))
              semantic_error("Linha %d: '%s' ja declarado", linha_atual, $2);
          else
              sym_set_declared_type($2, $4);
          char * s = cat("const ", $4, " ", $2, $5 ? $5 : "");
          char * s2 = cat(s, ";\n", "", "", "");
          free(s); free($2); free($4); free($5);
          $$ = createRecord(s2, ""); free(s2);
      }
    ;

array_decl_opt
    : %empty
      { $$ = strdup(""); }
    | ABRE_COLCHETES constant FECHA_COLCHETES
      {
          $$ = cat("[", $2->code, "]", "", "");
          freeRecord($2);
      }
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
          VarType left_type = type_from_string($1->opt1);
          if (left_type == TYPE_UNKNOWN && strcmp($1->opt1, "desconhecido") == 0) {
              char * base = get_base_name($1->code);
              Symbol * sym = sym_lookup(base);
              if (!sym)
                  semantic_error("Linha %d: '%s' nao declarado", linha_atual, base);
              free(base);
          } else if (strcmp($3->opt1, "desconhecido") != 0 &&
                     !declared_types_compatible($1->opt1, $3->opt1)) {
              char * base = get_base_name($1->code);
              semantic_error("Linha %d: tipos incompativeis em '%s'", linha_atual, base);
              free(base);
          }

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
    : call_expr
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
              semantic_error("Linha %d: '%s' nao e funcao declarada", linha_atual, $1);
          char * ret_t = sym ? strdup(sym->return_declared_type) : strdup("desconhecido");
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
    | SE condition block_start stmts SENAO block_start stmts FIM_SE
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
          char * t5 = cat(t4, lfs, ":;\n", $7->code, "");
          char * s  = cat(t5, les, ":;\n", "", "");
          free(t1); free(t2); free(t3); free(t4); free(t5);
          freeRecord($2); freeRecord($4); freeRecord($7);
          $$ = createRecord(s, ""); free(s);
      }
    ;

condition
    : ABRE_PARENTESES expr FECHA_PARENTESES  { $$ = $2; }
    ;

block_start
    : INICIO
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
    ;

return_stmt
    : RETORNE expr
      {
          ScopeEntry * top = scope_top();
          if (top) {
              if (strcmp($2->opt1, "desconhecido") != 0 &&
                  !declared_types_compatible(top->return_declared_type, $2->opt1))
                  semantic_error("Linha %d: tipo de retorno incompativel", linha_atual);
          }
          char * s = cat("return ", $2->code, ";\n", "", "");
          freeRecord($2);
          $$ = createRecord(s, ""); free(s);
      }
    ;

io_stmt
    : ESCREVER ABRE_PARENTESES expr FECHA_PARENTESES
      {
          char * s;
          VarType et = type_from_string($3->opt1);
          if (et == TYPE_UNKNOWN) {
              char * base = get_base_name($3->code);
              Symbol * sym = sym_lookup(base);
              free(base);
              if (!sym) {
                  base = get_base_name($3->opt1);
                  sym = sym_lookup(base);
                  free(base);
              }
              if (sym) et = sym->type;
          }
          if ($3->code[0] == '"')
              s = cat("printf(\"%s\\n\", ", $3->code, ");\n", "", "");
          else if (et == TYPE_FLOAT)
              s = cat("printf(\"%f\\n\", (float)(", $3->code, "));\n", "", "");
          else if (et == TYPE_STRING)
              s = cat("printf(\"%s\\n\", ", $3->code, ");\n", "", "");
          else
              s = cat("printf(\"%d\\n\", (int)(", $3->code, "));\n", "", "");
          freeRecord($3);
          $$ = createRecord(s, ""); free(s);
      }
    | ESCREVER_SEM_QUEBRA ABRE_PARENTESES expr FECHA_PARENTESES
      {
          char * s = generate_write_code($3, 0);
          freeRecord($3);
          $$ = createRecord(s, ""); free(s);
      }
    | LER ABRE_PARENTESES var FECHA_PARENTESES
      {
          char * base = get_base_name($3->code);
          Symbol * sym = sym_lookup(base);
          free(base);
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
              semantic_error("Linha %d: '%s' nao declarado", linha_atual, $1);
          char * t = sym ? strdup(sym->declared_type) : strdup("desconhecido");
          $$ = createRecord($1, t);   /* code = nome C, opt1 = tipo */
          /* reuse: code = nome C, opt1 = nome para lookup */
          free(t); free($1);
      }
    | IDENTIFICADOR ABRE_COLCHETES expr FECHA_COLCHETES
      {
          Symbol * sym = sym_lookup($1);
          if (!sym)
              semantic_error("Linha %d: '%s' nao declarado", linha_atual, $1);
          char * t = sym ? strdup(sym->declared_type) : strdup("desconhecido");
          char * s = cat($1, "[", $3->code, "]", "");
          freeRecord($3);
          $$ = createRecord(s, t);
          free(s); free($1); free(t);
      }
    | IDENTIFICADOR PONTO IDENTIFICADOR
      {
          Symbol * sym = sym_lookup($1);
          if (!sym)
              semantic_error("Linha %d: '%s' nao declarado", linha_atual, $1);
          TypeField * field = sym ? user_type_field_lookup(sym->declared_type, $3) : NULL;
          if (sym && sym->type != TYPE_USER_DEFINED)
              semantic_error("Linha %d: '%s' nao e um registro", linha_atual, $1);
          else if (sym && !field)
              semantic_error("Linha %d: campo '%s' nao existe em '%s'",
                             linha_atual, $3, sym->declared_type);
          char * t = field ? strdup(field->declared_type) : strdup("desconhecido");
          char * s = cat($1, ".", $3, "", "");
          $$ = createRecord(s, t);
          free(s); free($1); free($3); free(t);
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
    erros_sintaticos++;
    fprintf(stderr, "[ERRO SINTATICO] Linha %d, Coluna %d: %s proximo a '%s'\n",
            linha_atual, coluna_atual, s, yytext);
}

void semantic_error(const char *format, ...) {
    va_list args;

    erros_semanticos++;
    fprintf(stderr, "[ERRO SEMANTICO] ");
    va_start(args, format);
    vfprintf(stderr, format, args);
    va_end(args);
    fprintf(stderr, "\n");
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

char * get_base_name(const char * name) {
    char * p1 = strchr(name, '[');
    char * p2 = strchr(name, '.');
    char * p = NULL;
    if (p1 && p2) p = p1 < p2 ? p1 : p2;
    else if (p1) p = p1;
    else if (p2) p = p2;
    if (!p) return strdup(name);

    int len = p - name;
    char * base = malloc(len + 1);
    if (!base) { fprintf(stderr, "Sem memoria\n"); exit(1); }
    strncpy(base, name, len);
    base[len] = '\0';
    return base;
}

char * generate_write_code(struct record * expression, int append_newline) {
    VarType type = type_from_string(expression->opt1);
    const char * suffix = append_newline ? "\\n" : "";

    if (type == TYPE_UNKNOWN) {
        char * base = get_base_name(expression->code);
        Symbol * symbol = sym_lookup(base);
        free(base);
        if (symbol) type = symbol->type;
    }

    char format[16];
    if (expression->code[0] == '"' || type == TYPE_STRING)
        sprintf(format, "\"%%s%s\"", suffix);
    else if (type == TYPE_FLOAT)
        sprintf(format, "\"%%f%s\"", suffix);
    else
        sprintf(format, "\"%%d%s\"", suffix);

    if (expression->code[0] == '"' || type == TYPE_STRING)
        return cat("printf(", format, ", ", expression->code, ");\n");
    if (type == TYPE_FLOAT)
        return cat("printf(", format, ", (float)(", expression->code, "));\n");
    return cat("printf(", format, ", (int)(", expression->code, "));\n");
}

int publish_output(FILE * source, const char * output_path) {
    char buffer[4096];
    size_t bytes_read;
    int success = 1;
    FILE * output = fopen(output_path, "w");

    if (!output) {
        perror(output_path);
        return 0;
    }

    rewind(source);
    while ((bytes_read = fread(buffer, 1, sizeof(buffer), source)) > 0) {
        if (fwrite(buffer, 1, bytes_read, output) != bytes_read) {
            perror(output_path);
            success = 0;
            break;
        }
    }

    if (ferror(source)) {
        fprintf(stderr, "Erro ao ler o codigo C temporario.\n");
        success = 0;
    }

    if (fclose(output) != 0) {
        perror(output_path);
        success = 0;
    }

    if (!success)
        remove(output_path);

    return success;
}

int main(int argc, char ** argv) {
    if (argc != 3) {
        fprintf(stderr, "Uso: ./compiler entrada.edu saida.c\n");
        return 1;
    }

    if (strcmp(argv[1], argv[2]) == 0) {
        fprintf(stderr, "Os arquivos de entrada e saida devem ser diferentes.\n");
        return 1;
    }

    FILE * fin = fopen(argv[1], "r");
    if (!fin) { perror(argv[1]); return 1; }

    yyout = tmpfile();
    if (!yyout) {
        perror("Nao foi possivel criar a saida temporaria");
        fclose(fin);
        return 1;
    }

    extern FILE * yyin;
    extern FILE * yyout;
    yyin = fin;

    symtable_init();
    labels_init();
    scope_push("global", TYPE_VOID);

    int parse_result = yyparse();
    int analyses_succeeded = parse_result == 0 &&
                             erros_lexicos == 0 &&
                             erros_sintaticos == 0 &&
                             erros_semanticos == 0;
    int output_published = 0;

    if (analyses_succeeded) {
        output_published = publish_output(yyout, argv[2]);
        if (!output_published)
            remove(argv[2]);
    } else {
        remove(argv[2]);
    }

    symtable_free();
    fclose(fin);
    fclose(yyout);

    if (analyses_succeeded && output_published) {
        printf("[SUCESSO] Codigo C gerado em: %s\n", argv[2]);
        return 0;
    }

    if (!analyses_succeeded) {
        printf("[FALHA] Erros encontrados: %d lexico(s), %d sintatico(s), %d semantico(s).\n",
               erros_lexicos, erros_sintaticos, erros_semanticos);
    } else {
        printf("[FALHA] Nao foi possivel publicar o codigo C.\n");
    }

    return 1;
}
