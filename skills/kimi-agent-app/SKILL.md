---
name: kimi-agent-app
description: >
  Build full-stack web apps on the Kimi Agent scaffold: React + Vite +
  shadcn/ui frontend, Hono API backend with tRPC, Drizzle ORM + MySQL,
  Kimi OAuth 2.0 authentication, JWT session management, and AWS S3.
  Trigger this skill when the user wants to extend the kimi-agent-app
  starter, add tRPC routers, define Drizzle schema tables, wire new
  shadcn components, integrate Kimi OAuth, manage sessions, query the
  database, or follow the project's conventions for contracts, API
  middleware, and frontend data-fetching.
---

# Kimi Agent App — Full-Stack Scaffold

Stack: **React 18 + Vite 7 · Tailwind CSS 3 · shadcn/ui · tRPC · Hono ·
Drizzle ORM · MySQL · Kimi OAuth 2.0 · jose JWT · AWS S3**

---

## Project Structure

```
├── api/                  Backend — Hono + tRPC
│   ├── boot.ts           App entry, route mounting
│   ├── router.ts         Root tRPC router (add feature routers here)
│   ├── auth-router.ts    auth.me / auth.logout
│   ├── middleware.ts      createRouter, publicQuery, authedQuery
│   ├── context.ts        tRPC context (req headers, resHeaders, user)
│   ├── kimi/             Kimi OAuth integration
│   │   ├── auth.ts       OAuth callback, token exchange, session cookie
│   │   ├── session.ts    JWT sign / verify (HS256)
│   │   ├── platform.ts   Kimi Open API client (GET /v1/users/me/profile)
│   │   └── types.ts      TokenResponse, SessionPayload, UserProfile
│   ├── queries/          Drizzle queries
│   │   ├── users.ts      findUserByUnionId, upsertUser
│   │   └── connection.ts MySQL pool via drizzle-orm/mysql2
│   └── lib/
│       ├── env.ts        Typed env vars (zod-free, process.env)
│       ├── cookies.ts    Secure/sameSite cookie options
│       ├── http.ts       Typed fetch helpers
│       └── vite.ts       Static file serving in production
├── contracts/            Shared frontend ↔ backend constants
│   ├── constants.ts      Session cookie name, Paths, ErrorMessages
│   ├── errors.ts         Typed HTTP errors (forbidden, notFound, …)
│   └── types.ts          Shared type aliases
├── db/
│   ├── schema.ts         Drizzle table definitions (users table)
│   ├── relations.ts      Drizzle relations
│   └── seed.ts           Seed script
├── src/                  Frontend
│   ├── App.tsx           Router: /, /login, *
│   ├── providers/trpc.tsx tRPC + React Query provider
│   ├── hooks/useAuth.ts  Auth state hook (trpc.auth.me.useQuery)
│   ├── pages/            Home, Login, NotFound
│   └── components/
│       ├── AuthLayout.tsx Authenticated shell with sidebar
│       └── ui/           40+ shadcn/ui components
└── drizzle.config.ts     Points to db/schema.ts + MySQL URL
```

---

## Dev Commands

```bash
npm install
npm run dev        # Vite dev server + Hono API (concurrent)
npm run build      # Vite frontend build
npm run start      # Production Node server
npm run db:push    # Push schema to DB (no migration)
npm run db:generate  # Generate Drizzle migration files
npm run db:migrate   # Apply migrations
```

---

## Adding a tRPC Router

1. Create `api/[feature]-router.ts`:

```typescript
import { createRouter, authedQuery } from "./middleware";
import { db } from "./queries/connection";
import { posts } from "../db/schema";

export const postRouter = createRouter({
  list: authedQuery.query(async ({ ctx }) => {
    return db.select().from(posts).where(eq(posts.userId, ctx.user.id));
  }),
  create: authedQuery
    .input(z.object({ title: z.string().min(1) }))
    .mutation(async ({ ctx, input }) => {
      await db.insert(posts).values({ title: input.title, userId: ctx.user.id });
    }),
});
```

2. Register in `api/router.ts`:

```typescript
import { postRouter } from "./post-router";

export const appRouter = createRouter({
  ping: publicQuery.query(() => ({ ok: true, ts: Date.now() })),
  auth: authRouter,
  posts: postRouter,   // ← add here
});
```

3. Use in React:

```typescript
const { data: posts } = trpc.posts.list.useQuery();
const create = trpc.posts.create.useMutation();
```

---

## Adding a Drizzle Table

In `db/schema.ts`:

```typescript
export const posts = mysqlTable("posts", {
  id: serial("id").primaryKey(),
  // FK to users.id (serial → bigint unsigned):
  userId: bigint("userId", { mode: "number", unsigned: true }).notNull(),
  title: varchar("title", { length: 255 }).notNull(),
  content: text("content"),
  createdAt: timestamp("createdAt").defaultNow().notNull(),
});

export type Post = typeof posts.$inferSelect;
export type InsertPost = typeof posts.$inferInsert;
```

Then in `db/relations.ts`:

```typescript
import { relations } from "drizzle-orm";
import { users, posts } from "./schema";

export const usersRelations = relations(users, ({ many }) => ({
  posts: many(posts),
}));
export const postsRelations = relations(posts, ({ one }) => ({
  user: one(users, { fields: [posts.userId], references: [users.id] }),
}));
```

Apply: `npm run db:push` (dev) or `npm run db:generate && npm run db:migrate` (prod).

---

## Kimi OAuth Flow

```
Browser → GET /login
  → Redirect to Kimi auth server with client_id, redirect_uri (base64 as state), scope
  → User approves
  → GET /api/oauth/callback?code=…&state=…
      exchangeAuthCode(code, redirectUri)       → access_token
      verifyAccessToken(access_token)           → userId
      kimiUsers.getProfile(access_token)        → name, avatar_url
      upsertUser({ unionId, name, avatar })     → DB write
      signSessionToken({ unionId, clientId })   → JWT (HS256, 1 year)
      setCookie(kimi_sid, token, httpOnly)
  → Redirect to /
```

Session verification on each authed request (`api/context.ts`):
```typescript
const user = await authenticateRequest(req.headers);
// throws Errors.forbidden() if cookie missing/invalid/user not found
```

---

## Environment Variables

Copy `.env.example` → `.env`:

```bash
DATABASE_URL=mysql://user:pass@localhost:3306/kimiagent

KIMI_APP_ID=your_app_id
KIMI_APP_SECRET=your_app_secret
KIMI_AUTH_URL=https://auth.moonshot.cn      # Kimi OAuth server
KIMI_OPEN_URL=https://api.moonshot.cn       # Kimi Open API

AWS_ACCESS_KEY_ID=…
AWS_SECRET_ACCESS_KEY=…
AWS_REGION=us-east-1
AWS_BUCKET=your-bucket
```

---

## Adding a shadcn Component

All 40+ components are pre-installed in `src/components/ui/`. Import directly:

```typescript
import { Button } from "@/components/ui/button";
import { Card, CardHeader, CardTitle, CardContent } from "@/components/ui/card";
import { Input } from "@/components/ui/input";
import { Form, FormField, FormItem, FormLabel } from "@/components/ui/form";
import { Dialog, DialogContent, DialogHeader } from "@/components/ui/dialog";
import { DataTable } from "@/components/ui/table";
import { toast } from "sonner";
```

Full list: `accordion, alert-dialog, alert, avatar, badge, breadcrumb,
button-group, button, calendar, card, carousel, chart, checkbox,
collapsible, command, context-menu, dialog, drawer, dropdown-menu,
empty, field, form, hover-card, input-group, input-otp, input, item,
kbd, label, menubar, navigation-menu, pagination, popover, progress,
radio-group, resizable, scroll-area, select, separator, sheet, sidebar,
skeleton, slider, sonner, spinner, switch, table, tabs, textarea,
toggle-group, toggle, tooltip`

---

## Frontend Auth Pattern

```typescript
// hooks/useAuth.ts already handles this:
const { data: user, isLoading } = trpc.auth.me.useQuery(undefined, {
  retry: false,
});
const isAuthenticated = !!user;

// Logout
const utils = trpc.useUtils();
const logout = trpc.auth.logout.useMutation({
  onSuccess: () => utils.auth.me.invalidate(),
});
```

`AuthLayout.tsx` wraps pages that require auth — redirects to `/login` if unauthenticated.

---

## S3 File Upload Pattern

```typescript
// api: generate presigned upload URL
import { S3Client, PutObjectCommand } from "@aws-sdk/client-s3";
import { getSignedUrl } from "@aws-sdk/s3-request-presigner";

const s3 = new S3Client({ region: env.awsRegion });

export async function getUploadUrl(key: string, contentType: string) {
  return getSignedUrl(
    s3,
    new PutObjectCommand({ Bucket: env.awsBucket, Key: key, ContentType: contentType }),
    { expiresIn: 300 }
  );
}
```

Add to a tRPC router as an `authedQuery.mutation` that returns `{ url, key }`.
Client PUTs directly to S3 with the presigned URL.

---

## Conventions

- **`publicQuery`** — unauthenticated tRPC procedures
- **`authedQuery`** — procedures that call `authenticateRequest` via context; access `opts.ctx.user`
- **`contracts/`** — only pure constants/types, no runtime deps; imported by both `api/` and `src/`
- **FK columns** referencing `serial()` PKs must use `bigint("col", { mode: "number", unsigned: true })`
- **Cookie options** — always via `getSessionCookieOptions(headers)` to inherit `Secure` / `SameSite` from the request origin
