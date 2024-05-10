import { useState, useEffect, FormEvent } from 'react';
import { Consumer, Mixin, Subscription, createConsumer } from "@rails/actioncable";
import './App.css';

// const ws = new WebSocke'("ws://localhost:3000/cable")
const consumer = createConsumer('http://localhost:3000/cable');

function App() {
  const [messages, setMessages] = useState<any[]>([]);
  const [email, setEmail] = useState('');
  const [password, setPassword] = useState('');
  const [isLoggedIn, setIsLoggedIn] = useState<boolean>(false);
  const [sub, setSub] = useState<Subscription<Consumer> & Mixin>();
  const [conversationId, setConversationId] = useState<number>();
  const [receiverEmail, setReceiverEmail] = useState<string>('');

  const fetchMessages = async () => {
    console.log('fetching messages');
    const response = await fetch(`http://localhost:3000/conversations/${conversationId}`);
    const data = await response.json();
    setMessages(data);
  };

  const handleConnect = (event: FormEvent) => {
    event.preventDefault();

    // Functions that will handle the events. Type: Mixin
    const handlers = {
      received(data: any) {
        if ('error' in data) {
          console.error(data.error);
          return;
        }

        if (conversationId === undefined && 'conversation_id' in data) {
            setConversationId(data.conversation_id);
            console.log('conversation_id:', data.conversation_id);
        }
        console.log("received message!");
        console.log(data);
        setMessages((prevMessages) => ([...prevMessages, data]));

      },

      connected() {
        // this.perform works but the perform method is not declared yet.
        this.perform("connection_id");
        console.log("Connected");
      },

      disconnected() {
        console.log("Disconnected");
      },

      rejected() {
        console.log("Rejected");
      }
    };


    setSub(consumer.subscriptions.create({channel: 'MessagesChannel', receiver_email: receiverEmail}, handlers));

  };

  const handleLoginSubmit = async (event: FormEvent) => {
    event.preventDefault();

    try {
      const response = await fetch('http://localhost:3000/users/sign_in', {
        method: 'POST',
        credentials: 'include',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ email, password }),
      });

      if (!response.ok) {
        throw new Error(`Error: ${response.statusText}`);
      }

      // Handle successful login (e.g., redirect, store token)
      console.log('Login successful!');
      setIsLoggedIn(true);

    } catch (error) {
      console.error('Login failed:', error);
      // Handle login errors (e.g., display error message)
    }
  };

  useEffect(() => {
    if (conversationId) {
      fetchMessages();
    }
  }, [conversationId]);

  const handleMessageSubmit = async (event: FormEvent) => {
    event.preventDefault();
    const target = event.target as EventTarget & { message: { value:string } };
    const body = target.message.value;
    target.message.value = "";
    if (sub) {
      sub.send({ body: body });
    }
  }

  return (
    <div className='App'>
      <form onSubmit={handleLoginSubmit} className='centerForm'>
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
        <form onSubmit={handleConnect} className='centerForm'>
          <label htmlFor="receiver">Receiver email</label>
          <input
            type="email"
            id="receiver"
            name="receiver"
            value={receiverEmail}
            onChange={(e) => setReceiverEmail(e.target.value)}
          />
          <button type="submit" >
            Connect
          </button>
        </form>
      )}

      {isLoggedIn && (
        <div className='messagesContainer'>

          <div className='messageHeader'>
            <h1>Messages</h1>
            <p>{sub?.identifier}</p>
          </div>


          <div className='messages'>
            {messages.map((message) => (
              <div className='message' key={message.id}>
                <p>{message.body}</p>
              </div>
            ))}
          </div>

          <div className='messageForm'>
            <form onSubmit={handleMessageSubmit}>
              <input className='messageInput' type="text" name='message' />
              <button type="submit">Send</button>
            </form>
          </div>

        </div>
      )}


    </div>
  );
}

export default App;