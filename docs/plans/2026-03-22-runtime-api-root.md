# Runtime-Configurable API_ROOT Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Make `API_ROOT` configurable at container runtime via environment variables, following 12-factor principles (build once, promote through environments).

**Architecture:** Inject a `window._env_` config object via a `public/env-config.js` file loaded synchronously in `<head>`. At container startup, a shell entrypoint script overwrites this file with values from real environment variables. `src/agent.js` reads `window._env_.API_ROOT` first, then falls back to `process.env.REACT_APP_BACKEND_URL` (dev), then the hardcoded default.

**Tech Stack:** React (CRA), nginx (Docker), shell scripting for entrypoint

---

### Task 1: Create `public/env-config.js`

**Files:**
- Create: `public/env-config.js`

**Step 1: Create the default config file**

```javascript
window._env_ = {
  API_ROOT: "https://conduit.productionready.io/api"
};
```

**Step 2: Verify file exists**

Run: `cat public/env-config.js`
Expected: Shows the `window._env_` object with default API_ROOT

**Step 3: Commit**

```bash
git add public/env-config.js
git commit -m "feat: add default runtime env config file"
```

---

### Task 2: Add `env-config.js` script tag to `public/index.html`

**Files:**
- Modify: `public/index.html:19` (before `</head>`)

**Step 1: Add script tag**

Add before the `<title>` tag (line 19):
```html
<script src="%PUBLIC_URL%/env-config.js"></script>
```

**Step 2: Verify**

Run: `grep env-config public/index.html`
Expected: Shows the script tag

**Step 3: Commit**

```bash
git add public/index.html
git commit -m "feat: load runtime env config in index.html"
```

---

### Task 3: Update `src/agent.js` API_ROOT

**Files:**
- Modify: `src/agent.js:6`

**Step 1: Change the API_ROOT line**

Replace line 6:
```javascript
const API_ROOT = 'https://conduit.productionready.io/api';
```

With:
```javascript
const API_ROOT =
  (window._env_ && window._env_.API_ROOT) ||
  process.env.REACT_APP_BACKEND_URL ||
  'https://conduit.productionready.io/api';
```

**Step 2: Verify**

Run: `grep -A2 'const API_ROOT' src/agent.js`
Expected: Shows the new three-line fallback chain

**Step 3: Commit**

```bash
git add src/agent.js
git commit -m "feat: read API_ROOT from runtime config with fallback chain"
```

---

### Task 4: Create `docker-entrypoint.sh`

**Files:**
- Create: `docker-entrypoint.sh`

**Step 1: Create the entrypoint script**

```bash
#!/bin/sh
# Overwrite env-config.js at container startup using real env vars.
# This enables runtime configuration without rebuilding the image.
cat > /usr/share/nginx/html/env-config.js <<EOF
window._env_ = {
  API_ROOT: "${API_ROOT:-https://conduit.productionready.io/api}"
};
EOF
exec "$@"
```

**Step 2: Make executable**

Run: `chmod +x docker-entrypoint.sh`

**Step 3: Commit**

```bash
git add docker-entrypoint.sh
git commit -m "feat: add container entrypoint for runtime env injection"
```

---

### Task 5: Create `Dockerfile`

**Files:**
- Create: `Dockerfile`

**Step 1: Write Dockerfile**

```dockerfile
# Stage 1: Build
FROM node:16-alpine AS build
WORKDIR /app
COPY package*.json ./
RUN npm ci
COPY . .
RUN npm run build

# Stage 2: Serve
FROM nginx:1.25-alpine
COPY --from=build /app/build /usr/share/nginx/html
COPY docker-entrypoint.sh /docker-entrypoint.sh
RUN chmod +x /docker-entrypoint.sh && \
    chown -R nginx:nginx /usr/share/nginx/html
ENTRYPOINT ["/docker-entrypoint.sh"]
CMD ["nginx", "-g", "daemon off;"]
EXPOSE 80
```

**Step 2: Commit**

```bash
git add Dockerfile
git commit -m "feat: add multi-stage Dockerfile with runtime config support"
```

---

### Task 6: Update `README.md`

**Files:**
- Modify: `README.md:30-36` (the "Making requests to the backend API" section)

**Step 1: Replace the section**

Replace lines 30-36 with updated documentation covering:
- The default API URL
- How to change it for local dev (`REACT_APP_BACKEND_URL`)
- How to change it for container deployments (`API_ROOT` env var)
- The fallback chain order

**Step 2: Commit**

```bash
git add README.md
git commit -m "docs: update README with runtime API_ROOT configuration"
```

---

### Task 7: Run tests and verify

**Step 1: Install dependencies**

Run: `npm install`

**Step 2: Run tests**

Run: `npm test -- --watchAll=false`
Expected: All tests pass (or no tests exist yet — that's fine)

**Step 3: Verify build**

Run: `npm run build`
Expected: Build succeeds; `build/env-config.js` exists in output

---

### Task 8: Push and create PR

**Step 1: Push branch**

```bash
git push -u origin cyrus/eng-5-eact-redux-realworld-example-app
```

**Step 2: Create PR**

```bash
gh pr create --title "feat: runtime-configurable API_ROOT for 12-factor deployments" --body "..."
```
