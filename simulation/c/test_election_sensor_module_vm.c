#include "election_sensor_module_vm.h"

#include <stdio.h>
#include <string.h>

int main(void) {
  const char *program =
      "MODULE OBS_A 0.500\n"
      "SENSOR OBS_A turnout 0.700\n"
      "SENSOR OBS_A drift -0.200\n"
      "OBSERVE OBS_A turnout 0.800\n"
      "OBSERVE OBS_A drift 0.100\n"
      "ELECT OBS_A\n"
      "MANIFOLD OBS_A 0.600\n"
      "END\n";

  EsmProgramState state;
  esm_init(&state);
  EsmResult res = esm_interpret(&state, program);
  if (!res.ok) {
    fprintf(stderr, "interpret failed line %d: %s\n", res.line, res.message);
    return 1;
  }

  char out[512];
  if (esm_emit_report(&state, out, sizeof(out)) < 0) {
    fprintf(stderr, "emit failed\n");
    return 1;
  }

  puts(out);
  if (strstr(out, "\"name\":\"OBS_A\"") == NULL) return 2;
  if (strstr(out, "\"manifold\":0.8240") == NULL) return 3;
  return 0;
}
