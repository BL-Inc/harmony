export type SyncResult<T> = { value: T; syncedAt: number };

/**
 * Small retry helper for idempotent reads. Do not automatically retry
 * non-idempotent writes unless they use server-enforced idempotency keys.
 */
export async function withReadRetry<T>(
  operation: () => Promise<T>,
  attempts = 3,
  baseDelayMs = 250,
): Promise<SyncResult<T>> {
  let lastError: unknown;
  for (let attempt = 0; attempt < Math.max(1, attempts); attempt++) {
    try {
      const value = await operation();
      return { value, syncedAt: Date.now() };
    } catch (error) {
      lastError = error;
      if (attempt + 1 < attempts) {
        await new Promise((resolve) => setTimeout(resolve, baseDelayMs * (2 ** attempt)));
      }
    }
  }
  throw lastError instanceof Error ? lastError : new Error("Sync failed");
}
