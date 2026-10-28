import React, { FormEvent, useState } from "react";

export type QRJoinProps = {
  onJoin: (roomId: string) => void;
};

/** Accepts a room ID pasted from a QR scanner or invite link. */
export function QRJoin({ onJoin }: QRJoinProps) {
  const [roomId, setRoomId] = useState("");

  function submit(event: FormEvent) {
    event.preventDefault();
    const value = roomId.trim();
    if (!value || value.length > 128) return;
    onJoin(value);
  }

  return (
    <form onSubmit={submit} aria-label="Join a Harmony room">
      <label htmlFor="harmony-room-id">Room ID or invite code</label>
      <input
        id="harmony-room-id"
        value={roomId}
        onChange={(event) => setRoomId(event.target.value)}
        maxLength={128}
        autoComplete="off"
        required
      />
      <button type="submit">Join room</button>
    </form>
  );
}
