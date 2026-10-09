// src/hessian.ts
// Hessian.AI Plugin for pi coding agent
// Drop this file into ~/.config/pi/plugins/hessian.ts
// and add "hessian" to your pi config plugins array

import path from "node:path";
import os from "node:os";
import fs from "node:fs/promises";

import type { HessianModel, HessianPluginConfig, ApiResponse } from "./types.js";
import * as memory from "./hessian-memory.js";

// Configuration paths
const CONFIG = path.join(os.homedir(), ".config", "pi", "pi.json");
const PLUGIN_DIR = path.join(os.homedir(), ".config", "pi", "plugins", "hessian");
const PLUGIN_CONFIG = path.join(PLUGIN_DIR, "pi-hessian.json");

// API configuration
const DEFAULT_ENDPOINT = process.env.HESSIAN_API_URL || "https://api.hessian.ai/v1";
const HESSIAN_API_KEY = process.env.HESSIAN_API_KEY || process.env.PI_HESSIAN_API_KEY;

// TUD models (part of Hessian.AI)
const TUD_MODELS: readonly string[] = [
  "tud/glm-5.2-awq",
  "tud/gpt-oss-120b",
  "tud/gemma-4-31b-it",
  "tud/mistral-medium-3.5-128b",
  "tud/qwen3.6-35b-a3b",
  "tud/ministral-3-14b-instruct",
  "tud/qwen3-vl-30b-a3b",
] as const;

// Default permissions for Hessian plugin
export const PERMISSIONS: Record<string, "allow" | "ask" | "deny"> = {
  bash: "allow",
  edit: "allow",
  read: "allow",
  grep: "allow",
  glob: "allow",
  lsp: "allow",
  skill: "allow",
  task: "allow",
  webfetch: "allow",
  websearch: "allow",
  question: "allow",
  external_directory: "ask",
  doom_loop: "ask",
};

// ---------------------------------------------------------------------------
// Model categories
// ---------------------------------------------------------------------------

const CATEGORY_TUD = "tud";
const CATEGORY_TUD_VISION = "tud-vision";
const CATEGORY_MISTRAL = "mistral";
const CATEGORY_META = "meta";
const CATEGORY_QWEN = "qwen";
const CATEGORY_GOOGLE = "google";
const CATEGORY_GENERAL = "general";
const CATEGORY_REASONING = "reasoning";
const CATEGORY_AGENTIC = "agentic";
const CATEGORY_CODER = "coder";
const CATEGORY_LARGE_CONTEXT = "large-context";
const CATEGORY_MEDICAL = "medical";
const CATEGORY_VISION = "vision";

// ---------------------------------------------------------------------------
// Category lookup
// ---------------------------------------------------------------------------

export function categorizeModel(modelId: string): string {
  if (modelId.startsWith("tud/")) {
    return modelId.includes("vl") || modelId.includes("vision") ? CATEGORY_TUD_VISION : CATEGORY_TUD;
  }
  if (modelId.includes("mistral") || modelId.includes("mixtral") || modelId.includes("ministral")) {
    return CATEGORY_MISTRAL;
  }
  if (modelId.includes("llama")) {
    return CATEGORY_META;
  }
  if (modelId.includes("qwen")) {
    return CATEGORY_QWEN;
  }
  if (modelId.includes("gemma")) {
    return CATEGORY_GOOGLE;
  }
  if (modelId.includes("glm")) {
    return CATEGORY_QWEN;
  }
  return CATEGORY_GENERAL;
}

// ---------------------------------------------------------------------------
// Capabilities
// ---------------------------------------------------------------------------

export function canReason(modelId: string): boolean {
  const reasoningModels = [
    "gpt-oss-120b", "glm-5.2-awq", "mistral-medium-3.5-128b",
    "qwen3.6-35b-a3b", "ministral-3-14b-instruct", "qwen3-vl-30b-a3b",
  ];
  const lowercaseId = modelId.toLowerCase();
  return reasoningModels.some((m) => lowercaseId.includes(m)) ||
         lowercaseId.includes("80b") ||
         lowercaseId.includes("70b") ||
         lowercaseId.includes("mixtral");
}

export function supportsAttachment(modelId: string): boolean {
  return modelId.toLowerCase().includes("vl") || 
         modelId.toLowerCase().includes("vision") ||
         modelId.toLowerCase().includes("gemma-4");
}

// ---------------------------------------------------------------------------
// Token limits
// ---------------------------------------------------------------------------

export function getContextWindow(modelId: string): number {
  if (modelId.includes("128b")) return 131_072;
  if (modelId.includes("120b")) return 131_072;
  if (modelId.includes("70b") || modelId.includes("80b")) return 32_768;
  if (modelId.includes("35b") || modelId.includes("30b") || modelId.includes("31b")) return 131_072;
  if (modelId.includes("14b")) return 131_072;
  if (modelId.includes("7b")) return 32_768;
  return 4_096;
}

export function getOutputWindow(modelId: string): number {
  if (modelId.includes("128b") || modelId.includes("120b")) return 32_768;
  if (modelId.includes("70b") || modelId.includes("80b")) return 8_192;
  if (modelId.includes("35b") || modelId.includes("30b") || modelId.includes("31b")) return 32_768;
  if (modelId.includes("14b")) return 32_768;
  if (modelId.includes("7b")) return 8_192;
  return 2_048;
}

// ---------------------------------------------------------------------------
// Descriptions
// ---------------------------------------------------------------------------

export function getModelDescription(modelId: string): string {
  const descriptions: Record<string, string> = {
    // TUD models
    "tud/glm-5.2-awq": "GLM 5.2 AWQ INT4 - Advanced reasoning model",
    "tud/gpt-oss-120b": "GPT-OSS 120B - Open-source GPT model",
    "tud/gemma-4-31b-it": "Gemma 4 31B - Google's latest open model",
    "tud/mistral-medium-3.5-128b": "Mistral Medium 3.5 128B - Strong generalist",
    "tud/qwen3.6-35b-a3b": "Qwen 3.6 35B-A3B - Agentic coding model",
    "tud/ministral-3-14b-instruct": "Ministral 3 14B - Efficient instruct model",
    "tud/qwen3-vl-30b-a3b": "Qwen 3-VL 30B-A3B - Multimodal vision model",

    // Standard Hessian.AI models
    "mistral-7b": "Mistral 7B - Fast general purpose",
    "mixtral-8x7b": "Mixtral 8x7B - Sparse MoE model",
    "mistral-80b": "Mistral 80B - High-capability model",
    "llama-3-8b": "Llama 3 8B Instruct - Meta's instruct model",
    "llama-3-70b": "Llama 3 70B Instruct - High-capacity Meta model",
    "qwen-7b": "Qwen 7B Chat - Aloha's chat model",
    "qwen-14b": "Qwen 14B Chat - Higher-capacity Qwen",
    "gemma-7b": "Gemma 7B IT - Google's Gemma model",
  };

  return descriptions[modelId] || modelId;
}

// ---------------------------------------------------------------------------
// Metadata builder
// ---------------------------------------------------------------------------

export function getModelMetadata(modelId: string): Record<string, any> {
  const metadata: Record<string, any> = {
    name: modelId,
    category: categorizeModel(modelId),
    description: getModelDescription(modelId),
    limit: {
      context: getContextWindow(modelId),
      output: getOutputWindow(modelId),
    },
  };
  if (canReason(modelId)) metadata.can_reason = true;
  if (supportsAttachment(modelId)) metadata.attachment = true;
  return metadata;
}

// ---------------------------------------------------------------------------
// Aliases
// ---------------------------------------------------------------------------

export const ALIASES: Record<string, string> = {
  "best-for-coding": "tud/qwen3.6-35b-a3b",
  "best-for-reasoning": "tud/mistral-medium-3.5-128b",
  "best-for-agentic": "tud/qwen3.6-35b-a3b",
  "best-quality": "tud/mistral-medium-3.5-128b",
  fastest: "tud/ministral-3-14b-instruct",
  budget: "tud/ministral-3-14b-instruct",
  "best-for-vision": "tud/qwen3-vl-30b-a3b",
  "tud": "tud/mistral-medium-3.5-128b",
  "hessian": "tud/mistral-medium-3.5-128b",
};

// ---------------------------------------------------------------------------
// Profile defaults
// ---------------------------------------------------------------------------

export function getProfileDefaultModel(profile: string): string {
  switch (profile) {
    case "production":
      return "tud/mistral-medium-3.5-128b";
    case "development":
    case "dev":
      return "tud/qwen3.6-35b-a3b";
    case "budget":
      return "tud/ministral-3-14b-instruct";
    default:
      return "tud/mistral-medium-3.5-128b";
  }
}

export function includeInProfile(modelId: string, profile: string): boolean {
  switch (profile) {
    case "production":
      // All models
      return true;
    case "development":
    case "dev":
      // Mid-sized and smaller models for faster iteration
      return [
        "tud/qwen3.6-35b-a3b",
        "tud/gpt-oss-120b",
        "tud/gemma-4-31b-it",
        "tud/ministral-3-14b-instruct",
        "tud/qwen3-vl-30b-a3b",
        "mistral-7b",
        "mixtral-8x7b",
        "llama-3-8b",
        "qwen-7b",
        "gemma-7b",
      ].includes(modelId) || TUD_MODELS.includes(modelId);
    case "budget":
      return [
        "tud/ministral-3-14b-instruct",
        "tud/glm-5.2-awq",
        "mistral-7b",
        "qwen-7b",
        "gemma-7b",
      ].includes(modelId);
    default:
      return true;
  }
}

// ---------------------------------------------------------------------------
// Main plugin entry point
// ---------------------------------------------------------------------------

export default async (pi: any) => {
  const pluginName = "hessian";

  // Ensure plugin directory exists
  await fs.mkdir(PLUGIN_DIR, { recursive: true }).catch(() => {});

  // Refresh Hessian config on startup
  refreshHessianConfig(pi).catch((err: unknown) => {
    console.error("[Hessian Plugin] Initialization error:", err instanceof Error ? err.message : err);
  });

  // Register commands
  if (pi.registerCommand) {
    pi.registerCommand("refresh-hessian-models", {
      description: "Manually refresh Hessian.AI model list from API",
      handler: async () => {
        await refreshHessianConfig(pi, true);
        console.log("Hessian.AI models refreshed successfully");
      },
    });

    pi.registerCommand("list-hessian-models", {
      description: "List all available Hessian.AI models",
      handler: async () => {
        console.log(await listModels());
      },
    });

    pi.registerCommand("hessian-set-profile", {
      description: "Switch Hessian.AI profile (production, development, budget)",
      handler: async (args: string) => {
        const profile = args.trim();
        if (!["production", "development", "dev", "budget"].includes(profile)) {
          console.log(`Invalid profile: ${profile}. Valid: production, development, dev, budget`);
          return;
        }
        process.env.HESSIAN_PROFILE = profile;
        await refreshHessianConfig(pi, true);
        await memory.setPreferences({ defaultProfile: profile });
        console.log(`Switched to ${profile} profile and refreshed models`);
      },
    });

    pi.registerCommand("hessian-usage", {
      description: "Show Hessian.AI usage statistics",
      handler: async () => {
        const stats = await memory.getUsageStats();
        console.log(JSON.stringify(stats, null, 2));
      },
    });

    pi.registerCommand("hessian-cache-stats", {
      description: "Show Hessian.AI cache statistics",
      handler: async () => {
        const stats = memory.getCacheStats();
        console.log(JSON.stringify(stats, null, 2));
      },
    });

    pi.registerCommand("clear-hessian-cache", {
      description: "Clear Hessian.AI cache",
      handler: async () => {
        await memory.clearCache();
        console.log("Hessian.AI cache cleared");
      },
    });
  }

  console.log(`[Hessian Plugin] Loaded successfully`);

  return {
    name: pluginName,
    permissions: PERMISSIONS,
    config: {
      provider: "hessian",
      description: "Hessian.AI integration for pi coding agent",
    },
  };
};

// ---------------------------------------------------------------------------
// Model listing
// ---------------------------------------------------------------------------

async function listModels(): Promise<string> {
  try {
    const apiKey = process.env.HESSIAN_API_KEY || HESSIAN_API_KEY;
    if (!apiKey) {
      // Fall back to TUD models only
      const allModels = [...TUD_MODELS].sort();
      return formatModelList(allModels, true);
    }

    const result = await memory.fetchWithCache(fetchModels);
    const apiModels = result.data.data.map((m) => m.id);
    const allModels = [...new Set([...apiModels, ...TUD_MODELS])].sort();

    return formatModelList(allModels, result.cached);
  } catch (err) {
    return `Error listing models: ${err instanceof Error ? err.message : String(err)}`;
  }
}

function formatModelList(modelIds: string[], cached: boolean): string {
  const profile = process.env.HESSIAN_PROFILE || "production";
  const filteredModels = modelIds.filter((id) => includeInProfile(id, profile));

  if (filteredModels.length === 0) return "No models available";

  let output = `**Hessian.AI Models (${filteredModels.length} total, ${cached ? "cached" : "fresh"}):**\n\n`;

  // Group by category
  const categories: Record<string, string[]> = {};
  for (const id of filteredModels) {
    const cat = categorizeModel(id);
    if (!categories[cat]) categories[cat] = [];
    categories[cat].push(id);
  }

  // TUD models first
  if (categories[CATEGORY_TUD] || categories[CATEGORY_TUD_VISION]) {
    output += "### \ud83c\udfbb TUD Models\n";
    for (const modelId of categories[CATEGORY_TUD] || []) {
      const reason = canReason(modelId) ? " [reasoning]" : "";
      const attach = supportsAttachment(modelId) ? " [vision]" : "";
      output += `- \`${modelId}\`: ${getModelDescription(modelId) || "No description"}${reason}${attach}\n`;
    }
    for (const modelId of categories[CATEGORY_TUD_VISION] || []) {
      const reason = canReason(modelId) ? " [reasoning]" : "";
      const attach = supportsAttachment(modelId) ? " [vision]" : "";
      output += `- \`${modelId}\`: ${getModelDescription(modelId) || "No description"}${reason}${attach} \ud83d\udca5\n`;
    }
    output += "\n";
    delete categories[CATEGORY_TUD];
    delete categories[CATEGORY_TUD_VISION];
  }

  // Other Hessian.AI models
  for (const [category, models] of Object.entries(categories)) {
    const displayName = category.charAt(0).toUpperCase() + category.slice(1);
    output += `### ${displayName}\n`;
    for (const modelId of models) {
      const reason = canReason(modelId) ? " [reasoning]" : "";
      const attach = supportsAttachment(modelId) ? " [vision]" : "";
      output += `- \`${modelId}\`: ${getModelDescription(modelId) || "No description"}${reason}${attach}\n`;
    }
    output += "\n";
  }

  // Aliases
  output += "**Aliases:**\n";
  for (const [alias, target] of Object.entries(ALIASES)) {
    if (filteredModels.includes(target)) {
      output += `- \`${alias}\` \u2192 \`${target}\`\n`;
    }
  }

  return output;
}

// ---------------------------------------------------------------------------
// Fetch from API
// ---------------------------------------------------------------------------

async function fetchModels(): Promise<ApiResponse> {
  const apiKey = process.env.HESSIAN_API_KEY || HESSIAN_API_KEY;
  if (!apiKey) {
    // Return empty data when no API key - we'll fall back to TUD models
    return { data: [] };
  }

  const url = `${DEFAULT_ENDPOINT}/models`;

  const startTime = Date.now();
  let res;
  try {
    res = await fetch(url, {
      headers: { Authorization: `Bearer ${apiKey}` },
      signal: AbortSignal.timeout(30000),
    });
  } catch (err) {
    const latencyMs = Date.now() - startTime;
    await memory.updateMetrics("api", false, latencyMs);
    console.error(`[Hessian] Failed to fetch models: ${err instanceof Error ? err.message : err}`);
    return { data: [] };
  }

  const latencyMs = Date.now() - startTime;

  if (!res.ok) {
    await memory.updateMetrics("api", false, latencyMs);
    console.error(`[Hessian] API returned ${res.status}: ${res.statusText}`);
    return { data: [] };
  }

  await memory.updateMetrics("api", true, latencyMs);
  return res.json() as Promise<ApiResponse>;
}

// ---------------------------------------------------------------------------
// Config refresh
// ---------------------------------------------------------------------------

async function refreshHessianConfig(pi: any, forceRefresh = false) {
  const profile = process.env.HESSIAN_PROFILE || "production";
  const startTime = Date.now();

  try {
    const result = await memory.fetchWithCache(fetchModels, forceRefresh);
    await memory.updateMetrics("refresh", true, Date.now() - startTime);

    const apiModels = result.data.data.map((m) => m.id);
    const allModels = [...new Set([...apiModels, ...TUD_MODELS])].sort();
    const profileModels = allModels.filter((id) => includeInProfile(id, profile));

    if (profileModels.length === 0) {
      console.warn("[Hessian] No models available from API");
      return;
    }

    // Generate plugin config
    const pluginConfig: HessianPluginConfig = {
      $schema: "https://pi.code/config.json",
      permission: { ...PERMISSIONS },
      provider: {
        hessian: {
          npm: "@ai-sdk/openai-compatible",
          name: "Hessian.AI",
          options: {
            baseURL: DEFAULT_ENDPOINT,
            apiKey: "{env:HESSIAN_API_KEY}",
          },
          models: {},
        },
      },
    };

    // Add all models to config
    for (const modelId of profileModels) {
      const metadata = getModelMetadata(modelId);
      delete (metadata as Record<string, unknown>).name;
      pluginConfig.provider.hessian.models[modelId] = metadata as HessianModel;
    }

    // Add aliases
    for (const [aliasName, aliasTarget] of Object.entries(ALIASES)) {
      if (profileModels.includes(aliasTarget)) {
        pluginConfig.provider.hessian.models[aliasName] = {
          name: `Alias for ${aliasTarget}`,
          category: "alias",
          limit: { context: 0, output: 0 },
          metadata: { estimated_latency: "fast" },
          alias: true,
        };
      }
    }

    // Set default model based on profile
    const defaultModel = getProfileDefaultModel(profile);
    if (profileModels.includes(defaultModel)) {
      pluginConfig.model = `hessian/${defaultModel}`;
    } else if (profileModels.length > 0) {
      pluginConfig.model = `hessian/${profileModels[0]}`;
    }

    pluginConfig.last_updated = new Date().toISOString();

    // Write plugin config atomically
    const tmp = PLUGIN_CONFIG + ".tmp" + Date.now();
    await fs.writeFile(tmp, JSON.stringify(pluginConfig, null, 2));
    await fs.rename(tmp, PLUGIN_CONFIG);

    console.log(`[Hessian] Config refreshed: ${profileModels.length} models (${result.cached ? "from cache" : "fresh"})`);
    if (pluginConfig.model) {
      console.log(`[Hessian] Default model set to: ${pluginConfig.model}`);
    }

    // Log to pi if available
    if (pi?.log) {
      try {
        await pi.log({
          level: "info",
          message: `Hessian plugin: refreshed ${profileModels.length} models`,
          data: { cached: result.cached, profile, modelCount: profileModels.length },
        });
      } catch {
        // Ignore logging errors
      }
    }
  } catch (err) {
    await memory.updateMetrics("refresh", false, Date.now() - startTime);
    console.error("[Hessian] Config refresh failed:", err instanceof Error ? err.message : err);
    // Don't throw - just log and continue with existing config
  }
}
