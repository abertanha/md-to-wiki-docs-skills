# Swagger/OpenAPI Builder — Subagent

Generate an OpenAPI 3.0 specification and Swagger UI page from markdown API specs. Variables and conventions: [CONTEXT.md](../CONTEXT.md).

## Prerequisites

```bash
node --version 2>/dev/null || echo "node missing — validation will be skipped; see CONTEXT.md §Dependencies"
```

If any variable from CONTEXT.md is unset, ask the orchestrator before running.

## Steps

### 1. Scan sources

Scan every file under `$SOURCES` for endpoint definitions:

- Headings like `### GET /api/users` → method and path (cover **all** HTTP methods and **all** heading levels)
- `**Request:**` followed by a JSON block → request body schema
- `**Response:**` followed by a JSON block → response schema
- `**Parameters:**` followed by a table → query/path parameters
- `**Headers:**` followed by a list → request headers

Keep a list of every endpoint found. Done when every file has been scanned and every endpoint is on the list.

### 2. Generate `swagger-ui/openapi.yml`

```yaml
openapi: "3.0.3"
info:
  title: "{{PROJECT_NAME}} — API Specs"
  version: "1.0.0"
  description: "Auto-generated from spec-driven development markdowns"
servers:
  - url: "<base_url>"
    description: "<environment>"
paths:
  /<path>:
    get:
      summary: "<extracted>"
      description: "<extracted>"
      parameters: [...]
      responses:
        "200":
          description: "Success"
          content:
            application/json:
              schema:
                type: object
```

Fill `servers` from user input if the base URL is known; otherwise use `https://api.example.com` and flag it in the output. Done when **every endpoint from the step-1 list appears in `paths:`**.

If a file contains no structured API definitions, flag it to the orchestrator with a suggested skeleton spec.

### 3. Validate

```bash
npx @redocly/cli lint swagger-ui/openapi.yml
```

If `node` is unavailable, at minimum confirm the YAML parses and `paths` is non-empty. Done when validation reports no errors (warnings tolerable — list them).

### 4. Generate the Swagger UI page

From the template at `$SKILL_DIR/templates/swagger-ui.html`, write `swagger-ui/index.html`:

- Replace `{{PROJECT_NAME}}` with `$PROJECT_NAME`
- Replace `{{OPENAPI_YML}}` with `openapi.yml` (same directory)

Done when `swagger-ui/` contains both `index.html` and `openapi.yml`.

## Output

Return to the orchestrator:
- Path to `swagger-ui/` (deployable directory)
- List of endpoints discovered
- Files skipped (with reason)
- Validation result (clean / warnings / skipped — why)
- Placeholder values still in effect (e.g. default server URL)
