// src/hessian-memory.ts
import path from "node:path";
import os from "node:os";

const CACHE_DIR = path.join(os.homedir(), ".cache", "hessian");
const CACHE_FILE = path.join(CACHE_DIR, "models.json");
const CACHE_TTL_MS = 24 * 60 * 60 * 1000; // 24 hours

/**
 * Ensure cache directory exists
 */
async function ensureCacheDir(): Promise<void> {
  try {
    const fs = await import("node:fs/promises");
    await fs.mkdir(CACHE_DIR, { recursive: true });
  } catch (err) {
    console.error(`[Hessian Memory] Failed to create cache directory: ${err}`);
  }
}

/**
 * Fetch with caching
 */
export async function fetchWithCache<T>(
  fetcher: () => Promise<T>,
  forceRefresh = false
): Promise<{ data: T; cached: boolean }> {
  await ensureCacheDir();

  if (!forceRefresh) {
    try {
      const fs = await import("node:fs/promises");
      const cachedRaw = await fs.readFile(CACHE_FILE, "utf8");
      const cached = JSON.parse(cachedRaw) as { data: T; timestamp: number };
      const age = Date.now() - cached.timestamp;

      if (age < CACHE_TTL_MS) {
        console.log(`[Hessian Memory] Cache hit (age: ${Math.round(age / 1000 / 60)}m)`);
        return { data: cached.data, cached: true };
      }
    } catch {
      // Cache miss or invalid - continue to fetch fresh
    }
  }

  console.log("[Hessian Memory] Fetching fresh data...");

  const data = await fetcher();

  try {
    const fs = await import("node:fs/promises");
    const cacheEntry = { data, timestamp: Date.now() };
    const tempPath = `${CACHE_FILE}.tmp${Date.now()}`;
    await fs.writeFile(tempPath, JSON.stringify(cacheEntry, null, 2));
    await fs.rename(tempPath, CACHE_FILE);
    console.log("[Hessian Memory] Cache updated");
  } catch (err) {
    console.error(`[Hessian Memory] Failed to write cache: ${err}`);
  }

  return { data, cached: false };
}

/**
 * Clear cache
 */
export async function clearCache(): Promise<void> {
  try {
    const fs = await import("node:fs/promises");
    await fs.unlink(CACHE_FILE).catch(() => {
      /* File doesn't exist */
    });
    console.log("[Hessian Memory] Cache cleared");
  } catch (err) {
    console.error(`[Hessian Memory] Failed to clear cache: ${err}`);
  }
}
