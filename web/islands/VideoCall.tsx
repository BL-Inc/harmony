import React, { useEffect, useRef, useState } from "react";

export type VideoCallProps = {
  roomId: string;
  onLeave?: () => void;
};

/**
 * Minimal browser media preview. This does not connect participants together;
 * production calls require signaling plus STUN/TURN and usually an SFU.
 */
export function VideoCall({ roomId, onLeave }: VideoCallProps) {
  const videoRef = useRef<HTMLVideoElement>(null);
  const [error, setError] = useState<string>("");
  const [active, setActive] = useState(false);

  useEffect(() => {
    let stream: MediaStream | undefined;
    let disposed = false;

    async function start() {
      try {
        if (!navigator.mediaDevices?.getUserMedia) {
          throw new Error("Camera access is not supported by this browser.");
        }
        stream = await navigator.mediaDevices.getUserMedia({ video: true, audio: true });
        if (disposed) {
          stream.getTracks().forEach((track) => track.stop());
          return;
        }
        if (videoRef.current) videoRef.current.srcObject = stream;
        setActive(true);
      } catch (e) {
        setError(e instanceof Error ? e.message : "Could not access camera and microphone.");
      }
    }

    void start();
    return () => {
      disposed = true;
      stream?.getTracks().forEach((track) => track.stop());
    };
  }, []);

  return (
    <section aria-label="Video call" data-room-id={roomId}>
      <video ref={videoRef} autoPlay muted playsInline style={{ width: "100%", maxWidth: 640 }} />
      {error && <p role="alert">{error}</p>}
      <p>{active ? "Local camera preview active" : "Camera preview not active"}</p>
      <p>Room: {roomId}</p>
      <button type="button" onClick={onLeave}>Leave</button>
    </section>
  );
}
