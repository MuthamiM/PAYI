using Microsoft.Extensions.FileProviders;
using Payi.Api.Features.Auth.Endpoints;
using Payi.Api.Features.Auth.Services;
using Payi.Api.Features.Payments.Endpoints;
using Payi.Api.Features.Payments.Services;
using Payi.Api.Features.Platform.Endpoints;
using Payi.Api.Features.Platform.Services;
using Payi.Api.Features.System.Endpoints;
using Payi.Api.Features.System.Services;

var builder = WebApplication.CreateBuilder(args);

builder.Services.AddEndpointsApiExplorer();
builder.Services.AddMemoryCache();
builder.Services.AddOutputCache(options =>
{
    options.AddPolicy("ShortApi", policy => policy.Expire(TimeSpan.FromSeconds(30)));
    options.AddPolicy("MediumApi", policy => policy.Expire(TimeSpan.FromMinutes(3)));
    options.AddPolicy("LongApi", policy => policy.Expire(TimeSpan.FromMinutes(10)));
});
builder.Services.AddCors(options =>
{
    options.AddPolicy("DevCors", policy =>
    {
        policy
            .AllowAnyOrigin()
            .AllowAnyMethod()
            .AllowAnyHeader();
    });
});
builder.Services.AddSwaggerGen(options =>
{
    options.SwaggerDoc("v1", new()
    {
        Title = "PAYI API",
        Version = "v1",
        Description = "Cross-border payment platform API for authentication, platform information, and trust controls."
    });
});

builder.Services.AddSingleton<IUserRepository, JsonUserRepository>();
builder.Services.AddSingleton<IPasswordService, Pbkdf2PasswordService>();
builder.Services.AddSingleton<ITokenService, SimpleTokenService>();
builder.Services.AddSingleton<ITransactionRepository, JsonTransactionRepository>();
builder.Services.AddSingleton<IWalletRepository, JsonWalletRepository>();
builder.Services.AddSingleton<IPaymentRequestRepository, JsonPaymentRequestRepository>();
builder.Services.AddSingleton<IContactRepository, JsonContactRepository>();
builder.Services.AddSingleton(new RuntimeMetadata(DateTimeOffset.UtcNow));

var app = builder.Build();

app.UseCors("DevCors");
app.UseOutputCache();

app.UseSwagger();
app.UseSwaggerUI(options =>
{
    options.DocumentTitle = "PAYI API Docs";
    options.SwaggerEndpoint("/swagger/v1/swagger.json", "PAYI API v1");
    options.RoutePrefix = "swagger";
});

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
