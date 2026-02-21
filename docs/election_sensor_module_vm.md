# Election Sensor Observation Manifold Assembly Layer (C)

`simulation/c/election_sensor_module_vm.c` implements a compact assembly-like interpreter for module management.

## Syntax

- `MODULE <name> <baseline>`: create/reset module.
- `SENSOR <module> <sensor> <weight>`: register weighted sensor.
- `OBSERVE <module> <sensor> <reading>`: inject a reading.
- `ELECT <module>`: compute election score as baseline + weighted sum.
- `MANIFOLD <module> <alpha>`: interpolate from baseline to election score.
- `END`: terminate parse.

## Example

```txt
MODULE OBS_A 0.500
SENSOR OBS_A turnout 0.700
SENSOR OBS_A drift -0.200
OBSERVE OBS_A turnout 0.800
OBSERVE OBS_A drift 0.100
ELECT OBS_A
MANIFOLD OBS_A 0.600
END
```

Expected manifold output for `OBS_A` is `0.8240`.
