# ── Stage 1: Build ──
FROM mcr.microsoft.com/dotnet/sdk:9.0 AS build
WORKDIR /src

# Copy project file and restore dependencies first (layer caching)
COPY backend/Payi.Api/Payi.Api.csproj backend/Payi.Api/
RUN dotnet restore backend/Payi.Api/Payi.Api.csproj

# Copy the rest of the backend source and publish
COPY backend/ backend/
RUN dotnet publish backend/Payi.Api/Payi.Api.csproj \
    -c Release \
    -o /app/publish \
    --no-restore

# ── Stage 2: Runtime ──
FROM mcr.microsoft.com/dotnet/aspnet:9.0 AS runtime

# Install curl for health checks
RUN apt-get update && apt-get install -y --no-install-recommends curl && rm -rf /var/lib/apt/lists/*

# Create non-root user for security
RUN groupadd -r payi && useradd -r -g payi -s /sbin/nologin payi

# The .NET app resolves frontend via: Path.Combine(ContentRootPath, "..", "..")
# ContentRootPath = the directory of the DLL = /app/backend/Payi.Api
# So frontendRoot = /app/backend/Payi.Api/../../ = /app
# We must mirror this layout in the container.

# Copy published backend to match the expected path
WORKDIR /app/backend/Payi.Api
COPY --from=build /app/publish .

# Copy frontend static files to /app (the resolved frontendRoot)
WORKDIR /app
COPY index.html .
COPY auth.html .
COPY dashboard.html .
COPY about.html .
COPY how-it-works.html .
COPY transparency.html .
COPY src/ src/

# Create Data directory for JSON file storage
RUN mkdir -p /app/backend/Payi.Api/Data && \
    chown -R payi:payi /app

# Expose port 8080 (AWS default for containers)
ENV ASPNETCORE_URLS=http://+:8080
ENV ASPNETCORE_ENVIRONMENT=Production
EXPOSE 8080

# Health check
HEALTHCHECK --interval=30s --timeout=5s --start-period=10s --retries=3 \
    CMD curl -f http://localhost:8080/api/system/health || exit 1

USER payi
WORKDIR /app/backend/Payi.Api
ENTRYPOINT ["dotnet", "Payi.Api.dll"]
