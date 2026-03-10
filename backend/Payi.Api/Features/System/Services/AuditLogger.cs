using System.Text.Json;

namespace Payi.Api.Features.System.Services;

/// <summary>
/// Append-only audit logger that records security-sensitive events
/// (authentication, payments, wallet mutations) to a JSON-lines file.
/// Thread-safe via semaphore; designed for compliance and forensic review.
/// </summary>
public sealed class AuditLogger : IAuditLogger
{
    private static readonly JsonSerializerOptions JsonOptions = new()
    {
        PropertyNamingPolicy = JsonNamingPolicy.CamelCase,
        WriteIndented = false
    };

    private readonly string _filePath;
    private readonly SemaphoreSlim _gate = new(1, 1);

    public AuditLogger(IHostEnvironment environment)
    {
        var dataDirectory = Path.Combine(environment.ContentRootPath, "Data");
        Directory.CreateDirectory(dataDirectory);
        _filePath = Path.Combine(dataDirectory, "audit.jsonl");
    }

    public async Task LogAsync(AuditEntry entry, CancellationToken cancellationToken = default)
    {
        var line = JsonSerializer.Serialize(entry, JsonOptions);

        await _gate.WaitAsync(cancellationToken);
        try
        {
            await File.AppendAllTextAsync(_filePath, line + Environment.NewLine, cancellationToken);
        }
        finally
        {
            _gate.Release();
        }
    }
}

public interface IAuditLogger
{
    Task LogAsync(AuditEntry entry, CancellationToken cancellationToken = default);
}

public sealed record AuditEntry
{
    public DateTimeOffset Timestamp { get; init; } = DateTimeOffset.UtcNow;
    public required string Event { get; init; }
    public required string Actor { get; init; }
    public string? Target { get; init; }
    public string? Detail { get; init; }
    public string? IpAddress { get; init; }
    public bool Success { get; init; } = true;
}
