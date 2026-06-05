---
name: mykaarma-saml
description: Use when adding, fixing, or reviewing SAML login, SSO, SP metadata, ACS, SLO, session auth gates, or myKaarma IdP integration in a Python web app.
---

# SAML With myKaarma IdP

## Overview

Use `python3-saml` as the service provider toolkit for Python apps that need myKaarma SSO. Treat SAML as production security work: generate environment-specific SP metadata, register it with the SSO team, keep private keys out of source, and deny unauthorized users before creating the app session.

## When to Use

Use this skill for:
- Adding SAML login to Flask or FastAPI apps.
- Creating `/saml/metadata`, `/saml/login`, `/saml/acs`, `/saml/logout`, or `/saml/sls`.
- Debugging RelayState loops, IdP registration, ACS failures, signature errors, or metadata mismatches.
- Protecting operator/admin UI routes behind myKaarma SSO.

Do not use this skill for webhook authentication, Basic auth, OAuth, or `mkid` cookie product APIs unless SAML is also in scope. For myKaarma product APIs, keep following the cookie-based `mkid`/`withCredentials` standards.

## Required Dependencies

- Python package: `python3-saml>=1.16,<2.0`.
- FastAPI ACS forms: include `python-multipart`.
- Sessions: Flask session secret or Starlette `SessionMiddleware` with `SESSION_SECRET`.
- Containers/macOS must include XML security libraries for `python3-saml`: `xmlsec1`, `libxmlsec1-openssl`, `libxml2`, and build tooling as needed.

## IdP Settings

Use the myKaarma IdP values from the current UI integration docs. The current implementation references:

| Field | Value |
|---|---|
| IdP entity ID | `https://accounts.mykaarma.com/saml2/idp/metadata.php` |
| SSO URL | `https://accounts.mykaarma.com/saml2/idp/SSOService.php` |
| SLO URL | `https://accounts.mykaarma.com/saml2/idp/SingleLogoutService.php` |
| Binding | HTTP-Redirect |

Do not fetch IdP metadata dynamically at runtime; the metadata URL may redirect behind login. Pin or configure the IdP public cert and track its expiry in the runbook. The IdP public certificate may be committed if it contains no private material. Use [reference/mykaarma-idp-certificate.md](reference/mykaarma-idp-certificate.md) for the current public IdP certificate from the UI integration docs. The SP private key is a secret and must come from an environment variable or secret manager.

## SP Endpoint Contract

Implement these routes:

| Route | Purpose | Public? |
|---|---|---|
| `GET /saml/metadata` | Returns generated SP metadata XML | Yes |
| `GET /saml/login` | Starts AuthnRequest, accepts safe return target | Yes |
| `POST /saml/acs` | Processes SAMLResponse and creates session | Yes |
| `GET /saml/logout` | Starts logout with NameID/session index | Session-dependent |
| `GET /saml/sls` | Handles logout callback and clears session | Yes |

Protect all operator/admin UI routes. Keep only health checks, webhook ingestion routes, and SAML protocol routes unauthenticated at the app level.

## Security Settings

Use these defaults unless the SSO team confirms a different requirement:

- `authnRequestsSigned: True`
- `wantMessagesSigned: True`
- `wantAssertionsSigned: False`
- `requestedAuthnContext: False`
- `signatureAlgorithm: rsa-sha256`
- `digestAlgorithm: sha256`

Why: the myKaarma IdP signs the outer response, and requiring a separately signed assertion has rejected valid logins. Requesting `PasswordProtectedTransport` AuthnContext has also caused IdP rejections.

## Configuration

Required environment:
- `BASE_URL`: canonical public URL for the deployed app, no trailing slash.
- `SP_ENTITY_ID` or `SAML_SP_ENTITY_ID`: stable app-specific SP entity ID, using the agreed reverse-domain/app-name form such as `TLD.ORG.APPNAME`. Do not use `localhost`, `127.0.0.1`, ports, or request-derived URLs.
- `SESSION_SECRET`: high-entropy session signing secret.
- `SP_PUBLIC_CERT` or `certs/sp.crt`: public SP X.509 certificate configured as `sp.x509cert` so generated metadata includes `<X509Certificate>`.
- `SP_PRIVATE_KEY`: private key matching the SP public certificate, configured as `sp.privateKey`.

For Flask-only variants:
- `SAML_SP_ENTITY_ID`: same stable app-specific entity ID as above.
- `SAML_SP_ACS_URL`: usually `${BASE_URL}/saml/acs`.
- `SAML_SP_SLS_URL`: usually `${BASE_URL}/saml/sls`.
- `FLASK_SECRET_KEY`: high-entropy session secret.

Local bypass flags are allowed only for development and tests. They must default to off, be visibly named as local-only, and never be required for production.

## Implementation Notes

For FastAPI:
- Put SAML settings and request conversion in a dedicated `app/saml.py`.
- Derive ACS, SLS, and metadata endpoint URLs from `BASE_URL`, not from internal localhost/proxy request URLs.
- Set `sp.entityId` from the stable app-specific entity ID, not from `BASE_URL`.
- Add `SessionMiddleware` with `https_only=True` when `BASE_URL` is HTTPS.
- Convert `await request.form()` into `post_data` before calling `auth.process_response()`.

For Flask:
- Use `prepare_flask_request(request)` to pass scheme, host, path, query, and form data to `OneLogin_Saml2_Auth`.
- Use `X-Forwarded-Proto` or public env vars so metadata advertises HTTPS behind a proxy.
- Avoid RelayState loops: never redirect back to `/saml/login`.

In both:
- Keep SP entity ID stable per app/environment so multiple developers can reuse the same local default port, such as `127.0.0.1:5000`, without creating identical SP identities.
- Configure both the SP public certificate and private key when signing AuthnRequests. `python3-saml` needs the public certificate in `sp.x509cert` and the private key in `sp.privateKey`.
- Store only the minimal session payload needed: NameID, session index, attributes, authorization flags.
- Extract `UserUUID`, `Email`, `UserName`, and optionally `DealerUUIDs` from SAML attributes.
- Deny unauthorized users during ACS/session creation, not only after redirecting to the UI.
- Do not log SAML assertions, tokens, private keys, or full attribute dumps.

## Registration Flow

1. Deploy or run with the final public `BASE_URL`.
2. Confirm `/saml/metadata` returns valid XML, entity ID equals the stable app-specific ID, ACS/SLS URLs match the public domain exactly, and the SP `<X509Certificate>` is present.
3. Save the SP metadata XML for that environment.
4. Email the myKaarma SSO team at `sso@mykaarma.com` with the SP metadata XML file attached. In the email body, also list the entity ID, ACS URL, SLS URL, environment, and technical contact.
5. Wait for SSO team confirmation before testing real login.
6. Browser-test `/saml/login -> IdP -> /saml/acs -> protected UI`.
7. Re-enable all auth gates and remove any local bypass configuration.

## Verification

- `GET /saml/metadata` returns `200 text/xml`.
- Metadata validates through `OneLogin_Saml2_Settings.validate_metadata`.
- `/saml/login` redirects to the myKaarma IdP with signed request parameters when signing is enabled.
- ACS rejects bad responses and unauthenticated users.
- ACS accepts a valid registered user and creates a session.
- Protected UI routes redirect unauthenticated users to login.
- Unauthorized signed-in users get `403`.
- Logout clears the session.

## Common Mistakes

| Mistake | Correct Pattern |
|---|---|
| Metadata entity ID uses localhost, `127.0.0.1:5000`, a port, or an old domain | Use a stable app-specific entity ID such as `TLD.ORG.APPNAME`; use `BASE_URL` only for ACS/SLS URLs |
| Fetching IdP metadata live | Pin/configure IdP cert and URLs |
| Requiring signed assertions | Require signed response messages; set `wantAssertionsSigned: False` unless SSO confirms otherwise |
| Requesting default AuthnContext | Set `requestedAuthnContext: False` |
| Configuring only the SP private key | Configure both `sp.x509cert` / `certs/sp.crt` and `sp.privateKey` |
| Creating a session before authorization | Deny unauthorized users in ACS |
| Redirecting RelayState back to login | Sanitize return targets and fall back to a protected landing page |
| Committing SP private key or session secret | Use env vars or secret manager |
