# Troubleshooting

**Languages:** English | [Português](pt-BR/troubleshooting.md) | [Español](es/troubleshooting.md)

## The service did not apply the new maximum

Editing the YAML does not change the running service. Run `docker stack deploy` and check:

```bash
docker service inspect SERVICE_NAME --format '{{json .Spec.Labels}}'
```

## The service went back to 1 replica after a deploy

Without `replicas` in the YAML, Swarm uses 1 on every deploy, and ascaler corrects it in the next round.

## Frequent `no metrics, skipping`

Likely causes:

- **cAdvisor short on CPU:** in testing, the warning appeared with a 0.10 limit and went away under load with 0.50.
- **Window too short:** it must cover at least 2 scrapes.
- **Prometheus restarted:** normal for the first few seconds, as there is no history.

## New replicas stay at 0% CPU

Check the distribution:

```bash
for i in $(seq 1 40); do curl -s localhost:8080; done | sort | uniq -c
```

If all of them respond here but sit idle under load, the load generator is probably the limit: high-volume connections from a single IP. This can also happen with a CDN or load balancer in front. A reverse proxy, such as Traefik or HAProxy, distributes per request.

## The browser always shows the same replica

Browsers reuse the connection (keep-alive), and Swarm picks the replica when each connection opens. This is not an error. Test with `curl`.

## Utilization looks low, but replicas are saturated

Utilization is a service-wide average. With 3 saturated replicas and 3 idle ones, it reads ~50% and does not scale. Compare with `docker stats`.

## It does not scale, even with high CPU

Look for `need more replica than authorized`, which means it is already at the maximum. Also check the `METRIC` line: scale-up only uses the short window.

## `docker swarm init` asks for `--advertise-addr`

The host has more than one network address. Use `docker swarm init --advertise-addr eth0`.

## Error when updating `prometheus.yml`

Swarm configs do not change. Rename the config in `stack/ascaler.yml` before deploying.
