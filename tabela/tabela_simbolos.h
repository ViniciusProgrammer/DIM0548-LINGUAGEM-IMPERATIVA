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

typedef struct ParamInfo {
    char name[MAX_KEY_LEN];
    char declared_type[MAX_KEY_LEN];
    VarType type;
    int is_ref;
    int is_array;
    int dimensions;
    struct ParamInfo * next;
} ParamInfo;

typedef struct UserType {
    char name[MAX_KEY_LEN];
    TypeField * fields;
    struct UserType * next;
} UserType;

typedef struct TypeAlias {
    char name[MAX_KEY_LEN];
    char target[MAX_KEY_LEN];
    struct TypeAlias * next;
} TypeAlias;

typedef struct Symbol {
    char key[MAX_KEY_LEN];   
    char name[MAX_KEY_LEN];
    char scope[MAX_KEY_LEN];
    VarType type;
    char declared_type[MAX_KEY_LEN];
    int is_function;
    int is_const;
    int is_initialized;
    int is_ref;
    int is_array;
    int dimensions;
    int array_sizes[8];
    VarType return_type;
    char return_declared_type[MAX_KEY_LEN];
    ParamInfo * params;
    int param_count;
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
void sym_set_const(const char * name, int is_const);
void sym_set_initialized(const char * name, int is_initialized);
void sym_set_ref(const char * name, int is_ref);
void sym_set_array(const char * name, int dimensions, const int * sizes);
int sym_set_function_return(const char * name, VarType return_type, const char * declared_type);
int sym_add_param(const char * function_name, const char * param_name,
                  VarType type, const char * declared_type, int is_ref,
                  int is_array, int dimensions);
Symbol * sym_lookup(const char * name);   
Symbol * sym_lookup_local(const char * name); 
int sym_is_addressable_expression(const char * code);

int user_type_insert(const char * name);
UserType * user_type_lookup(const char * name);
int type_alias_insert(const char * name, const char * target);
const char * type_alias_lookup(const char * name);
int user_type_add_field(const char * type_name, const char * field_name,
                        VarType field_type, const char * declared_type);
TypeField * user_type_field_lookup(const char * type_name, const char * field_name);

const char * type_name(VarType t);
VarType type_from_string(const char * s);
int types_compatible(VarType t1, VarType t2);
int declared_types_compatible(const char * type1, const char * type2);

#endif
