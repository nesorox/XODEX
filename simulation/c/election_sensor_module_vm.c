#include "election_sensor_module_vm.h"

#include <ctype.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

static int streq(const char *a, const char *b) { return strcmp(a, b) == 0; }

static void set_error(EsmResult *result, int line, const char *message) {
  result->ok = 0;
  result->line = line;
  snprintf(result->message, sizeof(result->message), "%s", message);
}

static EsmModule *find_module(EsmProgramState *state, const char *name) {
  for (size_t i = 0; i < state->module_count; i++) {
    if (streq(state->modules[i].name, name)) return &state->modules[i];
  }
  return NULL;
}

static EsmSensor *find_sensor(EsmModule *module, const char *name) {
  for (size_t i = 0; i < module->sensor_count; i++) {
    if (streq(module->sensors[i].name, name)) return &module->sensors[i];
  }
  return NULL;
}

static char *skip_ws(char *s) {
  while (*s && isspace((unsigned char)*s)) s++;
  return s;
}

void esm_init(EsmProgramState *state) { memset(state, 0, sizeof(*state)); }

EsmResult esm_interpret(EsmProgramState *state, const char *source) {
  EsmResult result = {.ok = 1, .line = 0, .message = "ok"};
  size_t source_len = strlen(source);
  char *work = malloc(source_len + 1);
  if (work) memcpy(work, source, source_len + 1);
  if (!work) {
    set_error(&result, 0, "out of memory");
    return result;
  }

  int line_no = 0;
  for (char *line = strtok(work, "\n"); line; line = strtok(NULL, "\n")) {
    line_no++;
    char *cursor = skip_ws(line);
    if (*cursor == '\0' || *cursor == '#') continue;

    char op[24];
    if (sscanf(cursor, "%23s", op) != 1) continue;

    if (streq(op, "MODULE")) {
      char module_name[ESM_MAX_NAME];
      float baseline = 0.0f;
      if (sscanf(cursor, "%*s %31s %f", module_name, &baseline) != 2) {
        set_error(&result, line_no, "MODULE syntax: MODULE <name> <baseline>");
        break;
      }
      if (state->module_count >= ESM_MAX_MODULES) {
        set_error(&result, line_no, "module capacity exceeded");
        break;
      }
      EsmModule *existing = find_module(state, module_name);
      if (existing) {
        existing->baseline = baseline;
        existing->election_score = 0.0f;
        existing->manifold_value = baseline;
        existing->sensor_count = 0;
      } else {
        EsmModule *module = &state->modules[state->module_count++];
        memset(module, 0, sizeof(*module));
        snprintf(module->name, sizeof(module->name), "%s", module_name);
        module->baseline = baseline;
        module->manifold_value = baseline;
      }
    } else if (streq(op, "SENSOR")) {
      char module_name[ESM_MAX_NAME];
      char sensor_name[ESM_MAX_NAME];
      float weight = 0.0f;
      if (sscanf(cursor, "%*s %31s %31s %f", module_name, sensor_name, &weight) != 3) {
        set_error(&result, line_no, "SENSOR syntax: SENSOR <module> <sensor> <weight>");
        break;
      }
      EsmModule *module = find_module(state, module_name);
      if (!module) {
        set_error(&result, line_no, "module not found for SENSOR");
        break;
      }
      if (module->sensor_count >= ESM_MAX_SENSORS) {
        set_error(&result, line_no, "sensor capacity exceeded");
        break;
      }
      EsmSensor *sensor = find_sensor(module, sensor_name);
      if (!sensor) {
        sensor = &module->sensors[module->sensor_count++];
        memset(sensor, 0, sizeof(*sensor));
        snprintf(sensor->name, sizeof(sensor->name), "%s", sensor_name);
      }
      sensor->weight = weight;
    } else if (streq(op, "OBSERVE")) {
      char module_name[ESM_MAX_NAME];
      char sensor_name[ESM_MAX_NAME];
      float reading = 0.0f;
      if (sscanf(cursor, "%*s %31s %31s %f", module_name, sensor_name, &reading) != 3) {
        set_error(&result, line_no, "OBSERVE syntax: OBSERVE <module> <sensor> <reading>");
        break;
      }
      EsmModule *module = find_module(state, module_name);
      if (!module) {
        set_error(&result, line_no, "module not found for OBSERVE");
        break;
      }
      EsmSensor *sensor = find_sensor(module, sensor_name);
      if (!sensor) {
        set_error(&result, line_no, "sensor not found for OBSERVE");
        break;
      }
      sensor->reading = reading;
    } else if (streq(op, "ELECT")) {
      char module_name[ESM_MAX_NAME];
      if (sscanf(cursor, "%*s %31s", module_name) != 1) {
        set_error(&result, line_no, "ELECT syntax: ELECT <module>");
        break;
      }
      EsmModule *module = find_module(state, module_name);
      if (!module) {
        set_error(&result, line_no, "module not found for ELECT");
        break;
      }
      float score = module->baseline;
      for (size_t i = 0; i < module->sensor_count; i++) {
        score += module->sensors[i].reading * module->sensors[i].weight;
      }
      module->election_score = score;
    } else if (streq(op, "MANIFOLD")) {
      char module_name[ESM_MAX_NAME];
      float alpha = 0.0f;
      if (sscanf(cursor, "%*s %31s %f", module_name, &alpha) != 2) {
        set_error(&result, line_no, "MANIFOLD syntax: MANIFOLD <module> <alpha>");
        break;
      }
      EsmModule *module = find_module(state, module_name);
      if (!module) {
        set_error(&result, line_no, "module not found for MANIFOLD");
        break;
      }
      module->manifold_value = (1.0f - alpha) * module->baseline + alpha * module->election_score;
    } else if (streq(op, "END")) {
      break;
    } else {
      set_error(&result, line_no, "unknown opcode");
      break;
    }
  }

  free(work);
  if (!result.ok && result.message[0] == '\0') set_error(&result, line_no, "unknown parse error");
  return result;
}

int esm_emit_report(const EsmProgramState *state, char *buffer, size_t buffer_size) {
  size_t offset = 0;
  int written = snprintf(buffer, buffer_size, "{\"schema\":\"esm_v1\",\"modules\":[");
  if (written < 0 || (size_t)written >= buffer_size) return -1;
  offset = (size_t)written;

  for (size_t i = 0; i < state->module_count; i++) {
    const EsmModule *m = &state->modules[i];
    written = snprintf(buffer + offset, buffer_size - offset,
                       "%s{\"name\":\"%s\",\"baseline\":%.4f,\"election_score\":%.4f,\"manifold\":%.4f}",
                       i == 0 ? "" : ",", m->name, m->baseline, m->election_score, m->manifold_value);
    if (written < 0 || (size_t)written >= buffer_size - offset) return -1;
    offset += (size_t)written;
  }

  written = snprintf(buffer + offset, buffer_size - offset, "]}");
  if (written < 0 || (size_t)written >= buffer_size - offset) return -1;
  return (int)(offset + (size_t)written);
}
