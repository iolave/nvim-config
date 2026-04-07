local config = {
  -- Ensure 'jdtls' is in your system PATH or Mason bin
  cmd = { 'jdtls' },
  root_dir = vim.fs.dirname(vim.fs.find({ '.git', 'mvnw', 'gradlew' }, { upward = true })[1]),
  settings = {
    java = {
      format = {
        enabled = false,
      },
      configuration = {
        runtimes = {
          {
            name = 'temurin-jdk-11',
            path = '/opt/java/temurin-jdk-11/',
            default = true,
          },
        },
      },
    },
  },
}

return {
  'mfussenegger/nvim-jdtls',
  ft = 'java', -- Only load when opening a Java file
  config = function()
    local function setup_jdtls()
      require('jdtls').start_or_attach(config)
    end

    -- Trigger the setup on Java filetype events
    vim.api.nvim_create_autocmd('FileType', {
      pattern = 'java',
      callback = setup_jdtls,
    })

    -- Call once immediately if already in a java file
    if vim.bo.filetype == 'java' then
      setup_jdtls()
    end
  end,
}
