using System.Threading.RateLimiting;
using Microsoft.AspNetCore.RateLimiting;
using Microsoft.Extensions.FileProviders;
using Payi.Api.Features.Auth.Endpoints;
using Payi.Api.Features.Auth.Services;
using Payi.Api.Features.Payments.Endpoints;
using Payi.Api.Features.Payments.Services;
using Payi.Api.Features.Platform.Endpoints;
using Payi.Api.Features.Platform.Services;
using Payi.Api.Features.System.Endpoints;
using Payi.Api.Features.System.Services;

using Microsoft.AspNetCore.Authentication.JwtBearer;
using Microsoft.IdentityModel.Tokens;

var builder = WebApplication.CreateBuilder(args);

// --- Kestrel: restrict request body size (1 MB max for JSON-only API) ---
builder.WebHost.ConfigureKestrel(options =>
{
    options.Limits.MaxRequestBodySize = 1_048_576;
});

builder.Services.AddEndpointsApiExplorer();
builder.Services.AddMemoryCache();
builder.Services.AddOutputCache(options =>
{
    options.AddPolicy("ShortApi", policy => policy.Expire(TimeSpan.FromSeconds(30)));
    options.AddPolicy("MediumApi", policy => policy.Expire(TimeSpan.FromMinutes(3)));
    options.AddPolicy("LongApi", policy => policy.Expire(TimeSpan.FromMinutes(10)));
});

// --- Clerk JWT Authentication ---
var clerkAuthority = builder.Configuration["Clerk:Authority"];
if (string.IsNullOrEmpty(clerkAuthority))
{
    throw new InvalidOperationException("Clerk:Authority is missing in configuration.");
}

builder.Services.AddAuthentication(JwtBearerDefaults.AuthenticationScheme)
    .AddJwtBearer(options =>
    {
        options.Authority = clerkAuthority;
        options.TokenValidationParameters = new TokenValidationParameters
        {
            ValidateIssuer = true,
            ValidIssuer = clerkAuthority,
            ValidateAudience = false, // Clerk doesn't mandate audience for single-app setups by default
            ValidateLifetime = true,
            ClockSkew = TimeSpan.Zero
        };
    });

builder.Services.AddAuthorization();

// --- CORS: restrict to configured origins ---
var allowedOrigins = builder.Configuration.GetSection("Cors:AllowedOrigins").Get<string[]>()
                     ?? ["http://localhost:5088", "https://localhost:7064"];
builder.Services.AddCors(options =>
{
    options.AddPolicy("AppCors", policy =>
    {
        policy
            .WithOrigins(allowedOrigins)
            .WithMethods("GET", "POST", "OPTIONS")
            .AllowAnyHeader()
            .AllowCredentials();
    });
});

// --- Swagger (registered always, but UI conditionally) ---
builder.Services.AddSwaggerGen(options =>
{
    options.SwaggerDoc("v1", new()
    {
        Title = "PAYI API",
        Version = "v1",
        Description = "Cross-border payment platform API for authentication, platform information, and trust controls."
    });
});

// --- Rate limiting ---
builder.Services.AddRateLimiter(options =>
{
    options.RejectionStatusCode = StatusCodes.Status429TooManyRequests;

    options.AddFixedWindowLimiter("AuthRateLimit", limiter =>
    {
        limiter.PermitLimit = 5;
        limiter.Window = TimeSpan.FromSeconds(15);
        limiter.QueueProcessingOrder = QueueProcessingOrder.OldestFirst;
        limiter.QueueLimit = 0;
    });

    options.AddSlidingWindowLimiter("PaymentRateLimit", limiter =>
    {
        limiter.PermitLimit = 20;
        limiter.Window = TimeSpan.FromMinutes(1);
        limiter.SegmentsPerWindow = 4;
        limiter.QueueProcessingOrder = QueueProcessingOrder.OldestFirst;
        limiter.QueueLimit = 0;
    });

    options.AddFixedWindowLimiter("GeneralRateLimit", limiter =>
    {
        limiter.PermitLimit = 60;
        limiter.Window = TimeSpan.FromMinutes(1);
        limiter.QueueProcessingOrder = QueueProcessingOrder.OldestFirst;
        limiter.QueueLimit = 0;
    });
});

// --- Services ---
builder.Services.AddHttpClient("GeoIP");
builder.Services.AddSingleton<IUserRepository, JsonUserRepository>();
builder.Services.AddSingleton<IPasswordService, Pbkdf2PasswordService>();
builder.Services.AddSingleton<ITokenService, JwtTokenService>();
builder.Services.AddSingleton<ITransactionRepository, JsonTransactionRepository>();
builder.Services.AddSingleton<IWalletRepository, JsonWalletRepository>();
builder.Services.AddSingleton<IPaymentRequestRepository, JsonPaymentRequestRepository>();
builder.Services.AddSingleton<IContactRepository, JsonContactRepository>();
builder.Services.AddSingleton<IAuditLogger, AuditLogger>();
builder.Services.AddSingleton<LoginThrottleService>();
builder.Services.AddSingleton(new RuntimeMetadata(DateTimeOffset.UtcNow));

var app = builder.Build();

// --- Global Exception Handler to prevent stack trace leaks ---
if (!app.Environment.IsDevelopment())
{
    app.UseExceptionHandler(exceptionHandlerApp =>
    {
        exceptionHandlerApp.Run(async context =>
        {
            context.Response.StatusCode = StatusCodes.Status500InternalServerError;
            context.Response.ContentType = "application/problem+json";
            
            var problemDetails = new Microsoft.AspNetCore.Mvc.ProblemDetails
            {
                Status = StatusCodes.Status500InternalServerError,
                Title = "An unexpected error occurred.",
                Detail = "Please contact support if the issue persists."
            };
            
            await context.Response.WriteAsJsonAsync(problemDetails);
        });
    });
}

// --- Request Tracing & Security headers middleware ---
app.Use(async (context, next) =>
{
    var headers = context.Response.Headers;
    
    // Add request tracing ID
    headers["X-Request-ID"] = context.TraceIdentifier;
    
    headers["X-Content-Type-Options"] = "nosniff";
    headers["X-Frame-Options"] = "DENY";
    headers["Referrer-Policy"] = "strict-origin-when-cross-origin";
    headers["Permissions-Policy"] = "camera=(), microphone=(), geolocation=()";
    headers["Content-Security-Policy"] =
        "default-src 'self'; " +
        "script-src 'self' 'unsafe-inline' 'unsafe-eval' https://cdn.jsdelivr.net https://*.clerk.accounts.dev https://challenges.cloudflare.com; " +
        "style-src 'self' 'unsafe-inline' https://fonts.googleapis.com https://*.clerk.accounts.dev; " +
        "font-src 'self' https://fonts.gstatic.com; " +
        "img-src 'self' data: https://*.clerk.accounts.dev https://img.clerk.com; " +
        "connect-src 'self' https://*.clerk.accounts.dev https://challenges.cloudflare.com https://clerk-telemetry.com wss://*.clerk.accounts.dev; " +
        "frame-src 'self' https://*.clerk.accounts.dev https://challenges.cloudflare.com; " +
        "worker-src 'self' blob: https://*.clerk.accounts.dev https://challenges.cloudflare.com; " +
        "object-src 'none'; base-uri 'self'; form-action 'self';";
    headers["X-XSS-Protection"] = "1; mode=block";
    await next();
});

// --- HTTPS redirection (a no-op when not behind TLS, safe to keep) ---
if (!app.Environment.IsDevelopment())
{
    app.UseHsts();
}
app.UseHttpsRedirection();

// --- Geo-blocking (Must run before CORS/Auth)
app.UseGeoBlocking();

app.UseCors("AppCors");
app.UseAuthentication();
app.UseAuthorization();
app.UseRateLimiter();
app.UseOutputCache();

// --- Swagger: only in Development ---
if (app.Environment.IsDevelopment())
{
    app.UseSwagger();
    app.UseSwaggerUI(options =>
    {
        options.DocumentTitle = "PAYI API Docs";
        options.SwaggerEndpoint("/swagger/v1/swagger.json", "PAYI API v1");
        options.RoutePrefix = "swagger";
    });
}

AuthEndpoints.Map(app);
PaymentsEndpoints.Map(app);
PlatformEndpoints.Map(app);
SystemEndpoints.Map(app);

var frontendRoot = Path.GetFullPath(Path.Combine(app.Environment.ContentRootPath, "..", ".."));
var indexFile = Path.Combine(frontendRoot, "index.html");

if (File.Exists(indexFile))
{
    var staticProvider = new PhysicalFileProvider(frontendRoot);
    var defaultFilesOptions = new DefaultFilesOptions
    {
        FileProvider = staticProvider
    };

    defaultFilesOptions.DefaultFileNames.Clear();
    defaultFilesOptions.DefaultFileNames.Add("index.html");

    app.UseDefaultFiles(defaultFilesOptions);
    app.UseStaticFiles(new StaticFileOptions
    {
        FileProvider = staticProvider,
        OnPrepareResponse = context =>
        {
            var extension = Path.GetExtension(context.File.Name);

            if (string.Equals(extension, ".html", StringComparison.OrdinalIgnoreCase) ||
                string.Equals(extension, ".js", StringComparison.OrdinalIgnoreCase) ||
                string.Equals(extension, ".css", StringComparison.OrdinalIgnoreCase) ||
                string.Equals(extension, ".map", StringComparison.OrdinalIgnoreCase))
            {
                context.Context.Response.Headers.CacheControl = "no-store, no-cache, must-revalidate";
                return;
            }

            context.Context.Response.Headers.CacheControl = "public, max-age=86400";
        }
    });

    app.MapFallback(async context =>
    {
        if (context.Request.Path.StartsWithSegments("/api") || context.Request.Path.StartsWithSegments("/swagger"))
        {
            context.Response.StatusCode = StatusCodes.Status404NotFound;
            return;
        }

        context.Response.ContentType = "text/html; charset=utf-8";
        await context.Response.SendFileAsync(indexFile);
    });
}

app.Run();
