---
name: react-frontend-development
description: Modern React + TypeScript dashboard and SPA development patterns. Covers Vite, shadcn/ui, TanStack Query, Zustand, React Router, React Hook Form + Zod, Vitest + Testing Library, accessibility, and performance. Use when building React frontends, creating components, managing state, integrating APIs, writing frontend tests, or setting up a new React project.
---

<essential_principles>

**Stack (2025-2026)**

| Layer | Tool | Notes |
|-------|------|-------|
| Build | Vite + SWC | `npm create vite@latest app -- --template react-swc-ts` |
| Framework | React 19 | Compiler auto-memoization |
| Language | TypeScript 5.x (strict) | `noUncheckedIndexedAccess` required |
| Components | shadcn/ui + Radix UI | Copy-paste blueprints, you own the code |
| Styling | Tailwind CSS v4 | CSS-first config, OKLCH colors |
| Client State | Zustand | One store per feature |
| Server State | TanStack Query v5 | Query key factories, `queryOptions` |
| Routing | React Router v7 | Data mode, middleware for auth, typegen |
| Forms | React Hook Form + Zod | `z.infer` single source of truth |
| API Client | Axios | Interceptors for JWT refresh |
| Testing | Vitest + Testing Library + userEvent | `getByRole` first |
| Icons | lucide-react | Consistent with shadcn |

**Core Conventions**

- TypeScript strict mode is non-negotiable. Always `"strict": true` + `"noUncheckedIndexedAccess": true`.
- Never use `any`. Use `unknown` and narrow with type guards.
- File naming: kebab-case for files (`user-profile.tsx`), PascalCase for components (`UserProfile`), camelCase for hooks and utils.
- Test behavior, not implementation. Query by `getByRole` first.
- Profile before optimizing. Never blanket `memo` everything.
- Accessibility is a requirement, not a feature. Semantic HTML first, ARIA second.

</essential_principles>

<project_setup>

**Scaffold:**

```bash
npm create vite@latest my-app -- --template react-swc-ts
cd my-app
npm install
```

**tsconfig.app.json (strict):**

```json
{
  "compilerOptions": {
    "target": "ES2020",
    "module": "ESNext",
    "moduleResolution": "bundler",
    "jsx": "react-jsx",
    "strict": true,
    "noEmit": true,
    "isolatedModules": true,
    "skipLibCheck": true,
    "noUnusedLocals": true,
    "noUnusedParameters": true,
    "noUncheckedIndexedAccess": true,
    "noFallthroughCasesInSwitch": true,
    "paths": { "@/*": ["./src/*"] }
  }
}
```

**Path aliases:** Use `vite-tsconfig-paths` plugin so `@/components/Button` resolves to `src/components/Button`.

**Vite only transpiles -- it does NOT type-check.** Add `"typecheck": "tsc --noEmit"` to `package.json` scripts and run it in CI.

**ESLint:** Use `typescript-eslint` with strict type-checked rules, plus `eslint-plugin-react-hooks`, `eslint-plugin-react-refresh`, `eslint-plugin-jsx-a11y`.

**Directory structure:**

```text
src/
  components/       # Shared components
    ui/             # shadcn/ui generated components (don't modify)
  features/         # Feature-specific components, hooks, utils
    devices/
    auth/
    dashboard/
  hooks/            # Shared custom hooks
  lib/              # Utilities (cn, api client, etc.)
  routes/           # Route components (pages)
  schemas/          # Zod schemas (shared between forms and API)
  stores/           # Zustand stores
  types/            # Shared TypeScript types
  tests/            # Test setup and helpers
```

</project_setup>

<shadcn_ui>

**What it is:** Copy-paste component blueprints built on Radix UI primitives + Tailwind CSS. No runtime package -- you own the code after generation.

**Setup:**

```bash
npx shadcn@latest init
npx shadcn@latest add button card dialog input table form
```

**The `cn()` utility (required for class merging):**

```ts
import { clsx, type ClassValue } from "clsx";
import { twMerge } from "tailwind-merge";

export function cn(...inputs: ClassValue[]) {
  return twMerge(clsx(inputs));
}
```

**Tailwind v4 changes:**

- CSS-first configuration: `@theme` directive in CSS, no `tailwind.config.js`
- Colors use OKLCH instead of HSL
- Replace `tailwindcss-animate` with `tw-animate-css`

**Conventions:**

- Keep `components/ui/` for generated shadcn components; don't modify in place
- Use a `components/ui/overrides/` folder for heavy customizations
- Declare `dark:` variants early; retrofitting is double work
- Pin Radix versions -- major bumps change prop contracts
- Use `size-*` utility instead of `w-* h-*` pairs

</shadcn_ui>

<state_management>

**Rule: Zustand for client/UI state. TanStack Query for server state. Never mix them.**

### Zustand (client state)

Use for: sidebar open/closed, wizard steps, theme preference, form wizard state.

```ts
import { create } from "zustand";
import { devtools, persist } from "zustand/middleware";

interface SidebarStore {
  isOpen: boolean;
  toggle: () => void;
}

export const useSidebarStore = create<SidebarStore>()(
  devtools(
    persist(
      (set) => ({
        isOpen: true,
        toggle: () => set((s) => ({ isOpen: !s.isOpen })),
      }),
      { name: "sidebar-storage" }
    )
  )
);
```

**Conventions:**

- One store per domain/feature, not one monolithic store
- Always type stores with `create<StoreType>()()`
- Use `devtools` middleware in development
- Use `persist` for state that survives page refresh
- Design selectors first: `const isOpen = useSidebarStore((s) => s.isOpen)` -- never subscribe to whole store
- No async side effects in stores -- those belong in TanStack Query

### TanStack Query v5 (server state)

**Query key factory pattern:**

```ts
export const deviceKeys = {
  all: ["devices"] as const,
  lists: () => [...deviceKeys.all, "list"] as const,
  list: (filters: DeviceFilters) => [...deviceKeys.lists(), filters] as const,
  details: () => [...deviceKeys.all, "detail"] as const,
  detail: (id: string) => [...deviceKeys.details(), id] as const,
};
```

**Colocate with `queryOptions` for type safety:**

```ts
import { queryOptions } from "@tanstack/react-query";

export const deviceDetailOptions = (id: string) =>
  queryOptions({
    queryKey: deviceKeys.detail(id),
    queryFn: () => api.devices.get(id),
  });

// Usage: useQuery(deviceDetailOptions(id))
```

**Mutation with invalidation:**

```ts
export function useUpdateDevice() {
  const queryClient = useQueryClient();
  return useMutation({
    mutationFn: (data: UpdateDeviceInput) => api.devices.update(data),
    onSuccess: (_data, variables) => {
      queryClient.invalidateQueries({ queryKey: deviceKeys.detail(variables.id) });
      queryClient.invalidateQueries({ queryKey: deviceKeys.lists() });
    },
  });
}
```

**v5 breaking changes:**

- `isPending` replaces `isLoading` for initial load
- `gcTime` replaces `cacheTime`
- `onSuccess`/`onError` removed from `useQuery` -- use `useEffect`
- Single object parameter API for all hooks

</state_management>

<routing>

**Use `createBrowserRouter` + `<RouterProvider>`, not `<BrowserRouter>`.**

**Protected routes with middleware (v7.9+):**

```ts
const authMiddleware: Route.unstable_MiddlewareFunction = async ({ context }) => {
  const user = await getUser();
  if (!user) throw redirect("/login");
  context.user = user;
};

export const middleware = [authMiddleware];
```

**Loaders (data fetching before render):**

```ts
export async function loader({ request }: Route.LoaderArgs) {
  const devices = await api.devices.list();
  return { devices };
}

export default function DevicesPage({ loaderData }: Route.ComponentProps) {
  const { devices } = loaderData;
}
```

**Error boundaries:** Define `ErrorBoundary` per route. Nested routes propagate errors up to the nearest boundary.

**React Router v7 notes:**

- Use `react-router` only (not `react-router-dom` -- merged in v7)
- TypeScript typegen auto-generates `.d.ts` for routes in `.react-router/types/`
- Route-level code splitting with `React.lazy` + `Suspense`

</routing>

<api_integration>

**Axios instance with JWT interceptors:**

```ts
import axios from "axios";

export const api = axios.create({
  baseURL: "/api/v1",
  headers: { "Content-Type": "application/json" },
});

// Request: attach JWT
api.interceptors.request.use((config) => {
  const token = localStorage.getItem("access_token");
  if (token) config.headers.Authorization = `Bearer ${token}`;
  return config;
});

// Response: refresh on 401
let isRefreshing = false;
let failedQueue: Array<{ resolve: Function; reject: Function }> = [];

api.interceptors.response.use(
  (res) => res,
  async (error) => {
    const original = error.config;
    if (error.response?.status === 401 && !original._retry) {
      if (isRefreshing) {
        return new Promise((resolve, reject) => {
          failedQueue.push({ resolve, reject });
        }).then(() => api(original));
      }
      original._retry = true;
      isRefreshing = true;
      try {
        const { data } = await axios.post("/api/v1/auth/refresh", {
          refresh_token: localStorage.getItem("refresh_token"),
        });
        localStorage.setItem("access_token", data.access_token);
        failedQueue.forEach(({ resolve }) => resolve());
        return api(original);
      } catch {
        failedQueue.forEach(({ reject }) => reject(error));
        localStorage.clear();
        window.location.href = "/login";
        return Promise.reject(error);
      } finally {
        isRefreshing = false;
        failedQueue = [];
      }
    }
    return Promise.reject(error);
  }
);
```

**Typed API functions:**

```ts
export const devicesApi = {
  list: (params?: { page?: number; search?: string }) =>
    api.get<PaginatedResponse<Device>>("/devices", { params }).then((r) => r.data),
  get: (id: string) =>
    api.get<Device>(`/devices/${id}`).then((r) => r.data),
  create: (input: CreateDeviceInput) =>
    api.post<Device>("/devices", input).then((r) => r.data),
};
```

**Never use the same Axios instance for refresh token requests** (infinite loop). Use plain `axios.post` for the refresh call.

</api_integration>

<forms>

**React Hook Form + Zod: single source of truth.**

```ts
import { z } from "zod";

export const deviceSchema = z.object({
  name: z.string().min(1, "Name is required").max(100),
  ipAddress: z.string().ip({ message: "Invalid IP address" }),
  port: z.coerce.number().int().min(1).max(65535),
});

export type DeviceFormData = z.infer<typeof deviceSchema>;
```

```tsx
import { useForm } from "react-hook-form";
import { zodResolver } from "@hookform/resolvers/zod";

function DeviceForm({ onSubmit }: { onSubmit: (data: DeviceFormData) => void }) {
  const form = useForm<DeviceFormData>({
    resolver: zodResolver(deviceSchema),
    defaultValues: { name: "", ipAddress: "", port: 443 },
  });

  return (
    <form onSubmit={form.handleSubmit(onSubmit)}>
      {/* shadcn Form components */}
    </form>
  );
}
```

**Conventions:**

- Always use `z.infer<typeof schema>` -- never write a separate TypeScript type
- Keep schemas in `schemas/` for sharing between frontend and backend
- Use `z.coerce.number()` for inputs that come in as strings
- Cross-field validation with `.refine()` (e.g., password confirmation)

</forms>

<testing>

**Setup (`vite.config.ts`):**

```ts
export default defineConfig({
  plugins: [react()],
  test: {
    environment: "jsdom",
    globals: true,
    setupFiles: "./src/tests/setup.ts",
    css: true,
  },
});
```

**Setup file (`src/tests/setup.ts`):**

```ts
import { afterEach } from "vitest";
import { cleanup } from "@testing-library/react";
import "@testing-library/jest-dom/vitest";

afterEach(() => { cleanup(); });
```

**Test pattern:**

```ts
import { render, screen } from "@testing-library/react";
import userEvent from "@testing-library/user-event";
import { describe, it, expect, vi } from "vitest";

describe("DeviceCard", () => {
  it("calls onSelect when clicked", async () => {
    const onSelect = vi.fn();
    const user = userEvent.setup();
    render(<DeviceCard device={mockDevice} onSelect={onSelect} />);

    await user.click(screen.getByRole("button", { name: /select/i }));
    expect(onSelect).toHaveBeenCalledWith(mockDevice.id);
  });
});
```

**Query priority:** `getByRole` > `getByLabelText` > `getByText` > `getByTestId`

**Conventions:**

- Use `userEvent.setup()` + `await user.click()` over `fireEvent`
- Use `findByRole` / `waitFor` for async components
- Mock API calls, not component internals
- Create a `renderWithProviders` wrapper that includes `QueryClientProvider`, `RouterProvider`
- One assertion focus per test

</testing>

<accessibility>

**Semantic HTML first, ARIA second.** If a native element exists (`<button>`, `<nav>`, `<dialog>`), use it.

**Requirements:**

- All interactive elements Tab-reachable
- Focus order follows visual/logical sequence
- Focus visible -- never `outline: none` without replacement
- Skip links to bypass navigation
- Route changes: move focus to main heading
- Modals: trap focus, restore on close
- Data tables: `<table>` with `scope="col"`, `aria-sort` for sortable columns
- Toast notifications: `role="status"` or `aria-live="polite"`
- Charts: `aria-label` on container + visually-hidden data table

**Tooling:**

- `eslint-plugin-jsx-a11y` for lint-time checks
- `axe-core` / Axe DevTools for automated WCAG 2.2 AA audits
- Radix UI (used by shadcn) handles most ARIA patterns correctly

</accessibility>

<performance>

**Route-level code splitting (highest ROI):**

```ts
const Dashboard = lazy(() => import("./pages/Dashboard"));
// In routes:
{ path: "/dashboard", element: <Suspense fallback={<PageSkeleton />}><Dashboard /></Suspense> }
```

**Virtual lists for large datasets:**

```ts
import { useVirtualizer } from "@tanstack/react-virtual";
```

Use `@tanstack/react-virtual` for lists > 100 items.

**Concurrent features:**

- `useTransition` for non-urgent updates (filtering, searching)
- `useDeferredValue` for expensive re-renders on search input

**Conventions:**

- Profile with React DevTools Profiler before optimizing
- `React.memo` only when parent re-renders frequently with stable child props
- Use skeleton loaders that match content structure (prevent layout shift)
- Analyze bundle with `rollup-plugin-visualizer`

</performance>

<typescript_patterns>

**Discriminated unions for state:**

```ts
type AsyncState<T> =
  | { status: "idle" }
  | { status: "loading" }
  | { status: "error"; error: Error }
  | { status: "success"; data: T };
```

**Variant props (prevent impossible states):**

```ts
type ButtonProps =
  | { variant: "link"; href: string; onClick?: never }
  | { variant: "button"; onClick: () => void; href?: never };
```

**Generic components:**

```ts
interface SelectProps<T> {
  items: T[];
  value: T;
  onChange: (item: T) => void;
  getLabel: (item: T) => string;
}

function Select<T>({ items, value, onChange, getLabel }: SelectProps<T>) { ... }
```

**Conventions:**

- Props: use `interface` (not `type`) -- use `type` for unions and mapped types
- Extend native elements: `React.ComponentPropsWithoutRef<"button">`
- Custom hook returns: `as const` for tuple inference
- Config objects: `satisfies` operator for type checking with literal preservation
- Empty objects: `Record<string, never>` not `{}`
- Event handlers: `React.MouseEventHandler<HTMLButtonElement>`

</typescript_patterns>

<anti_patterns>

- **Prop drilling through 3+ levels** -- use Zustand or React context
- **Fetching in useEffect** -- use TanStack Query or route loaders
- **Global CSS** -- use Tailwind utility classes or CSS modules
- **Barrel exports** (`index.ts` re-exports) -- slows build and breaks tree-shaking
- **Premature `useMemo`/`useCallback`** -- profile first, memoize only proven bottlenecks
- **`any` types** -- use `unknown` with type guards
- **Testing implementation details** -- query by role, not by class name or test-id
- **Mixing client and server state** -- Zustand for UI, TanStack Query for API data

</anti_patterns>

<success_criteria>
A well-built React frontend:

- TypeScript strict mode with no `any` or `@ts-ignore`
- All components accessible (axe-core passes WCAG 2.2 AA)
- Server state managed by TanStack Query with proper cache invalidation
- Client state in Zustand with typed selectors
- Forms validated with Zod schemas (single source of truth)
- Route-level code splitting reduces initial bundle
- Tests cover user-facing behavior with Testing Library
- ESLint + Prettier pass with zero warnings
</success_criteria>
