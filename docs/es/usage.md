# Uso

**Idiomas:** [English](../usage.md) | [Português](../pt-BR/usage.md) | Español

## Requisitos

- Docker con Swarm activo.
- Ejecutar en un nodo manager.

En Windows, usa WSL2 con Docker Engine instalado. En PowerShell:

```bash
wsl --install -d Ubuntu
```

Dentro de Ubuntu:

```bash
curl -fsSL https://get.docker.com | sudo sh
sudo usermod -aG docker $USER
```

Reinicia la distro con `wsl --terminate Ubuntu`. Mantén el proyecto en la carpeta de Linux (`~`), no en `/mnt/c`.

## 1. Inicia Swarm

```bash
docker swarm init
```

En equipos con más de una dirección de red, como WSL, indica la interfaz:

```bash
docker swarm init --advertise-addr eth0
```

## 2. Genera la imagen

No hay ninguna imagen publicada para este fork.

```bash
docker build -t ascaler:local -f ascaler/Dockerfile.1.2.0 ascaler
```

En un clúster con varios nodos, publica la imagen en tu propio registro y ajusta `image:` en `stack/ascaler.yml`, para que los managers puedan descargarla.

## 3. Levanta ascaler

```bash
docker stack deploy --detach=true -c stack/ascaler.yml ascaler
docker service ls
```

El aviso `could not be accessed on a registry` es normal con una imagen local.

## 4. Etiqueta tu servicio

```yaml
services:
  web:
    image: mi-imagen
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
docker stack deploy --detach=true -c mi-app.yml miapp
```

Si el YAML no define `replicas`, cada nuevo despliegue devuelve el servicio a 1 réplica, y ascaler lo lleva de nuevo al mínimo.

## 5. Haz el seguimiento

```bash
docker service logs -f -t --no-task-ids --tail 0 ascaler_ascaler
```

| Mensaje | Significado |
|---|---|
| `METRIC: ... util_up=... util_down=...` | Utilización leída en cada ventana |
| `INFO: ... scaled to N replicas` | Escalado realizado |
| `WARNING: ... need more replica than authorized` | Ya está en el máximo y necesita más |
| `WARNING: ... no metrics, skipping` | Ronda omitida, sin datos |

CPU por réplica:

```bash
docker stats --no-stream --format "table {{.Name}}\t{{.CPUPerc}}"
```

## Antes de producción

- Prueba en un entorno separado: ascaler tiene acceso al socket de Docker.
- Empieza con un `ascaler.maximum` conservador y observa.
- Comprueba las etiquetas de mínimo y máximo en cada servicio etiquetado.
- ascaler no protege contra ataques. Usa un WAF o CDN y limitación de peticiones en la entrada.
- Swarm balancea por conexión. Para distribuir por petición, coloca un proxy inverso delante. Consulta [Solución de problemas](troubleshooting.md).
