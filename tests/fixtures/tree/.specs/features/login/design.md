# Login: Design

## Approach

The login page is a server-rendered form posting to a single endpoint.
The endpoint validates credentials against the user store and sets a
session cookie on success.

## Components

- Login page: form with email and password fields
- Auth endpoint: validates credentials, manages the session
- Session store: maps session tokens to users

## Trade-offs

- Server rendering keeps the page usable without JavaScript
- A single endpoint keeps the flow easy to test end to end

## Open questions

- Session lifetime and renewal policy
