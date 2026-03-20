# CLAUDE.md — conduit-frontend

This is the React + Redux frontend for the Conduit demo app (a Medium clone). It consumes the Conduit backend REST API.

## What this repo is

A single-page app built with React + Redux + React Router. It renders the home feed, article pages, editor, auth forms, and user profiles. All data comes from the Conduit backend API (configured via `REACT_APP_BACKEND_URL`).

## Key directories

```
src/
  agent.js              # All API calls via superagent — single source of truth for backend requests
  store.js              # Redux store setup
  reducer.js            # Root reducer (combines all slice reducers)
  index.js              # App entry, router setup
  components/
    App.js              # Top-level component, route definitions
    Header.js           # Nav bar with auth state
    Home/               # Home feed (global + personal + tags)
    Article/            # Article view, comments section
    Editor/             # New/edit article form
    Auth/               # Login + Register forms
    Profile/            # User profile + article lists
    Settings/           # Account settings
  middleware/
    promiseMiddleware.js  # Resolves promise payloads in actions
    localStorageMiddleware.js  # Persists JWT to localStorage
```

## How to run

```bash
npm install
REACT_APP_BACKEND_URL=http://localhost:3000/api npm start
# dev server on port 4100
```

## How to run tests

```bash
npm test
```

Uses Jest + React Testing Library. Tests are sparse — prefer integration-style tests that render components and assert on the DOM.

## Key patterns

- **API calls**: All backend communication goes through `src/agent.js`. It reads `REACT_APP_BACKEND_URL` and the JWT from the Redux store. To add a new API call, add a method to the relevant `agent` object (e.g. `agent.Articles`, `agent.Auth`).
- **Redux actions**: Each feature folder has a `reducer.js` that handles its slice of state. Actions are plain strings (e.g. `'ARTICLE_SUBMITTED'`). The promise middleware unwraps promises in action payloads automatically.
- **Routing**: React Router v4. Routes are defined in `components/App.js`. Use `<Link>` for internal navigation.
- **Auth state**: Stored in Redux under `state.common.currentUser`. JWT is persisted to `localStorage` by `localStorageMiddleware`. Read auth state from the store — don't access localStorage directly in components.

## Common entry points for tickets

- Adding a new field to the article editor → `components/Editor/` + `src/agent.js` Articles.create/update
- New page/route → add component under `components/`, add route in `App.js`, add API call in `agent.js`
- UI changes to the feed → `components/Home/`
- Comment changes → `components/Article/CommentContainer.js` + `CommentInput.js`
- Auth flow changes → `components/Auth/` + `localStorageMiddleware.js`

## Things to watch out for

- `agent.js` sets the JWT header globally via `superagent.set('authorization', ...)` — changes here affect all requests
- The app assumes the backend returns the exact Conduit API spec shape — if the backend changes a response shape, find all uses of that field in components
- Redux state is not persisted beyond the JWT — page refreshes lose all in-memory state (articles, comments, etc.) and refetch from the API
