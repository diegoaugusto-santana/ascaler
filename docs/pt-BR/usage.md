# Uso

**Idiomas:** [English](../usage.md) | Português | [Español](../es/usage.md)

## Requisitos

- Docker com Swarm ativo.
- Executar em um nó manager.

No Windows, use um WSL2 com Docker Engine instalado. No PowerShell:

```bash
wsl --install -d Ubuntu
```

Dentro do Ubuntu:

```bash
curl -fsSL https://get.docker.com | sudo sh
sudo usermod -aG docker $USER
```

Reinicie a distro com `wsl --terminate Ubuntu`. Mantenha o projeto na pasta do Linux (`~`), não em `/mnt/c`.

## 1. Inicie o Swarm

```bash
docker swarm init
```

Em ambientes com mais de um endereço de rede, como o WSL, informe a interface:

```bash
docker swarm init --advertise-addr eth0
```

## 2. Gere a imagem

Não há imagem publicada para este fork.

```bash
docker build -t ascaler:local -f ascaler/Dockerfile.1.2.0 ascaler
```

Em um cluster com vários nós, publique a imagem em um registry seu e ajuste `image:` em `stack/ascaler.yml`, para que os managers consigam baixá-la.

## 3. Suba o ascaler

```bash
docker stack deploy --detach=true -c stack/ascaler.yml ascaler
docker service ls
```

O aviso `could not be accessed on a registry` é esperado com imagem local.

## 4. Marque seu serviço

```yaml
services:
  web:
    image: minha-imagem
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
docker stack deploy --detach=true -c meu-app.yml meuapp
```

Se o YAML não definir `replicas`, cada novo deploy volta o serviço para 1 réplica, e o ascaler o leva de volta ao mínimo.

## 5. Acompanhe

```bash
docker service logs -f -t --no-task-ids --tail 0 ascaler_ascaler
```

| Mensagem | Significado |
|---|---|
| `METRIC: ... util_up=... util_down=...` | Utilização lida em cada janela |
| `INFO: ... scaled to N replicas` | Escala realizada |
| `WARNING: ... need more replica than authorized` | Já está no máximo e precisa de mais |
| `WARNING: ... no metrics, skipping` | Rodada ignorada, sem dados |

CPU por réplica:

```bash
docker stats --no-stream --format "table {{.Name}}\t{{.CPUPerc}}"
```

## Antes de produção

- Teste em um ambiente separado: o ascaler acessa o socket do Docker.
- Comece com um `ascaler.maximum` conservador e observe.
- Confira os labels de mínimo e máximo em todo serviço marcado.
- O ascaler não protege contra ataques. Use WAF ou CDN e limite de requisições na entrada.
- O Swarm balanceia por conexão. Para dividir por requisição, coloque um proxy reverso na frente. Veja [Problemas comuns](troubleshooting.md).
