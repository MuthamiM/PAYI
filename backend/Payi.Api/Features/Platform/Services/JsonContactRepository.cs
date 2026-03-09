using System.Text.Json;

namespace Payi.Api.Features.Platform.Services;

public sealed class JsonContactRepository : IContactRepository
{
    private static readonly JsonSerializerOptions JsonOptions = new()
    {
        PropertyNamingPolicy = JsonNamingPolicy.CamelCase,
        WriteIndented = true
    };

    private readonly string _filePath;
    private readonly SemaphoreSlim _gate = new(1, 1);

    public JsonContactRepository(IHostEnvironment environment)
    {
        var dataDirectory = Path.Combine(environment.ContentRootPath, "Data");
        Directory.CreateDirectory(dataDirectory);
        _filePath = Path.Combine(dataDirectory, "contact-messages.json");
    }

    public async Task<ContactMessage> AddAsync(ContactMessage message, CancellationToken cancellationToken)
    {
        await _gate.WaitAsync(cancellationToken);

        try
        {
            var current = await ReadAllNoLockAsync(cancellationToken);
            current.Add(message);
            await using var stream = File.Create(_filePath);
            await JsonSerializer.SerializeAsync(stream, current, JsonOptions, cancellationToken);
            return message;
        }
        finally
        {
            _gate.Release();
        }
    }

    private async Task<List<ContactMessage>> ReadAllNoLockAsync(CancellationToken cancellationToken)
    {
        if (!File.Exists(_filePath))
        {
            return [];
        }

        await using var stream = File.OpenRead(_filePath);
        var messages = await JsonSerializer.DeserializeAsync<List<ContactMessage>>(stream, JsonOptions, cancellationToken);
        return messages ?? [];
    }
}
