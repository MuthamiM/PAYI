using Payi.Api.Features.System.Services;

namespace Payi.Api.Features.System.Endpoints;

public static class SystemEndpoints
{
    public static void Map(IEndpointRouteBuilder app)
    {
        app.MapGet("/api/system/health", GetHealth)
            .WithTags("System")
            .WithName("HealthCheck")
            .WithSummary("Health check")
            .WithDescription("Returns service health, runtime uptime, and environment metadata.")
            .Produces(StatusCodes.Status200OK);
    }

    private static IResult GetHealth(RuntimeMetadata runtimeMetadata, IHostEnvironment environment)
    {
        var now = DateTimeOffset.UtcNow;
        return Results.Ok(new
        {
            status = "Healthy",
            environment = environment.EnvironmentName,
            startedAtUtc = runtimeMetadata.StartedAtUtc,
            uptimeSeconds = (long)(now - runtimeMetadata.StartedAtUtc).TotalSeconds,
            serverTimeUtc = now,
            latestVersion = "1.1.0",
            updateUrl = "https://github.com/MuthamiM/PAYI/releases/tag/v1.1.0-aws"
        });
    }
}
