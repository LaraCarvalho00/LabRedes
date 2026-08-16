# Respostas — Lab de Redes (Central de Avisos da Turma)

> **Uso de IA:** roteiro e código apoiados por IA para redação/estruturação;
> todo o conteúdo foi compreendido e é defensável.

---

## Parte A — TCP

**1. O que acontece se você iniciar o cliente antes do servidor? Por quê?**

O cliente falha ao conectar, lançando `Connection refused` (em Java,
`java.net.ConnectException`; em Python, `ConnectionRefusedError`). Isso ocorre
porque o TCP é **orientado a conexão**: antes de trocar qualquer dado, o cliente
precisa completar o *three-way handshake* (SYN → SYN/ACK → ACK) com um servidor
que esteja escutando (`listen`/`accept`) naquela porta. Sem ninguém aceitando a
conexão, o sistema operacional do lado do servidor responde com um pacote de
recusa (RST) e o `connect()` falha imediatamente.

**2. Qual mecanismo garante a ordem das mensagens?**

Os **números de sequência** (*sequence numbers*). Cada byte enviado recebe um
número de sequência; o receptor usa esses números para **reordenar** os segmentos
que chegam fora de ordem e para **descartar duplicatas**, entregando os dados à
aplicação exatamente na ordem em que foram enviados. Isso trabalha em conjunto com
os **ACKs** (confirmações) e a **retransmissão** de segmentos perdidos.

**3. E se dois clientes tentassem se conectar ao mesmo tempo? O código suporta?**

O código atual **não atende dois clientes simultaneamente**. O servidor chama
`accept()` uma única vez e depois entra no laço de leitura daquele cliente; ele
nunca volta a aceitar novas conexões. Um segundo cliente conseguiria completar o
handshake (ficaria na *backlog queue* do `ServerSocket`/`listen(1)`), mas suas
mensagens só seriam processadas depois que o primeiro cliente encerrasse — e, como
não há novo `accept()` dentro de um laço, na prática ele fica sem resposta. Para
suportar vários clientes seria preciso um laço `while(true)` em torno do `accept()`
e tratar cada cliente em sua própria thread (ou com `ExecutorService`/Virtual
Threads).

---

## Parte B — UDP

**1. O que aconteceu ao enviar mensagem com o servidor desligado? Compare com TCP.**

O cliente **não percebe erro imediato**: o `sendto`/`socket.send` do datagrama
"tem sucesso" (o SO só entrega o pacote à rede), mas em seguida o cliente fica
**bloqueado no `recvfrom`/`receive` esperando uma resposta que nunca chega** —
aparentando "travar". Isso acontece porque o UDP é **sem conexão**: não há
handshake nem confirmação de que existe alguém do outro lado; o datagrama é
simplesmente "gritado" na rede. No TCP, ao contrário, a ausência de servidor é
detectada logo no `connect()` (handshake falha com *connection refused*), antes de
qualquer dado ser enviado.
*(Observação: em algumas plataformas, se o teste for em `localhost`, o SO pode
devolver um ICMP "port unreachable" e o `recvfrom` lançar erro em vez de travar —
mas nunca há a confiabilidade/confirmação que o TCP oferece.)*

**2. Dois exemplos reais de aplicações que usam UDP e por quê.**

- **Streaming de vídeo/áudio ao vivo e VoIP (ex.: chamadas de voz/vídeo):** o que
  importa é a continuidade em tempo real. Retransmitir um pacote atrasado (como o
  TCP faria) chegaria tarde demais para ser útil e ainda causaria travamentos; é
  preferível perder um quadro e seguir em frente.
- **DNS:** a consulta é uma única pergunta/resposta curta. Abrir uma conexão TCP
  (handshake de 3 vias) para cada consulta seria muito mais lento; com UDP, se a
  resposta não vier, o cliente simplesmente repete a consulta.

**3. O servidor UDP poderia registrar "quem está conectado"? O que mudaria?**

Sim, seria possível, mas de forma **manual e em nível de aplicação**, já que o UDP
não tem conexão. O servidor teria que manter uma estrutura (ex.: um conjunto/mapa)
com os pares `(IP, porta)` de quem já enviou mensagens, decidir por quanto tempo
considerar um cliente "ativo" (timeouts, pois não há evento de desconexão) e,
possivelmente, criar mensagens de *keep-alive*. Ou seja, a aplicação passaria a
reimplementar parte do controle de sessão que o TCP oferece de graça.

---

## Parte C — Multicast

**1. Diferença entre unicast repetido 3× e um único envio multicast (tráfego de rede).**

No **unicast repetido**, o remetente gera **uma cópia do pacote para cada
destinatário** — com 3 clientes, 3 pacotes saem da máquina de origem, triplicando
o tráfego no enlace do remetente (e o custo cresce linearmente com o número de
destinatários). No **multicast**, o remetente envia **um único pacote** para o
endereço de grupo; a **rede (roteadores/switches com IGMP)** se encarrega de
duplicá-lo apenas onde é necessário, próximo aos destinatários. Resultado: muito
menos tráfego redundante, especialmente com muitos receptores.

**2. O que é o TTL e por que importa?**

O **TTL (time-to-live)** é um campo do pacote IP que limita **quantos saltos de
roteador** (hops) o pacote pode atravessar antes de ser descartado. A cada
roteador, o TTL é decrementado; ao chegar a zero, o pacote é descartado. No
multicast ele funciona como um **raio de alcance**: `TTL=1` mantém o tráfego na
rede local (não passa do primeiro roteador); valores maiores permitem alcançar
sub-redes mais distantes. É importante para **conter o escopo** dos pacotes e
evitar que avisos multicast "vazem" para toda a internet.

**3. Um cliente que ficou offline e voltou recebe os avisos perdidos? Por quê?**

**Não.** O multicast, por baixo, é **UDP — sem conexão, sem armazenamento e sem
retransmissão**. O servidor envia cada aviso uma vez ao grupo; quem não estava
inscrito/ativo naquele instante simplesmente não recebe, e não há buffer que
guarde mensagens antigas para reenviar depois. A comunicação em grupo é
"ao vivo": entrega a quem está no grupo no momento do envio. Para recuperar
mensagens perdidas seria preciso outra camada (ex.: um histórico persistido e um
mecanismo de *replay* na aplicação).

---

## Parte D — WebSocket

**1. O que muda na conexão depois do handshake `Upgrade: websocket`?**

A conexão deixa de seguir o modelo **requisição/resposta** do HTTP e passa a ser um
**canal TCP persistente e full-duplex**. Após o servidor responder `101 Switching
Protocols`, a mesma conexão TCP permanece aberta e **ambos os lados podem enviar
mensagens a qualquer momento**, de forma independente, sem precisar de uma nova
requisição HTTP a cada troca. Os dados passam a trafegar em *frames* WebSocket
(mais leves que cabeçalhos HTTP completos), em vez de mensagens HTTP.

**2. Compare o mural WebSocket (D) com o aviso Multicast (C): como cada um alcança os destinatários?**

- **Multicast (C):** o remetente **não conhece os destinatários**. Ele envia um
  único pacote a um **endereço de grupo** e a *rede* replica para quem estiver
  inscrito. A entrega é responsabilidade da infraestrutura (roteadores/switches),
  é sem conexão e não confiável.
- **WebSocket (D):** o servidor **mantém uma conexão TCP individual e conhecida com
  cada cliente** (a lista `getConnections()` / `clientes_conectados`). Para
  "difundir", ele percorre essa lista e **envia a mensagem explicitamente a cada
  conexão** (unicast N vezes, em nível de aplicação). É confiável e ordenado, mas o
  custo cresce com o número de clientes.

**3. Por que o WebSocket é mais adequado que TCP "cru" (Parte A) para o mural?**

Embora ambos sejam TCP por baixo, o WebSocket entrega, prontos, os recursos que o
mural precisa e que teríamos de implementar à mão sobre TCP cru: um **enquadramento
de mensagens** (*framing* — sabe onde uma mensagem termina e outra começa, sem
inventar delimitadores), o **handshake HTTP padronizado** que atravessa
firewalls/proxies e é compatível com navegadores, gerenciamento de **múltiplos
clientes** com eventos claros (`onOpen`/`onMessage`/`onClose`) e um modelo
**bidirecional/orientado a mensagens** ideal para *broadcast* em tempo real. Com
TCP cru teríamos que reinventar tudo isso (delimitação de mensagens, controle de
conexões, protocolo de aplicação) e ainda não seria acessível diretamente por um
navegador.
