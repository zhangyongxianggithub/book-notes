Here's the challenge: we've got a Kafka topic, where services publish messages to be delivered to browser-based clients through web sockets. Sounds simple? It might, but we're faced with an increasing number of messages, as well as a growing count of web socket clients. How do we scale our solution? As our system contains a larger number of servers, failures become more frequent. How to ensure fault tolerance? There’s a couple possible architectures. Each websocket node might consume all messages. Otherwise, we need an intermediary, which redistributes the messages to the proper web socket nodes.

Here, we might either use a Kafka topic, or a streaming forwarding service. However, we still need a feedback loop so that the intermediary knows where to distribute messages.

We’ll take a look at the strengths and weaknesses of each solution, as well as limitations created by the chosen technologies (Kafka and web sockets).


