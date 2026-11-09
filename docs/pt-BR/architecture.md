# Arquitetura

**Idiomas:** [English](../architecture.md) | Português | [Español](../es/architecture.md)

O ascaler é um **serviço central**, não um sidecar. O seu app não muda: basta receber labels. Um único ascaler atende todos os serviços marcados.

## Containers

| Serviço | Réplicas | O que faz |
|---|---|---|
| `ascaler` | 1, em um manager | Lê labels e métricas, decide e escala |
| `prometheus` | 1, em um manager | Coleta e guarda as métricas |
| `cadvisor` | 1 por nó (global) | Mede a CPU de todos os containers do nó |
| Seu app | Do mínimo ao máximo | Serviço escalado |

O ascaler precisa rodar em um manager porque acessa `/var/run/docker.sock`, e só managers podem escalar serviços.

## Ciclo de decisão

A cada `WAIT_TIME`, para cada serviço com `ascaler=true`:

1. Lê mínimo, máximo, réplicas e limite de CPU do Swarm.
2. Corrige as réplicas se estiverem fora do mínimo ou do máximo.
3. Consulta a CPU em duas janelas: `CPU_WINDOW_UP` e `CPU_WINDOW_DOWN`.
4. Calcula a utilização de cada janela.
5. Decide se sobe, desce ou mantém.

## Cálculo

```text
utilização = CPU somada das réplicas / (réplicas × limite de CPU)
réplicas desejadas = arredondar para cima (réplicas × utilização / CPU_TARGET)
```

A CPU vem em porcentagem de um núcleo. Sem limite definido, cada réplica conta como 1 núcleo.

**Exemplo:** 3 réplicas com limite de 0,5 somando 150%:

```text
utilização = 150 / (3 × 0,5) = 100%
réplicas desejadas = 3 × 100 / 60 = 5
```

## Regras

| Direção | Condição | Comportamento |
|---|---|---|
| Subir | Janela curta acima de `CPU_UPPER_LIMIT` | Vai direto ao valor calculado, até o máximo |
| Descer | **As duas janelas** abaixo de `CPU_LOWER_LIMIT` | Desce no máximo `MAX_DOWN_STEP` por rodada, até o mínimo |
| Sem métrica | A consulta veio vazia | Registra um aviso e não mexe no serviço |

Exigir as duas janelas na descida evita remover réplicas no começo de um pico, quando a janela longa ainda contém o período ocioso.

## Consulta usada

```text
sum(rate(container_cpu_usage_seconds_total{container_label_com_docker_swarm_service_name="SERVICO"}[JANELA])) * 100
```
