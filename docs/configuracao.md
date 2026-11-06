# Configuração

## Labels do serviço

Ficam em `deploy.labels` e valem depois de um `docker stack deploy`.

| Label | Valor | Descrição |
|---|---|---|
| `ascaler` | `true` | Ativa o autoscaling |
| `ascaler.minimum` | Inteiro | Mínimo de réplicas. **Obrigatório** |
| `ascaler.maximum` | Inteiro | Máximo de réplicas. **Obrigatório** |

Defina também `deploy.resources.limits.cpus`, porque a utilização é calculada sobre esse limite.

## Variáveis do ascaler

| Variável | Padrão do script | Em `stack/ascaler.yml` | Descrição |
|---|---|---|---|
| `PROMETHEUS_URL` | `http://apps6.local:9090` | `http://prometheus:9090` | Endereço do Prometheus |
| `WAIT_TIME` | `60s` | `10s` | Intervalo entre rodadas |
| `CPU_UPPER_LIMIT` | `85` | `70` | Acima disso, sobe (% do limite) |
| `CPU_LOWER_LIMIT` | `25` | `25` | Abaixo disso, desce (% do limite) |
| `CPU_TARGET` | `60` | `60` | Utilização que o cálculo busca alcançar |
| `CPU_WINDOW_UP` | `30s` | `15s` | Janela para subir |
| `CPU_WINDOW_DOWN` | `2m` | `2m` | Janela para descer |
| `MAX_DOWN_STEP` | `2` | `2` | Máximo de réplicas removidas por rodada |

## Coleta do Prometheus

O `scrape_interval` fica em `stack/config/prometheus.yml`, não no ascaler.

**Regra:** a janela do ascaler precisa cobrir pelo menos 2 coletas. Com janela de 15s, use coleta de no máximo 7s. Se a janela for curta demais, a consulta volta vazia, e a rodada é ignorada.

O Swarm não altera uma config existente. Ao mudar esse arquivo, renomeie a config em `stack/ascaler.yml`, por exemplo de `prometheus_config` para `prometheus_config_v2`.

## Sensibilidade

| Objetivo | Ajuste | Custo |
|---|---|---|
| Subir mais rápido | Reduzir `CPU_WINDOW_UP`, `WAIT_TIME` e a coleta | Mais chamadas ao Docker e reação a picos curtos |
| Disparar mais cedo | Reduzir `CPU_UPPER_LIMIT` | Mais réplicas ligadas |
| Descer com mais segurança | Aumentar `CPU_WINDOW_DOWN` ou reduzir `CPU_LOWER_LIMIT` | Réplicas ociosas por mais tempo |
| Mais folga por réplica | Reduzir `CPU_TARGET` | Mais réplicas |

Para picos previsíveis, aumente o `ascaler.minimum` antes do horário. O autoscaler sempre reage depois que a carga já começou.

## Dimensionar o máximo

```text
réplicas = requisições por segundo × CPU por requisição / (limite × CPU_TARGET)
```

Exemplo: `100 × 0,05 / (0,5 × 0,6) = 17` réplicas.

Se o máximo apenas igualar a capacidade necessária, não sobra folga para esvaziar a fila formada no início do pico.
