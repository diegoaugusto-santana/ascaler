# ascaler

**Idiomas:** [English](README.md) | [Português](README.pt-BR.md) | Español

Autoscaler sencillo para **Docker Swarm**, escrito en Bash. Supervisa la CPU de los servicios a través de Prometheus y ajusta el número de réplicas de forma proporcional a la carga.

> Fork de [UnclePhil/ascaler](https://github.com/UnclePhil/ascaler), que a su vez es una reescritura de [jcwimer/docker-swarm-autoscaler](https://github.com/jcwimer/docker-swarm-autoscaler). El crédito por la base del proyecto es de los autores originales.

## Qué cambia en este fork

- **Comparaciones corregidas:** el original comparaba números como texto, así que `3 > 10` era verdadero y un servicio inactivo subía al máximo.
- **Escalado proporcional:** calcula las réplicas necesarias, en lugar de sumar una cada vez.
- **CPU por límite:** usa el porcentaje del límite de cada réplica, en lugar de la suma de todas.
- **Ventanas separadas:** subida rápida y bajada lenta.
- **Registros de decisión:** la línea `METRIC` muestra lo que se leyó en cada ronda.
- **Simulación lista:** un entorno completo con pocos comandos.

## Componentes

| Contenedor | Función |
|---|---|
| **ascaler** | Decide cuántas réplicas debe tener cada servicio y ordena a Swarm que escale |
| **Prometheus** | Almacena las métricas |
| **cAdvisor** | Mide la CPU de los contenedores, con una instancia por nodo del clúster |

```text
contenedores de la app ──> cAdvisor ──> Prometheus
                                            │
                                            v
Docker Swarm  <────── escala ─────────── ascaler
```

Detalles en [docs/es/architecture.md](docs/es/architecture.md).

## Inicio rápido

Requiere Docker con Swarm, en un nodo manager.

```bash
git clone https://github.com/diegoaugusto-santana/ascaler.git
cd ascaler
docker swarm init
docker build -t ascaler:local -f ascaler/Dockerfile.1.2.0 ascaler
docker stack deploy --detach=true -c stack/ascaler.yml ascaler
```

Después, añade las etiquetas a tu servicio:

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

Paso a paso en [docs/es/usage.md](docs/es/usage.md).

## Simular un pico

```bash
./simulation/up.sh     # levanta todo
./simulation/logs.sh   # en otra terminal: sigue las decisiones
./simulation/load.sh   # genera la carga con k6
./simulation/down.sh   # elimina todo
```

Resultados y cómo leerlos en [docs/es/simulation.md](docs/es/simulation.md).

## Documentación

| Documento | Contenido |
|---|---|
| [Arquitectura](docs/es/architecture.md) | Cómo se conectan las piezas y cómo se toman las decisiones |
| [Configuración](docs/es/configuration.md) | Variables, etiquetas y ajustes de sensibilidad |
| [Uso](docs/es/usage.md) | Cómo instalarlo y aplicarlo a tus servicios |
| [Simulación](docs/es/simulation.md) | Cómo probar desde cero, con los resultados esperados |
| [Solución de problemas](docs/es/troubleshooting.md) | Síntomas, causas y soluciones encontrados en las pruebas |

## Registro de cambios

### 1.2.0

- Corrige las comparaciones numéricas, el valor `null` y el uso de un número de réplicas desactualizado.
- Añade escalado proporcional, ventanas separadas y registros de decisión.
- Añade la simulación y la documentación.

### 1.1.0

- Compatibilidad con Docker 29.

### 1.0.0

- Versión inicial.

## Licencia

MIT, como en el proyecto original. Consulta [LICENSE](LICENSE).
