{
  upstreams = {
    crof = {
      providerFamily = "openai";
      apiBase = "https://crof.ai/v1";
      apiKeyEnv = "CROFAI_API_KEY";
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
      chain = [
        {
          upstream = "neuralwatt";
          model = "glm-5.2";
        }
        {
          upstream = "opencode-go";
          model = "glm-5.2";
        }
      ];

    };
    "mimo-v2.5-pro" = {
      mode = "chat";
      chain = [
        {
          upstream = "crof";
          model = "mimo-v2.5-pro";
        }
        {
          upstream = "opencode-go";
          model = "mimo-v2.5-pro";
        }
      ];
    };

    "deepseek-v4-pro" = {
      mode = "chat";
      chain = [
        {
          upstream = "deepseek";
          model = "deepseek-v4-pro";
        }
        {
          upstream = "crof";
          model = "deepseek-v4-pro";
        }
      ];
    };

    "multimodal-default" = {
      mode = "chat";
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
          model = "qwen/qwen3.5-flash-02-23";
        }
      ];
    };

    "qwen3-embedding-8b" = {
      mode = "embedding";
      chain = [
        {
          upstream = "openrouter";
          model = "qwen/qwen3-embedding-8b";
        }
      ];
    };

    "deepseek-v4-flash" = {
      mode = "chat";
      chain = [
        {
          upstream = "opencode-go";
          model = "deepseek-v4-flash";
        }
        {
          upstream = "deepseek";
          model = "deepseek-v4-flash";
        }
      ];
    };
  };

  aliases = {
    coder = "mimo-v2.5-pro";
    main = "mimo-v2.5-pro";
    summariser = "deepseek-v4-pro";
    image = "multimodal-default";
    embedding = "qwen3-embedding-8b";
    budget = "deepseek-v4-flash";
    explorer = "deepseek-v4-flash";
  };

  clientModels = {
    coder = {
      name = "Coder";
      registryModel = [ "xiaomi/mimo-v2.5-pro" ];
      autogenerateVariants = true;
    };

    main = {
      name = "Main";
      registryModel = [ "xiaomi/mimo-v2.5-pro" ];
      autogenerateVariants = true;
    };

    summariser = {
      name = "Summariser";
      registryModel = [ "deepseek/deepseek-v4-pro" ];
      autogenerateVariants = true;
    };

    budget = {
      name = "Budget";
      registryModel = [ "deepseek/deepseek-v4-flash" ];
      autogenerateVariants = true;
    };

    explorer = {
      name = "Explorer";
      registryModel = [ "deepseek/deepseek-v4-flash" ];
      autogenerateVariants = true;
    };

    "glm-5.2" = {
      name = "GLM 5.2";
      registryModel = [ "zhipuai/glm-5.2" ];
      autogenerateVariants = true;
    };
  };
}
