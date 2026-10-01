# Specifications

*Generated on 2026-09-30*

\newpage
# Project Overview

TestProject is a small sample project used to exercise the spec-driven
documentation pipeline. It exists so that every generated surface can be
checked against a known, stable set of sources.

## Vision

Keep project documentation as close to the code as possible by treating
specs as the single source of truth and generating all published views
from them.

## Goals

- Provide a predictable home for project, codebase, and feature specs
- Generate the landing page, site skeleton, and book view from one tree
- Keep internal links valid across every published surface

## Scope

In scope:

- Specs under `project/`, `codebase/`, `features/`, and `quick/`
- Generated navigation, index page, and book views

Out of scope:

- Translating spec content
- Hosting or deploying the generated site

## Audience

Readers are developers joining the project who need orientation fast,
plus stakeholders who only want goals and milestones.


\newpage

# Roadmap

The roadmap lists milestones in delivery order. Dates are intentionally
omitted; each milestone ships when its acceptance criteria pass.

## Milestone 1: Site skeleton

- Generate the site configuration from the specs tree
- Mirror the specs tree under the docs directory
- Land the landing page with valid internal links

Acceptance: the generated navigation lists every top-level section and
every link resolves inside the site.

## Milestone 2: Feature pages

- Publish one page per feature directory
- Link spec, design, and tasks documents from the feature table
- Keep missing documents visible as an em dash instead of a dead link

Acceptance: each feature row renders with at least a spec link.

## Milestone 3: Book view

- Assemble the ordered book from explicit file arguments
- Fall back to the markdown book when no PDF engine is present
- Preserve the book content byte for byte between runs

Acceptance: repeated runs produce identical output.


\newpage

# Architecture

TestProject is a documentation pipeline with three moving parts.

## Components

- Specs tree: the source of truth, organized by directory (`project/`,
  `codebase/`, `features/`, `quick/`)
- Generator scripts: read the specs tree and emit the site skeleton,
  the landing page, and the book view
- Published surfaces: the site configuration plus mirrored docs, the
  landing page, and the book

## Data flow

The generator scripts take the specs tree as input and write their
outputs under a docs directory. Navigation labels are derived from
directory names, so renaming a directory renames its section.

## Constraints

- Generator scripts never edit spec content
- Every published link must resolve inside the generated tree
- Runs must be repeatable: same inputs, same bytes


\newpage

# Login: Spec

The login feature lets a registered user authenticate and reach the
dashboard.

## Requirements

- The login page accepts an email address and a password
- Invalid credentials show an error and keep the user on the page
- Successful authentication redirects to the dashboard

## Acceptance criteria

- A user with valid credentials reaches the dashboard in one step
- A user with invalid credentials sees an error message
- The login page renders without JavaScript enabled

## Non-goals

- Password recovery
- Multi-factor authentication


\newpage

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


\newpage

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


\newpage

# Fix nav: Spec

Quick task: the generated navigation dropped one section after a
directory was renamed.

## Problem

Renaming a top-level directory under the specs tree removed its section
from the generated navigation instead of relabeling it.

## Fix

- Derive navigation labels from the renamed directory
- Regenerate the site skeleton after any directory rename
- Assert that every top-level directory appears in the navigation

## Acceptance criteria

- After a rename, the navigation lists the section under the new label
- No internal link is broken by the rename
- Rerunning the generator produces the same navigation


\newpage

