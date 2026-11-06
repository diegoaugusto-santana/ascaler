# Simulação

Sobe um Swarm de um nó com o ascaler e um app que consome CPU por requisição.

## O que sobe

| Stack | Serviços | Arquivo |
|---|---|---|
| `ascaler` | ascaler, Prometheus, cAdvisor | `stack/ascaler.yml` |
| `demo` | `web`, app de teste na porta 8080 | `simulation/app.yml` |

O app gasta 50 ms de CPU por requisição. Com limite de 0,5 núcleo, cada réplica atende ~10 requisições por segundo.

## Passo a passo

**1. Suba o ambiente:**

```bash
./simulation/up.sh
```

O script ativa o Swarm se preciso, gera a imagem e espera o app chegar a `3/3`.

**2. Em outro terminal, acompanhe:**

```bash
./simulation/logs.sh
```

Para ver também a CPU lida em cada rodada, use `./simulation/logs.sh all`.

**3. Em outro terminal, gere a carga:**

```bash
./simulation/load.sh
```

Opcional, para ver a CPU por réplica:

```bash
watch -n 5 'docker stats --no-stream --format "table {{.Name}}\t{{.CPUPerc}}" $(docker ps -qf name=demo_web)'
```

**4. Remova tudo:**

```bash
./simulation/down.sh
```

Use `./simulation/down.sh --swarm` para sair do Swarm também.

## Carga

`simulation/load.js` sobe a 100 requisições por segundo em 1 minuto, mantém por 2 e desce em 30 segundos. Essa carga pede ~17 réplicas com `CPU_TARGET=60`.

## Resultado de referência

Execuções únicas, em WSL2 com um nó e 20 núcleos lógicos, com os valores de `stack/ascaler.yml`:

| Métrica | Máximo 10 | Máximo 20 |
|---|---|---|
| Erros (`http_req_failed`) | 6,47% | 0,78% |
| Latência mediana | 2,33s | 85ms |
| `p(95)` | 59,99s | 2,45s |
| Réplicas alcançadas | 10 | 19 |
| Primeira escala | ~26s | ~25s |

Com máximo 20, a sequência foi `5 → 8 → 14 → 19`, sem oscilar. Depois da carga, o serviço desceu de 2 em 2.

Uma segunda execução, já com os scripts desta pasta, teve `5 → 8 → 12 → 17`, 1,45% de erros, latência mediana de 93ms e `p(95)` de 4,26s.

O teste com máximo 10 foi interrompido aos 5min40, teve outra duração de carga e usava limite menor no cAdvisor, então serve só de comparação aproximada. Os números variam conforme a máquina.

## Como ler o `k6`

| Métrica | Significado |
|---|---|
| `http_req_failed` | Taxa de erros. Costuma se concentrar no início do pico |
| `p(95)` | 95% das requisições foram mais rápidas que esse valor |
| `dropped_iterations` | Requisições que o `k6` não conseguiu iniciar |

## Por que não usar `ab` com nginx

Um app muito leve, sob carga de um único IP, gera milhares de conexões novas por segundo. Nos testes, as réplicas novas ficaram em 0%, porque a carga seguiu nas antigas. A causa mais provável é o reaproveitamento de portas de origem no balanceamento do Swarm.

Com requisições mais pesadas e menos conexões, como nesta simulação, as réplicas novas recebem carga normalmente.
