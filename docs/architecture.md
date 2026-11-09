# Architecture

**Languages:** English | [Português](pt-BR/architecture.md) | [Español](es/architecture.md)

ascaler is a **central service**, not a sidecar. Your app does not change: it only needs labels. A single ascaler handles every labeled service.

## Containers

| Service | Replicas | What it does |
|---|---|---|
| `ascaler` | 1, on a manager | Reads labels and metrics, decides and scales |
| `prometheus` | 1, on a manager | Collects and stores the metrics |
| `cadvisor` | 1 per node (global) | Measures the CPU of all containers on the node |
| Your app | From minimum to maximum | The service being scaled |

ascaler must run on a manager because it uses `/var/run/docker.sock`, and only managers can scale services.

## Decision cycle

Every `WAIT_TIME`, for each service with `ascaler=true`:

1. Reads the minimum, maximum, replicas and CPU limit from Swarm.
2. Corrects the replicas if they are outside the minimum or maximum.
3. Queries CPU over two windows: `CPU_WINDOW_UP` and `CPU_WINDOW_DOWN`.
4. Calculates the utilization for each window.
5. Decides whether to scale up, scale down or hold.

## Calculation

```text
utilization = summed replica CPU / (replicas × CPU limit)
desired replicas = round up (replicas × utilization / CPU_TARGET)
```

CPU comes as a percentage of one core. Without a defined limit, each replica counts as 1 core.

**Example:** 3 replicas with a 0.5 limit, summing 150%:

```text
utilization = 150 / (3 × 0.5) = 100%
desired replicas = 3 × 100 / 60 = 5
```

## Rules

| Direction | Condition | Behavior |
|---|---|---|
| Up | Short window above `CPU_UPPER_LIMIT` | Goes straight to the calculated value, up to the maximum |
| Down | **Both windows** below `CPU_LOWER_LIMIT` | Removes at most `MAX_DOWN_STEP` per round, down to the minimum |
| No metric | The query came back empty | Logs a warning and leaves the service alone |

Requiring both windows for scale-down avoids removing replicas at the start of a peak, when the long window still contains the idle period.

## Query used

```text
sum(rate(container_cpu_usage_seconds_total{container_label_com_docker_swarm_service_name="SERVICE"}[WINDOW])) * 100
```
