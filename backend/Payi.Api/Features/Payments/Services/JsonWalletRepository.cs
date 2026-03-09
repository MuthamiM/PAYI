using Microsoft.Extensions.Caching.Memory;
using System.Text.Json;
using Payi.Api.Features.Payments.Domain;

namespace Payi.Api.Features.Payments.Services;

public sealed class JsonWalletRepository : IWalletRepository
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
    private const string CacheKey = "payments:wallets:all:v1";

    public JsonWalletRepository(IHostEnvironment environment, IMemoryCache cache)
    {
        var dataDirectory = Path.Combine(environment.ContentRootPath, "Data");
        Directory.CreateDirectory(dataDirectory);
        _filePath = Path.Combine(dataDirectory, "wallets.json");
        _cache = cache;
    }

    public async Task<WalletAccount> GetOrCreateAsync(string userEmail, CancellationToken cancellationToken)
    {
        await _gate.WaitAsync(cancellationToken);

        try
        {
            var wallets = await ReadAllNoLockAsync(cancellationToken);
            var account = GetOrCreateInternal(wallets, NormalizeEmail(userEmail));
            await WriteAllNoLockAsync(wallets, cancellationToken);
            SetCachedWallets(wallets);
            return Clone(account);
        }
        finally
        {
            _gate.Release();
        }
    }

    public Task<WalletMutationResult> CreditAsync(string userEmail, string currency, decimal amount, CancellationToken cancellationToken)
    {
        return ApplyDeltaAsync(userEmail, currency, amount, allowNegative: false, cancellationToken);
    }

    public Task<WalletMutationResult> DebitAsync(string userEmail, string currency, decimal amount, CancellationToken cancellationToken)
    {
        return ApplyDeltaAsync(userEmail, currency, -amount, allowNegative: false, cancellationToken);
    }

    public async Task<WalletMutationResult> SetBalanceAsync(string userEmail, string currency, decimal amount, CancellationToken cancellationToken)
    {
        if (amount < 0)
        {
            throw new ArgumentOutOfRangeException(nameof(amount), "Wallet balance cannot be negative.");
        }

        await _gate.WaitAsync(cancellationToken);

        try
        {
            var wallets = await ReadAllNoLockAsync(cancellationToken);
            var normalizedEmail = NormalizeEmail(userEmail);
            var normalizedCurrency = NormalizeCurrency(currency);
            var account = GetOrCreateInternal(wallets, normalizedEmail);
            account.Balances[normalizedCurrency] = decimal.Round(amount, 2);
            account.UpdatedAtUtc = DateTimeOffset.UtcNow;
            await WriteAllNoLockAsync(wallets, cancellationToken);
            SetCachedWallets(wallets);

            return new WalletMutationResult(
                true,
                $"Wallet balance set to {amount:0.00} {normalizedCurrency}.",
                Clone(account),
                normalizedCurrency,
                account.Balances[normalizedCurrency]);
        }
        finally
        {
            _gate.Release();
        }
    }

    private async Task<WalletMutationResult> ApplyDeltaAsync(
        string userEmail,
        string currency,
        decimal delta,
        bool allowNegative,
        CancellationToken cancellationToken)
    {
        if (delta == 0)
        {
            throw new ArgumentOutOfRangeException(nameof(delta), "Wallet delta cannot be zero.");
        }

        await _gate.WaitAsync(cancellationToken);

        try
        {
            var wallets = await ReadAllNoLockAsync(cancellationToken);
            var normalizedEmail = NormalizeEmail(userEmail);
            var normalizedCurrency = NormalizeCurrency(currency);
            var account = GetOrCreateInternal(wallets, normalizedEmail);

            if (!account.Balances.TryGetValue(normalizedCurrency, out var current))
            {
                current = 0m;
            }

            var next = decimal.Round(current + delta, 2);
            if (next < 0 && !allowNegative)
            {
                return new WalletMutationResult(
                    false,
                    $"Insufficient wallet balance. Current: {current:0.00} {normalizedCurrency}.",
                    Clone(account),
                    normalizedCurrency,
                    current);
            }

            account.Balances[normalizedCurrency] = next;
            account.UpdatedAtUtc = DateTimeOffset.UtcNow;
            await WriteAllNoLockAsync(wallets, cancellationToken);
            SetCachedWallets(wallets);

            var direction = delta > 0 ? "credited" : "debited";
            return new WalletMutationResult(
                true,
                $"Wallet {direction} successfully.",
                Clone(account),
                normalizedCurrency,
                next);
        }
        finally
        {
            _gate.Release();
        }
    }

    private async Task<List<WalletAccount>> ReadAllNoLockAsync(CancellationToken cancellationToken)
    {
        if (_cache.TryGetValue(CacheKey, out List<WalletAccount>? cached) && cached is not null)
        {
            return CloneWallets(cached);
        }

        if (!File.Exists(_filePath))
        {
            _cache.Set(CacheKey, new List<WalletAccount>(), _cacheOptions);
            return [];
        }

        await using var stream = File.OpenRead(_filePath);
        var wallets = await JsonSerializer.DeserializeAsync<List<WalletAccount>>(stream, JsonOptions, cancellationToken);
        var normalized = wallets ?? [];
        SetCachedWallets(normalized);
        return normalized;
    }

    private async Task WriteAllNoLockAsync(List<WalletAccount> wallets, CancellationToken cancellationToken)
    {
        await using var stream = File.Create(_filePath);
        await JsonSerializer.SerializeAsync(stream, wallets, JsonOptions, cancellationToken);
    }

    private static WalletAccount GetOrCreateInternal(List<WalletAccount> wallets, string normalizedEmail)
    {
        var existing = wallets.FirstOrDefault(w =>
            string.Equals(w.UserEmail, normalizedEmail, StringComparison.OrdinalIgnoreCase));

        if (existing is not null)
        {
            if (existing.Balances is null)
            {
                existing.Balances = new Dictionary<string, decimal>(StringComparer.OrdinalIgnoreCase);
            }

            NormalizeBalances(existing);
            return existing;
        }

        var created = new WalletAccount
        {
            UserEmail = normalizedEmail,
            Balances = new Dictionary<string, decimal>(StringComparer.OrdinalIgnoreCase),
            UpdatedAtUtc = DateTimeOffset.UtcNow
        };

        NormalizeBalances(created);
        wallets.Add(created);
        return created;
    }

    private static WalletAccount Clone(WalletAccount account)
    {
        return new WalletAccount
        {
            UserEmail = account.UserEmail,
            Balances = new Dictionary<string, decimal>(account.Balances, StringComparer.OrdinalIgnoreCase),
            UpdatedAtUtc = account.UpdatedAtUtc
        };
    }

    private void SetCachedWallets(List<WalletAccount> wallets)
    {
        _cache.Set(CacheKey, CloneWallets(wallets), _cacheOptions);
    }

    private static List<WalletAccount> CloneWallets(List<WalletAccount> wallets)
    {
        return [.. wallets.Select(Clone)];
    }

    private static string NormalizeEmail(string email) => email.Trim().ToLowerInvariant();

    private static string NormalizeCurrency(string currency)
    {
        var normalized = currency.Trim().ToUpperInvariant();
        return normalized switch
        {
            "KSH" => "KES",
            _ => normalized
        };
    }

    private static void NormalizeBalances(WalletAccount account)
    {
        var normalized = new Dictionary<string, decimal>(StringComparer.OrdinalIgnoreCase);

        foreach (var pair in account.Balances)
        {
            var key = NormalizeCurrency(pair.Key);
            if (normalized.TryGetValue(key, out var existing))
            {
                normalized[key] = decimal.Round(existing + pair.Value, 2);
                continue;
            }

            normalized[key] = decimal.Round(pair.Value, 2);
        }

        account.Balances = normalized;
    }
}
