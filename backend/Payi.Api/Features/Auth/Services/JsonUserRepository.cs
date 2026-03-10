using System.Text.Json;
using Payi.Api.Features.Auth.Domain;

namespace Payi.Api.Features.Auth.Services;

public sealed class JsonUserRepository : IUserRepository
{
    private static readonly JsonSerializerOptions JsonOptions = new()
    {
        PropertyNamingPolicy = JsonNamingPolicy.CamelCase,
        WriteIndented = true
    };

    private readonly string _filePath;
    private readonly SemaphoreSlim _gate = new(1, 1);

    public JsonUserRepository(IHostEnvironment environment)
    {
        var dataDirectory = Path.Combine(environment.ContentRootPath, "Data");
        Directory.CreateDirectory(dataDirectory);
        _filePath = Path.Combine(dataDirectory, "users.json");
    }

    public async Task<AppUser?> GetByEmailAsync(string email, CancellationToken cancellationToken)
    {
        var users = await ReadAllInternalAsync(cancellationToken);
        return users.FirstOrDefault(user => string.Equals(user.Email, email, StringComparison.OrdinalIgnoreCase));
    }

    public async Task<AppUser?> GetByIdAsync(Guid id, CancellationToken cancellationToken)
    {
        var users = await ReadAllInternalAsync(cancellationToken);
        return users.FirstOrDefault(user => user.Id == id);
    }

    public async Task<AppUser?> GetByClerkIdAsync(string clerkId, CancellationToken cancellationToken)
    {
        if (string.IsNullOrWhiteSpace(clerkId)) return null;
        var users = await ReadAllInternalAsync(cancellationToken);
        return users.FirstOrDefault(user => string.Equals(user.ClerkId, clerkId, StringComparison.OrdinalIgnoreCase));
    }

    public async Task<IReadOnlyCollection<AppUser>> GetAllAsync(CancellationToken cancellationToken)
    {
        return await ReadAllInternalAsync(cancellationToken);
    }

    public async Task<AppUser> AddAsync(AppUser user, CancellationToken cancellationToken)
    {
        await _gate.WaitAsync(cancellationToken);

        try
        {
            var users = await ReadAllNoLockAsync(cancellationToken);
            users.Add(user);
            await WriteAllNoLockAsync(users, cancellationToken);
            return user;
        }
        finally
        {
            _gate.Release();
        }
    }

    public async Task UpdateAsync(AppUser user, CancellationToken cancellationToken)
    {
        await _gate.WaitAsync(cancellationToken);

        try
        {
            var users = await ReadAllNoLockAsync(cancellationToken);
            var index = users.FindIndex(u => u.Id == user.Id);
            if (index >= 0)
            {
                users[index] = user;
                await WriteAllNoLockAsync(users, cancellationToken);
            }
        }
        finally
        {
            _gate.Release();
        }
    }

    private async Task<List<AppUser>> ReadAllInternalAsync(CancellationToken cancellationToken)
    {
        await _gate.WaitAsync(cancellationToken);

        try
        {
            return await ReadAllNoLockAsync(cancellationToken);
        }
        finally
        {
            _gate.Release();
        }
    }

    private async Task<List<AppUser>> ReadAllNoLockAsync(CancellationToken cancellationToken)
    {
        if (!File.Exists(_filePath))
        {
            return [];
        }

        await using var stream = File.OpenRead(_filePath);
        var users = await JsonSerializer.DeserializeAsync<List<AppUser>>(stream, JsonOptions, cancellationToken);
        return users ?? [];
    }

    private async Task WriteAllNoLockAsync(List<AppUser> users, CancellationToken cancellationToken)
    {
        await using var stream = File.Create(_filePath);
        await JsonSerializer.SerializeAsync(stream, users, JsonOptions, cancellationToken);
    }
}
