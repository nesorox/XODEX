#ifndef ELECTION_SENSOR_MODULE_VM_H
#define ELECTION_SENSOR_MODULE_VM_H

#include <stddef.h>

#ifdef __cplusplus
extern "C" {
#endif

#define ESM_MAX_MODULES 32
#define ESM_MAX_SENSORS 16
#define ESM_MAX_NAME 32

typedef struct {
  char name[ESM_MAX_NAME];
  float weight;
  float reading;
} EsmSensor;

typedef struct {
  char name[ESM_MAX_NAME];
  float baseline;
  float election_score;
  float manifold_value;
  size_t sensor_count;
  EsmSensor sensors[ESM_MAX_SENSORS];
} EsmModule;

typedef struct {
  size_t module_count;
  EsmModule modules[ESM_MAX_MODULES];
} EsmProgramState;

typedef struct {
  int ok;
  int line;
  char message[160];
} EsmResult;

void esm_init(EsmProgramState *state);
EsmResult esm_interpret(EsmProgramState *state, const char *source);
int esm_emit_report(const EsmProgramState *state, char *buffer, size_t buffer_size);

#ifdef __cplusplus
}
#endif

#endif
