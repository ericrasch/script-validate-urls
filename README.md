# URL Status Validator

A Bash script to validate one or more URL list files against their expected HTTP status codes.

## Requirements

- Bash shell
- `curl`

## File Naming Convention

Each URL list file must be a text file with a name containing a three-digit HTTP status code:

- `*410.txt` → URLs expected to return HTTP 410  
- `*301.txt` → URLs expected to return HTTP 301  
- `*200.txt` → URLs expected to return HTTP 200  

Each file should list one relative URL per line (e.g., `/old-page`).

## Usage

```bash
./validate_urls.sh <url-list-file> [<url-list-file> ...] [base_url] [auth_user] [auth_pass]
```

- `<url-list-file>`: one or more `.txt` files containing relative URLs.  
  The script extracts the expected status code from the first three-digit sequence in each filename.  
- `base_url` (optional): default: `https://example.com`  
- `auth_user` and `auth_pass` (optional): Basic Auth credentials for `curl`

Examples:

- Check only live URLs:
  ```bash
  ./validate_urls.sh url-200.txt
  ```
- Check removals and redirects:
  ```bash
  ./validate_urls.sh old-urls-410.txt redirects-301.txt
  ```
- Full run with custom domain and auth:
  ```bash
  ./validate_urls.sh url-410.txt url-301.txt url-200.txt https://staging.example.com user pass
  ```

## Output

- Generates `validation_results.csv` in the current directory.  
- Columns: `URL,Expected,HTTP_Status,Result`

## Behavior

- Skips missing or empty files with a warning (⚠️).  
- Console logs:
  - ✅ OK for matched responses  
  - ❌ MISMATCH for unexpected status codes  
  - ⚠️ Skip warnings for missing or empty files  

## Author & Version

- **Author:** Eric Rasch  
- **GitHub:** https://github.com/your-username/url-status-validator  
- **Created:** 2025-04-21  
- **Version:** 1.1
