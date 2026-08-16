#!/bin/bash
# Abre janelas do Terminal.app já posicionadas e roda o servidor + cliente(s)
# do exemplo escolhido, prontos para você tirar o print (Cmd+Shift+4).
#
# Uso:
#   ./scripts/abrir-demo.sh <protocolo> <linguagem>
#     protocolo : tcp | udp | multicast | websocket
#     linguagem : java | python
#
# Exemplos:
#   ./scripts/abrir-demo.sh tcp java
#   ./scripts/abrir-demo.sh multicast python
#
# Observações:
#  - TCP/UDP abrem 1 servidor + 1 cliente.
#  - Multicast/WebSocket abrem 1 servidor + 2 clientes (o roteiro pede 2).
#  - No multicast os clientes sobem ANTES do servidor (o script cuida disso).
#  - Para WebSocket em Java, rode antes uma vez: ./scripts/lab.sh setup-ws-java

set -e
cd "$(dirname "$0")/.."
RAIZ="$(pwd)"

PROTO="$1"
LANG="$2"

if [ -z "$PROTO" ] || [ -z "$LANG" ]; then
    echo "Uso: ./scripts/abrir-demo.sh <tcp|udp|multicast|websocket> <java|python>"
    exit 1
fi

# Abre uma janela do Terminal rodando um comando, com posição/tamanho definidos.
# args: <comando> <left> <top> <right> <bottom>
abrir() {
    local cmd="$1" l="$2" t="$3" r="$4" b="$5"
    osascript <<OSA
tell application "Terminal"
    activate
    set w to do script "cd '$RAIZ' && $cmd"
    delay 0.3
    try
        set bounds of front window to {$l, $t, $r, $b}
    end try
end tell
OSA
}

case "$PROTO" in
  tcp|udp)
    abrir "./scripts/lab.sh $PROTO $LANG servidor"  20  60  680 520
    sleep 2
    abrir "./scripts/lab.sh $PROTO $LANG cliente"  700  60 1360 520
    echo "Servidor e cliente abertos. Troque mensagens no cliente e tire o print (Cmd+Shift+4)."
    ;;
  multicast)
    # clientes primeiro, depois o servidor
    abrir "./scripts/lab.sh multicast $LANG cliente"  20  60  680 400
    abrir "./scripts/lab.sh multicast $LANG cliente" 700  60 1360 400
    sleep 2
    abrir "./scripts/lab.sh multicast $LANG servidor" 360 430 1020 780
    echo "2 clientes + servidor abertos. Aguarde os avisos aparecerem e tire o print."
    ;;
  websocket)
    if [ "$LANG" = "java" ] && [ ! -d java/websocket/lib ]; then
        echo "Libs do WebSocket Java ausentes. Rode antes: ./scripts/lab.sh setup-ws-java"; exit 1
    fi
    abrir "./scripts/lab.sh websocket $LANG servidor" 360  60 1020 380
    sleep 2
    abrir "./scripts/lab.sh websocket $LANG cliente"   20 400  680 780
    abrir "./scripts/lab.sh websocket $LANG cliente"  700 400 1360 780
    echo "Servidor + 2 clientes abertos. Envie uma mensagem por um cliente; ela aparece nos dois. Tire o print."
    ;;
  *)
    echo "Protocolo inválido: $PROTO"; exit 1 ;;
esac
