# Solución de problemas

**Idiomas:** [English](../troubleshooting.md) | [Português](../pt-BR/troubleshooting.md) | Español

## El servicio no aplicó el nuevo máximo

Editar el YAML no cambia el servicio en ejecución. Ejecuta `docker stack deploy` y comprueba:

```bash
docker service inspect NOMBRE_DEL_SERVICIO --format '{{json .Spec.Labels}}'
```

## El servicio volvió a 1 réplica después del despliegue

Sin `replicas` en el YAML, Swarm usa 1 en cada despliegue, y ascaler lo corrige en la ronda siguiente.

## `no metrics, skipping` frecuente

Causas probables:

- **cAdvisor con poca CPU:** en las pruebas, el aviso aparecía con un límite de 0,10 y desapareció bajo carga con 0,50.
- **Ventana demasiado corta:** debe cubrir al menos 2 recolecciones.
- **Prometheus reiniciado:** es normal en los primeros segundos, porque no hay historial.

## Las réplicas nuevas se quedan en 0% de CPU

Comprueba la distribución:

```bash
for i in $(seq 1 40); do curl -s localhost:8080; done | sort | uniq -c
```

Si todas responden aquí pero se quedan paradas bajo carga, probablemente el límite sea el generador de carga: conexiones de alto volumen desde una sola IP. Esto también puede ocurrir con una CDN o un balanceador delante. Un proxy inverso, como Traefik o HAProxy, distribuye por petición.

## El navegador siempre muestra la misma réplica

Los navegadores reutilizan la conexión (keep-alive), y Swarm elige la réplica al abrir cada conexión. No es un error. Prueba con `curl`.

## La utilización parece baja, pero hay réplicas saturadas

La utilización es una media del servicio. Con 3 réplicas saturadas y 3 paradas, lee ~50% y no escala. Compara con `docker stats`.

## No escala, incluso con CPU alta

Busca `need more replica than authorized`, que indica que ya está en el máximo. Comprueba también la línea `METRIC`: la subida solo usa la ventana corta.

## `docker swarm init` pide `--advertise-addr`

El equipo tiene más de una dirección de red. Usa `docker swarm init --advertise-addr eth0`.

## Error al actualizar `prometheus.yml`

Las configs de Swarm no cambian. Renombra la config en `stack/ascaler.yml` antes del despliegue.
