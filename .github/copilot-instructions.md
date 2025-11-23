# httpbin-re Copilot Instructions

## Architecture Snapshot
- `httpbin/core.py` holds the Flask app (imported via `httpbin/__init__.py`) plus every route; the root path serves the Flasgger UI mounted at `/` and traditional landing page still lives at `/legacy`.
- Helper modules (`httpbin/helpers.py`, `structures.py`, `filters.py`) centralize header parsing, digest auth math, case-insensitive dicts, and streaming helpers—re-use them instead of re-implementing request introspection.
- JSON responses should go through the local `jsonify` shim (adds trailing newline) or `helpers.get_dict`; multiple tests (`test_httpbin.py`) assert `response.data.endswith(b"\n")` and expect headers via `CaseInsensitiveDict`.
- Templates/static assets under `httpbin/templates` & `httpbin/static` include the Swagger shell; keep new assets referenced via `render_template` or Flask `send_file` to avoid breaking packaging (`MANIFEST.in`).

## Behavioral Conventions
- Every inspection endpoint returns a dict assembled by `get_dict()` so params, headers, files, and body stay consistent; pass the exact keys you need instead of hand-building JSON.
- `helpers.get_headers()` strips proxy/env headers unless `show_env=true`; respect that toggle when introducing new header views.
- Status routes rely on `helpers.status_code()` and `Response.autocorrect_location_header = False`; keep redirects using that helper so tests keep passing.
- Chunked request handling is guarded in `before_request()`—non-gunicorn servers must return 501. Mirror this behavior when adding new middleware logic.
- Auth flows (basic/digest/bearer) already have utilities; extend them there so the elaborate digest tests stay green.

## Configuration & Env Flags
- `SWAGGER_TITLE`/`SWAGGER_DESCRIPTION` env vars override the doc shell; `HTTPBIN_TRACKING` toggles template globals; `BUGSNAG_*` enables optional error reporting.
- Docker build args `TITLE` and `DESCRIPTION` map to those env vars, so keep ARG names in sync with `Dockerfile` if you surface new metadata.
- TLS termination in `nginx/conf.d/httpbin.conf` expects upstream `re:80` and mirrors healthz at `/healthz`; keep proxy headers (`X-Forwarded-*`) intact or helper logic will misreport origins.

## Local Development Workflow
- Preferred quick start: `python3 -m venv .venv && source .venv/bin/activate && pip install -r requirements.txt && pip install -e .` to match the Docker image layout.
- Run the full unittest suite with `python test_httpbin.py`; tox config exists but targets py27/py36/py37 and is mostly historical.
- When touching request/response helpers, add/adjust coverage in `test_httpbin.py`; tests use the Flask test client and frequently assert exact header casing and newline behavior.
- The dev server entry point is `gunicorn -b 0.0.0.0:80 httpbin:app -k gevent` (see `Dockerfile`); match that command when scripting deployments to surface the same gevent worker semantics.

## Containers & Deployment
- Images build from Ubuntu 24.04, install deps via `requirements.txt`, then `pip install .`; keep dependency changes pinned before editing `requirements.txt` or `setup.py`.
- `docker-compose.yml` runs the app (`httpbin-re`) plus an nginx `front` service that publishes `8080/8443` with certs mounted from `nginx/certs`; health checks hit `/healthz` through nginx, so ensure that route stays fast.
- Kubernetes manifest `k8s/httpbin-re.yaml` deploys the published image `ghcr.io/pichuang/httpbin-re:master` behind a ClusterIP Service on port 8080; update both sections together when bumping image tags.

## When Modifying or Adding Endpoints
- Add routes in `httpbin/core.py`, keep Swagger decorators/docstrings consistent with the existing style, and register output schemas so `/spec.json` stays accurate.
- Use `helpers.json_safe` when echoing request bodies or files; binary data must be base64 data URLs, matching `/post` behavior.
- Preserve newline-terminated JSON, header casing, and `origin` logic by delegating to helpers; tests will fail if you serialize manually.
- Any new configuration knobs should default via env vars and be plumbed through Docker/K8s manifests where relevant.
