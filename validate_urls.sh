#!/bin/bash
################################################################################
# Script Name: validate_urls.sh
#
# Validates one or more URL list files against their expected HTTP status codes.
#
# Usage:
#   ./validate_urls.sh <url-list-file> [<url-list-file> ...] \
#                     [base_url] [auth_user] [auth_pass]
#
#   - Each <url-list-file> must include the expected code in its filename,
#     e.g. "my-endpoints-410.txt" → HTTP 410, "redirects-301.txt" → HTTP 301,
#     "live-200.txt" → HTTP 200.
#   - You may supply 1–3 list files in any order. Any missing or empty file
#     is skipped with a warning.
#   - Optionally follow list files with:
#       base_url (default: https://example.com)
#       auth_user auth_pass (for Basic Auth)
#
# Requirements:
#   - Bash shell
#   - curl
#
# Behavior:
#   - Creates/overwrites validation_results.csv with header:
#       URL,Expected,HTTP_Status,Result
#   - For each valid list file:
#       • Detects expected_status by extracting the first “XXX” in filename
#       • Skips if file is missing or zero-length (⚠️ warning)
#       • Uses curl to fetch each URL and compares to expected_status
#       • Logs “✅ OK” or “❌ MISMATCH” to console and CSV
#
# Author: Eric Rasch
#   GitHub: https://github.com/ericrasch/script-validate-urls
# Created: 2025-04-21
# Updated: 2025-04-21
# Version: 1.1
################################################################################

# ---- Parse list files (must end in .txt, extract status code from name) ----
files=()
codes=()
while [[ $# -gt 0 ]] && [[ "$1" == *.txt ]]; do
  file="$1"
  if [[ "$file" =~ ([0-9]{3}) ]]; then
    code="${BASH_REMATCH[1]}"
    files+=("$file")
    codes+=("$code")
  else
    echo "⚠️  Skipping '$file': cannot detect HTTP status in filename"
  fi
  shift
done

# ---- Set base_url and optional auth ----
base_url="${1:-https://example.com}"; shift || true
auth_user="${1:-}"; shift || true
auth_pass="${1:-}"; shift || true

# ---- Ensure at least one list file supplied ----
if [[ ${#files[@]} -eq 0 ]]; then
  echo "Usage: $0 <url-list-file> [<url-list-file> ...] [base_url] [auth_user] [auth_pass]"
  exit 1
fi

# ---- Initialize CSV ----
output_csv="validation_results.csv"
echo "URL,Expected,HTTP_Status,Result" > "$output_csv"

# ---- Function: check a single list ----
check_urls() {
  local file=$1 expected=$2
  while IFS= read -r url; do
    [[ -z "$url" ]] && continue
    full_url="${base_url}${url}"
    if [[ -n "$auth_user" && -n "$auth_pass" ]]; then
      status=$(curl -u "$auth_user:$auth_pass" -s -o /dev/null -w "%{http_code}" "$full_url")
    else
      status=$(curl -s -o /dev/null -w "%{http_code}" "$full_url")
    fi

    if [[ "$status" == "$expected" ]]; then
      echo "$full_url,$expected,$status,✅ OK" >> "$output_csv"
      echo "✅ $full_url → $status"
    else
      echo "$full_url,$expected,$status,❌ MISMATCH" >> "$output_csv"
      echo "❌ $full_url → $status (expected $expected)"
    fi
  done < "$file"
}

# ---- Iterate through provided list files ----
for i in "${!files[@]}"; do
  file="${files[i]}"
  code="${codes[i]}"

  if [[ ! -s "$file" ]]; then
    echo "⚠️  Skipping '$file' for HTTP $code (missing or empty)"
  else
    echo "ℹ️  Checking '$file' for HTTP $code"
    check_urls "$file" "$code"
  fi
done

echo "📝 Results saved to $output_csv"
