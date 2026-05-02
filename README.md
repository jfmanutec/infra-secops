# infra-secops

Stack Docker Compose para centralizar na `VM3` os serviços:

- Keycloak
- Apache Guacamole
- Vaultwarden

Todos os serviços foram preparados para:

- persistir dados em diretórios locais já definidos
- usar a rede Docker externa `docker-network-ger`
- expor portas do host apenas em `127.0.0.1`
- operar atrás do Nginx Proxy Manager

## Estrutura

- `keycloak/`
- `guacamole/`
- `bitwarden/`
- `deploy_vm03.sh`
- `migracao_bitwarden.txt`

## Arquivos sensíveis

Os arquivos `.env` não devem ser versionados.

Cada serviço possui um `.env.example`:

- `keycloak/.env.example`
- `guacamole/.env.example`
- `bitwarden/.env.example`

Copie cada exemplo para `.env` e ajuste os valores reais antes do deploy.

## Deploy

1. Criar a rede externa na `VM3`:

```bash
docker network create docker-network-ger
```

2. Copiar os diretórios para `/srv/containers` na `VM3`.

3. Ajustar os `.env`.

4. Subir os serviços:

```bash
cd /srv/containers/keycloak && docker compose up -d
cd /srv/containers/guacamole && docker compose up -d
cd /srv/containers/bitwarden && docker compose up -d
```

## Comportamentos importantes

### Guacamole

O schema do Guacamole e inicializado automaticamente no primeiro `docker compose up -d` do PostgreSQL e:

- cria o schema apenas se o banco ainda estiver vazio
- não reaplica schema se o banco já existir

### Sincronização de senha do PostgreSQL

Keycloak e Guacamole usam um wrapper no PostgreSQL para alinhar a senha do usuário do banco com o valor atual do `.env` em cada `docker compose up -d`.

Para isso funcionar sem erro:

- no Keycloak, `POSTGRES_PASSWORD` e `KC_DB_PASSWORD` devem ser iguais
- no Guacamole, `POSTGRES_PASSWORD` e `POSTGRESQL_PASSWORD` devem ser iguais

Isso sincroniza senha. Não sincroniza renomeação de usuário, banco ou hostname.

## Documentação operacional

- deploy guiado: `deploy_vm03.sh`
- migração do Vaultwarden: `migracao_bitwarden.txt`
- documentação de deploy: `docs/DEPLOY.md`
- documentação de segredos: `docs/SECRETS.md`
