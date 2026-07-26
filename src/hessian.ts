// src/hessian.ts
import path from "node:path";
import os from "node:os";
import fs from "node:fs/promises";
import type { HessianModel, HessianPluginConfig, ApiResponse } from "./types.js";
import * as memory from "./hessian-memory.js";

// Constants
const DEFAULT_ENDPOINT = "https://api.hessian.ai/v1";
const PLUGIN_DIR = path.join(os.homedir(), ".config", "pi", "plugins", "hessian");
const PLUGIN_CONFIG_PATH = path.join(PLUGIN_DIR, "pi-hessian.json");

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

// Default permissions
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

export default async (pi: unknown): Promise<{ name: string; permissions: typeof PERMISSIONS; config: Record<string, unknown> }> => {
  await ensurePluginDirectory();

  try {
    await refreshHessianConfig();
    registerCommands(pi);
  } catch (error) {
    console.error("[Hessian Plugin] Initialization error:", error instanceof Error ? error.message : error);
  }

  return {
    name: "hessian",
    permissions: PERMISSIONS,
    config: {
      provider: "hessian",
      description: "Hessian.AI integration for pi coding agent",
      endpoint: DEFAULT_ENDPOINT,
    },
  };
};

// ============= CORE FUNCTIONS =============

/**
 * Fetch models from Hessian.AI API
 */
async function fetchModels(): Promise<ApiResponse> {
  const apiKey = process.env.HESSIAN_API_KEY;
  if (!apiKey) {
    throw new Error("HESSIAN_API_KEY environment variable is not set");
  }

  const controller = new AbortController();
  const timeoutId = setTimeout(() => controller.abort(), 30_000);

  try {
    const response = await fetch(`${DEFAULT_ENDPOINT}/models`, {
      headers: { Authorization: `Bearer ${apiKey}` },
      signal: controller.signal,
    });

    clearTimeout(timeoutId);

    if (!response.ok) {
      throw new Error(`API request failed: ${response.status} ${response.statusText}`);
    }

    return response.json() as Promise<ApiResponse>;
  } catch (error) {
    clearTimeout(timeoutId);
    throw error;
  }
}

/**
 * Ensure plugin directory exists
 */
async function ensurePluginDirectory(): Promise<void> {
  try {
    await fs.mkdir(PLUGIN_DIR, { recursive: true });
  } catch {
    // Directory already exists or other non-critical error
  }
}

/**
 * Register plugin commands
 */
function registerCommands(pi: unknown): void {
  if (!pi || typeof pi !== "object" || !("registerCommand" in pi)) {
    return;
  }

  const commandContext = pi as { registerCommand: (cmd: { name: string; description: string; handler: () => Promise<string> }) => void };

  commandContext.registerCommand({
    name: "refresh-hessian-models",
    description: "Refresh the list of available Hessian.AI models",
    async handler() {
      await refreshHessianConfig(true);
      return "Hessian.AI models refreshed successfully";
    },
  });

  commandContext.registerCommand({
    name: "list-hessian-models",
    description: "List all available Hessian.AI models",
    async handler() {
      return await listModels();
    },
  });
}

/**
 * Refresh Hessian.AI configuration
 */
async function refreshHessianConfig(forceRefresh = false): Promise<void> {
  const profile = process.env.HESSIAN_PROFILE || "production";

  try {
    const result = await memory.fetchWithCache(fetchModels, forceRefresh);
    const apiModels = result.data.data.map((model) => model.id).sort();
    const allModels = [...new Set([...apiModels, ...TUD_MODELS])].sort();

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

    // Add all models
    for (const modelId of allModels) {
      pluginConfig.provider.hessian.models[modelId] = createModelConfig(modelId);
    }

    // Add aliases
    pluginConfig.provider.hessian.models["tud"] = {
      name: "Best TUD model (auto-select)",
      category: "alias",
      limit: { context: 0, output: 0 },
      metadata: { estimated_latency: "fast" },
      alias: true,
    };

    pluginConfig.provider.hessian.models["hessian"] = {
      name: "Best Hessian.AI model (auto-select)",
      category: "alias",
      limit: { context: 0, output: 0 },
      metadata: { estimated_latency: "fast" },
      alias: true,
    };

    // Set default model based on profile
    const defaultModel = getDefaultModelForProfile(profile);
    if (allModels.includes(defaultModel)) {
      pluginConfig.model = `hessian/${defaultModel}`;
    } else if (allModels.length > 0) {
      pluginConfig.model = `hessian/${allModels[0]}`;
    }

    pluginConfig.last_updated = new Date().toISOString();

    // Write config atomically
    const tempPath = `${PLUGIN_CONFIG_PATH}.tmp${Date.now()}`;
    await fs.writeFile(tempPath, JSON.stringify(pluginConfig, null, 2));
    await fs.rename(tempPath, PLUGIN_CONFIG_PATH);

    console.log(`[Hessian] Configuration updated: ${allModels.length} models available`);
    if (pluginConfig.model) {
      console.log(`[Hessian] Default model set to: ${pluginConfig.model}`);
    }
  } catch (error) {
    console.error("[Hessian] Configuration refresh failed:", error instanceof Error ? error.message : error);
    throw error;
  }
}

/**
 * Create model configuration
 */
function createModelConfig(modelId: string): HessianModel {
  const isTudModel = modelId.startsWith("tud/");

  return {
    name: getModelDescription(modelId) || modelId,
    category: categorizeModel(modelId),
    limit: {
      context: getContextWindow(modelId),
      output: getOutputWindow(modelId),
    },
    metadata: {
      estimated_latency: getEstimatedLatency(modelId),
      ...(getModelDescription(modelId) && { description: getModelDescription(modelId) }),
    },
    can_reason: canReason(modelId),
    attachment: supportsAttachment(modelId),
  };
}

/**
 * List all models with formatting
 */
async function listModels(): Promise<string> {
  try {
    const result = await memory.fetchWithCache(fetchModels);
    const apiModels = result.data.data.map((model) => model.id);
    const allModels = [...new Set([...apiModels, ...TUD_MODELS])].sort();

    if (allModels.length === 0) {
      return "No models available from Hessian.AI";
    }

    let output = `**Hessian.AI Models (${allModels.length} total):**\n\n`;

    // Group by category
    const categories: Record<string, string[]> = {};
    for (const modelId of allModels) {
      const category = categorizeModel(modelId);
      if (!categories[category]) {
        categories[category] = [];
      }
      categories[category].push(modelId);
    }

    // TUD models first
    if (categories["tud"] || categories["tud-vision"]) {
      output += "### 🏫 TUD Models\n";
      for (const modelId of categories["tud"] || []) {
        output += `- \`${modelId}\`: ${getModelDescription(modelId) || "No description"}\n`;
      }
      for (const modelId of categories["tud-vision"] || []) {
        output += `- \`${modelId}\`: ${getModelDescription(modelId) || "No description"} 🖼️\n`;
      }
      output += "\n";
      delete categories["tud"];
      delete categories["tud-vision"];
    }

    // Other models
    for (const [category, models] of Object.entries(categories)) {
      output += `### ${category.charAt(0).toUpperCase() + category.slice(1)}\n`;
      for (const modelId of models) {
        output += `- \`${modelId}\`: ${getModelDescription(modelId) || "No description"}\n`;
      }
      output += "\n";
    }

    // Aliases
    output += "**Aliases:**\n";
    output += "- `tud`: Best TUD model\n";
    output += "- `hessian`: Best Hessian.AI model\n";

    return output;
  } catch (error) {
    return `Error listing models: ${error instanceof Error ? error.message : String(error)}`;
  }
}

// ============= HELPER FUNCTIONS =============

/**
 * Categorize model based on ID
 */
function categorizeModel(modelId: string): string {
  if (modelId.startsWith("tud/")) {
    return modelId.includes("vl") || modelId.includes("vision") ? "tud-vision" : "tud";
  }
  if (modelId.includes("mistral") || modelId.includes("mixtral")) {
    return "mistral";
  }
  if (modelId.includes("llama")) {
    return "meta";
  }
  if (modelId.includes("qwen")) {
    return "qwen";
  }
  if (modelId.includes("gemma")) {
    return "google";
  }
  return "general";
}

/**
 * Get model description
 */
function getModelDescription(modelId: string): string | undefined {
  const descriptions: Record<string, string> = {
    // TUD models
    "tud/glm-5.2-awq": "GLM 5.2 AWQ INT4",
    "tud/gpt-oss-120b": "GPT-OSS 120B",
    "tud/gemma-4-31b-it": "Gemma 4 31B",
    "tud/mistral-medium-3.5-128b": "Mistral Medium 3.5 128B",
    "tud/qwen3.6-35b-a3b": "Qwen 3.6 35B-A3B",
    "tud/ministral-3-14b-instruct": "Ministral 3 14B",
    "tud/qwen3-vl-30b-a3b": "Qwen 3-VL 30B-A3B",

    // Standard models
    "mistral-7b": "Mistral 7B",
    "mixtral-8x7b": "Mixtral 8x7B",
    "mistral-80b": "Mistral 80B",
    "llama-3-8b": "Llama 3 8B Instruct",
    "llama-3-70b": "Llama 3 70B Instruct",
    "qwen-7b": "Qwen 7B Chat",
    "qwen-14b": "Qwen 14B Chat",
    "gemma-7b": "Gemma 7B IT",
  };

  return descriptions[modelId];
}

/**
 * Check if model supports reasoning
 */
function canReason(modelId: string): boolean {
  const reasoningModels = ["80b", "70b", "mixtral", "llama-3-70b", "llama-3-8b"];
  return reasoningModels.some((suffix) => modelId.toLowerCase().includes(suffix));
}

/**
 * Check if model supports attachments (vision)
 */
function supportsAttachment(modelId: string): boolean {
  return modelId.toLowerCase().includes("vl") || modelId.toLowerCase().includes("vision");
}

/**
 * Get context window size
 */
function getContextWindow(modelId: string): number {
  if (modelId.includes("128b")) return 131_072;
  if (modelId.includes("120b")) return 131_072;
  if (modelId.includes("70b") || modelId.includes("80b")) return 32_768;
  if (modelId.includes("35b") || modelId.includes("30b")) return 16_384;
  if (modelId.includes("14b")) return 8_192;
  return 4_096;
}

/**
 * Get output window size
 */
function getOutputWindow(modelId: string): number {
  if (modelId.includes("128b") || modelId.includes("120b")) return 32_768;
  if (modelId.includes("70b") || modelId.includes("80b")) return 8_192;
  return 2_048;
}

/**
 * Get estimated latency
 */
function getEstimatedLatency(modelId: string): string {
  if (modelId.includes("7b")) return "fast";
  if (modelId.includes("14b")) return "moderate";
  if (modelId.includes("70b") || modelId.includes("80b") || modelId.includes("128b")) return "slow";
  return "moderate";
}

/**
 * Get default model for profile
 */
function getDefaultModelForProfile(profile: string): string {
  switch (profile) {
    case "production":
      return "tud/mistral-medium-3.5-128b";
    case "budget":
      return "tud/ministral-3-14b-instruct";
    default:
      return "tud/qwen3.6-35b-a3b";
  }
}
