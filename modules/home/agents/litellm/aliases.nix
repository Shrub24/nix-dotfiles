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

    neuralwatt = {
      providerFamily = "openai";
      apiBase = "https://api.neuralwatt.com/v1";
      apiKeyEnv = "NEURALWATT_API_KEY";
    };
  };

  routes = {
    "glm-5.2" = {
      mode = "chat";
      registryModel = "zhipuai/glm-5.2";
      chain = [
        "volcengine"
        "neuralwatt"
        "opencode-go"
      ];
    };
    "mimo-v2.5-pro" = {
      mode = "chat";
      registryModel = "xiaomi/mimo-v2.5-pro";
      chain = [
        "opencode-go"
      ];
    };

    "deepseek-v4-pro" = {
      mode = "chat";
      registryModel = "deepseek/deepseek-v4-pro";
      chain = [
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
        "opencode-go"
        "deepseek"
      ];
    };
  };

  aliases = {
    coder = "deepseek-v4-flash";
    main = "deepseek-v4-flash";
    summariser = "deepseek-v4-pro";
    image = "multimodal-default";
    embedding = "qwen3-embedding-8b";
    budget = "deepseek-v4-flash";
    explorer = "deepseek-v4-flash";
    "glm-5.2" = "glm-5.2";
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
  };
}
