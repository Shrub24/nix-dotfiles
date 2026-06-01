{
  coder = {
    priority = 1;
    matches = [ "coder" "main" ];
    fallbacks = [ "opencode_go/mimo-v2.5-pro" ];
    targets = [
      {
        provider = "openrouter";
        model = "moonshotai/kimi-k2.6:free";
        weight = 1.0;
      }
    ];
    opencodeModels = {
      coder = {
        name = "Bifrost Coder";
        context = 262144;
        output = 131072;
        inputModalities = [ "text" ];
        outputModalities = [ "text" ];
      };
      main = {
        name = "Bifrost Main";
        context = 262144;
        output = 131072;
        inputModalities = [ "text" ];
        outputModalities = [ "text" ];
      };
    };
  };

  summariser = {
    priority = 10;
    matches = [ "summariser" ];
    fallbacks = [ "crof/deepseek-v4-pro-precision" ];
    targets = [
      {
        provider = "deepseek";
        model = "deepseek-v4-pro";
        weight = 1.0;
      }
    ];
    opencodeModels = {
      summariser = {
        name = "Bifrost Summariser";
        context = 1000000;
        output = 131072;
        inputModalities = [ "text" ];
        outputModalities = [ "text" ];
      };
    };
  };

  image = {
    priority = 20;
    matches = [ "image" ];
    fallbacks = [
      "openrouter/moonshotai/kimi-k2.6:free"
      "qwen/qwen3.5-flash-02-23"
    ];
    targets = [
      {
        provider = "openrouter";
        model = "xiaomi/mimo-v2.5";
        weight = 1.0;
      }
    ];
    opencodeModels = { };
  };

  embedding = {
    priority = 30;
    matches = [ "embedding" ];
    targets = [
      {
        provider = "openrouter";
        model = "qwen/qwen3-embedding-8b";
        weight = 1.0;
      }
    ];
    opencodeModels = { };
  };

  budget = {
    priority = 40;
    matches = [ "budget" "explorer" ];
    fallbacks = [ "deepseek/deepseek-v4-flash" ];
    targets = [
      {
        provider = "opencode_go";
        model = "deepseek-v4-flash";
        weight = 1.0;
      }
    ];
    opencodeModels = {
      budget = {
        name = "Bifrost Budget";
        context = 1000000;
        output = 384000;
        inputModalities = [ "text" ];
        outputModalities = [ "text" ];
      };
      explorer = {
        name = "Bifrost Explorer";
        context = 1000000;
        output = 384000;
        inputModalities = [ "text" ];
        outputModalities = [ "text" ];
      };
    };
  };
}
