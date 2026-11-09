# Configuración

**Idiomas:** [English](../configuration.md) | [Português](../pt-BR/configuration.md) | Español

## Etiquetas del servicio

Van en `deploy.labels` y se aplican después de un `docker stack deploy`.

| Etiqueta | Valor | Descripción |
|---|---|---|
| `ascaler` | `true` | Activa el autoescalado |
| `ascaler.minimum` | Entero | Mínimo de réplicas. **Obligatorio** |
| `ascaler.maximum` | Entero | Máximo de réplicas. **Obligatorio** |

Define también `deploy.resources.limits.cpus`, porque la utilización se calcula sobre ese límite.

## Variables de ascaler

| Variable | Valor por defecto del script | En `stack/ascaler.yml` | Descripción |
|---|---|---|---|
| `PROMETHEUS_URL` | `http://apps6.local:9090` | `http://prometheus:9090` | Dirección de Prometheus |
| `WAIT_TIME` | `60s` | `10s` | Intervalo entre rondas |
| `CPU_UPPER_LIMIT` | `85` | `70` | Por encima, sube (% del límite) |
| `CPU_LOWER_LIMIT` | `25` | `25` | Por debajo, baja (% del límite) |
| `CPU_TARGET` | `60` | `60` | Utilización que busca el cálculo |
| `CPU_WINDOW_UP` | `30s` | `15s` | Ventana para subir |
| `CPU_WINDOW_DOWN` | `2m` | `2m` | Ventana para bajar |
| `MAX_DOWN_STEP` | `2` | `2` | Máximo de réplicas quitadas por ronda |

## Recolección de Prometheus

`scrape_interval` está en `stack/config/prometheus.yml`, no en ascaler.

**Regla:** la ventana de ascaler debe cubrir al menos 2 recolecciones. Con una ventana de 15s, recolecta cada 7s como máximo. Si la ventana es demasiado corta, la consulta vuelve vacía y se omite la ronda.

Swarm no modifica una config existente. Al cambiar ese archivo, renombra la config en `stack/ascaler.yml`, por ejemplo de `prometheus_config` a `prometheus_config_v2`.

## Sensibilidad

| Objetivo | Ajuste | Coste |
|---|---|---|
| Subir más rápido | Reducir `CPU_WINDOW_UP`, `WAIT_TIME` y la recolección | Más llamadas a Docker y reacción a picos cortos |
| Activar antes | Reducir `CPU_UPPER_LIMIT` | Más réplicas activas |
| Bajar con más seguridad | Aumentar `CPU_WINDOW_DOWN` o reducir `CPU_LOWER_LIMIT` | Réplicas inactivas durante más tiempo |
| Más margen por réplica | Reducir `CPU_TARGET` | Más réplicas |

Para picos previsibles, aumenta `ascaler.minimum` con antelación. Un autoescalador siempre reacciona cuando la carga ya ha empezado.

## Dimensionar el máximo

```text
réplicas = peticiones por segundo × CPU por petición / (límite × CPU_TARGET)
```

Ejemplo: `100 × 0,05 / (0,5 × 0,6) = 17` réplicas.

Si el máximo solo iguala la capacidad necesaria, no queda margen para vaciar la cola formada al inicio del pico.
