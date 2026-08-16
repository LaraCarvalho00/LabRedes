#!/bin/bash
# Script de apoio para rodar os exemplos do Lab de Redes (Roteiro 2).
#
# Uso:
#   ./scripts/lab.sh <protocolo> <linguagem> <papel>
#
#   protocolo : tcp | udp | multicast | websocket
#   linguagem : java | python
#   papel     : servidor | cliente
#
# Exemplos:
#   ./scripts/lab.sh tcp java servidor      # em um terminal
#   ./scripts/lab.sh tcp java cliente       # em outro terminal
#   ./scripts/lab.sh multicast python cliente   # abra 2 destes antes do servidor
#
# Para o WebSocket em Java, baixe as libs uma única vez:
#   ./scripts/lab.sh setup-ws-java

set -e
# Vai sempre para a raiz do repositório, independente de onde for chamado.
cd "$(dirname "$0")/.."
RAIZ="$(pwd)"

banner() {
    echo "=================================================="
    echo " Lab de Redes  |  $1"
    echo " Data/hora: $(date '+%d/%m/%Y %H:%M:%S')"
    echo "=================================================="
}

setup_ws_java() {
    local base="https://repo1.maven.org/maven2"
    mkdir -p java/websocket/lib
    cd java/websocket/lib
    echo "Baixando dependências do WebSocket (Java)..."
    curl -sS -O "$base/org/java-websocket/Java-WebSocket/1.5.6/Java-WebSocket-1.5.6.jar"
    curl -sS -O "$base/org/slf4j/slf4j-api/2.0.9/slf4j-api-2.0.9.jar"
    curl -sS -O "$base/org/slf4j/slf4j-simple/2.0.9/slf4j-simple-2.0.9.jar"
    echo "Libs baixadas em java/websocket/lib:"
    ls -1
}

PROTO="$1"
LANG="$2"
PAPEL="$3"

if [ "$PROTO" = "setup-ws-java" ]; then
    setup_ws_java
    exit 0
fi

if [ -z "$PROTO" ] || [ -z "$LANG" ] || [ -z "$PAPEL" ]; then
    echo "Uso: ./scripts/lab.sh <tcp|udp|multicast|websocket> <java|python> <servidor|cliente>"
    echo "     ./scripts/lab.sh setup-ws-java   (baixa libs do WebSocket Java)"
    exit 1
fi

# Mapeia papel -> nome do arquivo Python
py_arquivo() {
    case "$PAPEL" in
        servidor) echo "servidor_${1}.py" ;;
        cliente)  echo "cliente_${1}.py" ;;
        *) echo "" ;;
    esac
}

banner "$PROTO / $LANG / $PAPEL"

case "$LANG" in
  java)
    case "$PROTO" in
      tcp)
        javac java/tcp/*.java
        [ "$PAPEL" = "servidor" ] && exec java -cp java/tcp ServidorTCP
        exec java -cp java/tcp ClienteTCP ;;
      udp)
        javac java/udp/*.java
        [ "$PAPEL" = "servidor" ] && exec java -cp java/udp ServidorUDP
        exec java -cp java/udp ClienteUDP ;;
      multicast)
        javac java/multicast/*.java
        [ "$PAPEL" = "servidor" ] && exec java -cp java/multicast ServidorMulticast
        exec java -cp java/multicast ClienteMulticast ;;
      websocket)
        if [ ! -d java/websocket/lib ]; then
            echo "Libs não encontradas. Rode antes: ./scripts/lab.sh setup-ws-java"; exit 1
        fi
        if [ "$PAPEL" = "servidor" ]; then
            javac -cp "java/websocket/lib/*" -d java/websocket/out java/websocket/src/main/java/MuralServidor.java
            exec java -cp "java/websocket/out:java/websocket/lib/*" MuralServidor
        else
            javac -d java/websocket/out java/websocket/src/main/java/MuralCliente.java
            exec java -cp java/websocket/out MuralCliente
        fi ;;
      *) echo "Protocolo inválido: $PROTO"; exit 1 ;;
    esac ;;
  python)
    case "$PROTO" in
      tcp)       exec python3 "python/tcp/$(py_arquivo tcp)" ;;
      udp)       exec python3 "python/udp/$(py_arquivo udp)" ;;
      multicast) exec python3 "python/multicast/$(py_arquivo multicast)" ;;
      websocket)
        if [ "$PAPEL" = "servidor" ]; then exec python3 python/websocket/mural_servidor.py; fi
        exec python3 python/websocket/mural_cliente.py ;;
      *) echo "Protocolo inválido: $PROTO"; exit 1 ;;
    esac ;;
  *) echo "Linguagem inválida: $LANG"; exit 1 ;;
esac
