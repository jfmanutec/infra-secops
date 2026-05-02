# Deploy na VM3

## Pré-requisitos

- Docker e Docker Compose plugin instalados
- rede Docker externa `docker-network-ger` criada
- Nginx Proxy Manager já operacional na `VM3`

## Estrutura esperada

```text
/srv/containers/
  keycloak/
  guacamole/
  bitwarden/
```

## Passos

1. Criar a rede externa:

```bash
docker network create docker-network-ger
```

2. Copiar os diretórios do repositório para `/srv/containers`.

3. Em cada serviço, copiar `.env.example` para `.env` e ajustar os valores reais.

4. Subir os serviços:

```bash
cd /srv/containers/keycloak && docker compose up -d
cd /srv/containers/guacamole && docker compose up -d
cd /srv/containers/bitwarden && docker compose up -d
```

## Observações

- O schema do Guacamole e aplicado automaticamente pelo PostgreSQL apenas em banco novo.
- Keycloak e Guacamole reaplicam a senha atual do `.env` no PostgreSQL durante `up -d`.
- As portas do host ficam limitadas a `127.0.0.1`; o acesso externo deve ocorrer via NPM.
