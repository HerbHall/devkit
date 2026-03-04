---
name: react-frontend
version: 1.0
description: Standalone React/TypeScript frontends (Vite, SPA)
requires: []
winget:
  - id: OpenJS.NodeJS.LTS
    check: node
manual:
  - id: pnpm
    check: pnpm
    install: npm install -g pnpm
vscode-extensions:
  - dbaeumer.vscode-eslint
  - esbenp.prettier-vscode
  - bradlc.vscode-tailwindcss
claude-skills:
  - react-frontend-development
---

# React Frontend Profile

Use this profile for standalone React/TypeScript single-page applications built with Vite. No backend, no Docker -- just a modern frontend.

## When to Use This

- React SPAs deployed to static hosting (Cloudflare Pages, Netlify, Vercel)
- Dashboard UIs that consume external APIs
- Internal tools with client-side routing
- Component libraries and design systems

If your React app is part of a Docker Desktop extension, use **node-extension** instead.

## Project Structure

A typical React/Vite project:

```text
my-app/
├── src/
│   ├── components/      # Reusable UI components
│   ├── pages/           # Route-level components
│   ├── hooks/           # Custom React hooks
│   ├── api/             # API client functions
│   ├── App.tsx
│   ├── main.tsx
│   └── test-setup.ts    # Vitest setup
├── public/              # Static assets (not optimized)
├── index.html
├── package.json
├── pnpm-lock.yaml
├── tsconfig.json
├── eslint.config.js
├── vite.config.ts
├── vitest.config.ts
├── Makefile
├── VERSION
└── CHANGELOG.md
```

## Getting Started

```bash
pnpm create vite my-app --template react-ts
cd my-app
pnpm install
```

Then copy these DevKit templates into your project:

- `project-templates/eslint.config.js` -- ESLint flat config for TypeScript + React
- `project-templates/tsconfig.json` -- strict TypeScript config
- `project-templates/Makefile.node` -- Makefile with standard targets
- `project-templates/gitignore-node` -- copy as `.gitignore`

## Makefile

Copy `project-templates/Makefile.node` for standard targets:

```text
install:     pnpm install
build:       pnpm run build
dev:         pnpm run dev
test:        pnpm run test
lint:        npx eslint src/
typecheck:   npx tsc --noEmit
lint-all:    lint + typecheck + lint-md
ci:          lint-all + test + build
```

Run `make hooks` after cloning to install the pre-push hook.

## TypeScript Configuration

Use `project-templates/tsconfig.json` which enables strict mode with these key settings:

- `strict: true` -- all strict checks enabled
- `noUnusedLocals: true` -- catch unused imports
- `noUnusedParameters: true` -- catch unused function params
- `noUncheckedIndexedAccess: true` -- array/object index access returns `T | undefined`
- `noFallthroughCasesInSwitch: true` -- require break/return in switch cases

## ESLint Configuration

Use `project-templates/eslint.config.js` which provides:

- ESLint 9+ flat config format
- TypeScript strict rules via typescript-eslint
- React hooks plugin for hooks rules
- Unused variables allowed with `_` prefix

## Testing

Set up Vitest with jsdom for component testing:

```bash
pnpm add -D vitest @testing-library/react @testing-library/jest-dom jsdom
```

Create `vitest.config.ts` using `mergeConfig` from `vitest/config` to inherit Vite plugins:

```typescript
import { defineConfig, mergeConfig } from "vitest/config";
import viteConfig from "./vite.config";

export default mergeConfig(
  viteConfig,
  defineConfig({
    test: {
      environment: "jsdom",
      globals: true,
      setupFiles: "./src/test-setup.ts",
    },
  })
);
```

Create `src/test-setup.ts`:

```typescript
import "@testing-library/jest-dom/vitest";
```

Run tests:

```bash
pnpm run test          # or: npx vitest run
pnpm run test:watch    # watch mode: npx vitest
```

## VS Code Extensions

- **dbaeumer.vscode-eslint** -- ESLint integration with auto-fix on save
- **esbenp.prettier-vscode** -- code formatting
- **bradlc.vscode-tailwindcss** -- Tailwind CSS IntelliSense (if using Tailwind)

## Related Profiles

- **node-extension** -- for Docker Desktop extensions with React frontend
- **go-extension** -- for Docker Desktop extensions with Go backend + React frontend
