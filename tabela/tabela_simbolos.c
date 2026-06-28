#include "tabela_simbolos.h"
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

static Symbol * table[MAX_SYMBOLS];
static UserType * user_types = NULL;

static ScopeEntry scope_stack[MAX_SCOPES];
static int scope_sp = 0;

static unsigned int hash(const char * key) {
    unsigned int h = 0;
    while (*key) h = h * 31 + (unsigned char)(*key++);
    return h % MAX_SYMBOLS;
}

void symtable_init() {
    memset(table, 0, sizeof(table));
    user_types = NULL;
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

    while (user_types) {
        UserType * next_type = user_types->next;
        TypeField * field = user_types->fields;
        while (field) {
            TypeField * next_field = field->next;
            free(field);
            field = next_field;
        }
        free(user_types);
        user_types = next_type;
    }

    scope_sp = 0;
}

void scope_push(const char * name, VarType ret_type) {
    if (scope_sp >= MAX_SCOPES) {
        fprintf(stderr, "Erro: limite de escopos atingido\n");
        exit(1);
    }
    strncpy(scope_stack[scope_sp].name, name, MAX_KEY_LEN - 1);
    scope_stack[scope_sp].name[MAX_KEY_LEN - 1] = '\0';
    scope_stack[scope_sp].return_type = ret_type;
    strncpy(scope_stack[scope_sp].return_declared_type, type_name(ret_type), MAX_KEY_LEN - 1);
    scope_stack[scope_sp].return_declared_type[MAX_KEY_LEN - 1] = '\0';
    scope_sp++;
}

void scope_set_return_type(VarType ret_type, const char * declared_type) {
    if (scope_sp <= 0) return;
    scope_stack[scope_sp - 1].return_type = ret_type;
    strncpy(scope_stack[scope_sp - 1].return_declared_type,
            declared_type ? declared_type : type_name(ret_type), MAX_KEY_LEN - 1);
    scope_stack[scope_sp - 1].return_declared_type[MAX_KEY_LEN - 1] = '\0';
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
    sym->key[MAX_KEY_LEN - 1] = '\0';
    sym->name[MAX_KEY_LEN - 1] = '\0';
    sym->scope[MAX_KEY_LEN - 1] = '\0';
    sym->type = type;
    strncpy(sym->declared_type, type_name(type), MAX_KEY_LEN - 1);
    sym->declared_type[MAX_KEY_LEN - 1] = '\0';
    sym->is_function = is_function;
    sym->return_type = ret_type;
    strncpy(sym->return_declared_type, type_name(ret_type), MAX_KEY_LEN - 1);
    sym->return_declared_type[MAX_KEY_LEN - 1] = '\0';
    sym->next = table[h];
    table[h] = sym;
    return 1;
}

void sym_set_declared_type(const char * name, const char * declared_type) {
    Symbol * sym = sym_lookup_local(name);
    if (!sym || !declared_type) return;
    strncpy(sym->declared_type, declared_type, MAX_KEY_LEN - 1);
    sym->declared_type[MAX_KEY_LEN - 1] = '\0';
}

int sym_set_function_return(const char * name, VarType return_type, const char * declared_type) {
    char key[MAX_KEY_LEN];
    make_key("global", name, key);
    unsigned int h = hash(key);
    Symbol * sym = table[h];

    while (sym) {
        if (strcmp(sym->key, key) == 0 && sym->is_function) {
            sym->return_type = return_type;
            strncpy(sym->return_declared_type,
                    declared_type ? declared_type : type_name(return_type), MAX_KEY_LEN - 1);
            sym->return_declared_type[MAX_KEY_LEN - 1] = '\0';
            return 1;
        }
        sym = sym->next;
    }
    return 0;
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

int user_type_insert(const char * name) {
    UserType * type;

    if (user_type_lookup(name)) return 0;

    type = malloc(sizeof(UserType));
    if (!type) { fprintf(stderr, "Sem memória\n"); exit(1); }
    strncpy(type->name, name, MAX_KEY_LEN - 1);
    type->name[MAX_KEY_LEN - 1] = '\0';
    type->fields = NULL;
    type->next = user_types;
    user_types = type;
    return 1;
}

UserType * user_type_lookup(const char * name) {
    UserType * type = user_types;
    while (type) {
        if (strcmp(type->name, name) == 0) return type;
        type = type->next;
    }
    return NULL;
}

int user_type_add_field(const char * type_name_value, const char * field_name,
                        VarType field_type, const char * declared_type) {
    UserType * type = user_type_lookup(type_name_value);
    TypeField * field;

    if (!type || user_type_field_lookup(type_name_value, field_name)) return 0;

    field = malloc(sizeof(TypeField));
    if (!field) { fprintf(stderr, "Sem memória\n"); exit(1); }
    strncpy(field->name, field_name, MAX_KEY_LEN - 1);
    field->name[MAX_KEY_LEN - 1] = '\0';
    strncpy(field->declared_type, declared_type, MAX_KEY_LEN - 1);
    field->declared_type[MAX_KEY_LEN - 1] = '\0';
    field->type = field_type;
    field->next = type->fields;
    type->fields = field;
    return 1;
}

TypeField * user_type_field_lookup(const char * type_name_value, const char * field_name) {
    UserType * type = user_type_lookup(type_name_value);
    TypeField * field;

    if (!type) return NULL;
    field = type->fields;
    while (field) {
        if (strcmp(field->name, field_name) == 0) return field;
        field = field->next;
    }
    return NULL;
}

const char * type_name(VarType t) {
    switch (t) {
        case TYPE_BOOL:     return "bool";
        case TYPE_INT:      return "int";
        case TYPE_FLOAT:    return "float";
        case TYPE_STRING:   return "char*";
        case TYPE_USER_DEFINED: return "registro";
        case TYPE_VOID:     return "void";
        default:            return "desconhecido";
    }
}

VarType type_from_string(const char * s) {
    if (strcmp(s, "bool")  == 0) return TYPE_BOOL;
    if (strcmp(s, "int")   == 0) return TYPE_INT;
    if (strcmp(s, "float") == 0) return TYPE_FLOAT;
    if (strcmp(s, "texto") == 0 || strcmp(s, "char*") == 0) return TYPE_STRING;
    if (strcmp(s, "vazio") == 0 || strcmp(s, "void") == 0) return TYPE_VOID;
    if (user_type_lookup(s)) return TYPE_USER_DEFINED;
    
    return TYPE_UNKNOWN;
}

int declared_types_compatible(const char * type1, const char * type2) {
    VarType t1;
    VarType t2;

    if (!type1 || !type2) return 0;
    if (strcmp(type1, type2) == 0) return 1;

    t1 = type_from_string(type1);
    t2 = type_from_string(type2);
    if (t1 == TYPE_USER_DEFINED || t2 == TYPE_USER_DEFINED) return 0;
    return types_compatible(t1, t2);
}

int types_compatible(VarType t1, VarType t2) {
    if (t1 == t2) return 1;

    if ((t1 == TYPE_INT && t2 == TYPE_FLOAT) ||
        (t1 == TYPE_FLOAT && t2 == TYPE_INT)) return 1;
    return 0;
}
