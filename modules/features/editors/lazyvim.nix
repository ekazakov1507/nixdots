{ ... }:
{
  flake.nixosModules.lazyvim = { pkgs, ... }:
    let
      # Keep this in sync with modules/features/user.nix until user settings are centralized.
      username = "user";
    in
    {
      home-manager.users.${username} = {
        home.packages = with pkgs; [
          fd
          fzf
          gcc
          lazygit
          lua-language-server
          nil
          nixfmt
          nodejs
          ripgrep
          shfmt
          statix
          stylua
          tree-sitter
        ];

        home.sessionVariables = {
          EDITOR = "nvim";
          VISUAL = "nvim";
        };

        programs.neovim = {
          enable = true;
          defaultEditor = true;
          viAlias = true;
          vimAlias = true;
          withNodeJs = true;
        };

        xdg.configFile."nvim/init.lua".text = ''
          require("config.lazy")
        '';

        xdg.configFile."nvim/lua/config/lazy.lua".text = ''
          local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"

          if not (vim.uv or vim.loop).fs_stat(lazypath) then
            local lazyrepo = "https://github.com/folke/lazy.nvim.git"
            local out = vim.fn.system({
              "git",
              "clone",
              "--filter=blob:none",
              "--branch=stable",
              lazyrepo,
              lazypath,
            })

            if vim.v.shell_error ~= 0 then
              vim.api.nvim_echo({
                { "Failed to clone lazy.nvim:\n", "ErrorMsg" },
                { out, "WarningMsg" },
                { "\nPress any key to exit..." },
              }, true, {})
              vim.fn.getchar()
              os.exit(1)
            end
          end

          vim.opt.rtp:prepend(lazypath)

          require("lazy").setup({
            spec = {
              { "LazyVim/LazyVim", import = "lazyvim.plugins" },
              { import = "plugins" },
            },
            defaults = {
              lazy = false,
              version = false,
            },
            install = {
              colorscheme = { "tokyonight", "habamax" },
            },
            checker = {
              enabled = true,
              notify = false,
            },
            performance = {
              rtp = {
                disabled_plugins = {
                  "gzip",
                  "tarPlugin",
                  "tohtml",
                  "tutor",
                  "zipPlugin",
                },
              },
            },
          })
        '';

        xdg.configFile."nvim/lua/plugins/lang-nix.lua".text = ''
          return {
            { import = "lazyvim.plugins.extras.lang.nix" },
            {
              "neovim/nvim-lspconfig",
              opts = {
                servers = {
                  nil_ls = {
                    mason = false,
                  },
                  lua_ls = {
                    mason = false,
                  },
                },
              },
            },
          }
        '';
      };
    };
}
