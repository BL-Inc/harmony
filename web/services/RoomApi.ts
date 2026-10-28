export type RoomType = "video" | "audio" | "screen";
export type Room = {
  room_id: string;
  space_id: string | null;
  host_user_id: string;
  room_type: RoomType;
  created_at: string;
  ended_at: string | null;
};

export class RoomApi {
  constructor(
    private readonly apiBaseUrl: string,
    private readonly accessToken: () => Promise<string | null>,
  ) {}

  private async call<T>(path: string, init: RequestInit = {}): Promise<T> {
    const token = await this.accessToken();
    if (!token) throw new Error("Please sign in first.");
    const response = await fetch(`${this.apiBaseUrl.replace(/\/$/, "")}${path}`, {
      ...init,
      headers: {
        authorization: `Bearer ${token}`,
        "content-type": "application/json",
        ...(init.headers || {}),
      },
    });
    if (!response.ok) {
      const message = await response.text().catch(() => "");
      throw new Error(`Room API failed (${response.status})${message ? `: ${message}` : ""}`);
    }
    return response.json() as Promise<T>;
  }

  list(): Promise<Room[]> {
    return this.call<Room[]>("/api/rooms");
  }

  create(roomType: RoomType, spaceId?: string): Promise<Room> {
    return this.call<Room>("/api/rooms", {
      method: "POST",
      body: JSON.stringify({ room_type: roomType, ...(spaceId ? { space_id: spaceId } : {}) }),
    });
  }
}
