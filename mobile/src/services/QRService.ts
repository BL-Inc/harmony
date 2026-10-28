export type ParsedHarmonyInvite = { roomId: string };

/** Parse an invite URL or plain room ID. Validate authorization on the server. */
export function parseHarmonyInvite(raw: string): ParsedHarmonyInvite | null {
  const value = raw.trim();
  if (!value || value.length > 2048) return null;

  try {
    const url = new URL(value);
    const roomId = url.searchParams.get("room") || url.pathname.split("/").filter(Boolean).pop();
    return roomId && roomId.length <= 128 ? { roomId } : null;
  } catch {
    return value.length <= 128 && /^[a-zA-Z0-9_-]+$/.test(value)
      ? { roomId: value }
      : null;
  }
}
