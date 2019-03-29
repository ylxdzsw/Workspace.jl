module Workspace

using REPL
using InteractiveUtils
const LE = REPL.LineEdit

function hook_REPL_aborting()
    repl = Base.active_repl.interface.modes[1]
    mod = Dict(REPL.LineEdit.normalize_key("^D") => function (s,o...)
        LE.buffer(s).size > 0 && return LE.edit_delete(s)
        LE.replace_line(s, "Workspace.prompt_saving()")
        LE.commit_line(s)
        return :done
    end)
    repl.keymap_dict = REPL.LineEdit.keymap_merge(repl.keymap_dict, mod)
end

function prompt_saving()
    print(stderr, "Save workspace image? [y/n/c/s]: ")
    c = readline() |> strip
    if c in ("y", "Y")
        save_all()
        println(stderr, "data saved as .juliadata")
        exit()
    elseif c in ("n", "N")
        exit()
    elseif c in ("s", "S")
        select_variables()
    else
        println(stderr, "cancel")
    end
end

function save_all()
    @eval Workspace using JLD2
    @eval Main $(JLD2).@save ".juliadata"
end

function select_variables()
    println(stderr, "Select variables to save. Choose None to cancel.")
    vars = varinfo()
    not_modules = findall(x -> x[3] != "Module", vars.content[1].rows[2:end])
    lines = map(x->String(strip(x[2:end-1])), split(string(vars), '\n')[3:end-1])[not_modules]
    names = map(x->Symbol(x[1]), vars.content[1].rows[2:end])[not_modules]
    menu = REPL.TerminalMenus.MultiSelectMenu(lines)
    choice = REPL.TerminalMenus.request(menu)
    isempty(choice) && return println(stderr, "cancel")
    choice = names[collect(choice)]
    @eval Main $(JLD2).@save(".juliadata", $(choice...))
    println(stderr, "data saved as .juliadata")
    exit()
end

function __init__()
    hook_REPL_aborting()
end

end # module

# TODO:
# 0. ask reading image upon starting
# 1. handling Ctrl+C and second Ctrl+D
# 2. do not display the executed command & remove it from history
# 3. evaluating AST rather than a command?
# 4. catch exceptions and cancel exiting