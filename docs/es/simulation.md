# Simulación

**Idiomas:** [English](../simulation.md) | [Português](../pt-BR/simulation.md) | Español

Levanta un Swarm de un nodo con ascaler y una aplicación que consume CPU en cada petición.

## Qué se levanta

| Stack | Servicios | Archivo |
|---|---|---|
| `ascaler` | ascaler, Prometheus, cAdvisor | `stack/ascaler.yml` |
| `demo` | `web`, aplicación de prueba en el puerto 8080 | `simulation/app.yml` |

La aplicación gasta 50 ms de CPU por petición. Con un límite de 0,5 núcleos, cada réplica atiende ~10 peticiones por segundo.

## Paso a paso

**1. Levanta el entorno:**

```bash
./simulation/up.sh
```

El script activa Swarm si hace falta, genera la imagen y espera a que la aplicación llegue a `3/3`.

**2. En otra terminal, haz el seguimiento:**

```bash
./simulation/logs.sh
```

Para ver también la CPU leída en cada ronda, usa `./simulation/logs.sh all`.

**3. En otra terminal, genera la carga:**

```bash
./simulation/load.sh
```

Opcional, para ver la CPU por réplica:

```bash
watch -n 5 'docker stats --no-stream --format "table {{.Name}}\t{{.CPUPerc}}" $(docker ps -qf name=demo_web)'
```

**4. Elimina todo:**

```bash
./simulation/down.sh
```

Usa `./simulation/down.sh --swarm` para salir también del Swarm.

## Carga

`simulation/load.js` sube a 100 peticiones por segundo en 1 minuto, las mantiene durante 2 y baja en 30 segundos. Esta carga requiere ~17 réplicas con `CPU_TARGET=60`.

## Resultados de referencia

Ejecuciones únicas, en WSL2 con un nodo y 20 núcleos lógicos, con los valores de `stack/ascaler.yml`:

| Métrica | Máximo 10 | Máximo 20 |
|---|---|---|
| Errores (`http_req_failed`) | 6,47% | 0,78% |
| Latencia mediana | 2,33s | 85ms |
| `p(95)` | 59,99s | 2,45s |
| Réplicas alcanzadas | 10 | 19 |
| Primer escalado | ~26s | ~25s |

Con máximo 20, la secuencia fue `5 → 8 → 14 → 19`, sin oscilaciones. Después de la carga, el servicio bajó de 2 en 2.

Una segunda ejecución, con los scripts de esta carpeta, tuvo `5 → 8 → 12 → 17`, 1,45% de errores, latencia mediana de 93ms y un `p(95)` de 4,26s.

La prueba con máximo 10 se interrumpió a los 5min40, tuvo otra duración de carga y usaba un límite menor en cAdvisor, así que solo sirve como comparación aproximada. Los números varían según la máquina.

## Cómo leer k6

| Métrica | Significado |
|---|---|
| `http_req_failed` | Tasa de errores. Suele concentrarse al inicio del pico |
| `p(95)` | El 95% de las peticiones fue más rápido que este valor |
| `dropped_iterations` | Peticiones que k6 no pudo iniciar |

## Por qué no usar `ab` con nginx

Una aplicación muy ligera, con carga desde una sola IP, genera miles de conexiones nuevas por segundo. En las pruebas, las réplicas nuevas se quedaron en 0%, porque la carga siguió en las antiguas. La causa más probable es la reutilización de puertos de origen en el balanceo de Swarm.

Con peticiones más pesadas y menos conexiones, como en esta simulación, las réplicas nuevas reciben carga con normalidad.
