using Microsoft.Extensions.Caching.Memory;

namespace Payi.Api.Features.Payments.Services;

/// <summary>
/// Endpoint filter that prevents duplicate payment operations by checking
/// for an Idempotency-Key header. If a request with the same key has been
/// seen within the deduplication window, the original response is returned.
/// </summary>
public sealed class IdempotencyGuard : IEndpointFilter
{
    private static readonly TimeSpan DeduplicationWindow = TimeSpan.FromMinutes(10);
    private const string HeaderName = "Idempotency-Key";

    public async ValueTask<object?> InvokeAsync(EndpointFilterInvocationContext context, EndpointFilterDelegate next)
    {
        var httpContext = context.HttpContext;

        // Only apply to mutation methods (POST, PUT, PATCH)
        if (!HttpMethods.IsPost(httpContext.Request.Method) &&
            !HttpMethods.IsPut(httpContext.Request.Method) &&
            !HttpMethods.IsPatch(httpContext.Request.Method))
        {
            return await next(context);
        }

        var idempotencyKey = httpContext.Request.Headers[HeaderName].FirstOrDefault();
        if (string.IsNullOrWhiteSpace(idempotencyKey))
        {
            // No key provided — proceed normally (idempotency is opt-in)
            return await next(context);
        }

        var cache = httpContext.RequestServices.GetRequiredService<IMemoryCache>();
        var cacheKey = $"idempotency:{idempotencyKey.Trim()}";

        if (cache.TryGetValue(cacheKey, out IdempotencyRecord? cached) && cached is not null)
        {
            // Duplicate request — return the cached result
            httpContext.Response.Headers["X-Idempotency-Replayed"] = "true";
            return cached.Result;
        }

        var result = await next(context);

        // Cache the result for the deduplication window
        var record = new IdempotencyRecord { Result = result };
        cache.Set(cacheKey, record, new MemoryCacheEntryOptions
        {
            AbsoluteExpirationRelativeToNow = DeduplicationWindow
        });

        return result;
    }

    private sealed class IdempotencyRecord
    {
        public object? Result { get; init; }
    }
}
