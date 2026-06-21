#ifndef RECORD
#define RECORD

struct record {
    char * code;
    char * opt1;
};

typedef struct record record;

void freeRecord(record *);
record * createRecord(char *, char *);

#endif
