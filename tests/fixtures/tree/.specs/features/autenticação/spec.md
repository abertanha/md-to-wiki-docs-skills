# Autenticacao: Spec

The authentication feature governs how sessions are issued and revoked
for every authenticated area of the project.

## Requirements

- Sessions are issued only after credentials are validated
- Every authenticated page checks the session before rendering
- Revoking a session takes effect on the next request

## Acceptance criteria

- A request without a session is redirected to the login page
- A revoked session cannot reach any authenticated page
- The session check adds no visible delay to page loads

## Non-goals

- Single sign-on across external providers
- Device management or session listing for end users
