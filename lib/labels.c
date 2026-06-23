#include "labels.h"
#include <stdio.h>
#include <stdlib.h>

static int counter = 0;
static char buf[32];

void labels_init() { counter = 0; }

int new_label() { return ++counter; }

char * label_str(int n) {
    snprintf(buf, sizeof(buf), "L%d", n);
    return buf;
}
