#include "tabela_simbolos.h"
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

static Symbol * table[MAX_SYMBOLS];

static ScopeEntry scope_stack[MAX_SCOPES];
static int scope_sp = 0;

static unsigned int hash(const char * key) {
    unsigned int h = 0;
    while (*key) h = h * 31 + (unsigned char)(*key++);
    return h % MAX_SYMBOLS;
}

void symtable_init() {
    memset(table, 0, sizeof(table));
    scope_sp = 0;
}

void symtable_free() {
    for (int i = 0; i < MAX_SYMBOLS; i++) {
        Symbol * s = table[i];
        while (s) {
            Symbol * next = s->next;
            free(s);
            s = next;
        }
        table[i] = NULL;
    }
    scope_sp = 0;
}

void scope_push(const char * name, VarType ret_type) {
    if (scope_sp >= MAX_SCOPES) {
        fprintf(stderr, "Erro: limite de escopos atingido\n");
        exit(1);
    }
    strncpy(scope_stack[scope_sp].name, name, MAX_KEY_LEN - 1);
    scope_stack[scope_sp].return_type = ret_type;
    scope_sp++;
}

void scope_pop() {
    if (scope_sp <= 0) {
        fprintf(stderr, "Erro interno: pilha de escopos vazia\n");
        return;
    }
    scope_sp--;
}

ScopeEntry * scope_top() {
    if (scope_sp <= 0) return NULL;
    return &scope_stack[scope_sp - 1];
}

int scope_depth() {
    return scope_sp;
}

static void make_key(const char * scope, const char * name, char * out) {
    snprintf(out, MAX_KEY_LEN, "%s::%s", scope, name);
}

int sym_insert(const char * name, VarType type, int is_function, VarType ret_type) {
    if (scope_sp <= 0) {
        fprintf(stderr, "Erro interno: nenhum escopo ativo\n");
        return 0;
    }
    char * current_scope = scope_stack[scope_sp - 1].name;
    char key[MAX_KEY_LEN];
    make_key(current_scope, name, key);

    unsigned int h = hash(key);
    Symbol * s = table[h];
    while (s) {
        if (strcmp(s->key, key) == 0) return 0; 
        s = s->next;
    }

    Symbol * sym = (Symbol *) malloc(sizeof(Symbol));
    if (!sym) { fprintf(stderr, "Sem memória\n"); exit(1); }
    strncpy(sym->key, key, MAX_KEY_LEN - 1);
    strncpy(sym->name, name, MAX_KEY_LEN - 1);
    strncpy(sym->scope, current_scope, MAX_KEY_LEN - 1);
    sym->type = type;
    sym->is_function = is_function;
    sym->return_type = ret_type;
    sym->next = table[h];
    table[h] = sym;
    return 1;
}

Symbol * sym_lookup(const char * name) {
    for (int i = scope_sp - 1; i >= 0; i--) {
        char key[MAX_KEY_LEN];
        make_key(scope_stack[i].name, name, key);
        unsigned int h = hash(key);
        Symbol * s = table[h];
        while (s) {
            if (strcmp(s->key, key) == 0) return s;
            s = s->next;
        }
    }
    return NULL;
}

Symbol * sym_lookup_local(const char * name) {
    if (scope_sp <= 0) return NULL;
    char key[MAX_KEY_LEN];
    make_key(scope_stack[scope_sp - 1].name, name, key);
    unsigned int h = hash(key);
    Symbol * s = table[h];
    while (s) {
        if (strcmp(s->key, key) == 0) return s;
        s = s->next;
    }
    return NULL;
}

const char * type_name(VarType t) {
    switch (t) {
        case TYPE_BOOL:    return "bool";
        case TYPE_INT:     return "int";
        case TYPE_FLOAT:   return "float";
        case TYPE_STRING:  return "char*";
        case TYPE_VOID:    return "void";
        default:           return "desconhecido";
    }
}

VarType type_from_string(const char * s) {
    if (strcmp(s, "bool")  == 0) return TYPE_BOOL;
    if (strcmp(s, "int")   == 0) return TYPE_INT;
    if (strcmp(s, "float") == 0) return TYPE_FLOAT;
    if (strcmp(s, "texto") == 0) return TYPE_STRING;
    if (strcmp(s, "vazio") == 0) return TYPE_VOID;
    
    return TYPE_UNKNOWN;
}

int types_compatible(VarType t1, VarType t2) {
    if (t1 == t2) return 1;

    if ((t1 == TYPE_INT && t2 == TYPE_FLOAT) ||
        (t1 == TYPE_FLOAT && t2 == TYPE_INT)) return 1;
    return 0;
}
