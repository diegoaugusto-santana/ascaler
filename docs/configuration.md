# Configuration

**Languages:** English | [Português](pt-BR/configuration.md) | [Español](es/configuration.md)

## Service labels

They go in `deploy.labels` and take effect after a `docker stack deploy`.

| Label | Value | Description |
|---|---|---|
| `ascaler` | `true` | Enables autoscaling |
| `ascaler.minimum` | Integer | Minimum replicas. **Required** |
| `ascaler.maximum` | Integer | Maximum replicas. **Required** |

Also set `deploy.resources.limits.cpus`, because utilization is calculated against that limit.

## ascaler variables

| Variable | Script default | In `stack/ascaler.yml` | Description |
|---|---|---|---|
| `PROMETHEUS_URL` | `http://apps6.local:9090` | `http://prometheus:9090` | Prometheus address |
| `WAIT_TIME` | `60s` | `10s` | Interval between rounds |
| `CPU_UPPER_LIMIT` | `85` | `70` | Above this, scale up (% of limit) |
| `CPU_LOWER_LIMIT` | `25` | `25` | Below this, scale down (% of limit) |
| `CPU_TARGET` | `60` | `60` | Utilization the calculation aims for |
| `CPU_WINDOW_UP` | `30s` | `15s` | Scale-up window |
| `CPU_WINDOW_DOWN` | `2m` | `2m` | Scale-down window |
| `MAX_DOWN_STEP` | `2` | `2` | Maximum replicas removed per round |

## Prometheus scraping

`scrape_interval` lives in `stack/config/prometheus.yml`, not in ascaler.

**Rule:** the ascaler window must cover at least 2 scrapes. With a 15s window, scrape every 7s at most. If the window is too short, the query comes back empty and the round is skipped.

Swarm does not change an existing config. When you edit that file, rename the config in `stack/ascaler.yml`, for example from `prometheus_config` to `prometheus_config_v2`.

## Sensitivity

| Goal | Setting | Cost |
|---|---|---|
| Scale up faster | Lower `CPU_WINDOW_UP`, `WAIT_TIME` and the scrape interval | More Docker calls and reactions to short spikes |
| Trigger earlier | Lower `CPU_UPPER_LIMIT` | More replicas running |
| Scale down more safely | Raise `CPU_WINDOW_DOWN` or lower `CPU_LOWER_LIMIT` | Idle replicas for longer |
| More headroom per replica | Lower `CPU_TARGET` | More replicas |

For predictable peaks, raise `ascaler.minimum` ahead of time. An autoscaler always reacts after the load has started.

## Sizing the maximum

```text
replicas = requests per second × CPU per request / (limit × CPU_TARGET)
```

Example: `100 × 0.05 / (0.5 × 0.6) = 17` replicas.

If the maximum only matches the required capacity, there is no headroom left to drain the queue built up at the start of a peak.
