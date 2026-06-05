---
name: building-apps
description: Use when creating a new local app, prototype, browser tool, game, demo, or greenfield project, especially when no existing repo stack is already fixed.
---

# Building Apps

## Overview

Build the smallest useful local app while preserving a clean path to review, staging, production, and ownership. If no existing stack is fixed, default to a Python backend and vanilla HTML/CSS/JavaScript frontend served by the backend on `localhost`.

## When to Use

Use this skill for:
- Net-new local apps, browser tools, demos, games, and prototypes.
- Greenfield apps where the owning repo has no established stack.
- AI-assisted builds that may later need security review, SAML, staging, or production handoff.

Do not use this skill when:
- An existing repo already defines the stack. Follow the repo.
- The user asks only for SAML setup. Use `mykaarma-saml`.
- The task is a production deployment. Use the relevant deployment skill.

## Core Rules

1. Define before building: problem, user stories, success criteria, data boundaries, and owner.
2. Develop locally from a git repo on `localhost`; avoid cloud IDE/runtime shortcuts unless explicitly approved.
3. Use sandbox, fixture, or synthetic data during development. Never use real customer or production data locally.
4. Serve the frontend from the backend. Do not ask the user to open `index.html` directly.
5. Keep secrets out of source. Use environment variables or ignored `.env`; commit only `.env.example`.
6. Use vanilla JS unless the repo or user requires a frontend framework.
7. Own AI-generated code. Review auth, authorization, data access, logging, deletion, and external calls carefully.
8. Log every API response made by the app for debugging, with redaction and truncation for any response body.
9. Document run, test, and handoff notes as you build.
10. Start the local server and verify the app in a browser before claiming done.

## Default Architecture

Use one of these shapes unless the repo already has a better convention.

Flask plus static SPA, as in simple audit/dashboard tools:

```text
project/
  app.py
  requirements.txt
  static/
    index.html
    app.js
    style.css
  tests/
  .env.example
```

FastAPI plus server-rendered templates, as in small operator/admin tools:

```text
project/
  app/
    main.py
    templates/
      index.html
    services/
    __init__.py
  requirements.txt
  tests/
  .env.example
```

Choose Flask when the app is a small local tool with simple routes and static assets. Choose FastAPI when typed request handling, async endpoints, form parsing, service modules, or server-rendered operator pages materially help.

## Web App Requirements

- Serve `/` from the backend.
- Put API routes under `/api/...` unless the app already has a domain-specific route contract.
- Use relative frontend API calls such as `fetch("/api/items")`.
- Keep secrets and privileged external API calls server-side.
- Keep route handlers thin; move business logic, external calls, and persistence into services/modules as the app grows.
- Keep frontend API calls in one small JS service/module instead of scattering `fetch` across UI event handlers.
- For every frontend fetch, backend API route, and backend outbound API client call, log the response method/route or upstream URL, status, elapsed time, and request/correlation ID.
- When response bodies are useful for debugging, log only a sanitized and truncated summary. Never log auth cookies, tokens, credentials, raw secrets, or sensitive customer data.
- Use `const` or `let` in JavaScript; never use `var`.
- If using in-memory state, document single-process limits and avoid multiple workers unless state is externalized.
- For local auth bypasses, require an explicit env flag and label them local-dev only.

## Minimal Flask Pattern

```python
from flask import Flask, jsonify, send_from_directory

app = Flask(__name__, static_folder="static", static_url_path="")


@app.get("/")
def index():
    return send_from_directory(app.static_folder, "index.html")


@app.get("/api/health")
def health():
    return jsonify({"status": "ok"})
```

## Minimal FastAPI Pattern

```python
from pathlib import Path

from fastapi import FastAPI, Request
from fastapi.responses import HTMLResponse
from fastapi.templating import Jinja2Templates

app = FastAPI()
templates = Jinja2Templates(directory=str(Path(__file__).parent / "templates"))


@app.get("/", response_class=HTMLResponse)
def index(request: Request):
    return templates.TemplateResponse(request, "index.html", {})


@app.get("/api/health")
def health() -> dict[str, str]:
    return {"status": "ok"}
```

## Verification

Before claiming done:
- Run the relevant tests, usually `python -m pytest`.
- Start the backend server.
- Verify `/` returns the frontend through the backend.
- Verify at least one `/api/...` route.
- Open the localhost URL in a browser and exercise the golden path.
- Check browser console and backend logs for errors.

## Common Mistakes

| Mistake | Correct Pattern |
|---|---|
| Opening `index.html` directly | Serve it from Flask/FastAPI and provide a localhost URL |
| Hardcoding API hosts in frontend code | Use relative paths like `fetch("/api/...")` |
| Putting secrets in JS, HTML, or committed config | Read secrets from backend env vars |
| Adding React/Vite for a small app without a reason | Use vanilla JS unless needed |
| Using real customer data in local development | Use sandbox, fixture, or synthetic data |
| Making API calls without response logs | Log status, elapsed time, request ID, and a redacted/truncated response summary |
| Putting business logic directly in routes after the app grows | Move it into service modules |
| Running multiple workers with in-memory jobs/cache | Use one worker or externalize state |
| Treating local success as production readiness | Add review, staging/UAT, support, and ownership gates |
