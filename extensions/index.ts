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
// Verified live 2026-10-09 against GET https://llm-service.ai.tu-darmstadt.de/v1/models
// (companion list in ~/git/ansible roles/coding_agent/defaults/main.yaml must stay in sync).
// IMPORTANT: id must be the EXACT upstream model name. The TUD gateway is case-sensitive
// and pi sends the id verbatim as the API model name — probes: "glm-5.2-awq" -> 400,
// "GLM-5.2-AWQ-INT4" -> 200; "gpt-oss-120b" -> 400 (not served upstream).
const TUD_MODELS: ProviderModelConfig[] = [
  {
    id: "occiglot-7b-eu5-instruct",
    name: "Occiglot 7B EU5 Instruct (TUD)",
    reasoning: false,
    input: ["text"],
    cost: { input: 0, output: 0, cacheRead: 0, cacheWrite: 0 },
    contextWindow: 8_192,
    maxTokens: 4_096,
  },
  {
    id: "leo-hessianai-13b-chat",
    name: "LEO HessianAI 13B Chat (TUD)",
    reasoning: false,
    input: ["text"],
    cost: { input: 0, output: 0, cacheRead: 0, cacheWrite: 0 },
    contextWindow: 8_192,
    maxTokens: 4_096,
  },
  {
    id: "gemma-4-31B-it",
    name: "Gemma 4 31B IT (TUD)",
    reasoning: true,
    input: ["text", "image"],
    cost: { input: 0, output: 0, cacheRead: 0, cacheWrite: 0 },
    contextWindow: 262_144,
    maxTokens: 32_768,
  },
  {
    id: "GLM-5.2-AWQ-INT4",
    name: "GLM 5.2 AWQ INT4 (TUD)",
    reasoning: true,
    input: ["text"],
    cost: { input: 0, output: 0, cacheRead: 0, cacheWrite: 0 },
    contextWindow: 131_072,
    maxTokens: 32_768,
  },
  {
    id: "Kimi-K2.6",
    name: "Kimi K2.6 (TUD)",
    reasoning: true,
    input: ["text"],
    cost: { input: 0, output: 0, cacheRead: 0, cacheWrite: 0 },
    contextWindow: 131_072,
    maxTokens: 32_768,
  },
  {
    id: "Mistral-Medium-3.5-128B",
    name: "Mistral Medium 3.5 128B (TUD)",
    reasoning: true,
    input: ["text"],
    cost: { input: 0, output: 0, cacheRead: 0, cacheWrite: 0 },
    contextWindow: 131_072,
    maxTokens: 32_768,
  },
  {
    id: "Ministral-3-14B-Instruct-2512",
    name: "Ministral 3 14B (TUD)",
    reasoning: true,
    input: ["text"],
    cost: { input: 0, output: 0, cacheRead: 0, cacheWrite: 0 },
    contextWindow: 131_072,
    maxTokens: 32_768,
  },
  {
    id: "Qwen3.8-27B",
    name: "Qwen 3.8 27B (TUD)",
    reasoning: true,
    input: ["text"],
    cost: { input: 0, output: 0, cacheRead: 0, cacheWrite: 0 },
    contextWindow: 131_072,
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
