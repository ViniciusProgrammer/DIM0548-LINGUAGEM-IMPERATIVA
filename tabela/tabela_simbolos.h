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
    TYPE_USER_DEFINED,
    TYPE_VOID,
    TYPE_UNKNOWN
} VarType;

typedef struct TypeField {
    char name[MAX_KEY_LEN];
    char declared_type[MAX_KEY_LEN];
    VarType type;
    struct TypeField * next;
} TypeField;

typedef struct UserType {
    char name[MAX_KEY_LEN];
    TypeField * fields;
    struct UserType * next;
} UserType;

typedef struct Symbol {
    char key[MAX_KEY_LEN];   
    char name[MAX_KEY_LEN];
    char scope[MAX_KEY_LEN];
    VarType type;
    char declared_type[MAX_KEY_LEN];
    int is_function;
    VarType return_type;
    char return_declared_type[MAX_KEY_LEN];
    struct Symbol * next;    
} Symbol;


typedef struct {
    char name[MAX_KEY_LEN]; 
    VarType return_type;
    char return_declared_type[MAX_KEY_LEN];
} ScopeEntry;

void symtable_init();
void symtable_free();

void scope_push(const char * name, VarType ret_type);
void scope_set_return_type(VarType ret_type, const char * declared_type);
void scope_pop();
ScopeEntry * scope_top();
int scope_depth();

int sym_insert(const char * name, VarType type, int is_function, VarType ret_type);
void sym_set_declared_type(const char * name, const char * declared_type);
int sym_set_function_return(const char * name, VarType return_type, const char * declared_type);
Symbol * sym_lookup(const char * name);   
Symbol * sym_lookup_local(const char * name); 

int user_type_insert(const char * name);
UserType * user_type_lookup(const char * name);
int user_type_add_field(const char * type_name, const char * field_name,
                        VarType field_type, const char * declared_type);
TypeField * user_type_field_lookup(const char * type_name, const char * field_name);

const char * type_name(VarType t);
VarType type_from_string(const char * s);
int types_compatible(VarType t1, VarType t2);
int declared_types_compatible(const char * type1, const char * type2);

#endif
