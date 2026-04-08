local function format()
  local cmd = '/opt/npm/node_modules/prettier/bin/prettier.cjs'
  local plugin = '/opt/npm/node_modules/prettier-plugin-java/dist/index.js'

  -- check if /opt/npm/node_modules/prettier-plugin-java/dist/index.js exists
  if vim.fn.filereadable(plugin) == 0 then
    vim.notify('prettier-plugin-java not installed, install it with `npm install prettier-plugin-java` in the `/opt/npm` directory', vim.log.levels.ERROR)
    return
  end

  local args = {
    '--tab-width=4',
    '--plugin=' .. plugin,
    '--write',
  }

  local bufnr = vim.api.nvim_get_current_buf()
  local fname = vim.api.nvim_buf_get_name(bufnr)
  if fname == '' then
    vim.notify('No filename for buffer; save file first.', vim.log.levels.WARN)
    return
  end

  -- build job args: if using gjf wrapper that edits file in-place, pass filename
  local job_args = vim.deepcopy(args)
  table.insert(job_args, fname)

  -- run the external formatter as an async job
  vim.fn.jobstart(vim.fn.join(vim.list_extend({ cmd }, job_args), ' '), {
    stdout_buffered = true,
    stderr_buffered = true,
    on_exit = function(_, exit_code, _)
      if exit_code ~= 0 then
        vim.schedule(function()
          vim.notify('failed to format (exit ' .. tostring(exit_code) .. ')', vim.log.levels.ERROR)
        end)
        return
      end

      -- reload buffer to reflect changes made in-place
      vim.schedule(function()
        local view = vim.fn.winsaveview()
        vim.api.nvim_buf_call(bufnr, function()
          vim.cmd 'edit'
        end)
        vim.fn.winrestview(view)
        vim.notify('Formatted java', vim.log.levels.INFO)
      end)
    end,
  })
end

vim.api.nvim_create_autocmd('BufWritePre', {
  pattern = '*.java',
  callback = format,
})

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
          -- {
          --   name = 'temurin-jdk-11',
          --   path = '/opt/java/temurin-jdk-11/',
          --   default = true,
          -- },
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
