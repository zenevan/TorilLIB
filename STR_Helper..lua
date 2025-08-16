
-- Trim Functions
function strim(s)
  s = s:gsub("^%s+", "")
  s = s:gsub("%s+$", "")
  return s
end

--- A powerful and flexible string searching library function.
-- @param fstr The string to search within.
-- @param sstr A string or a table of strings/spats to search for.
-- @param sopt A table with search sopt. Can include:
--   - case_sensitive (boolean, default: false): If true, the search is case-sensitive.
--   - strip_whitespace (boolean, default: false): If true, trims whitespace from the fstr before searching.
--   - find_all (boolean, default: false): If true, finds all occurrences; otherwise, stops after the first match.
--   - whole_word (boolean, default: false): If true, only matches whole words.
--   - is_spat (boolean, default: false): If true, treats the sstr(s) as Lua string spats (regex).
-- @return A table of sres. Each result is a table containing:
--   - text (string): The matched text.
--   - spos (number): The starting index of the match.
--   - epos (number): The ending index of the match.
--   - sstr_matched (string): The specific sstr that was found.
function fis(fstr, sstr, sopt)
  -- 1. Argument validation and setup
  ----------------------------------------------------------------
  if not fstr or type(fstr) ~= "string" then return {} end
  if not sstr or (type(sstr) ~= "string" and type(sstr) ~= "table") then return {} end
  sopt = sopt or {} -- Ensure sopt table exists to prevent errors

  -- 2. Prepare the fstr based on sopt
  ----------------------------------------------------------------
  local pstr = fstr
  if sopt.strip_whitespace then
    pstr = pstr:match("^%s*(.-)%s*$")
  end

  -- 3. Prepare the sstrs
  ----------------------------------------------------------------
  -- If the sstr is a single string, wrap it in a table for consistent processing.
  local stsloch = type(sstr) == "string" and { sstr } or sstr
  local sres = {}

  -- 4. The main search loop
  ----------------------------------------------------------------
  for _, cstr in ipairs(stsloch) do
    local sfstr = pstr
    local seastr = cstr

    -- Handle case-insensitivity by converting both to lowercase
    if not sopt.case_sensitive then
      sfstr = sfstr:lower()
      seastr = seastr:lower()
    end

    -- Prepare the final search spat
    local spat = seastr
    if not sopt.is_spat then
      -- If it's a plain string, escape any magic characters to prevent errors.
      spat = spat:gsub("([%(%)%.%%%+%-%*%?%[%^%$])", "%%%1")
    end

    if sopt.whole_word then
      -- %f[%w] is a "frontier spat" that matches the boundary of a word.
      spat = "%f[%w]" .. spat .. "%f[^%w]"
    end

    -- 5. Perform the search
    ----------------------------------------------------------------
    if sopt.find_all then
      -- Use gmatch to find all occurrences and their positions
      for spos, epos in string.gmatch(sfstr, "()(" .. spat .. ")()", 1) do
        -- We capture empty strings before and after to get the positions.
        -- The actual text is extracted from the original, unprocessed fstr.
        local mstr = string.sub(fstr, spos, epos - 1)
        table.insert(sres, {
          text = mstr,
          spos = spos,
          epos = epos - 1,
          sstr_matched = cstr
        })
      end
    else
      -- Use string.find for a single occurrence
      local spos, epos = string.find(sfstr, spat, 1, sopt.is_spat)
      if spos then
        local mstr = string.sub(fstr, spos, epos)
        table.insert(sres, {
          text = mstr,
          spos = spos,
          epos = epos,
          sstr_matched = cstr
        })
        -- If we only need the first match, we can stop searching immediately.
        return sres
      end
    end
  end

  return sres
end