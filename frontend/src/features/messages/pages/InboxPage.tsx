import { useState, useEffect, useRef } from 'react';
import { formatDistanceToNow } from 'date-fns';
import { useAuth } from '../../auth/hooks/useAuth';
import { messageApi } from '../services/messageApi';
import { type Message } from '../types/message.types';

export const InboxPage = () => {
  const { user } = useAuth();
  const [messages, setMessages] = useState<Message[]>([]);
  const [selectedPartnerId, setSelectedPartnerId] = useState<number | null>(null);
  const [newMessage, setNewMessage] = useState('');
  const [loading, setLoading] = useState(true);
  const messagesEndRef = useRef<HTMLDivElement>(null);

  // Fetch all conversations
  const fetchMessages = async () => {
    if (!user) return;
    setLoading(true);
    try {
      const res = await messageApi.getConversations();
      setMessages(res.data);
    } catch (error) {
      console.error('Failed to load messages', error);
    } finally {
      setLoading(false);
    }
  };

  useEffect(() => {
    fetchMessages();
  }, [user]);

  // Auto‑scroll to bottom when messages change
  useEffect(() => {
    messagesEndRef.current?.scrollIntoView({ behavior: 'smooth' });
  }, [messages, selectedPartnerId]);

  if (!user) return <div className="flex justify-center items-center h-screen">Loading...</div>;
  if (loading) return <div className="flex justify-center items-center h-screen">Loading messages...</div>;

  // Group messages by conversation partner
  const conversations: Record<number, { partner: { id: number; name: string }; messages: Message[] }> = {};

  messages.forEach((msg) => {
    const partnerId = msg.from_user_id === user.id ? msg.to_user_id : msg.from_user_id;
    const partner = msg.from_user_id === user.id ? msg.to_user : msg.from_user;
    if (!conversations[partnerId]) {
      conversations[partnerId] = {
        partner: { id: partnerId, name: partner.name },
        messages: [],
      };
    }
    conversations[partnerId].messages.push(msg);
  });

  // Sort conversations by latest message date
  const sortedConversations = Object.entries(conversations).sort((a, b) => {
    const aLatest = a[1].messages[a[1].messages.length - 1]?.created_at || '';
    const bLatest = b[1].messages[b[1].messages.length - 1]?.created_at || '';
    return new Date(bLatest).getTime() - new Date(aLatest).getTime();
  });

  const sendMessage = async () => {
    if (!selectedPartnerId || !newMessage.trim()) return;
    try {
      await messageApi.sendMessage(selectedPartnerId, newMessage);
      setNewMessage('');
      await fetchMessages(); // refresh after send
    } catch (error) {
      console.error('Failed to send message', error);
      alert('Could not send message. Please try again.');
    }
  };

  const selectedConversation = selectedPartnerId ? conversations[selectedPartnerId] : null;

  return (
    <div className="flex h-[calc(100vh-120px)] max-w-7xl mx-auto my-4 border rounded-xl overflow-hidden shadow-lg bg-white">
      {/* Sidebar */}
      <div className="w-80 border-r bg-gray-50 flex flex-col">
        <div className="p-4 border-b bg-white">
          <h2 className="text-xl font-semibold text-gray-800">Messages</h2>
        </div>
        <div className="flex-1 overflow-y-auto">
          {sortedConversations.length === 0 ? (
            <div className="p-4 text-center text-gray-500">No conversations yet</div>
          ) : (
            sortedConversations.map(([partnerId, { partner, messages: convMsgs }]) => {
              const lastMsg = convMsgs[convMsgs.length - 1];
              const unreadCount = convMsgs.filter((m) => !m.is_read && m.to_user_id === user.id).length;
              const lastMsgTime = lastMsg?.created_at ? formatDistanceToNow(new Date(lastMsg.created_at), { addSuffix: true }) : '';
              return (
                <div
                  key={partnerId}
                  onClick={() => setSelectedPartnerId(Number(partnerId))}
                  className={`flex items-center gap-3 p-3 border-b cursor-pointer transition hover:bg-gray-100 ${
                    selectedPartnerId === Number(partnerId) ? 'bg-blue-50' : ''
                  }`}
                >
                  {/* Avatar placeholder */}
                  <div className="w-12 h-12 rounded-full bg-gray-300 flex items-center justify-center text-gray-600 font-bold">
                    {partner.name.charAt(0).toUpperCase()}
                  </div>
                  <div className="flex-1 min-w-0">
                    <div className="flex justify-between items-baseline">
                      <span className="font-semibold truncate">{partner.name}</span>
                      {lastMsgTime && <span className="text-xs text-gray-400 whitespace-nowrap ml-2">{lastMsgTime}</span>}
                    </div>
                    <div className="flex justify-between items-center">
                      <p className="text-sm text-gray-600 truncate">{lastMsg?.message || ''}</p>
                      {unreadCount > 0 && (
                        <span className="ml-2 bg-blue-500 text-white text-xs rounded-full px-2 py-0.5">{unreadCount}</span>
                      )}
                    </div>
                  </div>
                </div>
              );
            })
          )}
        </div>
      </div>

      {/* Chat area */}
      <div className="flex-1 flex flex-col bg-white">
        {selectedConversation ? (
          <>
            {/* Chat header */}
            <div className="border-b p-4 bg-white flex items-center gap-3">
              <div className="w-10 h-10 rounded-full bg-gray-300 flex items-center justify-center text-gray-600 font-bold">
                {selectedConversation.partner.name.charAt(0).toUpperCase()}
              </div>
              <div>
                <h3 className="font-semibold">{selectedConversation.partner.name}</h3>
              </div>
            </div>

            {/* Messages area */}
            <div className="flex-1 overflow-y-auto p-4 space-y-3 bg-gray-50">
              {selectedConversation.messages.map((msg) => {
                const isOwn = msg.from_user_id === user.id;
                return (
                  <div key={msg.id} className={`flex ${isOwn ? 'justify-end' : 'justify-start'}`}>
                    <div
                      className={`max-w-[70%] rounded-2xl px-4 py-2 shadow ${
                        isOwn ? 'bg-blue-500 text-white rounded-br-none' : 'bg-white text-gray-800 rounded-bl-none'
                      }`}
                    >
                      <p className="text-sm break-words">{msg.message}</p>
                      <span className={`text-xs mt-1 block ${isOwn ? 'text-blue-100' : 'text-gray-400'}`}>
                        {formatDistanceToNow(new Date(msg.created_at), { addSuffix: true })}
                      </span>
                    </div>
                  </div>
                );
              })}
              <div ref={messagesEndRef} />
            </div>

            {/* Input area */}
            <div className="border-t p-3 bg-white flex gap-2">
              <input
                type="text"
                value={newMessage}
                onChange={(e) => setNewMessage(e.target.value)}
                onKeyPress={(e) => e.key === 'Enter' && sendMessage()}
                placeholder="Type a message..."
                className="flex-1 border rounded-full px-4 py-2 focus:outline-none focus:ring-2 focus:ring-blue-400"
              />
              <button
                onClick={sendMessage}
                disabled={!newMessage.trim()}
                className="bg-blue-500 text-white rounded-full px-5 py-2 hover:bg-blue-600 transition disabled:opacity-50 disabled:cursor-not-allowed"
              >
                Send
              </button>
            </div>
          </>
        ) : (
          <div className="flex-1 flex items-center justify-center text-gray-400">
            Select a conversation to start messaging
          </div>
        )}
      </div>
    </div>
  );
};