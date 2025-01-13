#ifndef Prover_h
#define Prover_h

#include <stdarg.h>
#include <stdbool.h>
#include <stdint.h>
#include <stdlib.h>

void setup_tracing(void);

const char *prover(const char *config_json);

#endif
