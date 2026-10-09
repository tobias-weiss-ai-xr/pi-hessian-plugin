/**
 * pi-hessian-plugin: Hessian.AI provider registration.
 *
 * Registers the Hessian.AI provider with TUD models.
 *
 * Install: pi install /path/to/pi-hessian-plugin
 * Reload:  /reload
 *
 * Provider: Hessian.AI (https://api.hessian.ai)
 * TUD Service: https://llm-service.ai.tu-darmstadt.de
 */

import type { ExtensionAPI, ProviderModelConfig } from "@earendil-works/pi-coding-agent";

// TUD models hosted at Hessian.AI TU Darmstadt
// These are the primary models available through the Hessian.AI infrastructure
const TUD_MODELS: ProviderModelConfig[] = [
  // Reasoning models
  {
    id: "gpt-oss-120b",
    name: "GPT-OSS 120B (TUD)",
    reasoning: true,
    input: ["text"],
    cost: { input: 0, output: 0, cacheRead: 0, cacheWrite: 0 },
    contextWindow: 131_072,
    maxTokens: 32_768,
  },
  {
    id: "glm-5.2-awq",
    name: "GLM 5.2 AWQ INT4 (TUD)",
    reasoning: true,
    input: ["text"],
    cost: { input: 0, output: 0, cacheRead: 0, cacheWrite: 0 },
    contextWindow: 131_072,
    maxTokens: 32_768,
  },
  {
    id: "mistral-medium-3.5-128b",
    name: "Mistral Medium 3.5 128B (TUD)",
    reasoning: true,
    input: ["text"],
    cost: { input: 0, output: 0, cacheRead: 0, cacheWrite: 0 },
    contextWindow: 131_072,
    maxTokens: 32_768,
  },
  {
    id: "qwen3.6-35b-a3b",
    name: "Qwen 3.6 35B A3B (TUD)",
    reasoning: true,
    input: ["text"],
    cost: { input: 0, output: 0, cacheRead: 0, cacheWrite: 0 },
    contextWindow: 131_072,
    maxTokens: 32_768,
  },
  {
    id: "ministral-3-14b-instruct",
    name: "Ministral 3 14B (TUD)",
    reasoning: true,
    input: ["text"],
    cost: { input: 0, output: 0, cacheRead: 0, cacheWrite: 0 },
    contextWindow: 131_072,
    maxTokens: 32_768,
  },

  // Vision model
  {
    id: "gemma-4-31b-it",
    name: "Gemma 4 31B IT (TUD)",
    reasoning: true,
    input: ["text", "image"],
    cost: { input: 0, output: 0, cacheRead: 0, cacheWrite: 0 },
    contextWindow: 262_144,
    maxTokens: 32_768,
  },
  {
    id: "qwen3-vl-30b-a3b-instruct-awq",
    name: "Qwen 3 VL 30B (TUD)",
    reasoning: true,
    input: ["text", "image"],
    cost: { input: 0, output: 0, cacheRead: 0, cacheWrite: 0 },
    contextWindow: 131_072,
    maxTokens: 32_768,
  },

  // convenience shortcuts
  {
    id: "tud",
    name: "Best TUD model (auto-select)",
    reasoning: true,
    input: ["text"],
    cost: { input: 0, output: 0, cacheRead: 0, cacheWrite: 0 },
    contextWindow: 131_072,
    maxTokens: 32_768,
  },
  {
    id: "best-for-reasoning",
    name: "best-for-reasoning -> mistral-medium-3.5-128b",
    reasoning: true,
    input: ["text"],
    cost: { input: 0, output: 0, cacheRead: 0, cacheWrite: 0 },
    contextWindow: 131_072,
    maxTokens: 32_768,
  },
  {
    id: "best-for-coding",
    name: "best-for-coding -> qwen3.6-35b-a3b",
    reasoning: true,
    input: ["text"],
    cost: { input: 0, output: 0, cacheRead: 0, cacheWrite: 0 },
    contextWindow: 131_072,
    maxTokens: 32_768,
  },
  {
    id: "best-for-vision",
    name: "best-for-vision -> qwen3-vl-30b-a3b-instruct-awq",
    reasoning: true,
    input: ["text", "image"],
    cost: { input: 0, output: 0, cacheRead: 0, cacheWrite: 0 },
    contextWindow: 131_072,
    maxTokens: 32_768,
  },
  {
    id: "best-quality",
    name: "best-quality -> mistral-medium-3.5-128b",
    reasoning: true,
    input: ["text"],
    cost: { input: 0, output: 0, cacheRead: 0, cacheWrite: 0 },
    contextWindow: 131_072,
    maxTokens: 32_768,
  },
  {
    id: "fastest",
    name: "fastest -> ministral-3-14b-instruct",
    reasoning: true,
    input: ["text"],
    cost: { input: 0, output: 0, cacheRead: 0, cacheWrite: 0 },
    contextWindow: 131_072,
    maxTokens: 32_768,
  },
  {
    id: "budget",
    name: "budget -> ministral-3-14b-instruct",
    reasoning: true,
    input: ["text"],
    cost: { input: 0, output: 0, cacheRead: 0, cacheWrite: 0 },
    contextWindow: 131_072,
    maxTokens: 32_768,
  },
];

// Hessian.AI main service models
const HESSIAN_MODELS: ProviderModelConfig[] = [
  // Mistral family
  {
    id: "mistral-7b",
    name: "Mistral 7B (Hessian)",
    reasoning: false,
    input: ["text"],
    cost: { input: 0, output: 0, cacheRead: 0, cacheWrite: 0 },
    contextWindow: 32_768,
    maxTokens: 2_048,
  },
  {
    id: "mixtral-8x7b",
    name: "Mixtral 8x7B (Hessian)",
    reasoning: true,
    input: ["text"],
    cost: { input: 0, output: 0, cacheRead: 0, cacheWrite: 0 },
    contextWindow: 32_768,
    maxTokens: 2_048,
  },
  {
    id: "mistral-80b",
    name: "Mistral 80B (Hessian)",
    reasoning: true,
    input: ["text"],
    cost: { input: 0, output: 0, cacheRead: 0, cacheWrite: 0 },
    contextWindow: 32_768,
    maxTokens: 8_192,
  },

  // Meta Llama family
  {
    id: "llama-3-8b",
    name: "Llama 3 8B Instruct (Hessian)",
    reasoning: false,
    input: ["text"],
    cost: { input: 0, output: 0, cacheRead: 0, cacheWrite: 0 },
    contextWindow: 131_072,
    maxTokens: 4_096,
  },
  {
    id: "llama-3-70b",
    name: "Llama 3 70B Instruct (Hessian)",
    reasoning: true,
    input: ["text"],
    cost: { input: 0, output: 0, cacheRead: 0, cacheWrite: 0 },
    contextWindow: 32_768,
    maxTokens: 8_192,
  },

  // Qwen family
  {
    id: "qwen-7b",
    name: "Qwen 7B Chat (Hessian)",
    reasoning: false,
    input: ["text"],
    cost: { input: 0, output: 0, cacheRead: 0, cacheWrite: 0 },
    contextWindow: 32_768,
    maxTokens: 2_048,
  },
  {
    id: "qwen-14b",
    name: "Qwen 14B Chat (Hessian)",
    reasoning: false,
    input: ["text"],
    cost: { input: 0, output: 0, cacheRead: 0, cacheWrite: 0 },
    contextWindow: 8_192,
    maxTokens: 2_048,
  },

  // Google Gemma family
  {
    id: "gemma-7b",
    name: "Gemma 7B IT (Hessian)",
    reasoning: false,
    input: ["text"],
    cost: { input: 0, output: 0, cacheRead: 0, cacheWrite: 0 },
    contextWindow: 8_192,
    maxTokens: 2_048,
  },
];

// Combined all models
export const ALL_MODELS: ProviderModelConfig[] = [...TUD_MODELS, ...HESSIAN_MODELS];

// Export model lists for external use
export { TUD_MODELS, HESSIAN_MODELS };

export default function (pi: ExtensionAPI) {
  // Register TUD provider (primary)
  pi.registerProvider("tud", {
    name: "Hessian TUD LLM Service",
    baseUrl: "https://llm-service.ai.tu-darmstadt.de/v1",
    apiKey: "$TUD_API_KEY",
    api: "openai-completions",
    models: TUD_MODELS,
  });

  // Register Hessian.AI provider
  pi.registerProvider("hessian", {
    name: "Hessian.AI",
    baseUrl: "https://api.hessian.ai/v1",
    apiKey: "$HESSIAN_API_KEY",
    api: "openai-completions",
    models: HESSIAN_MODELS,
  });
}
