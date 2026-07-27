/**
 * pi-hessian-plugin: Hessian (TUD/TU Darmstadt) provider registration.
 *
 * Registers the TUD provider with GPT-OSS, Gemma 4, GLM, Mistral, Qwen, and Ministral models.
 * API key is read from auth.json (key: "tud") or models.json provider apiKey.
 *
 * Install: pi install /path/to/pi-hessian-plugin
 * Reload:  /reload
 */

import type { ExtensionAPI } from "@earendil-works/pi-coding-agent";

const TUD_MODELS = [
  {
    id: "gpt-oss-120b",
    name: "GPT-OSS 120B (TUD)",
    reasoning: true,
    input: ["text"] as const,
    contextWindow: 131_072,
    maxTokens: 32_768,
  },
  {
    id: "gemma-4-31B-it",
    name: "Gemma 4 31B IT (TUD)",
    reasoning: true,
    input: ["text", "image"] as const,
    contextWindow: 262_144,
    maxTokens: 32_768,
  },
  {
    id: "GLM-5.2-AWQ-INT4",
    name: "GLM 5.2 AWQ INT4 (TUD)",
    reasoning: true,
    input: ["text"] as const,
    contextWindow: 131_072,
    maxTokens: 32_768,
  },
  {
    id: "Mistral-Medium-3.5-128B",
    name: "Mistral Medium 3.5 128B (TUD)",
    reasoning: true,
    input: ["text"] as const,
    contextWindow: 131_072,
    maxTokens: 32_768,
  },
  {
    id: "Qwen3.6-35B-A3B",
    name: "Qwen 3.6 35B A3B (TUD)",
    reasoning: true,
    input: ["text"] as const,
    contextWindow: 131_072,
    maxTokens: 32_768,
  },
  {
    id: "Ministral-3-14B-Instruct-2512",
    name: "Ministral 3 14B (TUD)",
    reasoning: true,
    input: ["text"] as const,
    contextWindow: 131_072,
    maxTokens: 32_768,
  },
  {
    id: "qwen3-vl-30b-a3b-instruct-awq",
    name: "Qwen 3 VL 30B (TUD)",
    reasoning: true,
    input: ["text", "image"] as const,
    contextWindow: 131_072,
    maxTokens: 32_768,
  },
];

export default function (pi: ExtensionAPI) {
  pi.registerProvider("tud", {
    name: "Hessian TUD LLM Service",
    baseUrl: "https://llm-service.ai.tu-darmstadt.de/v1",
    apiKey: "$TUD_API_KEY",
    api: "openai-completions",
    models: TUD_MODELS,
  });
}
