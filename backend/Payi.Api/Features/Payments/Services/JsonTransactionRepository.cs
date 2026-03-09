using Microsoft.Extensions.Caching.Memory;
using System.Text.Json;
using Payi.Api.Features.Payments.Domain;

namespace Payi.Api.Features.Payments.Services;

public sealed class JsonTransactionRepository : ITransactionRepository
{
    private static readonly JsonSerializerOptions JsonOptions = new()
    {
        PropertyNamingPolicy = JsonNamingPolicy.CamelCase,
        WriteIndented = true
    };

    private readonly string _filePath;
    private readonly IMemoryCache _cache;
    private readonly MemoryCacheEntryOptions _cacheOptions = new()
    {
        AbsoluteExpirationRelativeToNow = TimeSpan.FromMinutes(5)
    };
    private readonly SemaphoreSlim _gate = new(1, 1);
    private const string CacheKey = "payments:transactions:all:v1";

    public JsonTransactionRepository(IHostEnvironment environment, IMemoryCache cache)
    {
        var dataDirectory = Path.Combine(environment.ContentRootPath, "Data");
        Directory.CreateDirectory(dataDirectory);
        _filePath = Path.Combine(dataDirectory, "transactions.json");
        _cache = cache;
    }

    public async Task<IReadOnlyCollection<PaymentTransaction>> GetByUserEmailAsync(string userEmail, CancellationToken cancellationToken)
    {
        var all = await ReadAllAsync(cancellationToken);
        return all
            .Where(tx => string.Equals(tx.UserEmail, userEmail, StringComparison.OrdinalIgnoreCase))
            .OrderByDescending(tx => tx.CreatedAtUtc)
            .ToArray();
    }

    public async Task<PaymentTransaction> AddAsync(PaymentTransaction transaction, CancellationToken cancellationToken)
    {
        await _gate.WaitAsync(cancellationToken);

        try
        {
            var all = await ReadAllNoLockAsync(cancellationToken);
            all.Add(transaction);
            await WriteAllNoLockAsync(all, cancellationToken);
            _cache.Set(CacheKey, all.ToArray(), _cacheOptions);
            return transaction;
        }
        finally
        {
            _gate.Release();
        }
    }

    private async Task<List<PaymentTransaction>> ReadAllAsync(CancellationToken cancellationToken)
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

    private async Task<List<PaymentTransaction>> ReadAllNoLockAsync(CancellationToken cancellationToken)
    {
        if (_cache.TryGetValue(CacheKey, out PaymentTransaction[]? cached) && cached is not null)
        {
            return [.. cached];
        }

        if (!File.Exists(_filePath))
        {
            _cache.Set(CacheKey, Array.Empty<PaymentTransaction>(), _cacheOptions);
            return [];
        }

        await using var stream = File.OpenRead(_filePath);
        var records = await JsonSerializer.DeserializeAsync<List<PaymentTransaction>>(stream, JsonOptions, cancellationToken);
        var normalized = records ?? [];
        _cache.Set(CacheKey, normalized.ToArray(), _cacheOptions);
        return normalized;
    }

    private async Task WriteAllNoLockAsync(List<PaymentTransaction> records, CancellationToken cancellationToken)
    {
        await using var stream = File.Create(_filePath);
        await JsonSerializer.SerializeAsync(stream, records, JsonOptions, cancellationToken);
    }
}
