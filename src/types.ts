// src/types.ts

export interface HessianModel {
  id: string;
  name: string;
  category: string;
  limit: {
    context: number;
    output: number;
  };
  metadata: {
    estimated_latency: string;
    description?: string;
  };
  can_reason?: boolean;
  attachment?: boolean;
  alias?: boolean;
}

export interface HessianPluginConfig {
  $schema: string;
  permission: Record<string, "allow" | "ask" | "deny">;
  provider: {
    hessian: {
      npm: string;
      name: string;
      options: {
        baseURL: string;
        apiKey: string;
      };
      models: Record<string, HessianModel>;
    };
  };
  model?: string;
  last_updated?: string;
}

export interface ApiModel {
  id: string;
  [key: string]: unknown;
}

export interface ApiResponse {
  data: ApiModel[];
}
