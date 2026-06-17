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
          upstream = "opencode-go";
          model = "minimax-m3";
        }
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
          upstream = "crof";
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
      context = 262144;
      output = 131072;
      inputModalities = [ "text" ];
      outputModalities = [ "text" ];
    };

    main = {
      name = "Main";
      context = 262144;
      output = 131072;
      inputModalities = [ "text" ];
      outputModalities = [ "text" ];
    };

    summariser = {
      name = "Summariser";
      context = 1000000;
      output = 131072;
      inputModalities = [ "text" ];
      outputModalities = [ "text" ];
    };

    budget = {
      name = "Budget";
      context = 1000000;
      output = 384000;
      inputModalities = [ "text" ];
      outputModalities = [ "text" ];
    };

    explorer = {
      name = "Explorer";
      context = 1000000;
      output = 384000;
      inputModalities = [ "text" ];
      outputModalities = [ "text" ];
    };
  };
}
