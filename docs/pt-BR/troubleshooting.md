# Problemas comuns

**Idiomas:** [English](../troubleshooting.md) | Português | [Español](../es/troubleshooting.md)

## O serviço não aplicou o novo máximo

Editar o YAML não altera o serviço em execução. Rode `docker stack deploy` e confira:

```bash
docker service inspect NOME_DO_SERVICO --format '{{json .Spec.Labels}}'
```

## O serviço voltou para 1 réplica depois do deploy

Sem `replicas` no YAML, o Swarm usa 1 a cada deploy, e o ascaler corrige na rodada seguinte.

## `no metrics, skipping` frequente

Causas prováveis:

- **cAdvisor com pouca CPU:** nos testes, o aviso aparecia com limite de 0,10 e sumiu sob carga com 0,50.
- **Janela curta demais:** ela deve cobrir pelo menos 2 coletas.
- **Prometheus reiniciado:** é normal nos primeiros segundos, porque não há histórico.

## Réplicas novas ficam em 0% de CPU

Verifique a distribuição:

```bash
for i in $(seq 1 40); do curl -s localhost:8080; done | sort | uniq -c
```

Se todas responderem aqui, mas ficarem paradas sob carga, o gerador de carga provavelmente é o limite: conexões em alto volume vindas de um único IP. Isso pode ocorrer também com CDN ou balanceador na frente. Um proxy reverso, como Traefik ou HAProxy, distribui por requisição.

## O navegador sempre mostra a mesma réplica

Navegadores reaproveitam a conexão (keep-alive), e o Swarm escolhe a réplica ao abrir cada conexão. Não é erro. Teste com `curl`.

## A utilização parece baixa, mas há réplicas saturadas

A utilização é uma média do serviço. Com 3 réplicas saturadas e 3 paradas, ele lê ~50% e não escala. Compare com `docker stats`.

## Não escala, mesmo com CPU alta

Procure por `need more replica than authorized`, que indica que ele já está no máximo. Confira também a linha `METRIC`: a subida usa só a janela curta.

## `docker swarm init` pede `--advertise-addr`

O host tem mais de um endereço de rede. Use `docker swarm init --advertise-addr eth0`.

## Erro ao atualizar `prometheus.yml`

Configs do Swarm não mudam. Renomeie a config em `stack/ascaler.yml` antes do deploy.
