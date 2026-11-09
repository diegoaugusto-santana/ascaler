# ascaler

**Languages:** English | [Português](README.pt-BR.md) | [Español](README.es.md)

A simple autoscaler for **Docker Swarm**, written in Bash. It watches service CPU through Prometheus and adjusts the number of replicas in proportion to the load.

> Fork of [UnclePhil/ascaler](https://github.com/UnclePhil/ascaler), which is itself a rewrite of [jcwimer/docker-swarm-autoscaler](https://github.com/jcwimer/docker-swarm-autoscaler). Credit for the base of the project goes to the original authors.

## What this fork changes

- **Fixed comparisons:** the original compared numbers as text, so `3 > 10` was true and an idle service scaled up to the maximum.
- **Proportional scaling:** calculates the replicas needed, instead of adding one at a time.
- **CPU per limit:** uses the percentage of each replica's limit, instead of the sum across replicas.
- **Separate windows:** fast scale-up and slow scale-down.
- **Decision logs:** the `METRIC` line shows what was read in each round.
- **Ready-made simulation:** a complete environment in a few commands.

## Components

| Container | Role |
|---|---|
| **ascaler** | Decides how many replicas each service should have and tells Swarm to scale |
| **Prometheus** | Stores the metrics |
| **cAdvisor** | Measures container CPU, with one instance per cluster node |

```text
app containers ──> cAdvisor ──> Prometheus
                                    │
                                    v
Docker Swarm  <──── scales ───── ascaler
```

Details in [docs/architecture.md](docs/architecture.md).

## Quick start

Requires Docker with Swarm, on a manager node.

```bash
git clone https://github.com/diegoaugusto-santana/ascaler.git
cd ascaler
docker swarm init
docker build -t ascaler:local -f ascaler/Dockerfile.1.2.0 ascaler
docker stack deploy --detach=true -c stack/ascaler.yml ascaler
```

Then add the labels to your service:

```yaml
deploy:
  resources:
    limits:
      cpus: '0.50'
  labels:
    ascaler: 'true'
    ascaler.minimum: '3'
    ascaler.maximum: '20'
```

Step by step in [docs/usage.md](docs/usage.md).

## Simulate a peak

```bash
./simulation/up.sh     # starts everything
./simulation/logs.sh   # in another terminal: follows the decisions
./simulation/load.sh   # generates load with k6
./simulation/down.sh   # removes everything
```

Results and how to read them in [docs/simulation.md](docs/simulation.md).

## Documentation

| Document | Contents |
|---|---|
| [Architecture](docs/architecture.md) | How the pieces connect and how decisions are made |
| [Configuration](docs/configuration.md) | Variables, labels and sensitivity settings |
| [Usage](docs/usage.md) | How to install it and apply it to your services |
| [Simulation](docs/simulation.md) | How to test from scratch, with expected results |
| [Troubleshooting](docs/troubleshooting.md) | Symptoms, causes and fixes found during testing |

## Changelog

### 1.2.0

- Fixes numeric comparisons, the `null` value and the use of stale replica counts.
- Adds proportional scaling, separate windows and decision logs.
- Adds the simulation and the documentation.

### 1.1.0

- Docker 29 compatibility.

### 1.0.0

- Initial release.

## License

MIT, as in the original project. See [LICENSE](LICENSE).
