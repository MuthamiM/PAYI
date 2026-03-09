# PAYI

PAYI is a cross-border payments platform prototype focused on Africa, Asia, and the Middle East.

It includes:
- A SaaS-style landing page and multi-page web frontend
- Login and registration flow
- Merchant dashboard for send/receive, notifications, wallet, and QR payments
- C# backend API with feature-first architecture
- Swagger API docs

## Tech Stack

- Frontend: Vanilla JavaScript, HTML, CSS
- Backend: .NET 9 Minimal API (C#)
- API docs: Swagger (Swashbuckle)

## Project Structure

- `src/` frontend app source
- `backend/Payi.Api/` backend API source
- `index.html`, `auth.html`, `dashboard.html`, `about.html`, `how-it-works.html`, `transparency.html` page entry files

## Run Locally

1. Start backend:

```powershell
cd backend/Payi.Api
dotnet run --urls http://0.0.0.0:5088
```

2. Open app:

- `http://localhost:5088/index.html`
- `http://localhost:5088/auth.html`
- `http://localhost:5088/dashboard.html`

3. Open Swagger:

- `http://localhost:5088/swagger`

## Security and Repository Hygiene

- Runtime/build artifacts are ignored (`bin/`, `obj/`, logs).
- Local transaction/user runtime data is ignored (`backend/Payi.Api/Data/`).
- This repository should not contain production secrets, access tokens, or personal credential dumps.

If you need environment-specific values, use local-only files and keep them out of version control.
