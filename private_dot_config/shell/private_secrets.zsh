# ============================================
# Secret Environment
# ============================================

_keychain_secret() {
  local service="$1"
  local account="${USER:-$(id -un)}"

  [[ "$(uname -s)" == "Darwin" ]] || return 1
  command -v security >/dev/null 2>&1 || return 1

  security find-generic-password -a "$account" -s "$service" -w 2>/dev/null
}

_op_secret() {
  local ref="$1"

  [[ -n "$ref" ]] || return 1
  command -v op >/dev/null 2>&1 || return 1

  op read "$ref" 2>/dev/null
}

_secret_value() {
  local service="$1"
  local op_ref="${2:-}"
  local value

  value="$(_keychain_secret "$service")" && [[ -n "$value" ]] && {
    print -r -- "$value"
    return 0
  }

  value="$(_op_secret "$op_ref")" && [[ -n "$value" ]] && {
    print -r -- "$value"
    return 0
  }

  return 1
}

_export_keychain_env() {
  local name="$1"
  local service="${2:-shell-env:$name}"
  local value

  [[ -z "${(P)name:-}" ]] || return 0

  value="$(_keychain_secret "$service")" || return 0
  [[ -n "$value" ]] || return 0

  export "$name=$value"
}

_export_keychain_env CONTEXT7_API_KEY
_export_keychain_env GEMINI_API_KEY
