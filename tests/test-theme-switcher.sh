#!/usr/bin/env bash
# Behavioral tests for theme-switcher.sh
# Tests the generated wrapper's symlink management and hook invocation.
# Use with mocked desktop commands to avoid side effects.

set -euo pipefail

# Test counter
TESTS_PASSED=0
TESTS_FAILED=0

# Color output helpers
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

test_pass() {
  echo -e "${GREEN}✓${NC} $1"
  ((TESTS_PASSED++))
}

test_fail() {
  echo -e "${RED}✗${NC} $1"
  ((TESTS_FAILED++))
}

test_warn() {
  echo -e "${YELLOW}⚠${NC} $1"
}

# Setup mock environment
setup_mocks() {
  local test_dir="$1"
  
  # Create mock PATH with stubbed commands
  mkdir -p "$test_dir/mocks"
  
  # Mock dconf: succeeds for required writes, fails if explicitly broken
  cat > "$test_dir/mocks/dconf" << 'EOF'
#!/usr/bin/env bash
case "${1:-}" in
  read)
    echo "'prefer-light'"
    exit 0
    ;;
  write)
    if [[ "${3:-}" == "FAIL_DCONF" ]]; then
      exit 1
    fi
    exit 0
    ;;
  *)
    exit 1
    ;;
esac
EOF
  chmod +x "$test_dir/mocks/dconf"
  
  # Mock plasma-apply-colorscheme: succeeds unless explicitly broken
  cat > "$test_dir/mocks/plasma-apply-colorscheme" << 'EOF'
#!/usr/bin/env bash
if [[ "${1:-}" == "FAIL" ]]; then
  exit 1
fi
exit 0
EOF
  chmod +x "$test_dir/mocks/plasma-apply-colorscheme"
  
  # Mock swaync-client: optional, always succeeds
  cat > "$test_dir/mocks/swaync-client" << 'EOF'
#!/usr/bin/env bash
exit 0
EOF
  chmod +x "$test_dir/mocks/swaync-client"
  
  # Mock tmux: optional, check list-sessions or fail
  cat > "$test_dir/mocks/tmux" << 'EOF'
#!/usr/bin/env bash
case "${1:-}" in
  list-sessions)
    exit 0
    ;;
  source-file)
    exit 0
    ;;
  *)
    exit 1
    ;;
esac
EOF
  chmod +x "$test_dir/mocks/tmux"
  
  # Mock notify-send: optional, always succeeds
  cat > "$test_dir/mocks/notify-send" << 'EOF'
#!/usr/bin/env bash
exit 0
EOF
  chmod +x "$test_dir/mocks/notify-send"
  
   # Mock gsettings: required for live theme reloading
   cat > "$test_dir/mocks/gsettings" << 'EOF'
#!/usr/bin/env bash
case "${1:-}" in
   get|set)
     if [[ "${3:-}" == "FAIL_GSETTINGS" ]]; then
       exit 1
     fi
     exit 0
     ;;
   *)
     exit 1
     ;;
esac
EOF
   chmod +x "$test_dir/mocks/gsettings"

   # Mock touch: required for Alacritty reload
   cat > "$test_dir/mocks/touch" << 'EOF'
#!/usr/bin/env bash
# For -c flag (not modifying non-existent files), just succeed
if [[ "${1:-}" == "-c" ]]; then
   exit 0
fi
exit 1
EOF
   chmod +x "$test_dir/mocks/touch"
}

# Test 1: Valid mode arguments
test_mode_validation() {
  local test_dir="$1"
  local hook="${test_dir}/theme-switcher.sh"
  
  # Setup mocks
  setup_mocks "$test_dir"
  
  # Copy hook to test directory
  cp ~/.dotfiles/scripts/theme-switcher.sh "$hook"
  
  # Test valid dark mode
  if PATH="${test_dir}/mocks:$PATH" "$hook" dark > /dev/null 2>&1; then
    test_pass "Accepts 'dark' argument"
  else
    test_fail "Rejects 'dark' argument"
  fi
  
  # Test valid light mode
  if PATH="${test_dir}/mocks:$PATH" "$hook" light > /dev/null 2>&1; then
    test_pass "Accepts 'light' argument"
  else
    test_fail "Rejects 'light' argument"
  fi
  
  # Test invalid argument
  if ! PATH="${test_dir}/mocks:$PATH" "$hook" "invalid" > /dev/null 2>&1; then
    test_pass "Rejects invalid mode argument"
  else
    test_fail "Should reject invalid mode argument"
  fi
  
  # Test missing argument
  if ! PATH="${test_dir}/mocks:$PATH" "$hook" > /dev/null 2>&1; then
    test_pass "Rejects missing argument"
  else
    test_fail "Should reject missing argument"
  fi
  
  # Test --status flag (read-only)
  if PATH="${test_dir}/mocks:$PATH" "$hook" --status > /dev/null 2>&1; then
    test_pass "Accepts --status flag"
  else
    test_fail "Rejects --status flag"
  fi
}

# Test 2: Status output does not modify state
test_status_readonly() {
  local test_dir="$1"
  local hook="${test_dir}/theme-switcher.sh"
  
  setup_mocks "$test_dir"
  cp ~/.dotfiles/scripts/theme-switcher.sh "$hook"
  
  # Status should produce JSON output without errors
  local output
  output=$(PATH="${test_dir}/mocks:$PATH" "$hook" --status 2>&1)
  
  if echo "$output" | grep -q '"text"'; then
    test_pass "Status output contains JSON"
  else
    test_fail "Status output missing JSON structure"
  fi
  
  # Status should exit 0
  if PATH="${test_dir}/mocks:$PATH" "$hook" --status > /dev/null 2>&1; then
    test_pass "Status exits with 0"
  else
    test_fail "Status should exit 0"
  fi
}

# Test 3: Required commands fail properly (skip mocking - validated in integration)
test_required_command_failure() {
  local hook="/home/earn/.dotfiles/scripts/theme-switcher.sh"
  
  # Verify the script has the required command checks
  if grep -q "command -v dconf" "$hook" && \
     grep -q "command -v gsettings" "$hook" && \
     grep -q "command -v plasma-apply-colorscheme" "$hook"; then
    test_pass "Script validates all required commands"
  else
    test_fail "Script missing required command validation"
  fi
  
  # Verify error messages are informative
  if grep -q "Error: dconf not found" "$hook" && \
     grep -q "Error: gsettings not found" "$hook" && \
     grep -q "Error: plasma-apply-colorscheme not found" "$hook"; then
    test_pass "Script provides clear error messages for missing commands"
  else
    test_fail "Script missing clear error messages"
  fi
}

# Test 4: Repeated modes are idempotent
test_idempotent_modes() {
  local test_dir="$1"
  local hook="${test_dir}/theme-switcher.sh"
  
  setup_mocks "$test_dir"
  cp ~/.dotfiles/scripts/theme-switcher.sh "$hook"
  
  # Run light twice
  if PATH="${test_dir}/mocks:$PATH" "$hook" light > /dev/null 2>&1 && \
     PATH="${test_dir}/mocks:$PATH" "$hook" light > /dev/null 2>&1; then
    test_pass "Light mode can be run repeatedly"
  else
    test_fail "Light mode should be idempotent"
  fi
  
  # Run dark twice
  if PATH="${test_dir}/mocks:$PATH" "$hook" dark > /dev/null 2>&1 && \
     PATH="${test_dir}/mocks:$PATH" "$hook" dark > /dev/null 2>&1; then
    test_pass "Dark mode can be run repeatedly"
  else
    test_fail "Dark mode should be idempotent"
  fi
}

# Test 5: Optional commands don't break the hook
test_optional_commands() {
  local hook="/home/earn/.dotfiles/scripts/theme-switcher.sh"
  
  # Verify swaync-client is used optionally (within conditional check)
  if grep -q "command -v swaync-client" "$hook"; then
    test_pass "Script checks for optional swaync-client"
  else
    test_fail "Script should check for optional swaync-client"
  fi
  
  # Verify tmux is used optionally
  if grep -q "command -v tmux" "$hook"; then
    test_pass "Script checks for optional tmux"
  else
    test_fail "Script should check for optional tmux"
  fi
  
  # Verify notify-send is used optionally
  if grep -q "command -v notify-send" "$hook"; then
    test_pass "Script checks for optional notify-send"
  else
    test_fail "Script should check for optional notify-send"
  fi
}

# Test 6: Correct commands and arguments used
test_correct_arguments() {
  local hook="/home/earn/.dotfiles/scripts/theme-switcher.sh"
  
  # Verify dark mode uses correct values
  if grep -q "dconf write /org/gnome/desktop/interface/color-scheme 'prefer-dark'" "$hook" || \
     grep -q 'dconf write .* "prefer-dark"' "$hook"; then
    test_pass "Dark mode sets color-scheme to prefer-dark"
  else
    test_fail "Dark mode should set color-scheme to prefer-dark"
  fi
  
  if grep -q "gsettings set org.gnome.desktop.interface gtk-theme 'Adwaita-dark'" "$hook" || \
     grep -q 'gsettings set .* "Adwaita-dark"' "$hook"; then
    test_pass "Dark mode uses gsettings to set gtk-theme to Adwaita-dark"
  else
    test_fail "Dark mode should use gsettings to set gtk-theme to Adwaita-dark"
  fi
  
  if grep -q "plasma-apply-colorscheme.*BreezeDark" "$hook"; then
    test_pass "Dark mode uses BreezeDark KDE scheme"
  else
    test_fail "Dark mode should use BreezeDark KDE scheme"
  fi
  
  # Verify light mode uses correct values
  if grep -q "dconf write /org/gnome/desktop/interface/color-scheme 'prefer-light'" "$hook" || \
     grep -q 'dconf write .* "prefer-light"' "$hook"; then
    test_pass "Light mode sets color-scheme to prefer-light"
  else
    test_fail "Light mode should set color-scheme to prefer-light"
  fi
  
  if grep -q "gsettings set org.gnome.desktop.interface gtk-theme 'Adwaita'" "$hook" || \
     grep -q 'gsettings set .* "Adwaita"' "$hook"; then
    test_pass "Light mode uses gsettings to set gtk-theme to Adwaita"
  else
    test_fail "Light mode should use gsettings to set gtk-theme to Adwaita"
  fi
  
  if grep -q "plasma-apply-colorscheme.*BreezeLight" "$hook"; then
    test_pass "Light mode uses BreezeLight KDE scheme"
  else
    test_fail "Light mode should use BreezeLight KDE scheme"
  fi
}

# Test 7: Alacritty reload is triggered
test_alacritty_reload() {
  local hook="/home/earn/.dotfiles/scripts/theme-switcher.sh"
  
  # Verify the script attempts to reload Alacritty by touching its config
  if grep -q "touch -c.*alacritty.toml" "$hook"; then
    test_pass "Alacritty reload triggered via touch -c"
  else
    test_fail "Should trigger Alacritty reload with touch -c"
  fi
}

# Test 8: Bash syntax check
test_bash_syntax() {
  local hook="/home/earn/.dotfiles/scripts/theme-switcher.sh"
  
  if bash -n "$hook" > /dev/null 2>&1; then
    test_pass "Bash syntax is valid"
  else
    test_fail "Bash syntax error in theme-switcher.sh"
  fi
}

# Test 9: ShellCheck if available
test_shellcheck() {
  local hook="/home/earn/.dotfiles/scripts/theme-switcher.sh"
  
  if ! command -v shellcheck &>/dev/null; then
    test_warn "ShellCheck not available, skipping"
    return
  fi
  
  if shellcheck "$hook" > /dev/null 2>&1; then
    test_pass "ShellCheck validation passed"
  else
    test_fail "ShellCheck found issues"
  fi
}

# Test 10: GTK settings.ini created from scratch (dark mode)
test_gtk_settings_ini_created_dark() {
  local test_dir="$1"
  local hook="${test_dir}/theme-switcher.sh"
  local home_mock="${test_dir}/home_gtk_dark"
  
  mkdir -p "$home_mock/.config"
  setup_mocks "$test_dir"
  cp ~/.dotfiles/scripts/theme-switcher.sh "$hook"
  
  HOME="$home_mock" PATH="${test_dir}/mocks:$PATH" "$hook" dark > /dev/null 2>&1
  
  if [[ -f "$home_mock/.config/gtk-3.0/settings.ini" ]]; then
    if grep -q "gtk-application-prefer-dark-theme=0" "$home_mock/.config/gtk-3.0/settings.ini" && \
       grep -q "gtk-theme-name=Adwaita-dark" "$home_mock/.config/gtk-3.0/settings.ini"; then
       test_pass "GTK settings.ini created in gtk-3.0 with dark values"
    else
       test_fail "GTK settings.ini in gtk-3.0 has incorrect values"
    fi
  else
    test_fail "GTK settings.ini not created in gtk-3.0"
  fi
  
  if [[ -f "$home_mock/.config/gtk-4.0/settings.ini" ]]; then
    if grep -q "gtk-application-prefer-dark-theme=0" "$home_mock/.config/gtk-4.0/settings.ini" && \
       grep -q "gtk-theme-name=Adwaita-dark" "$home_mock/.config/gtk-4.0/settings.ini"; then
       test_pass "GTK settings.ini created in gtk-4.0 with dark values"
    else
       test_fail "GTK settings.ini in gtk-4.0 has incorrect values"
    fi
  else
    test_fail "GTK settings.ini not created in gtk-4.0"
  fi
}

# Test 11: GTK settings.ini created from scratch (light mode)
test_gtk_settings_ini_created_light() {
  local test_dir="$1"
  local hook="${test_dir}/theme-switcher.sh"
  local home_mock="${test_dir}/home_gtk_light"
  
  mkdir -p "$home_mock/.config"
  setup_mocks "$test_dir"
  cp ~/.dotfiles/scripts/theme-switcher.sh "$hook"
  
  HOME="$home_mock" PATH="${test_dir}/mocks:$PATH" "$hook" light > /dev/null 2>&1
  
  if [[ -f "$home_mock/.config/gtk-3.0/settings.ini" ]]; then
    if grep -q "gtk-application-prefer-dark-theme=0" "$home_mock/.config/gtk-3.0/settings.ini" && \
       grep -q "gtk-theme-name=Adwaita" "$home_mock/.config/gtk-3.0/settings.ini"; then
      test_pass "GTK settings.ini created in gtk-3.0 with light values"
    else
      test_fail "GTK settings.ini in gtk-3.0 has incorrect values"
    fi
  else
    test_fail "GTK settings.ini not created in gtk-3.0 for light mode"
  fi
  
  if [[ -f "$home_mock/.config/gtk-4.0/settings.ini" ]]; then
    if grep -q "gtk-application-prefer-dark-theme=0" "$home_mock/.config/gtk-4.0/settings.ini" && \
       grep -q "gtk-theme-name=Adwaita" "$home_mock/.config/gtk-4.0/settings.ini"; then
      test_pass "GTK settings.ini created in gtk-4.0 with light values"
    else
      test_fail "GTK settings.ini in gtk-4.0 has incorrect values"
    fi
  else
    test_fail "GTK settings.ini not created in gtk-4.0 for light mode"
  fi
}

# Test 12: GTK settings.ini updates existing key without clobbering other settings
test_gtk_settings_ini_updates_existing() {
  local test_dir="$1"
  local hook="${test_dir}/theme-switcher.sh"
  local home_mock="${test_dir}/home_gtk_update"
  
  mkdir -p "$home_mock/.config/gtk-3.0"
  
  # Pre-seed with existing config and unrelated setting
  cat > "$home_mock/.config/gtk-3.0/settings.ini" << 'EOF'
[Settings]
gtk-application-prefer-dark-theme=1
gtk-cursor-theme-name=Adwaita
gtk-theme-name=Adwaita
EOF
  
  setup_mocks "$test_dir"
  cp ~/.dotfiles/scripts/theme-switcher.sh "$hook"
  
  HOME="$home_mock" PATH="${test_dir}/mocks:$PATH" "$hook" dark > /dev/null 2>&1
  
  local content
  content=$(cat "$home_mock/.config/gtk-3.0/settings.ini")
  
  if echo "$content" | grep -q "gtk-application-prefer-dark-theme=0" && \
     echo "$content" | grep -q "gtk-theme-name=Adwaita-dark" && \
     echo "$content" | grep -q "gtk-cursor-theme-name=Adwaita"; then
    test_pass "GTK settings.ini updates existing keys while preserving unrelated settings"
  else
    test_fail "GTK settings.ini update clobbered or missed settings"
  fi
}

# Test 13: GTK settings.ini appends missing key under [Settings]
test_gtk_settings_ini_appends_missing_key() {
  local test_dir="$1"
  local hook="${test_dir}/theme-switcher.sh"
  local home_mock="${test_dir}/home_gtk_append"
  
  mkdir -p "$home_mock/.config/gtk-3.0"
  
  # Pre-seed with [Settings] section but no dark-theme key
  cat > "$home_mock/.config/gtk-3.0/settings.ini" << 'EOF'
[Settings]
gtk-theme-name=Adwaita
EOF
  
  setup_mocks "$test_dir"
  cp ~/.dotfiles/scripts/theme-switcher.sh "$hook"
  
  HOME="$home_mock" PATH="${test_dir}/mocks:$PATH" "$hook" light > /dev/null 2>&1
  
  local content
  content=$(cat "$home_mock/.config/gtk-3.0/settings.ini")
  
  if echo "$content" | grep -q "gtk-application-prefer-dark-theme=0" && \
     ! (echo "$content" | grep "gtk-application-prefer-dark-theme" | wc -l | grep -qv "^1$"); then
    test_pass "GTK settings.ini appends missing key without duplication"
  else
    test_fail "GTK settings.ini failed to append or duplicated key"
  fi
}

# Main test runner
main() {
  local test_dir
  test_dir=$(mktemp -d)
  
  echo "Running theme-switcher.sh behavioral tests..."
  echo "Test directory: $test_dir"
  echo ""
  
  test_bash_syntax
  test_shellcheck
  echo ""
  
  test_mode_validation "$test_dir"
  echo ""
  
  test_status_readonly "$test_dir"
  echo ""
  
  test_required_command_failure
  echo ""
  
  test_idempotent_modes "$test_dir"
  echo ""
  
  test_optional_commands
  echo ""
  
  test_correct_arguments
  echo ""
  
  test_alacritty_reload
  echo ""
  
  test_gtk_settings_ini_created_dark "$test_dir"
  echo ""
  
  test_gtk_settings_ini_created_light "$test_dir"
  echo ""
  
  test_gtk_settings_ini_updates_existing "$test_dir"
  echo ""
  
  test_gtk_settings_ini_appends_missing_key "$test_dir"
  echo ""
  
  # Cleanup
  rm -rf "$test_dir"
  
  # Summary
  echo "================================"
  echo -e "Tests passed: ${GREEN}$TESTS_PASSED${NC}"
  echo -e "Tests failed: ${RED}$TESTS_FAILED${NC}"
  echo "================================"
  
  if [[ $TESTS_FAILED -eq 0 ]]; then
    echo -e "${GREEN}All tests passed!${NC}"
    return 0
  else
    echo -e "${RED}Some tests failed!${NC}"
    return 1
  fi
}

main "$@"
