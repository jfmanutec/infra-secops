#!/bin/bash
# ============================================================
# GUIA COMPLETO DE DEPLOY - VM03
# Keycloak + Guacamole + Vaultwarden
# ============================================================
# Diretório raiz: /srv/containers
# Timezone: America/Fortaleza (UTC-3)
# Rede Docker externa: docker-network-ger
# ============================================================
# IMPORTANTE: Execute todos os comandos como root ou com sudo.
# Este script pode ser executado como referência passo a passo
# ou como script bash diretamente.
# ============================================================


echo "============================================================"
echo " FASE 1: PREPARAÇÃO DO AMBIENTE LINUX"
echo "============================================================"

# ----- 1.1 Criar estrutura de diretórios raiz -----
echo "[1.1] Criando estrutura de diretórios..."

sudo mkdir -p /srv/containers/keycloak/data/postgres
sudo mkdir -p /srv/containers/guacamole/data/postgres
sudo mkdir -p /srv/containers/guacamole/data/drive
sudo mkdir -p /srv/containers/guacamole/data/record
sudo mkdir -p /srv/containers/bitwarden/data

# ----- 1.2 Configurar permissões -----
echo "[1.2] Configurando permissões..."

# PostgreSQL roda como UID 999 dentro do container oficial
sudo chown -R 999:999 /srv/containers/keycloak/data/postgres
sudo chown -R 999:999 /srv/containers/guacamole/data/postgres

# Guacamole guacd precisa gravar nos diretórios compartilhados
sudo chown -R 1000:1000 /srv/containers/guacamole/data/drive
sudo chown -R 1000:1000 /srv/containers/guacamole/data/record
sudo chmod 750 /srv/containers/guacamole/data/drive
sudo chmod 750 /srv/containers/guacamole/data/record

# Vaultwarden persiste todo o estado em /data
sudo chown -R root:root /srv/containers/bitwarden/data
sudo chmod 700 /srv/containers/bitwarden/data

# Proteger diretório raiz
sudo chmod 750 /srv/containers

echo "[1.2] Permissões configuradas."

# ----- 1.3 Verificar timezone do host -----
echo "[1.3] Verificando/configurando timezone do host..."
sudo timedatectl set-timezone America/Fortaleza
timedatectl


echo ""
echo "============================================================"
echo " FASE 2: REDE DOCKER EXTERNA"
echo "============================================================"

# ----- 2.1 Criar a rede compartilhada -----
echo "[2.1] Criando rede docker-network-ger..."

# Verifica se já existe antes de criar
if ! docker network inspect docker-network-ger >/dev/null 2>&1; then
    docker network create docker-network-ger
    echo ">>> Rede docker-network-ger criada com sucesso."
else
    echo ">>> Rede docker-network-ger já existe. Pulando..."
fi

# ----- 2.2 Verificar rede -----
docker network ls | grep docker-network-ger


echo ""
echo "============================================================"
echo " FASE 3: COPIAR ARQUIVOS DE CONFIGURAÇÃO"
echo "============================================================"

# ----- 3.1 Copiar docker-compose.yml, .env e scripts auxiliares para cada diretório -----
# A partir da sua máquina Windows, use SCP ou WinSCP para copiar:
#
# SCP a partir da máquina Windows (PowerShell):
#   scp .\keycloak\docker-compose.yml .\keycloak\.env .\keycloak\postgres-ensure-password.sh usuario@IP_VM03:/srv/containers/keycloak/
#   scp .\guacamole\docker-compose.yml .\guacamole\.env .\guacamole\postgres-ensure-password.sh usuario@IP_VM03:/srv/containers/guacamole/
#   scp .\bitwarden\docker-compose.yml .\bitwarden\.env usuario@IP_VM03:/srv/containers/bitwarden/
#
# Ou via WinSCP, arraste os arquivos para os diretórios corretos.
#
# IMPORTANTE: Certifique-se que os arquivos .env foram copiados!
#   (ls -la /srv/containers/keycloak/.env)

echo "[3.1] Verifique que os arquivos foram copiados:"
echo "      /srv/containers/keycloak/docker-compose.yml"
echo "      /srv/containers/keycloak/.env"
echo "      /srv/containers/keycloak/postgres-ensure-password.sh"
echo "      /srv/containers/guacamole/docker-compose.yml"
echo "      /srv/containers/guacamole/.env"
echo "      /srv/containers/guacamole/postgres-ensure-password.sh"
echo "      /srv/containers/bitwarden/docker-compose.yml"
echo "      /srv/containers/bitwarden/.env"

# ----- 3.2 Proteger os arquivos .env (contêm senhas) -----
echo "[3.2] Protegendo arquivos .env..."
sudo chmod 600 /srv/containers/keycloak/.env
sudo chmod 600 /srv/containers/guacamole/.env
sudo chmod 600 /srv/containers/bitwarden/.env

# ----- 3.3 Verificar a estrutura final -----
echo "[3.3] Estrutura de diretórios final:"
find /srv/containers -type f | sort


echo ""
echo "============================================================"
echo " FASE 4: DEPLOY DO KEYCLOAK"
echo "============================================================"

# ----- 4.1 Navegar até o diretório -----
cd /srv/containers/keycloak

# ----- 4.2 Puxar as imagens -----
echo "[4.2] Baixando imagens do Keycloak..."
docker compose pull

# ----- 4.3 Subir os containers -----
echo "[4.3] Subindo Keycloak + PostgreSQL..."
docker compose up -d

# ----- 4.4 Aguardar e verificar saúde -----
echo "[4.4] Aguardando inicialização (pode levar ~60s na primeira vez)..."
sleep 15
docker compose ps
docker compose logs --tail=30 keycloak

# ----- 4.5 Testar acesso local -----
echo "[4.5] Testando acesso local..."
# A porta HTTP depende do .env (padrão 8080)
curl -sfI http://localhost:8080 && echo " >>> Keycloak HTTP OK" || echo " >>> Keycloak ainda iniciando..."


echo ""
echo "============================================================"
echo " FASE 5: DEPLOY DO GUACAMOLE"
echo "============================================================"

# ----- 5.1 Navegar até o diretório -----
cd /srv/containers/guacamole

# ----- 5.2 Puxar as imagens -----
echo "[5.2] Baixando imagens do Guacamole..."
docker compose pull

# ----- 5.3 Subir stack completa com schema automático via PostgreSQL -----
echo "[5.3] Subindo stack completa com schema automático no primeiro boot do banco..."
docker compose up -d

# ----- 5.4 Verificar status -----
echo "[5.4] Verificando status..."
docker compose ps
docker compose logs --tail=20 guacamole

# ----- 5.5 Testar acesso local -----
echo "[5.5] Testando acesso local..."
# A porta depende do .env (padrão 8081)
# NOTA: O Guacamole responde em /guacamole/ (não na raiz /)
curl -sf http://localhost:8081/guacamole/ && echo " >>> Guacamole OK" || echo " >>> Guacamole ainda iniciando..."

echo ""
echo ">>> CREDENCIAIS PADRÃO DO GUACAMOLE (primeira vez):"
echo "    Usuário: guacadmin"
echo "    Senha:   guacadmin"
echo "    IMPORTANTE: Altere imediatamente após o primeiro login!"
echo "    Revise também conexões e permissões padrão após validar o acesso."


echo ""
echo "============================================================"
echo " FASE 6: MIGRAÇÃO E DEPLOY DO BITWARDEN (VAULTWARDEN)"
echo "============================================================"

# Se você já tem o Bitwarden na VM02, siga o guia:
#   migracao_bitwarden.txt
#
# Se é uma instalação nova, prossiga diretamente:

# ----- 6.1 Navegar até o diretório -----
cd /srv/containers/bitwarden

# ----- 6.2 Puxar a imagem -----
echo "[6.2] Baixando imagem do Vaultwarden..."
docker compose pull

# ----- 6.3 Subir o container -----
echo "[6.3] Subindo Vaultwarden..."
docker compose up -d

# ----- 6.4 Verificar status -----
echo "[6.4] Verificando status..."
sleep 5
docker compose ps
docker compose logs --tail=20 vaultwarden

# ----- 6.5 Testar acesso local -----
echo "[6.5] Testando acesso local..."
# A porta depende do .env (padrão 8082)
curl -sf http://localhost:8082/alive && echo " >>> Vaultwarden OK" || echo " >>> Vaultwarden ainda iniciando..."


echo ""
echo "============================================================"
echo " FASE 7: CONFIGURAÇÃO DO DNS NO ACTIVE DIRECTORY"
echo "============================================================"
echo ""
echo "Nos seus servidores DC (SRVDC01 / SRVDC02), crie os seguintes"
echo "registros DNS do tipo A, todos apontando para o IP da VM03:"
echo ""
echo "  sso.domio.local.br      →  IP_DA_VM03"
echo "  acesso.domio.local.br   →  IP_DA_VM03"
echo "  cofre.domio.local.br    →  IP_DA_VM03"
echo ""
echo "Comandos PowerShell nos DCs (ajuste o IP):"
echo '  Add-DnsServerResourceRecordA -Name "sso" -ZoneName "domio.local.br" -IPv4Address "172.23.X.X"'
echo '  Add-DnsServerResourceRecordA -Name "acesso" -ZoneName "domio.local.br" -IPv4Address "172.23.X.X"'
echo '  Add-DnsServerResourceRecordA -Name "cofre" -ZoneName "domio.local.br" -IPv4Address "172.23.X.X"'


echo ""
echo "============================================================"
echo " FASE 8: CONFIGURAÇÃO DO NGINX PROXY MANAGER"
echo "============================================================"
echo ""
echo "No Nginx Proxy Manager (que já está rodando na VM03),"
echo "crie 3 Proxy Hosts:"
echo ""
echo "  ┌──────────────────────┬────────┬──────────────────┬──────┬────────────┐"
echo "  │ Domain               │ Scheme │ Forward Hostname │ Port │ WebSockets │"
echo "  ├──────────────────────┼────────┼──────────────────┼──────┼────────────┤"
echo "  │ sso.domio.local.br   │ http   │ keycloak         │ 8080 │ Off        │"
echo "  │ acesso.domio.local.br│ http   │ guacamole        │ 8080 │ On         │"
echo "  │ cofre.domio.local.br │ http   │ vaultwarden      │ 80   │ On         │"
echo "  └──────────────────────┴────────┴──────────────────┴──────┴────────────┘"
echo ""
echo "NOTA: O Forward Hostname usa o nome do container Docker."
echo "      As portas são as INTERNAS do container (não as do host)."
echo "      Isso funciona porque todos compartilham a rede docker-network-ger."
echo "      As portas publicadas no host ficam restritas a 127.0.0.1."
echo ""
echo "Para o Guacamole, na aba 'Custom locations' do NPM, adicione:"
echo "  Location: /"
echo "  Forward: http://guacamole:8080/guacamole/"
echo ""
echo "Ou configure o path completo no proxy:"
echo "  Custom Nginx Configuration (Advanced):"
echo "    proxy_set_header Upgrade \$http_upgrade;"
echo "    proxy_set_header Connection \$http_connection;"
echo "    proxy_buffering off;"


echo ""
echo "============================================================"
echo " FASE 9: VALIDAÇÃO FINAL"
echo "============================================================"

echo "[9.1] Verificando todos os containers..."
docker ps --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}" | grep -E "(keycloak|guac|vaultwarden|postgres)"

echo ""
echo "[9.2] Verificando uso de recursos..."
docker stats --no-stream --format "table {{.Name}}\t{{.CPUPerc}}\t{{.MemUsage}}" | grep -E "(keycloak|guac|vaultwarden|postgres)"

echo ""
echo "[9.3] Testes de conectividade local..."
echo -n "  Keycloak:    " && curl -sfI http://localhost:8080 > /dev/null && echo "✅ OK" || echo "❌ FALHOU"
echo -n "  Guacamole:   " && curl -sf http://localhost:8081/guacamole/ > /dev/null && echo "✅ OK" || echo "❌ FALHOU"
echo -n "  Vaultwarden: " && curl -sf http://localhost:8082/alive > /dev/null && echo "✅ OK" || echo "❌ FALHOU"

echo ""
echo "[9.4] Testes de conectividade via DNS (após configurar DNS e NPM)..."
echo -n "  sso.domio.local.br:    " && curl -sf https://sso.domio.local.br > /dev/null && echo "✅ OK" || echo "❌ Ainda não configurado"
echo -n "  acesso.domio.local.br: " && curl -sf https://acesso.domio.local.br > /dev/null && echo "✅ OK" || echo "❌ Ainda não configurado"
echo -n "  cofre.domio.local.br:  " && curl -sf https://cofre.domio.local.br > /dev/null && echo "✅ OK" || echo "❌ Ainda não configurado"
echo ""
echo "[9.5] Hardening pós-deploy..."
echo "  1. Confirmar que SIGNUPS_ALLOWED=false no Vaultwarden."
echo "  2. Alterar imediatamente a senha padrão guacadmin."
echo "  3. Validar backup/restauração dos diretórios em /srv/containers."


echo ""
echo "============================================================"
echo " FASE 10: COMANDOS ÚTEIS DE OPERAÇÃO"
echo "============================================================"
echo ""
echo "--- Verificar logs em tempo real ---"
echo "  cd /srv/containers/keycloak  && docker compose logs -f"
echo "  cd /srv/containers/guacamole && docker compose logs -f"
echo "  cd /srv/containers/bitwarden && docker compose logs -f"
echo ""
echo "--- Reiniciar um serviço ---"
echo "  cd /srv/containers/keycloak  && docker compose restart"
echo "  cd /srv/containers/guacamole && docker compose restart"
echo "  cd /srv/containers/bitwarden && docker compose restart"
echo ""
echo "--- Parar um serviço ---"
echo "  cd /srv/containers/keycloak  && docker compose down"
echo "  cd /srv/containers/guacamole && docker compose down"
echo "  cd /srv/containers/bitwarden && docker compose down"
echo ""
echo "--- Atualizar imagens ---"
echo "  cd /srv/containers/keycloak  && docker compose pull && docker compose up -d"
echo "  cd /srv/containers/guacamole && docker compose pull && docker compose up -d"
echo "  cd /srv/containers/bitwarden && docker compose pull && docker compose up -d"
echo ""
echo "--- Backup dos dados (executar periodicamente) ---"
echo "  tar -czvf /srv/backups/keycloak_\$(date +%Y%m%d).tar.gz  /srv/containers/keycloak/data/"
echo "  tar -czvf /srv/backups/guacamole_\$(date +%Y%m%d).tar.gz /srv/containers/guacamole/data/"
echo "  tar -czvf /srv/backups/bitwarden_\$(date +%Y%m%d).tar.gz /srv/containers/bitwarden/data/"
echo ""
echo "============================================================"
echo " DEPLOY CONCLUÍDO!"
echo "============================================================"
