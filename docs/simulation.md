# Simulation

**Languages:** English | [Português](pt-BR/simulation.md) | [Español](es/simulation.md)

Starts a single-node Swarm with ascaler and an app that burns CPU on each request.

## What starts

| Stack | Services | File |
|---|---|---|
| `ascaler` | ascaler, Prometheus, cAdvisor | `stack/ascaler.yml` |
| `demo` | `web`, test app on port 8080 | `simulation/app.yml` |

The app spends 50 ms of CPU per request. With a 0.5 core limit, each replica handles ~10 requests per second.

## Step by step

**1. Start the environment:**

```bash
./simulation/up.sh
```

The script enables Swarm if needed, builds the image and waits for the app to reach `3/3`.

**2. In another terminal, follow along:**

```bash
./simulation/logs.sh
```

To also see the CPU read in each round, use `./simulation/logs.sh all`.

**3. In another terminal, generate the load:**

```bash
./simulation/load.sh
```

Optional, to see CPU per replica:

```bash
watch -n 5 'docker stats --no-stream --format "table {{.Name}}\t{{.CPUPerc}}" $(docker ps -qf name=demo_web)'
```

**4. Remove everything:**

```bash
./simulation/down.sh
```

Use `./simulation/down.sh --swarm` to also leave the Swarm.

## Load

`simulation/load.js` ramps up to 100 requests per second over 1 minute, holds for 2 and ramps down over 30 seconds. This load calls for ~17 replicas with `CPU_TARGET=60`.

## Reference results

Single runs, on WSL2 with one node and 20 logical cores, using the values in `stack/ascaler.yml`:

| Metric | Maximum 10 | Maximum 20 |
|---|---|---|
| Errors (`http_req_failed`) | 6.47% | 0.78% |
| Median latency | 2.33s | 85ms |
| `p(95)` | 59.99s | 2.45s |
| Replicas reached | 10 | 19 |
| First scale-up | ~26s | ~25s |

With maximum 20, the sequence was `5 → 8 → 14 → 19`, with no flapping. After the load, the service scaled down 2 at a time.

A second run, using the scripts in this folder, had `5 → 8 → 12 → 17`, 1.45% errors, 93ms median latency and a `p(95)` of 4.26s.

The maximum 10 test was stopped at 5min40, had a different load duration and used a lower cAdvisor limit, so it is only a rough comparison. Numbers vary by machine.

## Reading k6 output

| Metric | Meaning |
|---|---|
| `http_req_failed` | Error rate. Tends to concentrate at the start of the peak |
| `p(95)` | 95% of requests were faster than this value |
| `dropped_iterations` | Requests k6 could not start |

## Why not use `ab` with nginx

A very light app, under load from a single IP, produces thousands of new connections per second. In testing, new replicas stayed at 0% because the load stayed on the old ones. The most likely cause is source port reuse in Swarm's load balancing.

With heavier requests and fewer connections, as in this simulation, new replicas receive load normally.
