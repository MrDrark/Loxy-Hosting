#!/usr/bin/env bash
set -euo pipefail

# --- Configuráveis (troque se quiser) ---
GITHUB_ZIP_RAW="https://raw.githubusercontent.com/MrDrark/Loxy-Hosting/main/samp03.zip"
WORKDIR="/mnt/server"
TMPDIR="/tmp/samp03_extract"
RCON_ENV="${RCON_PASS:-${PASSWORD:-}}"

# --- Funções utilitárias ---
log() { echo -e "[start.sh] $*"; }

# --- Limpeza / preparação ---
log "Iniciando processo de preparação..."
rm -rf "$TMPDIR"
mkdir -p "$TMPDIR"
mkdir -p "$WORKDIR"

# Remove logs antigos (protege contra arquivos enormes)
log "Removendo logs antigos..."
rm -rf "${WORKDIR}/logs" "${WORKDIR}/samp.log" "${WORKDIR}/server_log.txt" || true

# --- Baixar e extrair o zip do GitHub (se houver) ---
log "Baixando $GITHUB_ZIP_RAW..."
curl -fsSL "$GITHUB_ZIP_RAW" -o /tmp/samp03.zip || {
    log "Falha ao baixar $GITHUB_ZIP_RAW. Verifique o link ou conectividade."
    # Ainda tenta continuar caso os arquivos já estejam no WORKDIR
}

if [ -f /tmp/samp03.zip ]; then
    log "Extraindo zip..."
    unzip -o /tmp/samp03.zip -d "$TMPDIR" >/dev/null
    # mover conteúdo extraído para /mnt/server
    # Some zips may contain a root folder (ex: samp03/...), então movemos tudo de forma segura
    shopt -s dotglob
    for f in "$TMPDIR"/*; do
        # mv -n to avoid overwriting files the admin may have modified? aqui usamos overwrite
        mv -f "$f" "$WORKDIR/" || true
    done
    shopt -u dotglob
    rm -f /tmp/samp03.zip
    rm -rf "$TMPDIR"
    log "Arquivos movidos para $WORKDIR."
else
    log "Nenhum zip baixado — assumindo que os arquivos já estão em $WORKDIR."
fi

cd "$WORKDIR" || { log "Erro: não consegui entrar em $WORKDIR"; exit 1; }

# --- Garantir permissões e variável HOME ---
chmod -R 755 "$WORKDIR" || true
export HOME="$WORKDIR"

# --- Apagar logs toda vez que o servidor iniciar (pedido explícito) ---
log "Removendo logs antes da inicialização..."
rm -rf ./logs ./samp.log ./server_log.txt || true

# --- RCON: garantir que existe rcon_password no server.cfg ---
CFG="./server.cfg"
if [ ! -f "$CFG" ]; then
    log "server.cfg não encontrado — criando um template mínimo..."
    cat > "$CFG" <<'EOF'
# server.cfg gerado automaticamente
maxplayers 50
port 7777
hostname Loxy - SA-MP Server
EOF
fi

if [ -n "$RCON_ENV" ]; then
    # Se já existir rcon_password, substitui; senão, adiciona no final
    if grep -qi '^rcon_password' "$CFG"; then
        sed -i "s/^rcon_password.*/rcon_password $RCON_ENV/I" "$CFG"
        log "rcon_password atualizado no server.cfg via variável de ambiente."
    else
        echo "rcon_password $RCON_ENV" >> "$CFG"
        log "rcon_password adicionado ao server.cfg via variável de ambiente."
    fi
else
    log "Nenhuma variável RCON encontrada (use RCON_PASS ou PASSWORD no egg). O server.cfg não terá rcon configurado."
fi

# --- Plugins: detectar .so vs .dll e agir ---
PLUGINS_DIR="./plugins"
mkdir -p "$PLUGINS_DIR"

shopt -s nullglob
so_count=0
dll_count=0
for f in "$PLUGINS_DIR"/*.so; do so_count=$((so_count+1)); done
for f in "$PLUGINS_DIR"/*.dll; do dll_count=$((dll_count+1)); done
shopt -u nullglob

log "Plugins: .so encontrados = $so_count, .dll encontrados = $dll_count"

if [ "$so_count" -eq 0 ] && [ "$dll_count" -gt 0 ]; then
    log "Atenção: não há .so, mas existem .dll. Vou renomear .dll -> .so COMO ÚLTIMO RECURSO (NÃO converte o binário!)."
    for dll in "$PLUGINS_DIR"/*.dll; do
        base=$(basename "$dll" .dll)
        target="$PLUGINS_DIR/$base.so"
        if [ -f "$target" ]; then
            log "Ignorando $dll porque $target já existe."
        else
            cp -a "$dll" "$target"
            log "Renomeado (cópia) $dll -> $target  (ATENÇÃO: isso pode NÃO funcionar se o plugin for compilado para Windows)."
        fi
    done

    # Atualizar server.cfg substituindo referências a .dll por .so (só se houver)
    if grep -qi '\.dll' "$CFG"; then
        sed -i 's/\.dll/\.so/gI' "$CFG"
        log "server.cfg atualizado: referências a .dll trocadas por .so."
    fi

    log "Lembrete: renomear DLL não garante funcionamento no Linux. Se der crash de plugin, providencie .so apropriado para Linux."
fi

# --- Se existirem .so, garantir que server.cfg usa .so ---
if [ "$so_count" -gt 0 ]; then
    if grep -qi '\.dll' "$CFG"; then
        sed -i 's/\.dll/\.so/gI' "$CFG"
        log "server.cfg: troquei .dll por .so porque há .so disponíveis."
    fi
fi

# --- Garantir que o binário do servidor é executável ---
SERVER_BIN="./samp03svr"
if [ ! -f "$SERVER_BIN" ]; then
    log "Arquivo $SERVER_BIN não encontrado. Tentando tornar executável qualquer binário similar..."
    # procura por nomes comuns
    if [ -f ./samp03svr_R3-1-0 ] || [ -f ./samp03svr_R2-2-1 ]; then
        # tenta achar qualquer arquivo executável
        for possible in ./samp*svr* ./samp03svr*; do
            if [ -f "$possible" ]; then
                mv -f "$possible" "$SERVER_BIN" && log "Renomeei $possible -> $SERVER_BIN"
                break
            fi
        done
    fi
fi

if [ ! -f "$SERVER_BIN" ]; then
    log "ERRO FATAL: $SERVER_BIN não existe. O servidor não pode iniciar."
    exit 1
fi

chmod +x "$SERVER_BIN" || true

# --- Rodar o servidor (substitui o PID do processo atual) ---
log "Iniciando o servidor (exec)..."
exec "$SERVER_BIN"
