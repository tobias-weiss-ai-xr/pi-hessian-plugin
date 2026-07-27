// src/hessian-memory.ts
// Memory layer utilities for Hessian.AI plugin
// Provides caching, usage tracking, metrics, and preferences

import path from "node:path";
import os from "node:os";

const CACHE_DIR = path.join(os.homedir(), ".cache", "hessian");
const CACHE_FILE = path.join(CACHE_DIR, "models.json");
const MODELS_CACHE_FILE = path.join(CACHE_DIR, "models-list.json");
const USAGE_FILE = path.join(CACHE_DIR, "pi-usage.jsonl");
const METRICS_FILE = path.join(CACHE_DIR, "pi-metrics.json");
const PREFERENCES_FILE = path.join(os.homedir(), ".config", "pi", "hessian-preferences.json");
const PROJECT_CONTEXT_FILE = path.join(process.cwd(), ".pi", "hessian", "context.json");

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
    await fs.unlink(CACHE_FILE).catch(() => {});
    await fs.unlink(MODELS_CACHE_FILE).catch(() => {});
    console.log("[Hessian Memory] Cache cleared");
  } catch (err) {
    console.error(`[Hessian Memory] Failed to clear cache: ${err}`);
  }
}

/**
 * Log model usage per project
 */
export async function logUsage(modelId: string, taskType?: string, latencyMs?: number): Promise<void> {
  await ensureCacheDir();
  try {
    const fs = await import("node:fs/promises");
    const entry = {
      timestamp: new Date().toISOString(),
      projectRoot: process.cwd(),
      modelId,
      taskType: taskType || "general",
      latencyMs,
    };
    await fs.appendFile(USAGE_FILE, JSON.stringify(entry) + "\n");
  } catch (err: unknown) {
    console.error(`[Hessian Memory] Failed to log usage: ${err instanceof Error ? err.message : String(err)}`);
  }
}

/**
 * Update metrics for API operations
 */
export async function updateMetrics(
  identifier: string,
  success: boolean,
  latencyMs?: number,
): Promise<void> {
  await ensureCacheDir();
  try {
    const fs = await import("node:fs/promises");
    const metricsRaw = await fs.readFile(METRICS_FILE, "utf8").catch(() => "{}");
    const metrics: Record<string, any> = JSON.parse(metricsRaw);

    if (!metrics[identifier]) {
      metrics[identifier] = { count: 0, success: 0, errors: 0, totalLatency: 0, lastUsed: null };
    }

    const entityMetrics = metrics[identifier] as Record<string, any>;
    entityMetrics.count++;
    entityMetrics[success ? "success" : "errors"]++;
    if (latencyMs !== undefined) {
      entityMetrics.totalLatency += latencyMs;
    }
    entityMetrics.lastUsed = new Date().toISOString();

    const tmp = METRICS_FILE + ".tmp";
    await fs.writeFile(tmp, JSON.stringify(metrics, null, 2));
    await fs.rename(tmp, METRICS_FILE);
  } catch (err: unknown) {
    console.error(`[Hessian Memory] Failed to update metrics: ${err instanceof Error ? err.message : String(err)}`);
  }
}

/**
 * Get user preferences
 */
export async function getPreferences(): Promise<Record<string, any>> {
  try {
    const fs = await import("node:fs/promises");
    const raw = await fs.readFile(PREFERENCES_FILE, "utf8");
    return JSON.parse(raw);
  } catch {
    return {};
  }
}

/**
 * Set user preferences
 */
export async function setPreferences(prefs: Record<string, unknown>): Promise<void> {
  try {
    const fs = await import("node:fs/promises");
    const existing = await getPreferences();
    const merged = { ...existing, ...prefs };
    const dir = path.dirname(PREFERENCES_FILE);
    await fs.mkdir(dir, { recursive: true });
    const tmp = PREFERENCES_FILE + ".tmp";
    await fs.writeFile(tmp, JSON.stringify(merged, null, 2));
    await fs.rename(tmp, PREFERENCES_FILE);
    console.log("[Hessian Memory] Preferences saved");
  } catch (err) {
    console.error(`[Hessian Memory] Failed to save preferences: ${err}`);
  }
}

/**
 * Get project context
 */
export async function getContext(): Promise<Record<string, unknown>> {
  try {
    const fs = await import("node:fs/promises");
    const raw = await fs.readFile(PROJECT_CONTEXT_FILE, "utf8");
    return JSON.parse(raw);
  } catch {
    return {};
  }
}

/**
 * Update project context
 */
export async function updateContext(updates: Record<string, unknown>): Promise<void> {
  try {
    const fs = await import("node:fs/promises");
    const existing = await getContext();
    const merged = { ...existing, ...updates };
    const dir = path.dirname(PROJECT_CONTEXT_FILE);
    await fs.mkdir(dir, { recursive: true });
    const tmp = PROJECT_CONTEXT_FILE + ".tmp";
    await fs.writeFile(tmp, JSON.stringify(merged, null, 2));
    await fs.rename(tmp, PROJECT_CONTEXT_FILE);
  } catch (err) {
    console.error(`[Hessian Memory] Failed to update project context: ${err}`);
  }
}

/**
 * Get usage statistics
 */
export async function getUsageStats(): Promise<Record<string, any>> {
  try {
    const fs = await import("node:fs/promises");
    const raw = await fs.readFile(USAGE_FILE, "utf8").catch(() => "");
    const lines = raw.trim().split("\n").filter(Boolean);
    const stats: Record<string, any> = { total: lines.length, byModel: {}, byTask: {} };

    for (const line of lines) {
      try {
        const entry = JSON.parse(line);
        const model = entry.modelId || "unknown";
        const task = entry.taskType || "unknown";
        stats.byModel[model] = (stats.byModel[model] || 0) + 1;
        stats.byTask[task] = (stats.byTask[task] || 0) + 1;
      } catch { /* skip invalid lines */ }
    }
    return stats;
  } catch {
    return { total: 0, byModel: {}, byTask: {} };
  }
}

/**
 * Get metrics summary
 */
export async function getMetricsSummary(): Promise<Record<string, any>> {
  try {
    const fs = await import("node:fs/promises");
    const raw = await fs.readFile(METRICS_FILE, "utf8").catch(() => "{}");
    const metrics = JSON.parse(raw);
    const summary: Record<string, any> = { totalRequests: 0, successRate: 0, byEndpoint: {} };

    for (const [key, value] of Object.entries(metrics)) {
      const entry = value as Record<string, any>;
      summary.totalRequests += entry.count || 0;
      summary.byEndpoint[key] = {
        count: entry.count || 0,
        successRate: entry.count > 0 ? ((entry.success || 0) / entry.count) * 100 : 0,
        avgLatency: entry.count > 0 ? (entry.totalLatency || 0) / entry.count : 0,
      };
    }

    const rates = Object.values(summary.byEndpoint).map((e: any) => e.successRate || 0);
    summary.successRate = rates.length > 0
      ? rates.reduce((sum, r) => sum + r, 0) / rates.length
      : 0;

    return summary;
  } catch {
    return { totalRequests: 0, successRate: 0, byEndpoint: {} };
  }
}

/**
 * Check for new or removed models compared to last cached list
 */
export async function checkForNewModels(apiKey?: string): Promise<{ added: string[]; removed: string[] }> {
  await ensureCacheDir();
  const fs = await import("node:fs/promises");

  let cachedIds: string[] = [];
  try {
    const raw = await fs.readFile(MODELS_CACHE_FILE, "utf8");
    const parsed = JSON.parse(raw);
    if (Array.isArray(parsed.ids)) cachedIds = parsed.ids;
  } catch { /* no cache yet */ }

  const key = apiKey || process.env.HESSIAN_API_KEY || "";
  if (!key) return { added: [], removed: [] };

  const url = "https://api.hessian.ai/v1/models";

  let freshIds: string[] = [];
  try {
    const res = await fetch(url, {
      headers: { Authorization: `Bearer ${key}` },
      signal: AbortSignal.timeout(15_000),
    });
    if (!res.ok) return { added: [], removed: [] };
    const body = await res.json() as { data?: Array<{ id: string }> };
    freshIds = (body.data || []).map((m) => m.id).sort();

    const tmp = MODELS_CACHE_FILE + ".tmp";
    await fs.writeFile(tmp, JSON.stringify({ ids: freshIds, timestamp: Date.now() }, null, 2));
    await fs.rename(tmp, MODELS_CACHE_FILE);
  } catch {
    return { added: [], removed: [] };
  }

  if (cachedIds.length === 0) return { added: [], removed: [] };

  const freshSet = new Set(freshIds);
  const cachedSet = new Set(cachedIds);
  const added = freshIds.filter((id) => !cachedSet.has(id));
  const removed = cachedIds.filter((id) => !freshSet.has(id));

  if (added.length > 0 || removed.length > 0) {
    console.log(`[Hessian Memory] Model changes detected: +${added.length} -${removed.length}`);
    for (const id of added) console.log(`  [+] ${id}`);
    for (const id of removed) console.log(`  [-] ${id}`);
  }

  return { added, removed };
}
