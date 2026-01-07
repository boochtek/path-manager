# path - Manipulate $PATH easily
# Source this file in your .bashrc or .zshrc
# Compatible with Bash 3.2+ and Zsh
#
# https://github.com/boochtek/path-manager
# MIT License - Copyright (c) 2026 BoochTek, LLC

path() {
    local cmd="${1:-list}"
    shift 2>/dev/null

    case "$cmd" in
        list|ls|show)       _path_list "$@" ;;
        add|a)              _path_add "$@" ;;
        remove|rm|del)      _path_remove "$@" ;;
        move|mv)            _path_move "$@" ;;
        check|validate)     _path_check "$@" ;;
        dedup)              _path_dedup "$@" ;;
        clean)              _path_clean "$@" ;;
        contains|has)       _path_contains "$@" ;;
        help|--help|-h)     _path_help ;;
        *)                  _path_error "Unknown command: $cmd"; _path_help; return 1 ;;
    esac
}

# --- Output helpers ---

_path_info()    { printf '\033[34m%s\033[0m\n' "$*"; }
_path_warn()    { printf '\033[33mWARNING: %s\033[0m\n' "$*" >&2; }
_path_error()   { printf '\033[31mERROR: %s\033[0m\n' "$*" >&2; }

# --- Path manipulation helpers ---

_path_normalize() {
    local p="$1"
    if [[ "$p" != *'$'* ]]; then
        p="${p/#\~/$HOME}"
    fi
    [[ "$p" != "/" ]] && p="${p%/}"
    echo "$p"
}

_path_to_array() {
    local IFS=':'
    if [[ -n "$ZSH_VERSION" ]]; then
        echo "${(ps.:.)PATH}"
    else
        local -a arr=($PATH)
        printf '%s\n' "${arr[@]}"
    fi
}

_path_from_array() {
    local IFS=':'
    echo "$*"
}

_path_contains() {
    local target
    target="$(_path_normalize "$1")"
    [[ -z "$target" ]] && { _path_error "Usage: path contains <path>"; return 1; }

    while IFS= read -r p; do
        [[ "$p" == "$target" ]] && return 0
    done < <(_path_to_array)
    return 1
}

_path_count_occurrences() {
    local target="$1" count=0
    while IFS= read -r p; do
        [[ "$p" == "$target" ]] && ((count++))
    done < <(_path_to_array)
    echo "$count"
}

_path_warn_if_dup() {
    local target="$1"
    local count
    count="$(_path_count_occurrences "$target")"
    if [[ $count -gt 1 ]]; then
        _path_warn "'$target' appears $count times; using first. Run 'path dedup' to fix."
    fi
}

# --- Commands ---

_path_list() {
    local i=1
    while IFS= read -r p; do
        printf '%3d  %s\n' "$i" "$p"
        ((i++))
    done < <(_path_to_array)
}

_path_add() {
    local new_path="" position="end" relative_to=""

    while [[ $# -gt 0 ]]; do
        case "$1" in
            --beginning|-b) position="beginning"; shift ;;
            --end|-e)       position="end"; shift ;;
            --before)       position="before"; relative_to="$2"; shift 2 ;;
            --after)        position="after"; relative_to="$2"; shift 2 ;;
            -*)             _path_error "Unknown option: $1"; return 1 ;;
            *)              new_path="$1"; shift ;;
        esac
    done

    [[ -z "$new_path" ]] && { _path_error "Usage: path add <path> [--beginning|--end|--before <p>|--after <p>]"; return 1; }

    new_path="$(_path_normalize "$new_path")"

    if _path_contains "$new_path"; then
        _path_info "Already in PATH: $new_path"
        return 0
    fi

    case "$position" in
        beginning)
            export PATH="${new_path}:${PATH}"
            ;;
        end)
            export PATH="${PATH}:${new_path}"
            ;;
        before|after)
            [[ -z "$relative_to" ]] && { _path_error "Missing path for --$position"; return 1; }
            relative_to="$(_path_normalize "$relative_to")"

            if ! _path_contains "$relative_to"; then
                _path_error "Reference path not found: $relative_to"
                return 1
            fi

            _path_warn_if_dup "$relative_to"

            local -a parts=() new_parts=() inserted=0
            while IFS= read -r p; do parts+=("$p"); done < <(_path_to_array)

            local entry
            for entry in "${parts[@]}"; do
                if [[ "$entry" == "$relative_to" && $inserted -eq 0 ]]; then
                    [[ "$position" == "before" ]] && new_parts+=("$new_path")
                    new_parts+=("$entry")
                    [[ "$position" == "after" ]] && new_parts+=("$new_path")
                    inserted=1
                else
                    new_parts+=("$entry")
                fi
            done
            export PATH="$(_path_from_array "${new_parts[@]}")"
            ;;
    esac

    _path_info "Added: $new_path"
}

_path_remove() {
    local target
    target="$(_path_normalize "$1")"
    [[ -z "$target" ]] && { _path_error "Usage: path remove <path>"; return 1; }

    _path_contains "$target" || return 0

    local -a parts=() new_parts=()
    while IFS= read -r p; do parts+=("$p"); done < <(_path_to_array)

    local entry
    for entry in "${parts[@]}"; do
        [[ "$entry" != "$target" ]] && new_parts+=("$entry")
    done
    export PATH="$(_path_from_array "${new_parts[@]}")"

    _path_info "Removed: $target"
}

_path_move() {
    local target="" position="" relative_to=""

    while [[ $# -gt 0 ]]; do
        case "$1" in
            --beginning|-b) position="beginning"; shift ;;
            --end|-e)       position="end"; shift ;;
            --before)       position="before"; relative_to="$2"; shift 2 ;;
            --after)        position="after"; relative_to="$2"; shift 2 ;;
            -*)             _path_error "Unknown option: $1"; return 1 ;;
            *)              target="$1"; shift ;;
        esac
    done

    [[ -z "$target" ]] && { _path_error "Usage: path move <path> [--beginning|--end|--before <p>|--after <p>]"; return 1; }
    [[ -z "$position" ]] && { _path_error "Must specify position: --beginning, --end, --before <p>, or --after <p>"; return 1; }

    target="$(_path_normalize "$target")"

    if ! _path_contains "$target"; then
        _path_error "Path not found: $target"
        return 1
    fi

    if [[ "$position" == "before" || "$position" == "after" ]]; then
        [[ -z "$relative_to" ]] && { _path_error "Missing path for --$position"; return 1; }
        relative_to="$(_path_normalize "$relative_to")"

        if ! _path_contains "$relative_to"; then
            _path_error "Reference path not found: $relative_to"
            return 1
        fi

        if [[ "$target" == "$relative_to" ]]; then
            _path_error "Cannot move path relative to itself"
            return 1
        fi

        _path_warn_if_dup "$relative_to"
    fi

    _path_warn_if_dup "$target"

    # Remove target from current position (all occurrences)
    local -a parts=() without_target=()
    while IFS= read -r p; do parts+=("$p"); done < <(_path_to_array)

    local entry
    for entry in "${parts[@]}"; do
        [[ "$entry" != "$target" ]] && without_target+=("$entry")
    done

    # Insert at new position
    local -a new_parts=() inserted=0
    case "$position" in
        beginning)
            new_parts=("$target" "${without_target[@]}")
            ;;
        end)
            new_parts=("${without_target[@]}" "$target")
            ;;
        before|after)
            for entry in "${without_target[@]}"; do
                if [[ "$entry" == "$relative_to" && $inserted -eq 0 ]]; then
                    [[ "$position" == "before" ]] && new_parts+=("$target")
                    new_parts+=("$entry")
                    [[ "$position" == "after" ]] && new_parts+=("$target")
                    inserted=1
                else
                    new_parts+=("$entry")
                fi
            done
            ;;
    esac

    export PATH="$(_path_from_array "${new_parts[@]}")"
    _path_info "Moved: $target"
}

_path_check() {
    local missing=0 dup_count=0
    local -a seen=()

    while IFS= read -r p; do
        # Check for duplicates
        local is_dup=0 s
        for s in "${seen[@]}"; do
            if [[ "$s" == "$p" ]]; then
                is_dup=1
                break
            fi
        done
        seen+=("$p")

        # Check existence
        local exists=1
        [[ ! -d "$p" ]] && exists=0

        # Output
        if [[ $is_dup -eq 1 ]]; then
            printf '\033[33m⚠ %s (duplicate)\033[0m\n' "$p"
            ((dup_count++))
        elif [[ $exists -eq 0 ]]; then
            printf '\033[31m✗ %s (not found)\033[0m\n' "$p"
            ((missing++))
        else
            printf '\033[32m✓\033[0m %s\n' "$p"
        fi
    done < <(_path_to_array)

    # Summary
    if [[ $missing -gt 0 || $dup_count -gt 0 ]]; then
        echo ""
        [[ $missing -gt 0 ]] && _path_warn "$missing path(s) not found"
        [[ $dup_count -gt 0 ]] && _path_warn "$dup_count duplicate(s) found"
        _path_info "Run 'path clean' to fix"
    fi

    return $((missing + dup_count))
}

_path_dedup() {
    local -a seen=() new_parts=()
    while IFS= read -r p; do
        local is_dup=0 s
        for s in "${seen[@]}"; do
            [[ "$s" == "$p" ]] && { is_dup=1; break; }
        done
        if [[ $is_dup -eq 0 ]]; then
            seen+=("$p")
            new_parts+=("$p")
        else
            _path_info "Removed duplicate: $p"
        fi
    done < <(_path_to_array)
    export PATH="$(_path_from_array "${new_parts[@]}")"
}

_path_clean() {
    local -a seen=() new_parts=()
    while IFS= read -r p; do
        # Skip duplicates
        local is_dup=0 s
        for s in "${seen[@]}"; do
            [[ "$s" == "$p" ]] && { is_dup=1; break; }
        done

        if [[ $is_dup -eq 1 ]]; then
            _path_info "Removed duplicate: $p"
            continue
        fi

        seen+=("$p")

        # Skip non-existent
        if [[ ! -d "$p" ]]; then
            _path_info "Removed non-existent: $p"
            continue
        fi

        new_parts+=("$p")
    done < <(_path_to_array)
    export PATH="$(_path_from_array "${new_parts[@]}")"
}

_path_help() {
    cat <<'HELPEOF'
Usage: path <command> [args]

Commands:
  list, ls, show                List all paths (numbered)
  add, a <path>                 Add path to end
    --beginning, -b               Add to beginning instead
    --end, -e                     Add to end (default)
    --before <other>              Add before <other>
    --after <other>               Add after <other>
  remove, rm, del <path>        Remove path from PATH
  move, mv <path>               Move existing path to new position
    --beginning, -b               Move to beginning
    --end, -e                     Move to end
    --before <other>              Move before <other>
    --after <other>               Move after <other>
  check, validate               Show missing paths and duplicates
  dedup                         Remove duplicate entries
  clean                         Remove duplicates and non-existent paths
  contains, has <path>          Exit 0 if in PATH, 1 otherwise
  help, --help, -h              Show this help

Examples:
  path list                     Show all entries in PATH
  path add ~/bin                Add ~/bin to end of PATH
  path add ~/bin -b             Add ~/bin to beginning of PATH
  path add ~/bin --before /usr/bin
  path remove ~/bin             Remove ~/bin from PATH
  path move /usr/local/bin -b   Move /usr/local/bin to beginning
  path check                    Validate all paths exist
  path clean                    Remove duplicates and missing paths

https://github.com/boochtek/path-manager
HELPEOF
}
