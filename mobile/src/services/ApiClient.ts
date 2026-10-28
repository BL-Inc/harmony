export type HarmonyRoomType = "video" | "audio" | "screen";

export type HarmonyRoom = {
  room_id: string;
  space_id: string | null;
  host_user_id: string;
  room_type: HarmonyRoomType;
  created_at: string;
  ended_at: string | null;
};

export class HarmonyApiClient {
  constructor(
    private readonly baseUrl: string,
    private readonly getAccessToken: () => Promise<string | null>,
  ) {}

  private async request<T>(path: string, init: RequestInit = {}): Promise<T> {
    const token = await this.getAccessToken();
    if (!token) throw new Error("Authentication required");
    const response = await fetch(`${this.baseUrl.replace(/\/$/, "")}${path}`, {
      ...init,
      headers: {
        "content-type": "application/json",
        "authorization": `Bearer ${token}`,
        ...(init.headers || {}),
      },
    });
    if (!response.ok) throw new Error(`Harmony API error (${response.status})`);
    return response.json() as Promise<T>;
  }

  listRooms(): Promise<HarmonyRoom[]> {
    return this.request<HarmonyRoom[]>("/api/rooms");
  }

  createRoom(roomType: HarmonyRoomType, spaceId?: string): Promise<HarmonyRoom> {
    return this.request<HarmonyRoom>("/api/rooms", {
      method: "POST",
      body: JSON.stringify({ room_type: roomType, ...(spaceId ? { space_id: spaceId } : {}) }),
    });
  }
}
