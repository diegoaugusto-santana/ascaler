# Arquitectura

**Idiomas:** [English](../architecture.md) | [Português](../pt-BR/architecture.md) | Español

ascaler es un **servicio central**, no un sidecar. Tu aplicación no cambia: solo necesita etiquetas. Un único ascaler atiende todos los servicios etiquetados.

## Contenedores

| Servicio | Réplicas | Qué hace |
|---|---|---|
| `ascaler` | 1, en un manager | Lee etiquetas y métricas, decide y escala |
| `prometheus` | 1, en un manager | Recoge y almacena las métricas |
| `cadvisor` | 1 por nodo (global) | Mide la CPU de todos los contenedores del nodo |
| Tu aplicación | Del mínimo al máximo | El servicio que se escala |

ascaler debe ejecutarse en un manager porque usa `/var/run/docker.sock`, y solo los managers pueden escalar servicios.

## Ciclo de decisión

Cada `WAIT_TIME`, para cada servicio con `ascaler=true`:

1. Lee el mínimo, el máximo, las réplicas y el límite de CPU desde Swarm.
2. Corrige las réplicas si están fuera del mínimo o del máximo.
3. Consulta la CPU en dos ventanas: `CPU_WINDOW_UP` y `CPU_WINDOW_DOWN`.
4. Calcula la utilización de cada ventana.
5. Decide si sube, baja o mantiene.

## Cálculo

```text
utilización = CPU sumada de las réplicas / (réplicas × límite de CPU)
réplicas deseadas = redondear hacia arriba (réplicas × utilización / CPU_TARGET)
```

La CPU se expresa como porcentaje de un núcleo. Sin un límite definido, cada réplica cuenta como 1 núcleo.

**Ejemplo:** 3 réplicas con límite de 0,5 que suman 150%:

```text
utilización = 150 / (3 × 0,5) = 100%
réplicas deseadas = 3 × 100 / 60 = 5
```

## Reglas

| Dirección | Condición | Comportamiento |
|---|---|---|
| Subir | Ventana corta por encima de `CPU_UPPER_LIMIT` | Va directamente al valor calculado, hasta el máximo |
| Bajar | **Ambas ventanas** por debajo de `CPU_LOWER_LIMIT` | Quita como máximo `MAX_DOWN_STEP` por ronda, hasta el mínimo |
| Sin métrica | La consulta volvió vacía | Registra un aviso y no toca el servicio |

Exigir ambas ventanas para bajar evita quitar réplicas al inicio de un pico, cuando la ventana larga todavía contiene el periodo inactivo.

## Consulta utilizada

```text
sum(rate(container_cpu_usage_seconds_total{container_label_com_docker_swarm_service_name="SERVICIO"}[VENTANA])) * 100
```
