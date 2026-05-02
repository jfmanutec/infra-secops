# Segredos e Arquivos `.env`

## Regras

- Nunca versionar `.env`
- Versionar apenas `.env.example`
- Manter as senhas reais apenas na `VM3` ou em cofre seguro

## Sincronização de senha

### Keycloak

Os campos abaixo devem sempre ter o mesmo valor:

- `POSTGRES_PASSWORD`
- `KC_DB_PASSWORD`

### Guacamole

Os campos abaixo devem sempre ter o mesmo valor:

- `POSTGRES_PASSWORD`
- `POSTGRESQL_PASSWORD`

## Caracteres especiais

Se a senha contiver `$`, mantenha o valor entre aspas simples no `.env`, por exemplo:

```env
POSTGRES_PASSWORD='Senha$Com$Dolar'
```

## Vaultwarden

- `ADMIN_TOKEN` deve permanecer fora do Git
- `SIGNUPS_ALLOWED=false` é o padrão recomendado em produção

