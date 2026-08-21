{
  upstreams = {
    crof = {
      providerFamily = "openai";
      apiBase = "https://crof.ai/v1";
      apiKeyEnv = "CROFAI_API_KEY";
    };

    volcengine = {
      providerFamily = "openai";
      apiBase = "https://ark.cn-beijing.volces.com/api/coding/v3";
      apiKeyEnv = "VOLCENGINE_API_KEY";
    };

    deepseek = {
      providerFamily = "deepseek";
      apiKeyEnv = "DEEPSEEK_API_KEY";
    };

    openrouter = {
      providerFamily = "openai";
      apiBase = "https://openrouter.ai/api/v1";
      apiKeyEnv = "OPENROUTER_API_KEY";
    };

    opencode-go = {
      providerFamily = "openai";
      apiBase = "https://opencode.ai/zen/go/v1";
      apiKeyEnv = "OPENCODE_API_KEY";
    };

    # ponytail: US egress relay (la-admin-1, tailnet-only) for Aus-geo-blocked models;
    # maps /opencode-go/* → opencode.ai/zen/go/v1/*, preserves Authorization.
    opencode-go-relay = {
      providerFamily = "openai";
      apiBase = "http://la-admin-1.tail0fe19b.ts.net:8787/opencode-go";
      apiKeyEnv = "OPENCODE_API_KEY";
    };

    neuralwatt = {
      providerFamily = "openai";
      apiBase = "https://api.neuralwatt.com/v1";
      apiKeyEnv = "NEURALWATT_API_KEY";
    };
  };

  routes = {
    "qwen3.8-flash" = {
      mode = "chat";
      registryModel = "alibaba/qwem3.8-flash";
      chain = [
        "volcengine"
        "opencode-go"
      ];
    };
    "glm-5.3-flash" = {
      mode = "chat";
      registryModel = "zhipuai/glm-5.3-flash";
      chain = [
        "volcengine"
        "opencode-go"
      ];
    };
    "glm-5.3" = {
      mode = "chat";
      registryModel = "zhipuai/glm-5.3";
      chain = [
        "volcengine"
        "opencode-go"
      ];
    };
    "glm-5.2" = {
      mode = "chat";
      registryModel = "zhipuai/glm-5.2";
      chain = [
        "volcengine"
        "opencode-go"
        "neuralwatt"
      ];
    };
    "mimo-v2.5-pro" = {
      mode = "chat";
      registryModel = "xiaomi/mimo-v2.5-pro";
      chain = [
        "opencode-go"
      ];
    };

    "muse-spark-1.2" = {
      mode = "chat";
      registryModel = "meta/muse-spark-1.2";
      chain = [
        {
          model = "muse-spark-1.2-contributor";
          upstream = "opencode-go";
        }
      ];
    };

    "deepseek-v4-pro" = {
      mode = "chat";
      registryModel = "deepseek/deepseek-v4-pro";
      chain = [
        "volcengine"
        "neuralwatt"
        "opencode-go"
        "deepseek"
      ];
    };

    "multimodal-default" = {
      mode = "chat";
      registryModel = "minimax/MiniMax-M3";
      chain = [
        {
          upstream = "opencode-go";
          model = "minimax-m3";
        }
        {
          upstream = "openrouter";
          model = "xiaomi/mimo-v2.5";
        }
        {
          upstream = "openrouter";
          model = "qwen/qwen3.7-flash";
        }
      ];
    };

    "qwen3-embedding-8b" = {
      mode = "embedding";
      registryModel = "qwen/qwen3-embedding-8b";
      chain = [
        {
          upstream = "openrouter";
          model = "qwen/qwen3-embedding-8b";
        }
      ];
    };

    "deepseek-v4-flash" = {
      mode = "chat";
      registryModel = "deepseek/deepseek-v4-flash";
      chain = [
        "volcengine"
        "opencode-go"
        "neuralwatt"
        "deepseek"
      ];
    };
  };

  aliases = {
    coder = "qwen3.8-flash";
    main = "glm-5.3-flash";
    summariser = "qwen3.8-flash";
    image = "multimodal-default";
    embedding = "qwen3-embedding-8b";
    budget = "qwen3.8-flash";
    explorer = "deepseek-v4-flash";
    "glm-5.2" = "glm-5.2";
    "glm-5.3" = "glm-5.3";
    "glm-5.3-flash" = "glm-5.3-flash";
    "qwen3.8-flash" = "qwen3.8-flash";
    "muse-spark-1.2" = "muse-spark-1.2";
  };

  clientModels = {
    coder = {
      name = "Coder";
      autogenerateVariants = true;
    };

    main = {
      name = "Main";
      autogenerateVariants = true;
    };

    summariser = {
      name = "Summariser";
      autogenerateVariants = true;
    };

    budget = {
      name = "Budget";
      autogenerateVariants = true;
    };

    explorer = {
      name = "Explorer";
      autogenerateVariants = true;
    };

    "glm-5.2" = {
      name = "GLM 5.2";
      autogenerateVariants = true;
    };
    "glm-5.3" = {
      name = "GLM 5.3";
      autogenerateVariants = true;
    };
    "muse-spark-1.2" = {
      name = "Muse Spark 1.2";
      autogenerateVariants = true;
    };
  };
}
