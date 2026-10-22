-- Format statement headings in the PDF manual and keep them with their
-- description:
--
--   * the first bold line becomes an unnumbered subsubsection heading;
--   * the remaining bold lines become monospaced syntax lines;
--   * \needspace requests prevent a heading from being left alone at the
--     bottom of a page.
--
-- manual.md stays plain Markdown for the Atari editor; this only affects the
-- generated PDF.

local function statement_lines(block)
    if block.t ~= "Para" or #block.content == 0 then
        return nil
    end
    local lines = {}
    for _, inline in ipairs(block.content) do
        if inline.t == "Strong" then
            lines[#lines + 1] = inline.content
        elseif inline.t ~= "LineBreak" then
            return nil
        end
    end
    if #lines == 0 then
        return nil
    end
    return lines
end

local function is_italic_heading(block)
    if block.t ~= "Para" or #block.content ~= 1
        or block.content[1].t ~= "Emph" then
        return false
    end
    -- Italic notes end with a sentence period; the few italic subheadings do
    -- not.
    return pandoc.utils.stringify(block):sub(-1) ~= "."
end

local function needspace(lines)
    return pandoc.RawBlock("latex",
        "\\needspace{" .. lines .. "\\baselineskip}")
end

local latex_escapes = {
    ["\\"] = "\\textbackslash{}",
    ["{"] = "\\{",
    ["}"] = "\\}",
    ["#"] = "\\#",
    ["%"] = "\\%",
    ["&"] = "\\&",
    ["_"] = "\\_",
    ["$"] = "\\$",
    ["^"] = "\\textasciicircum{}",
    ["~"] = "\\textasciitilde{}",
}

local function latex_escape(text)
    local out = {}
    for i = 1, #text do
        local c = text:sub(i, i)
        out[#out + 1] = latex_escapes[c] or c
    end
    return table.concat(out)
end

local function literal_text(text)
    -- Pandoc's smart extension turns quotes in the Markdown source into
    -- typographic quotes; command syntax should keep the literal quotes.
    text = text:gsub("“", '"'):gsub("”", '"')
    text = text:gsub("‘", "'"):gsub("’", "'")
    return latex_escape(text)
end

local function render_inlines(inlines)
    local out = {}
    for _, inline in ipairs(inlines) do
        if inline.t == "Str" then
            out[#out + 1] = literal_text(inline.text)
        elseif inline.t == "Space" then
            out[#out + 1] = " "
        elseif inline.t == "Emph" then
            out[#out + 1] = "\\emph{" .. render_inlines(inline.content) .. "}"
        elseif inline.t == "Strong" then
            out[#out + 1] = "\\textbf{" .. render_inlines(inline.content) .. "}"
        elseif inline.t == "Quoted" then
            local quote = inline.quotetype == "DoubleQuote" and '"' or "'"
            out[#out + 1] = quote .. render_inlines(inline.content) .. quote
        elseif inline.t == "Code" then
            out[#out + 1] = literal_text(inline.text)
        elseif inline.t == "SoftBreak" or inline.t == "LineBreak" then
            out[#out + 1] = " "
        else
            out[#out + 1] = literal_text(pandoc.utils.stringify(inline))
        end
    end
    return table.concat(out)
end

local function command_block(lines)
    if #lines < 2 then
        return nil
    end
    local parts = {
        "{\\ttfamily\\raggedright",
        "\\setlength{\\parindent}{0pt}%",
        "\\setlength{\\parskip}{0pt}%",
    }
    for i = 2, #lines do
        local text = render_inlines(lines[i])
        parts[#parts + 1] = "\\hangindent=2em\\hangafter=1 "
            .. text .. "\\par"
    end
    parts[#parts + 1] = "}"
    return pandoc.RawBlock("latex", table.concat(parts, "\n"))
end

function Pandoc(doc)
    local out = pandoc.Blocks{}
    for i, block in ipairs(doc.blocks) do
        local following = doc.blocks[i + 1]
        local previous = doc.blocks[i - 1]
        local lines = statement_lines(block)
        if lines then
            -- A statement right after a section heading is covered by the
            -- space requested before that heading.
            if not (previous and previous.t == "Header") then
                out:insert(needspace(#lines + 4))
            end
            local attr = pandoc.Attr("", {"unnumbered"})
            out:insert(pandoc.Header(3, lines[1], attr))
            local commands = command_block(lines)
            if commands then
                out:insert(commands)
            end
        elseif block.t == "Header" then
            local lines_wanted = 6
            local following_lines = following and statement_lines(following)
            if following_lines then
                lines_wanted = #following_lines + 6
            end
            out:insert(needspace(lines_wanted))
            out:insert(block)
        elseif is_italic_heading(block) and following and following.t == "Para" then
            out:insert(needspace(5))
            out:insert(block)
        else
            out:insert(block)
        end
    end
    return pandoc.Pandoc(out, doc.meta)
end
