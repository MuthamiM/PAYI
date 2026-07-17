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

---

## Deploy to AWS

### Prerequisites

- [AWS CLI v2](https://aws.amazon.com/cli/) installed and configured (`aws configure`)
- [Docker Desktop](https://www.docker.com/products/docker-desktop/) installed and running
- An AWS account with permissions for ECR, ECS, ELB, IAM, SSM, CloudWatch

### One-Command Deploy

```powershell
.\deploy\aws-deploy.ps1
```

This script automatically:
1. Creates an ECR repository and pushes the Docker image
2. Creates an ECS Fargate cluster with an Application Load Balancer
3. Stores secrets in AWS SSM Parameter Store
4. Outputs the public URL when done

### Options

```powershell
# Deploy to a specific region
.\deploy\aws-deploy.ps1 -Region eu-west-1

# Skip Docker build (re-deploy existing image)
.\deploy\aws-deploy.ps1 -SkipBuild

# Use a specific VPC
.\deploy\aws-deploy.ps1 -VpcId vpc-0123456789abcdef0
```

### After Deployment

1. **Set secrets** (if not already set):
   ```powershell
   aws ssm put-parameter --name '/payi/jwt-signing-key' --value 'YOUR_STRONG_KEY_HERE' --type SecureString
   aws ssm put-parameter --name '/payi/stripe-secret-key' --value 'sk_live_...' --type SecureString
   aws ssm put-parameter --name '/payi/stripe-publishable-key' --value 'pk_live_...' --type SecureString
   ```

2. **Update mobile app** for production:
   ```powershell
   flutter build apk --dart-define=PAYI_API_BASE_URL=http://YOUR-ALB-DNS.amazonaws.com/api
   ```

### Architecture

```
Internet → ALB (HTTP:80) → ECS Fargate (.NET 9 container, port 8080)
                                ├── /api/*       → REST API endpoints
                                ├── /swagger     → API documentation
                                └── /*           → Static frontend files
```
