import { useState, useEffect, FormEvent } from "react";
import {
  Consumer,
  Mixin,
  Subscription,
  createConsumer,
} from "@rails/actioncable";
import "./App.css";

const BACKEND_URL = "http://localhost:3000";

const consumer = createConsumer(`${BACKEND_URL}/cable`);

type UserMessage = {
  id: number;
  body: string;
  created_at: string;
  updated_at: string;
  user_id: number;
  conversation_id: number;
};

type ErrorMessage = {
  error: string;
};

type Message = UserMessage | ErrorMessage;

function isErrorMessage(msg: Message): msg is ErrorMessage {
  return "error" in msg;
}

function App() {
  const [messages, setMessages] = useState<UserMessage[]>([]);
  const [email, setEmail] = useState("user1@example.com");
  const [password, setPassword] = useState("123");
  const [isLoggedIn, setIsLoggedIn] = useState<boolean>(false);
  const [sub, setSub] = useState<Subscription<Consumer> & Mixin>();
  const [conversationId, setConversationId] = useState<number>();
  const [receiverEmail, setReceiverEmail] = useState<string>("");

  const handleConnect = (event: FormEvent) => {
    event.preventDefault();

    // Functions that will handle the events
    const handlers: Mixin = {
      received(data: Message) {
        if (isErrorMessage(data)) {
          console.error(data);
          return;
        }

        if (!conversationId) {
          setConversationId(() => data.conversation_id);
          console.log("set conversation_id:", data.conversation_id);
        } else {
          console.log("received message!", data);
          setMessages((prevMessages) => [...prevMessages, data]);
        }
      },

      connected() {
        // Calls the conversation_id method on the backend to receive the conversation_id and get
        // the messages of the current conversation.
        this.perform("conversation_id"); // perform is a method of Subscription
        console.log("Connected");
      },

      disconnected() {
        console.log("Disconnected");
      },

      rejected() {
        console.log("Rejected");
      },
    };

    setSub(() =>
      consumer.subscriptions.create(
        { channel: "MessagesChannel", receiver_email: receiverEmail },
        // @ts-expect-error typescript is expecting `handlers` to be of type 'Mixin & Subscription<Consumer>'
        // No idea how to make the types work here :).
        handlers,
      ),
    );
  };

  const handleLoginSubmit = async (event: FormEvent) => {
    event.preventDefault();

    try {
      const response = await fetch(`${BACKEND_URL}/users/sign_in`, {
        method: "POST",
        credentials: "include",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({ email, password }),
      });

      if (!response.ok) {
        throw new Error(`Error: ${response.statusText}`);
      }

      // Handle successful login (e.g. redirect, store token)
      console.log("Login successful!");
      setIsLoggedIn(true);
    } catch (error) {
      console.error("Login failed:", error);
      // Handle login errors (e.g. display error message)
    }
  };

  // Fetch all chat messages every time the conversation_id changes.
  useEffect(() => {
    async function fetchMessages() {
      const response = await fetch(
        `${BACKEND_URL}/conversations/${conversationId}`,
      );
      const data = await response.json();
      setMessages(data);
    }

    if (conversationId) {
      fetchMessages();
    }
  }, [conversationId]);

  const handleMessageSubmit = async (event: FormEvent) => {
    event.preventDefault();
    const target = event.target as EventTarget & { message: { value: string } };
    const body = target.message.value;
    target.message.value = "";

    // Send a message to the channel.
    if (sub) {
      sub.send({ body: body });
    }
  };

  return (
    <div className="App">
      <form onSubmit={handleLoginSubmit} className="centerForm">
        <label htmlFor="email">Email:</label>
        <input
          type="email"
          id="email"
          value={email}
          onChange={(e) => setEmail(e.target.value)}
          required
        />

        <label htmlFor="password">Password:</label>
        <input
          type="password"
          id="password"
          value={password}
          onChange={(e) => setPassword(e.target.value)}
          required
        />

        <button type="submit">Login</button>
      </form>

      {isLoggedIn && (
        <form onSubmit={handleConnect} className="centerForm">
          <label htmlFor="receiver">Receiver email</label>
          <input
            type="email"
            id="receiver"
            name="receiver"
            value={receiverEmail}
            onChange={(e) => setReceiverEmail(e.target.value)}
          />
          <button type="submit">Connect</button>
        </form>
      )}

      {conversationId && (
        <div className="messagesContainer">
          <div className="messageHeader">
            <h1>Messages</h1>
            <p>{sub?.identifier}</p>
          </div>

          <div className="messages">
            {messages.map((message) => (
              <div key={message.id} className="message">
                <p>
                  {message.id} - {message.body}
                </p>
              </div>
            ))}
          </div>

          <div className="messageForm">
            <form onSubmit={handleMessageSubmit}>
              <input className="messageInput" type="text" name="message" />
              <button type="submit">Send</button>
            </form>
          </div>
        </div>
      )}
    </div>
  );
}

export default App;
