# ascaler

**Idiomas:** [English](README.md) | Português | [Español](README.es.md)

Autoscaler simples para **Docker Swarm**, escrito em Bash. Ele acompanha a CPU dos serviços pelo Prometheus e ajusta o número de réplicas de forma proporcional à carga.

> Fork de [UnclePhil/ascaler](https://github.com/UnclePhil/ascaler), que por sua vez é uma reescrita de [jcwimer/docker-swarm-autoscaler](https://github.com/jcwimer/docker-swarm-autoscaler). O crédito pela base do projeto é dos autores originais.

## O que muda neste fork

- **Comparações corrigidas:** o original comparava números como texto, então `3 > 10` era verdadeiro e um serviço ocioso subia ao máximo.
- **Escala proporcional:** calcula as réplicas necessárias, em vez de somar uma por vez.
- **CPU por limite:** usa a porcentagem do limite de cada réplica, em vez da soma de todas.
- **Janelas separadas:** subida rápida e descida lenta.
- **Logs de decisão:** a linha `METRIC` mostra o que foi lido em cada rodada.
- **Simulação pronta:** um ambiente completo com poucos comandos.

## Componentes

| Container | Papel |
|---|---|
| **ascaler** | Decide quantas réplicas cada serviço deve ter e manda o Swarm escalar |
| **Prometheus** | Guarda as métricas |
| **cAdvisor** | Mede a CPU dos containers, com um por nó do cluster |

```text
containers do app ──> cAdvisor ──> Prometheus
                                       │
                                       v
Docker Swarm  <──── escala ──────── ascaler
```

Detalhes em [docs/pt-BR/architecture.md](docs/pt-BR/architecture.md).

## Início rápido

Requer Docker com Swarm, em um nó manager.

```bash
git clone https://github.com/diegoaugusto-santana/ascaler.git
cd ascaler
docker swarm init
docker build -t ascaler:local -f ascaler/Dockerfile.1.2.0 ascaler
docker stack deploy --detach=true -c stack/ascaler.yml ascaler
```

Depois, adicione os labels ao seu serviço:

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

Passo a passo em [docs/pt-BR/usage.md](docs/pt-BR/usage.md).

## Simular um pico

```bash
./simulation/up.sh     # sobe tudo
./simulation/logs.sh   # em outro terminal: acompanha as decisões
./simulation/load.sh   # gera a carga com k6
./simulation/down.sh   # remove tudo
```

Resultados e leitura em [docs/pt-BR/simulation.md](docs/pt-BR/simulation.md).

## Documentação

| Documento | Conteúdo |
|---|---|
| [Arquitetura](docs/pt-BR/architecture.md) | Como as peças se conectam e como a decisão é tomada |
| [Configuração](docs/pt-BR/configuration.md) | Variáveis, labels e ajustes de sensibilidade |
| [Uso](docs/pt-BR/usage.md) | Como instalar e aplicar nos seus serviços |
| [Simulação](docs/pt-BR/simulation.md) | Como testar, do zero, com os resultados esperados |
| [Problemas comuns](docs/pt-BR/troubleshooting.md) | Sintomas, causas e soluções encontrados em testes |

## Changelog

### 1.2.0

- Corrige comparações numéricas, o valor `null` e o uso de réplicas desatualizadas.
- Adiciona escala proporcional, janelas separadas e logs de decisão.
- Adiciona a simulação e a documentação.

### 1.1.0

- Compatibilidade com Docker 29.

### 1.0.0

- Versão inicial.

## Licença

MIT, como no projeto original. Veja [LICENSE](LICENSE).
