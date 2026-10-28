# Web islands

`VideoCall.tsx` provides a local camera/microphone preview only. `QRJoin.tsx`
accepts a room code or scanned value. Wire them into your existing React app.
For real multi-party calls, implement authenticated signaling and use a reviewed
WebRTC/SFU architecture; do not treat local preview as a working conference.
