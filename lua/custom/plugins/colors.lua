-- Палитра Matugen (end-4 dots) -> Neovim. Читается один раз при запуске.
-- Источник: ~/.local/state/quickshell/user/generated/material_colors.scss
-- Структура групп (интерфейс, режимы статуслайна, плагины) повторяет tokyonight.nvim.

local M = {}

local PALETTE = vim.fn.expand '~/.local/state/quickshell/user/generated/material_colors.scss'

local function warn(msg)
  vim.notify('[colors] ' .. msg, vim.log.levels.WARN)
end

local function is_hex(v)
  return type(v) == 'string' and v:match '^#%x%x%x%x%x%x$' ~= nil
end

-- Разбор строк вида `$name: value;`
local function parse(path)
  local f, err = io.open(path, 'r')
  if not f then
    return nil, 'не удалось открыть ' .. path .. ' (' .. tostring(err) .. ')'
  end
  local vars = {}
  for line in f:lines() do
    local name, value = line:match '^%s*%$([%w_]+)%s*:%s*([^;]-)%s*;'
    if name then
      vars[name] = value
    end
  end
  f:close()
  return vars
end

local function blend(fg, bg, a)
  local out = '#'
  for _, i in ipairs { 2, 4, 6 } do
    local x = tonumber(fg:sub(i, i + 1), 16)
    local y = tonumber(bg:sub(i, i + 1), 16)
    out = out .. string.format('%02X', math.floor(x * a + y * (1 - a) + 0.5))
  end
  return out
end

local function lum(hex)
  local function lin(i)
    local v = tonumber(hex:sub(i, i + 1), 16) / 255
    return v <= 0.03928 and v / 12.92 or ((v + 0.055) / 1.055) ^ 2.4
  end
  return 0.2126 * lin(2) + 0.7152 * lin(4) + 0.0722 * lin(6)
end

local function contrast(a, b)
  local la, lb = lum(a), lum(b)
  if la < lb then
    la, lb = lb, la
  end
  return (la + 0.05) / (lb + 0.05)
end

function M.setup()
  local vars, err = parse(PALETTE)
  if not vars then
    return warn(err .. '. Используется стандартная цветовая схема.')
  end

  local missing, bad = {}, {}
  -- Первый корректный цвет из списка имён
  local function c(...)
    for _, name in ipairs { ... } do
      local v = vars[name]
      if is_hex(v) then
        return v
      elseif v ~= nil then
        bad[name] = v
      end
    end
    missing[#missing + 1] = (...)
    return nil
  end

  local bg = c 'background'
  local fg = c 'onBackground'
  if not (bg and fg) then
    return warn 'в палитре нет $background/$onBackground. Используется стандартная цветовая схема.'
  end

  -- Material-цвета
  local fg_dim = c('onSurfaceVariant', 'outline') or fg
  local outline = c('outline', 'outlineVariant') or fg_dim
  local surf = c('surfaceContainer', 'surfaceContainerLow', 'surface') or bg
  local surf_hi = c('surfaceContainerHigh', 'surfaceContainerHighest') or surf
  local primary = c 'primary' or fg
  local secondary = c('secondary', 'primary') or fg
  local tertiary = c('tertiary', 'secondary') or fg
  local error = c 'error' or '#FF5555'
  local sel = c('secondaryContainer', 'primaryContainer') or surf_hi
  local on_sel = c('onSecondaryContainer', 'onPrimaryContainer') or fg

  -- Терминальные цвета
  local term = {}
  for i = 0, 15 do
    term[i] = c('term' .. i)
    if term[i] then
      vim.g['terminal_color_' .. i] = term[i]
    end
  end

  -- Акценты (ANSI, с запасом на Material)
  local red = term[1] or error
  local green = term[2] or tertiary
  local yellow = term[3] or tertiary
  local blue = term[4] or primary
  local magenta = term[5] or secondary
  local cyan = term[6] or secondary

  -- Цвет текста поверх акцентной плашки: bg или fg, что контрастнее
  local function readable(color)
    return contrast(color, bg) >= contrast(color, fg) and bg or fg
  end

  -- Тема
  local dark = tostring(vars.darkmode or ''):lower() ~= 'false'
  vim.opt.background = dark and 'dark' or 'light'
  vim.opt.fillchars:append { eob = ' ' }

  vim.cmd 'highlight clear'
  if vim.fn.exists 'syntax_on' == 1 then
    vim.cmd 'syntax reset'
  end
  vim.g.colors_name = 'matugen'

  local function set(group, spec)
    vim.api.nvim_set_hl(0, group, spec)
  end
  local function link(group, target)
    vim.api.nvim_set_hl(0, group, { link = target })
  end

  ---------------------------------------------------------------------------
  -- Интерфейс (фон Normal не задаём: виден фон терминала)
  ---------------------------------------------------------------------------
  set('Normal', { fg = fg })
  set('NormalNC', { fg = fg })
  set('NormalFloat', { fg = fg, bg = surf })
  set('FloatBorder', { fg = outline, bg = surf })
  set('FloatTitle', { fg = primary, bg = surf, bold = true })
  set('MsgArea', { fg = fg })
  set('CursorLine', { bg = surf })
  set('CursorColumn', { bg = surf })
  set('ColorColumn', { bg = surf })
  set('LineNr', { fg = fg_dim })
  set('CursorLineNr', { fg = primary, bold = true })
  set('SignColumn', { fg = fg_dim })
  set('FoldColumn', { fg = fg_dim })
  set('Folded', { fg = fg_dim, bg = surf })
  set('WinSeparator', { fg = outline })
  link('VertSplit', 'WinSeparator')
  set('StatusLine', { fg = fg, bg = surf })
  set('StatusLineNC', { fg = fg_dim, bg = surf })
  link('WinBar', 'StatusLine')
  link('WinBarNC', 'StatusLineNC')
  set('TabLine', { fg = fg_dim, bg = surf })
  set('TabLineSel', { fg = readable(primary), bg = primary })
  set('TabLineFill', { bg = surf })
  set('Title', { fg = primary, bold = true })
  set('Directory', { fg = primary })
  set('NonText', { fg = outline })
  set('EndOfBuffer', { fg = bg })
  set('Whitespace', { fg = outline })
  set('SpecialKey', { fg = outline })
  set('Conceal', { fg = fg_dim })
  set('MatchParen', { fg = primary, bg = sel, bold = true })
  set('QuickFixLine', { bg = sel, bold = true })
  set('SnippetTabstop', { bg = sel })
  set('ModeMsg', { fg = fg, bold = true })
  set('ErrorMsg', { fg = error })
  set('WarningMsg', { fg = yellow })
  set('MoreMsg', { fg = green })
  set('Question', { fg = primary })
  set('WildMenu', { fg = on_sel, bg = sel })

  -- Курсор (по умолчанию инверсия: без этого на прозрачном фоне «белое на белом»)
  set('Cursor', { fg = bg, bg = fg })
  link('lCursor', 'Cursor')
  link('CursorIM', 'Cursor')
  link('TermCursor', 'Cursor')
  set('TermCursorNC', { fg = bg, bg = fg_dim })

  -- Поиск и выделение
  set('Visual', { bg = sel })
  set('VisualNOS', { bg = sel })
  set('Search', { fg = on_sel, bg = sel })
  set('IncSearch', { fg = readable(primary), bg = primary })
  set('CurSearch', { fg = readable(primary), bg = primary, bold = true })
  set('Substitute', { fg = readable(red), bg = red })

  -- Меню (Blink CMP, wildmenu, :menu)
  set('Pmenu', { fg = fg, bg = surf })
  set('PmenuSel', { fg = on_sel, bg = sel, bold = true })
  set('PmenuSbar', { bg = surf_hi })
  set('PmenuThumb', { bg = outline })
  set('PmenuKind', { fg = cyan, bg = surf })
  set('PmenuKindSel', { fg = cyan, bg = sel })
  set('PmenuExtra', { fg = fg_dim, bg = surf })
  set('PmenuExtraSel', { fg = fg_dim, bg = sel })
  set('PmenuMatch', { fg = primary, bg = surf, bold = true })
  set('PmenuMatchSel', { fg = primary, bg = sel, bold = true })

  ---------------------------------------------------------------------------
  -- Синтаксис
  ---------------------------------------------------------------------------
  set('Comment', { fg = fg_dim, italic = true })
  set('Constant', { fg = yellow })
  set('String', { fg = green })
  set('Character', { fg = green })
  set('Number', { fg = yellow })
  set('Boolean', { fg = yellow })
  set('Float', { fg = yellow })
  set('Identifier', { fg = fg })
  set('Function', { fg = primary })
  set('Statement', { fg = magenta })
  set('Conditional', { fg = magenta })
  set('Repeat', { fg = magenta })
  set('Label', { fg = magenta })
  set('Keyword', { fg = magenta })
  set('Exception', { fg = magenta })
  set('Operator', { fg = secondary })
  set('PreProc', { fg = tertiary })
  set('Include', { fg = tertiary })
  set('Define', { fg = tertiary })
  set('Macro', { fg = tertiary })
  set('Type', { fg = cyan })
  set('StorageClass', { fg = cyan })
  set('Structure', { fg = cyan })
  set('Typedef', { fg = cyan })
  set('Special', { fg = tertiary })
  set('SpecialChar', { fg = tertiary })
  set('Delimiter', { fg = fg_dim })
  set('Underlined', { fg = primary, underline = true })
  set('Todo', { fg = readable(tertiary), bg = tertiary, bold = true })
  set('Error', { fg = error })

  -- Treesitter (остальные @-группы наследуются от стандартных групп выше)
  set('@variable', { fg = fg })
  set('@variable.builtin', { fg = tertiary })
  set('@variable.parameter', { fg = fg })
  set('@variable.member', { fg = fg })
  set('@property', { fg = fg })
  set('@attribute', { fg = tertiary })
  set('@constant.builtin', { fg = yellow })
  set('@function.builtin', { fg = primary })
  set('@constructor', { fg = cyan })
  set('@type.builtin', { fg = cyan })
  set('@module', { fg = fg })
  set('@module.builtin', { fg = tertiary })
  set('@operator', { fg = secondary })
  set('@keyword.operator', { fg = secondary })
  set('@punctuation', { fg = fg_dim })
  set('@punctuation.bracket', { fg = fg_dim })
  set('@punctuation.delimiter', { fg = fg_dim })
  set('@punctuation.special', { fg = secondary })
  set('@string.escape', { fg = tertiary })
  set('@string.regexp', { fg = tertiary })
  set('@string.special.url', { fg = primary, underline = true })
  set('@tag', { fg = magenta })
  set('@tag.attribute', { fg = cyan })
  set('@tag.delimiter', { fg = fg_dim })
  set('@markup.heading', { fg = primary, bold = true })
  set('@markup.link', { fg = primary, underline = true })
  set('@markup.strong', { bold = true })
  set('@markup.italic', { italic = true })
  set('@markup.raw', { fg = green })
  set('@diff.plus', { fg = green })
  set('@diff.minus', { fg = red })
  set('@diff.delta', { fg = yellow })
  set('@comment.error', { fg = readable(red), bg = red, bold = true })
  set('@comment.warning', { fg = readable(yellow), bg = yellow, bold = true })
  set('@comment.todo', { fg = readable(blue), bg = blue, bold = true })
  set('@comment.note', { fg = readable(cyan), bg = cyan, bold = true })

  ---------------------------------------------------------------------------
  -- Диагностика и LSP
  ---------------------------------------------------------------------------
  set('DiagnosticError', { fg = red })
  set('DiagnosticWarn', { fg = yellow })
  set('DiagnosticInfo', { fg = blue })
  set('DiagnosticHint', { fg = cyan })
  set('DiagnosticOk', { fg = green })
  set('DiagnosticUnnecessary', { fg = fg_dim })
  set('DiagnosticDeprecated', { fg = fg_dim, strikethrough = true })
  set('DiagnosticUnderlineError', { undercurl = true, sp = red })
  set('DiagnosticUnderlineWarn', { undercurl = true, sp = yellow })
  set('DiagnosticUnderlineInfo', { undercurl = true, sp = blue })
  set('DiagnosticUnderlineHint', { undercurl = true, sp = cyan })
  set('DiagnosticVirtualTextError', { fg = red, bg = blend(red, bg, 0.12) })
  set('DiagnosticVirtualTextWarn', { fg = yellow, bg = blend(yellow, bg, 0.12) })
  set('DiagnosticVirtualTextInfo', { fg = blue, bg = blend(blue, bg, 0.12) })
  set('DiagnosticVirtualTextHint', { fg = cyan, bg = blend(cyan, bg, 0.12) })
  set('SpellBad', { undercurl = true, sp = red })
  set('SpellCap', { undercurl = true, sp = yellow })
  set('SpellLocal', { undercurl = true, sp = blue })
  set('SpellRare', { undercurl = true, sp = cyan })
  set('LspReferenceText', { bg = surf_hi })
  set('LspReferenceRead', { bg = surf_hi })
  set('LspReferenceWrite', { bg = surf_hi })
  set('LspInlayHint', { fg = fg_dim, bg = blend(fg_dim, bg, 0.12) })
  set('LspCodeLens', { fg = fg_dim })
  set('LspSignatureActiveParameter', { bg = sel, bold = true })
  link('LspInfoBorder', 'FloatBorder')

  ---------------------------------------------------------------------------
  -- Git / diff
  ---------------------------------------------------------------------------
  set('DiffAdd', { bg = blend(green, bg, 0.18) })
  set('DiffChange', { bg = blend(yellow, bg, 0.14) })
  set('DiffDelete', { fg = red, bg = blend(red, bg, 0.18) })
  set('DiffText', { bg = blend(yellow, bg, 0.32) })
  set('Added', { fg = green })
  set('Changed', { fg = yellow })
  set('Removed', { fg = red })

  -- Gitsigns
  set('GitSignsAdd', { fg = green })
  set('GitSignsChange', { fg = yellow })
  set('GitSignsDelete', { fg = red })
  set('GitSignsTopdelete', { fg = red })
  set('GitSignsChangedelete', { fg = yellow })
  set('GitSignsUntracked', { fg = blue })
  set('GitSignsCurrentLineBlame', { fg = fg_dim, italic = true })

  ---------------------------------------------------------------------------
  -- mini.statusline (режимы как в tokyonight: цветная плашка + тёмный текст)
  ---------------------------------------------------------------------------
  local function mode(name, color)
    set('MiniStatuslineMode' .. name, { fg = readable(color), bg = color, bold = true })
  end
  mode('Normal', primary)
  mode('Insert', green)
  mode('Visual', magenta)
  mode('Replace', red)
  mode('Command', yellow)
  mode('Other', cyan)
  set('MiniStatuslineDevinfo', { fg = fg, bg = surf_hi })
  set('MiniStatuslineFileinfo', { fg = fg, bg = surf_hi })
  set('MiniStatuslineFilename', { fg = fg_dim, bg = surf })
  set('MiniStatuslineInactive', { fg = fg_dim, bg = surf })
  link('MiniSurround', 'IncSearch')

  ---------------------------------------------------------------------------
  -- Telescope
  ---------------------------------------------------------------------------
  link('TelescopeNormal', 'NormalFloat')
  link('TelescopeBorder', 'FloatBorder')
  set('TelescopeTitle', { fg = primary, bg = surf, bold = true })
  set('TelescopePromptNormal', { fg = fg, bg = surf_hi })
  set('TelescopePromptBorder', { fg = outline, bg = surf_hi })
  set('TelescopePromptTitle', { fg = readable(primary), bg = primary, bold = true })
  set('TelescopePromptPrefix', { fg = primary, bg = surf_hi })
  set('TelescopePromptCounter', { fg = fg_dim, bg = surf_hi })
  set('TelescopeResultsTitle', { fg = primary, bg = surf, bold = true })
  set('TelescopePreviewTitle', { fg = green, bg = surf, bold = true })
  set('TelescopeSelection', { fg = on_sel, bg = sel, bold = true })
  set('TelescopeSelectionCaret', { fg = primary, bg = sel })
  set('TelescopeMultiSelection', { fg = magenta })
  set('TelescopeMatching', { fg = primary, bold = true })

  ---------------------------------------------------------------------------
  -- Which-key
  ---------------------------------------------------------------------------
  set('WhichKey', { fg = primary })
  set('WhichKeyDesc', { fg = fg })
  set('WhichKeyGroup', { fg = secondary })
  set('WhichKeySeparator', { fg = fg_dim })
  set('WhichKeyValue', { fg = fg_dim })
  set('WhichKeyTitle', { fg = primary, bg = surf, bold = true })
  link('WhichKeyNormal', 'NormalFloat')
  link('WhichKeyBorder', 'FloatBorder')
  set('WhichKeyIcon', { fg = primary })
  set('WhichKeyIconAzure', { fg = blue })
  set('WhichKeyIconBlue', { fg = blue })
  set('WhichKeyIconCyan', { fg = cyan })
  set('WhichKeyIconGreen', { fg = green })
  set('WhichKeyIconGrey', { fg = fg_dim })
  set('WhichKeyIconOrange', { fg = yellow })
  set('WhichKeyIconPurple', { fg = magenta })
  set('WhichKeyIconRed', { fg = red })
  set('WhichKeyIconYellow', { fg = yellow })

  ---------------------------------------------------------------------------
  -- Blink CMP
  ---------------------------------------------------------------------------
  link('BlinkCmpMenu', 'Pmenu')
  link('BlinkCmpMenuBorder', 'FloatBorder')
  link('BlinkCmpMenuSelection', 'PmenuSel')
  set('BlinkCmpScrollBarThumb', { bg = outline })
  set('BlinkCmpScrollBarGutter', { bg = surf_hi })
  set('BlinkCmpLabel', { fg = fg })
  set('BlinkCmpLabelDeprecated', { fg = fg_dim, strikethrough = true })
  set('BlinkCmpLabelMatch', { fg = primary, bold = true })
  set('BlinkCmpLabelDetail', { fg = fg_dim })
  set('BlinkCmpLabelDescription', { fg = fg_dim })
  set('BlinkCmpSource', { fg = fg_dim })
  set('BlinkCmpGhostText', { fg = outline, italic = true })
  link('BlinkCmpDoc', 'NormalFloat')
  link('BlinkCmpDocBorder', 'FloatBorder')
  set('BlinkCmpDocSeparator', { fg = outline, bg = surf })
  link('BlinkCmpDocCursorLine', 'Visual')
  link('BlinkCmpSignatureHelp', 'NormalFloat')
  link('BlinkCmpSignatureHelpBorder', 'FloatBorder')
  link('BlinkCmpSignatureHelpActiveParameter', 'LspSignatureActiveParameter')
  set('BlinkCmpKind', { fg = cyan })
  local kinds = {
    Function = 'Function', Method = 'Function', Constructor = 'Function',
    Variable = '@variable', Field = '@property', Property = '@property',
    Class = 'Type', Interface = 'Type', Struct = 'Type', Enum = 'Type', Module = 'Type', TypeParameter = 'Type',
    Keyword = 'Keyword', Operator = 'Operator',
    Constant = 'Constant', EnumMember = 'Constant', Value = 'Constant',
    Snippet = 'Special', Text = 'String', Unit = 'Number', Color = 'Special',
    File = 'Directory', Folder = 'Directory', Reference = 'Special', Event = 'Special',
  }
  for kind, target in pairs(kinds) do
    link('BlinkCmpKind' .. kind, target)
  end

  ---------------------------------------------------------------------------
  -- Mason, Fidget
  ---------------------------------------------------------------------------
  link('MasonNormal', 'NormalFloat')
  set('MasonHeader', { fg = readable(primary), bg = primary, bold = true })
  set('MasonHeaderSecondary', { fg = readable(secondary), bg = secondary, bold = true })
  set('MasonHighlight', { fg = primary })
  set('MasonHighlightBlock', { fg = readable(primary), bg = primary })
  set('MasonHighlightBlockBold', { fg = readable(primary), bg = primary, bold = true })
  set('MasonHighlightSecondary', { fg = secondary })
  set('MasonHighlightBlockSecondary', { fg = readable(secondary), bg = secondary })
  set('MasonHighlightBlockBoldSecondary', { fg = readable(secondary), bg = secondary, bold = true })
  set('MasonMuted', { fg = fg_dim })
  set('MasonMutedBlock', { fg = fg_dim, bg = surf_hi })
  set('MasonMutedBlockBold', { fg = fg_dim, bg = surf_hi, bold = true })
  set('MasonError', { fg = red })
  set('MasonWarning', { fg = yellow })
  set('FidgetTitle', { fg = primary })
  set('FidgetTask', { fg = fg_dim })

  -- Как `:colorscheme`: плагины (gitsigns, which-key, todo-comments и др.)
  -- пере-регистрируют свои группы после `highlight clear`
  pcall(vim.api.nvim_exec_autocmds, 'ColorScheme', { pattern = 'matugen', modeline = false })

  -- Предупреждение о неполной/некорректной палитре (одно сообщение)
  local problems = {}
  if #missing > 0 then
    problems[#problems + 1] = 'отсутствуют: ' .. table.concat(missing, ', ')
  end
  local bad_list = {}
  for k, v in pairs(bad) do
    bad_list[#bad_list + 1] = k .. '=' .. v
  end
  if #bad_list > 0 then
    table.sort(bad_list)
    problems[#problems + 1] = 'некорректный формат: ' .. table.concat(bad_list, ', ')
  end
  if #problems > 0 then
    warn('палитра неполная (' .. table.concat(problems, '; ') .. '), использованы запасные цвета.')
  end
end

local ok, e = pcall(M.setup)
if not ok then
  warn('ошибка применения палитры: ' .. tostring(e))
end

return M
