using Microsoft.Extensions.Caching.Memory;
using System.Text.Json;
using Payi.Api.Features.Payments.Domain;

namespace Payi.Api.Features.Payments.Services;

public sealed class JsonPaymentRequestRepository : IPaymentRequestRepository
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
    private const string CacheKey = "payments:requests:all:v1";

    public JsonPaymentRequestRepository(IHostEnvironment environment, IMemoryCache cache)
    {
        var dataDirectory = Path.Combine(environment.ContentRootPath, "Data");
        Directory.CreateDirectory(dataDirectory);
        _filePath = Path.Combine(dataDirectory, "payment-requests.json");
        _cache = cache;
    }

    public async Task<PaymentRequest> AddAsync(PaymentRequest request, CancellationToken cancellationToken)
    {
        await _gate.WaitAsync(cancellationToken);

        try
        {
            var all = await ReadAllNoLockAsync(cancellationToken);
            all.Add(request);
            await WriteAllNoLockAsync(all, cancellationToken);
            SetCachedRequests(all);
            return Clone(request);
        }
        finally
        {
            _gate.Release();
        }
    }

    public async Task<PaymentRequest?> GetByIdAsync(Guid id, CancellationToken cancellationToken)
    {
        await _gate.WaitAsync(cancellationToken);

        try
        {
            var all = await ReadAllNoLockAsync(cancellationToken);
            var request = all.FirstOrDefault(item => item.Id == id);
            return request is null ? null : Clone(request);
        }
        finally
        {
            _gate.Release();
        }
    }

    public async Task<IReadOnlyCollection<PaymentRequest>> GetByRecipientEmailAsync(string recipientEmail, CancellationToken cancellationToken)
    {
        await _gate.WaitAsync(cancellationToken);

        try
        {
            var all = await ReadAllNoLockAsync(cancellationToken);
            return all
                .Where(item => string.Equals(item.RecipientEmail, recipientEmail, StringComparison.OrdinalIgnoreCase))
                .OrderByDescending(item => item.CreatedAtUtc)
                .Select(Clone)
                .ToArray();
        }
        finally
        {
            _gate.Release();
        }
    }

    public async Task<IReadOnlyCollection<PaymentRequest>> GetByRequesterEmailAsync(string requesterEmail, CancellationToken cancellationToken)
    {
        await _gate.WaitAsync(cancellationToken);

        try
        {
            var all = await ReadAllNoLockAsync(cancellationToken);
            return all
                .Where(item => string.Equals(item.RequesterEmail, requesterEmail, StringComparison.OrdinalIgnoreCase))
                .OrderByDescending(item => item.CreatedAtUtc)
                .Select(Clone)
                .ToArray();
        }
        finally
        {
            _gate.Release();
        }
    }

    public async Task<PaymentRequest> UpdateAsync(PaymentRequest request, CancellationToken cancellationToken)
    {
        await _gate.WaitAsync(cancellationToken);

        try
        {
            var all = await ReadAllNoLockAsync(cancellationToken);
            var index = all.FindIndex(item => item.Id == request.Id);

            if (index < 0)
            {
                throw new KeyNotFoundException($"Payment request {request.Id} was not found.");
            }

            all[index] = request;
            await WriteAllNoLockAsync(all, cancellationToken);
            SetCachedRequests(all);
            return Clone(request);
        }
        finally
        {
            _gate.Release();
        }
    }

    private async Task<List<PaymentRequest>> ReadAllNoLockAsync(CancellationToken cancellationToken)
    {
        if (_cache.TryGetValue(CacheKey, out List<PaymentRequest>? cached) && cached is not null)
        {
            return CloneRequests(cached);
        }

        if (!File.Exists(_filePath))
        {
            _cache.Set(CacheKey, new List<PaymentRequest>(), _cacheOptions);
            return [];
        }

        await using var stream = File.OpenRead(_filePath);
        var requests = await JsonSerializer.DeserializeAsync<List<PaymentRequest>>(stream, JsonOptions, cancellationToken);
        var normalized = requests ?? [];
        SetCachedRequests(normalized);
        return normalized;
    }

    private async Task WriteAllNoLockAsync(List<PaymentRequest> requests, CancellationToken cancellationToken)
    {
        await using var stream = File.Create(_filePath);
        await JsonSerializer.SerializeAsync(stream, requests, JsonOptions, cancellationToken);
    }

    private void SetCachedRequests(List<PaymentRequest> requests)
    {
        _cache.Set(CacheKey, CloneRequests(requests), _cacheOptions);
    }

    private static List<PaymentRequest> CloneRequests(List<PaymentRequest> requests)
    {
        return [.. requests.Select(Clone)];
    }

    private static PaymentRequest Clone(PaymentRequest request)
    {
        return new PaymentRequest
        {
            Id = request.Id,
            Reference = request.Reference,
            RequesterEmail = request.RequesterEmail,
            RequesterName = request.RequesterName,
            RecipientEmail = request.RecipientEmail,
            RecipientName = request.RecipientName,
            Amount = request.Amount,
            Currency = request.Currency,
            Country = request.Country,
            Note = request.Note,
            Status = request.Status,
            CreatedAtUtc = request.CreatedAtUtc,
            UpdatedAtUtc = request.UpdatedAtUtc,
            SettlementReference = request.SettlementReference
        };
    }
}
