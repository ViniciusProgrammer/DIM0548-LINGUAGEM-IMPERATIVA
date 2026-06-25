#ifndef SYMTABLE_H
#define SYMTABLE_H

#define MAX_SYMBOLS 1024
#define MAX_SCOPES  64
#define MAX_KEY_LEN 256

typedef enum {
    TYPE_BOOL,
    TYPE_INT,
    TYPE_FLOAT,
    TYPE_STRING,
    TYPE_RATIONAL,
    TYPE_VOID,
    TYPE_UNKNOWN
} VarType;


typedef struct Symbol {
    char key[MAX_KEY_LEN];   
    char name[MAX_KEY_LEN];
    char scope[MAX_KEY_LEN];
    VarType type;
    int is_function;
    VarType return_type;     
    struct Symbol * next;    
} Symbol;


typedef struct {
    char name[MAX_KEY_LEN]; 
    VarType return_type;     
} ScopeEntry;

void symtable_init();
void symtable_free();

void scope_push(const char * name, VarType ret_type);
void scope_pop();
ScopeEntry * scope_top();
int scope_depth();

int sym_insert(const char * name, VarType type, int is_function, VarType ret_type);
Symbol * sym_lookup(const char * name);   
Symbol * sym_lookup_local(const char * name); 

const char * type_name(VarType t);
VarType type_from_string(const char * s);
int types_compatible(VarType t1, VarType t2);

#endif
