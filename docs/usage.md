# Usage

**Languages:** English | [Português](pt-BR/usage.md) | [Español](es/usage.md)

## Requirements

- Docker with Swarm enabled.
- Running on a manager node.

On Windows, use WSL2 with Docker Engine installed. In PowerShell:

```bash
wsl --install -d Ubuntu
```

Inside Ubuntu:

```bash
curl -fsSL https://get.docker.com | sudo sh
sudo usermod -aG docker $USER
```

Restart the distro with `wsl --terminate Ubuntu`. Keep the project in the Linux folder (`~`), not in `/mnt/c`.

## 1. Start Swarm

```bash
docker swarm init
```

On hosts with more than one network address, such as WSL, specify the interface:

```bash
docker swarm init --advertise-addr eth0
```

## 2. Build the image

No image is published for this fork.

```bash
docker build -t ascaler:local -f ascaler/Dockerfile.1.2.0 ascaler
```

On a multi-node cluster, publish the image to your own registry and update `image:` in `stack/ascaler.yml`, so managers can pull it.

## 3. Start ascaler

```bash
docker stack deploy --detach=true -c stack/ascaler.yml ascaler
docker service ls
```

The `could not be accessed on a registry` warning is expected with a local image.

## 4. Label your service

```yaml
services:
  web:
    image: my-image
    deploy:
      resources:
        limits:
          cpus: '0.50'
      labels:
        ascaler: 'true'
        ascaler.minimum: '3'
        ascaler.maximum: '20'
```

```bash
docker stack deploy --detach=true -c my-app.yml myapp
```

If the YAML does not set `replicas`, each new deploy returns the service to 1 replica, and ascaler brings it back to the minimum.

## 5. Follow along

```bash
docker service logs -f -t --no-task-ids --tail 0 ascaler_ascaler
```

| Message | Meaning |
|---|---|
| `METRIC: ... util_up=... util_down=...` | Utilization read for each window |
| `INFO: ... scaled to N replicas` | Scaling performed |
| `WARNING: ... need more replica than authorized` | Already at the maximum and needs more |
| `WARNING: ... no metrics, skipping` | Round skipped, no data |

CPU per replica:

```bash
docker stats --no-stream --format "table {{.Name}}\t{{.CPUPerc}}"
```

## Before production

- Test in a separate environment: ascaler has access to the Docker socket.
- Start with a conservative `ascaler.maximum` and observe.
- Check the minimum and maximum labels on every labeled service.
- ascaler does not protect against attacks. Use a WAF or CDN and rate limiting at the edge.
- Swarm balances per connection. To distribute per request, put a reverse proxy in front. See [Troubleshooting](troubleshooting.md).
