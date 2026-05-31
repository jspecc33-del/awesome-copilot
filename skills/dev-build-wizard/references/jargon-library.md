# Jargon Library — Plain-English Dropdown Descriptions

This file contains pre-written plain-English descriptions for every dropdown option
in the planning widget. Use these verbatim in the side panel when an option is selected.

Format per entry:
- **What it is** (1-2 sentences, zero jargon)
- **Best for** (1 sentence)
- **Not great for** (1 sentence)
- **Real-world analogy** (everyday comparison)

---

## Project Type

### Web App
- **What it is:** A program that runs in a browser — people visit a web address and use it there. No download required.
- **Best for:** Things lots of people need to access from any device.
- **Not great for:** Tasks that need heavy local hardware (like video editing or 3D rendering).
- **Analogy:** Like a shop you visit — the shop is on a street (a server), you just walk in (open a browser).

### Desktop App
- **What it is:** A program you download and install on a computer. Runs on your machine, not in a browser.
- **Best for:** Tools that need to work offline, access local files, or use a lot of computing power.
- **Not great for:** Sharing with lots of people or updating automatically.
- **Analogy:** Like software you buy in a box — installed on your machine, stays there.

### CLI Tool
- **What it is:** A program you control by typing commands into the terminal (the black text window). No graphical buttons.
- **Best for:** Repetitive tasks, automation, developer tools, and scripts that run in the background.
- **Not great for:** Tools that non-technical people need to use easily.
- **Analogy:** Like a remote control with only buttons and no screen — fast once you know what to press.

### REST API
- **What it is:** A backend service that other programs can talk to. It listens for requests and sends back data.
- **Best for:** When you want to build the "engine" that powers other apps (mobile app, website, scripts).
- **Not great for:** If you need a visual interface — this is data only.
- **Analogy:** Like a restaurant kitchen — apps place orders (requests), the API prepares and sends back the food (data).

### Mobile App
- **What it is:** An app for phones or tablets — typically built for iOS (iPhone) or Android.
- **Best for:** Tools people need on the go, with access to phone features like camera, GPS, or notifications.
- **Not great for:** Heavy data processing or things people typically do at a desk.
- **Analogy:** Like the apps on your phone — installed, runs offline, uses phone hardware.

### Library / Package
- **What it is:** A bundle of reusable code that other developers add to their own projects.
- **Best for:** If you've built something useful that others want to use in their code.
- **Not great for:** End-user products — libraries have no interface of their own.
- **Analogy:** Like a power tool that builders use — it does one thing well and gets included in other people's projects.

---

## Primary Language

### Python
- **What it is:** A beginner-friendly, readable language popular for web backends, data science, automation, and AI.
- **Best for:** Scripts, APIs, data processing, machine learning, and rapid prototyping.
- **Not great for:** Mobile apps, high-performance games, or anything needing maximum speed.
- **Analogy:** The Swiss Army knife of coding — does a lot of things reasonably well, very easy to read.

### JavaScript
- **What it is:** The language that runs in web browsers. Also runs on servers (with Node.js).
- **Best for:** Web frontends (what users see) and Node.js backends.
- **Not great for:** Anything needing strict type safety or very high performance.
- **Analogy:** The language of the web — if a webpage has moving parts, JavaScript is making them move.

### TypeScript
- **What it is:** JavaScript with extra rules that catch mistakes before you run the code.
- **Best for:** Larger teams and projects where catching bugs early saves time.
- **Not great for:** Quick scripts or solo projects where speed of writing matters more than safety.
- **Analogy:** Like JavaScript wearing a seatbelt — slightly slower to put on, but much safer.

### C#
- **What it is:** Microsoft's language, used for Windows apps, game development (Unity), and enterprise software.
- **Best for:** Windows desktop apps, game modding/development, enterprise APIs, .NET ecosystem.
- **Not great for:** Linux-first or lightweight tools (though .NET runs everywhere now).
- **Analogy:** A well-engineered machine — powerful, structured, and designed for serious work.

### Go
- **What it is:** Google's language. Fast, simple, and great for things that need to handle a lot of traffic.
- **Best for:** High-performance APIs, network tools, cloud services, and CLI tools.
- **Not great for:** Rapid prototyping or if you need a large library ecosystem.
- **Analogy:** A sports car — fast, efficient, designed for performance, but you don't cruise slowly in it.

### Rust
- **What it is:** A language designed for maximum performance and safety. The hardest to learn, but incredibly reliable.
- **Best for:** Systems programming, performance-critical tools, anything where crashes are unacceptable.
- **Not great for:** Beginners, quick projects, or anything time-sensitive to build.
- **Analogy:** A Formula 1 car — extraordinary when you know what you're doing, overwhelming otherwise.

### Kotlin
- **What it is:** The modern language for Android app development. Also works on the server.
- **Best for:** Android apps, and teams already in the Java ecosystem.
- **Not great for:** iOS apps (use Swift for that) or non-JVM environments.
- **Analogy:** Like Java's younger, better-designed sibling.

---

## Backend Framework

### FastAPI (Python)
- **What it is:** A Python tool for building APIs. Fast to write, fast to run, automatically creates documentation.
- **Best for:** APIs, data APIs, ML model serving, anything async.
- **Not great for:** Full web apps with server-rendered pages (use Django for that).
- **Analogy:** A fast-food counter — you say what you want, it gives you exactly that, very efficiently.

### Express (Node.js)
- **What it is:** The most popular Node.js web framework. Minimal, flexible, you add what you need.
- **Best for:** REST APIs, backends for React/Vue apps, rapid development.
- **Not great for:** Projects that need a lot of built-in features — you'll assemble them yourself.
- **Analogy:** A bare kitchen — great ingredients available, but you cook it yourself.

### Django (Python)
- **What it is:** A full-featured Python framework — includes database tools, user auth, admin panel, all built in.
- **Best for:** Content sites, apps with complex data models, teams that want batteries included.
- **Not great for:** Simple APIs or projects where you don't need all the built-in features.
- **Analogy:** A fully equipped restaurant — everything's there, you just open for business.

### ASP.NET (C#)
- **What it is:** Microsoft's web framework for building APIs and web apps in C#.
- **Best for:** Enterprise applications, Windows-heavy environments, teams already using Microsoft tools.
- **Not great for:** Lightweight or non-Microsoft stacks.
- **Analogy:** A Microsoft-built, enterprise-grade production line — reliable and deeply integrated.

### Gin (Go)
- **What it is:** A fast, lightweight web framework for Go. Great for high-performance APIs.
- **Best for:** High-traffic APIs, microservices, and any Go backend.
- **Not great for:** Teams new to Go.
- **Analogy:** A sports car chassis — minimal weight, maximum performance.

---

## Database

### PostgreSQL
- **What it is:** A powerful, full-featured relational database. Stores data in tables with rows and columns.
- **Best for:** Most web apps, anything with complex data relationships, production systems.
- **Not great for:** Super simple apps where you just need a file (SQLite is easier then).
- **Analogy:** A heavy-duty metal filing cabinet — organised, reliable, handles anything you throw at it.

### SQLite
- **What it is:** A database stored in a single file on disk. No separate server needed.
- **Best for:** Personal tools, desktop apps, small web apps, development and testing.
- **Not great for:** Multiple users writing data at the same time, or high-traffic production.
- **Analogy:** A folder on your desk — great for personal organisation, falls apart under office-wide use.

### MongoDB
- **What it is:** A "NoSQL" database that stores data as flexible documents (like JSON) instead of rigid tables.
- **Best for:** Apps where data structure varies a lot, content management, real-time apps.
- **Not great for:** Complex data relationships that would be natural in a table format.
- **Analogy:** A big box of sticky notes — flexible and fast to add to, but harder to cross-reference.

### Redis
- **What it is:** An in-memory database — stores data in RAM for extremely fast access. Usually used alongside a main database.
- **Best for:** Caching (saving results to reuse quickly), sessions, real-time features, queues.
- **Not great for:** Storing large amounts of permanent data.
- **Analogy:** Your desk surface — lightning fast to reach, but limited space, and it clears when you leave.

### Supabase
- **What it is:** A hosted service built on PostgreSQL. Gives you a database, auth, file storage, and real-time updates — all managed for you.
- **Best for:** Startups and solo developers who want a backend without managing servers.
- **Not great for:** Complex custom backends or teams that need full control.
- **Analogy:** A furnished apartment — everything's set up, you just move in. Less control than building your own house.

### Firebase
- **What it is:** Google's hosted backend service — database, auth, file storage, and hosting. Particularly strong for mobile.
- **Best for:** Mobile apps, real-time collaborative features, Google ecosystem projects.
- **Not great for:** Complex data queries or when you need to move away from Google later.
- **Analogy:** Google's version of a furnished apartment — very easy to start, but Google owns the building.

---

## Auth Strategy

### JWT (JSON Web Token)
- **What it is:** A secure token your app gives users when they log in. They carry it with every request to prove who they are.
- **Best for:** APIs, SPAs (single-page apps), mobile apps, stateless authentication.
- **Not great for:** Revoking access instantly (tokens work until they expire).
- **Analogy:** A wristband at a concert — the venue gives it to you at the door, you show it at each area.

### OAuth2
- **What it is:** "Login with Google/GitHub/Apple" — lets users use an existing account from another service.
- **Best for:** Apps where you don't want to manage passwords, or when social login reduces friction.
- **Not great for:** Apps that need fully isolated accounts or sensitive data that can't be linked to Google/etc.
- **Analogy:** Using your hotel key card to get into the gym — one card, multiple doors, hotel manages it.

### API Key
- **What it is:** A long random string that acts as a password for machine-to-machine access.
- **Best for:** APIs consumed by other developers or automated services (not end users).
- **Not great for:** User-facing login — it's too technical for normal users.
- **Analogy:** A staff access card for employees — useful for the team, not how customers get in.

### Session
- **What it is:** The server remembers who you are after login by storing a record. Your browser holds a cookie that points to it.
- **Best for:** Traditional web apps with server-rendered pages (like Django or Rails apps).
- **Not great for:** APIs consumed by mobile apps or external services.
- **Analogy:** A restaurant table number — the staff track your order by your table, you just show up.

---

## Package Manager

### pip / uv (Python)
- **What it is:** `pip` installs Python packages. `uv` is a faster, modern alternative. Both download and install code libraries.
- **Best for:** Any Python project.
- **Analogy:** The Python app store — you ask for what you need, it downloads and installs it.

### npm (Node.js)
- **What it is:** Node's package manager. The largest ecosystem of open-source packages in the world.
- **Best for:** JavaScript and TypeScript projects (frontend and backend).
- **Analogy:** The JavaScript app store — massive selection, installs with one command.

### yarn / pnpm (Node.js)
- **What it is:** Faster alternatives to npm. pnpm is especially efficient with disk space.
- **Best for:** Teams that ran into npm speed or reliability issues, or monorepos.
- **Analogy:** A faster checkout lane at the same store — same products, quicker process.

### cargo (Rust)
- **What it is:** Rust's built-in package manager and build tool. Handles everything.
- **Best for:** All Rust projects — it's the only choice and an excellent one.
- **Analogy:** The Rust toolbox — comes with the language, does everything you need.

### dotnet (C#)
- **What it is:** Microsoft's CLI tool that manages C# projects, packages (NuGet), and builds.
- **Best for:** All C#/.NET projects.
- **Analogy:** The Microsoft Swiss Army knife for .NET — one tool for everything.

---

## Deployment Target

### Local Only
- **What it is:** The project runs only on your own computer. Nobody else can access it.
- **Best for:** Personal tools, development, learning, and testing.
- **Analogy:** A home workshop — everything you build is for your own use.

### Docker
- **What it is:** Packages your app and all its dependencies into a portable container. Runs the same everywhere.
- **Best for:** Consistent deployment, teams with multiple environments, cloud deployment.
- **Analogy:** A shipping container — standardised, stackable, works on any dock worldwide.

### Vercel
- **What it is:** A hosting service designed for frontend apps and serverless backends. Deploy by pushing code.
- **Best for:** React/Next.js apps, static sites, serverless API routes.
- **Analogy:** A fully managed airport gate — you just show up with your luggage (code), they handle takeoff.

### Railway
- **What it is:** A simple cloud hosting service. Paste your repo URL, it figures out how to run it.
- **Best for:** Full-stack apps with databases, quick production deployments, small to medium traffic.
- **Analogy:** A self-driving courier — give it the package, it delivers itself.

### AWS / Azure
- **What it is:** Full-scale cloud platforms with every tool imaginable. Powerful but complex.
- **Best for:** Large applications, enterprise, when you need fine-grained control over infrastructure.
- **Not great for:** Small projects or solo developers (overwhelming and expensive to start).
- **Analogy:** A full industrial factory — endless capabilities, but you need engineers to run it.
