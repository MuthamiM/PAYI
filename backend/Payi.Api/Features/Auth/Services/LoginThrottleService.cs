using Microsoft.Extensions.Caching.Memory;

namespace Payi.Api.Features.Auth.Services;

/// <summary>
/// Tracks failed login attempts per email using in-memory cache.
/// Locks accounts for a cooldown period after exceeding the threshold.
/// </summary>
public sealed class LoginThrottleService
{
    private const int MaxFailedAttempts = 5;
    private static readonly TimeSpan LockoutDuration = TimeSpan.FromMinutes(15);
    private static readonly TimeSpan AttemptWindow = TimeSpan.FromMinutes(15);
    private const string CachePrefix = "login:attempts:";

    private readonly IMemoryCache _cache;

    public LoginThrottleService(IMemoryCache cache)
    {
        _cache = cache;
    }

    /// <summary>
    /// Returns true if the account is currently locked out due to too many failed attempts.
    /// </summary>
    public bool IsLockedOut(string email)
    {
        var key = CachePrefix + email.Trim().ToLowerInvariant();
        return _cache.TryGetValue(key, out LoginAttemptRecord? record)
               && record is not null
               && record.FailedCount >= MaxFailedAttempts
               && record.LockedUntilUtc > DateTimeOffset.UtcNow;
    }

    /// <summary>
    /// Returns the remaining lockout duration, or null if not locked.
    /// </summary>
    public TimeSpan? GetRemainingLockout(string email)
    {
        var key = CachePrefix + email.Trim().ToLowerInvariant();
        if (!_cache.TryGetValue(key, out LoginAttemptRecord? record) || record is null)
        {
            return null;
        }

        if (record.FailedCount < MaxFailedAttempts || record.LockedUntilUtc <= DateTimeOffset.UtcNow)
        {
            return null;
        }

        return record.LockedUntilUtc - DateTimeOffset.UtcNow;
    }

    /// <summary>
    /// Records a failed login attempt. Triggers lockout after threshold is reached.
    /// </summary>
    public void RecordFailure(string email)
    {
        var key = CachePrefix + email.Trim().ToLowerInvariant();
        var record = _cache.GetOrCreate(key, entry =>
        {
            entry.AbsoluteExpirationRelativeToNow = AttemptWindow;
            return new LoginAttemptRecord();
        })!;

        record.FailedCount++;

        if (record.FailedCount >= MaxFailedAttempts)
        {
            record.LockedUntilUtc = DateTimeOffset.UtcNow.Add(LockoutDuration);
            _cache.Set(key, record, new MemoryCacheEntryOptions
            {
                AbsoluteExpirationRelativeToNow = LockoutDuration
            });
        }
    }

    /// <summary>
    /// Clears failure count after a successful login.
    /// </summary>
    public void RecordSuccess(string email)
    {
        var key = CachePrefix + email.Trim().ToLowerInvariant();
        _cache.Remove(key);
    }

    private sealed class LoginAttemptRecord
    {
        public int FailedCount { get; set; }
        public DateTimeOffset LockedUntilUtc { get; set; }
    }
}
