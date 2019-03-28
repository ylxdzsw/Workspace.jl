module Workspace

using REPL
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
    print("Save workspace image? [y/n/c/s]: ")
    c = readline() |> strip
    if c in ("y", "Y")
        save_all()
        println("data saved as .juliadata")
        exit()
    elseif c in ("n", "N")
        exit()
    elseif c in ("s", "S")
        select_variables()
    else
        println("cancel")
    end
end

function save_all()
    @eval Workspace using JLD2
    @eval Main $(JLD2).@save ".juliadata"
end

function select_variables()

end

function __init__()
    println("inited")
end

end # module

# TODO:
# 0. ask reading image upon starting
# 1. handling Ctrl+C and second Ctrl+D
# 2. do not display the executed command & remove it from history
# 3. evaluating AST rather than a command?
# 4. catch exceptions and cancel exiting