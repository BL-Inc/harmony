import React, { useState } from "react";
import { createRoot } from "react-dom/client";
import { QRCodeSVG } from "qrcode.react";
import { VideoCall } from "./islands/VideoCall";
import { QRJoin } from "./islands/QRJoin";
import "./styles.css";

function App() {
  const [roomId, setRoomId] = useState("");
  const [showCall, setShowCall] = useState(false);

  function createLocalRoom() {
    const id = crypto.randomUUID();
    setRoomId(id);
    setShowCall(true);
  }

  return (
    <main className="shell">
      <header>
        <div className="brand-mark">H</div>
        <div>
          <h1>Harmony</h1>
          <p>Hybrid room collaboration starter</p>
        </div>
      </header>

      <section className="panel">
        <h2>Join a room</h2>
        <QRJoin onJoin={(id) => { setRoomId(id); setShowCall(true); }} />
        <p className="muted">Paste a room ID or value scanned from a QR code.</p>
      </section>

      <section className="panel">
        <h2>Start a local preview</h2>
        <p>This creates a local demo room ID and opens your camera preview. It does not connect remote participants.</p>
        <button onClick={createLocalRoom}>Create demo room</button>
      </section>

      {roomId && (
        <section className="panel">
          <h2>Room invite</h2>
          <code>{roomId}</code>
          <div className="qr-wrap"><QRCodeSVG value={`${location.origin}/?room=${encodeURIComponent(roomId)}`} /></div>
        </section>
      )}

      {showCall && roomId && (
        <section className="panel">
          <h2>Local camera preview</h2>
          <VideoCall roomId={roomId} onLeave={() => setShowCall(false)} />
        </section>
      )}

      <footer>Starter build — configure authentication and media signaling before production use.</footer>
    </main>
  );
}

const root = document.getElementById("root");
if (!root) throw new Error("Root element #root not found");
createRoot(root).render(<React.StrictMode><App /></React.StrictMode>);
