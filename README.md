# Central de Avisos da Turma — Lab de Redes

Implementação da mesma "central de comunicação da turma" em quatro protocolos
(TCP, UDP, Multicast, WebSocket), cada um em **Java** e **Python**.

## Estrutura

```
lab-redes/
├── java/{tcp,udp,multicast,websocket}/
├── python/{tcp,udp,multicast,websocket}/
├── evidencias/{tcp,udp,multicast,websocket}/
├── RESPOSTAS.md
└── README.md
```

## Portas (com OFFSET pessoal — seção 3.3)

| Parte | Porta-base |
|---|---|
| A — TCP | 5000 |
| B — UDP | 5001 |
| C — Multicast | 4446 |
| D — WebSocket (Java) | 8887 |
| D — WebSocket (Python) | 8888 |

> Ajuste `OFFSET` nos arquivos de multicast (`ServidorMulticast.java`,
> `ClienteMulticast.java`, `servidor_multicast.py`, `cliente_multicast.py`) para
> os 2 últimos dígitos da sua matrícula antes de testar em rede compartilhada.

## Como executar (resumo)

### A — TCP
```bash
cd java/tcp && javac ServidorTCP.java ClienteTCP.java && java ServidorTCP   # e java ClienteTCP em outro terminal
cd python/tcp && python3 servidor_tcp.py                                     # e python3 cliente_tcp.py em outro terminal
```
Teste também a mensagem `hora` (o servidor responde com o horário atual).

### B — UDP
```bash
cd java/udp && javac ServidorUDP.java ClienteUDP.java && java ServidorUDP    # e java ClienteUDP
cd python/udp && python3 servidor_udp.py                                     # e python3 cliente_udp.py
```

### C — Multicast (abra os clientes primeiro)
```bash
cd java/multicast && javac ServidorMulticast.java ClienteMulticast.java
java ClienteMulticast   # 1+ terminais; depois:  java ServidorMulticast
cd python/multicast && python3 cliente_multicast.py   # depois: python3 servidor_multicast.py
```

### D — WebSocket
```bash
# Python
cd python/websocket && pip install websockets && python3 mural_servidor.py   # e python3 mural_cliente.py

# Java (sem Maven — jars manuais; ver seção 7.2 do roteiro)
cd java/websocket
mkdir -p lib && cd lib
curl -O https://repo1.maven.org/maven2/org/java-websocket/Java-WebSocket/1.5.6/Java-WebSocket-1.5.6.jar
curl -O https://repo1.maven.org/maven2/org/slf4j/slf4j-api/2.0.9/slf4j-api-2.0.9.jar
curl -O https://repo1.maven.org/maven2/org/slf4j/slf4j-simple/2.0.9/slf4j-simple-2.0.9.jar
cd ..
javac -cp "lib/*" -d out src/main/java/MuralServidor.java && java -cp "out:lib/*" MuralServidor
javac -d out src/main/java/MuralCliente.java && java -cp out MuralCliente
```
> No macOS/Linux o separador de classpath é `:` (no Windows é `;`).

## Evidências

Salve um print por protocolo/linguagem em `evidencias/<protocolo>/<protocolo>-<linguagem>.png`,
mostrando a execução real (servidor + cliente(s) trocando mensagens) e a saída de
`date` (macOS/Linux) ou `Get-Date` (PowerShell) no canto do terminal.
