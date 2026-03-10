using System.Security.Claims;
using Microsoft.Extensions.Caching.Memory;
using Payi.Api.Features.Auth.Domain;

namespace Payi.Api.Features.Auth.Services;

/// <summary>
/// Minimal API endpoint filter that verifies the user is authenticated via the standard ASP.NET Core
/// Authentication middleware (JWT Bearer via Clerk).
/// Sets HttpContext.Items["AuthEmail"] and ["AuthUserId"] on success.
/// Returns 401 Unauthorized if the user is not authenticated.
/// </summary>
public sealed class AuthGuard : IEndpointFilter
{
    public async ValueTask<object?> InvokeAsync(EndpointFilterInvocationContext context, EndpointFilterDelegate next)
    {
        var httpContext = context.HttpContext;
        var principal = httpContext.User;

        if (principal?.Identity?.IsAuthenticated != true)
        {
            return Results.Problem(
                statusCode: StatusCodes.Status401Unauthorized,
                title: "Authentication required",
                detail: "Provide a valid Bearer token in the Authorization header.");
        }

        Console.WriteLine("-------- JWT CLAIMS --------");
        foreach (var claim in principal.Claims)
        {
            Console.WriteLine($"Claim: {claim.Type} = {claim.Value}");
        }
        Console.WriteLine($"Default NameIdentifier: {principal.FindFirst(ClaimTypes.NameIdentifier)?.Value}");
        Console.WriteLine("----------------------------");

        // Clerk stores the user's primary email address either in a custom claim or we can fall back to standard claims
        var email = principal.FindFirst(ClaimTypes.Email)?.Value
                    ?? principal.FindFirst("email")?.Value
                    ?? principal.FindFirst("http://schemas.xmlsoap.org/ws/2005/05/identity/claims/emailaddress")?.Value;
        
        var userId = principal.FindFirst(ClaimTypes.NameIdentifier)?.Value
                     ?? principal.FindFirst("sub")?.Value;

        if (string.IsNullOrWhiteSpace(userId))
        {
            return Results.Problem(statusCode: 401, title: "Invalid Token", detail: "Token missing subject claim.");
        }

        var userRepository = httpContext.RequestServices.GetRequiredService<IUserRepository>();

        // TOFU (Trust On First Use) email binding if JWT lacks email claim
        if (string.IsNullOrWhiteSpace(email))
        {
            if (!httpContext.Request.Headers.TryGetValue("X-User-Email", out var headerEmailValue) || string.IsNullOrWhiteSpace(headerEmailValue.ToString()))
            {
                return Results.Problem(statusCode: 401, title: "Email required", detail: "JWT lacks email claim and X-User-Email header is missing.");
            }
            email = headerEmailValue.ToString().Trim().ToLowerInvariant();

            var existingByClerkId = await userRepository.GetByClerkIdAsync(userId, default);
            if (existingByClerkId != null)
            {
                // User is already bound. Requested email must match stored email exactly.
                if (!string.Equals(existingByClerkId.Email, email, StringComparison.OrdinalIgnoreCase))
                {
                    return Results.Problem(statusCode: 403, title: "Forbidden", detail: "Spoofed email: Header email does not match the bound account for this Clerk ID.");
                }
            }
            else
            {
                // First time we are seeing this Clerk ID. Look up the email.
                var existingByEmail = await userRepository.GetByEmailAsync(email, default);
                if (existingByEmail != null)
                {
                    // Wait, email is already registered. If it has no ClerkId, adopt it (migrations from legacy).
                    // If it has a DIFFERENT ClerkId, reject it (spoofing attempt on someone else's email).
                    if (string.IsNullOrWhiteSpace(existingByEmail.ClerkId))
                    {
                        var boundUser = new AppUser
                        {
                            Id = existingByEmail.Id,
                            ClerkId = userId,
                            Name = existingByEmail.Name,
                            Email = existingByEmail.Email,
                            Country = existingByEmail.Country,
                            PasswordHash = existingByEmail.PasswordHash,
                            CreatedAtUtc = existingByEmail.CreatedAtUtc
                        };
                        await userRepository.UpdateAsync(boundUser, default);
                    }
                    else if (!string.Equals(existingByEmail.ClerkId, userId, StringComparison.OrdinalIgnoreCase))
                    {
                        return Results.Problem(statusCode: 403, title: "Forbidden", detail: "Email is bound to a different Clerk ID.");
                    }
                }
            }
        }

        httpContext.Items["AuthEmail"] = email;
        httpContext.Items["AuthUserId"] = userId;

        // Ensure user and wallet exist in DB (sync if not exists)
        var cache = httpContext.RequestServices.GetRequiredService<IMemoryCache>();
        var syncKey = $"UserSynced_{userId}";
        
        if (!cache.TryGetValue(syncKey, out _))
        {
            var existingUser = await userRepository.GetByClerkIdAsync(userId, default);
            
            if (existingUser == null)
            {
                var name = principal.FindFirst(ClaimTypes.Name)?.Value 
                           ?? principal.FindFirst("name")?.Value 
                           ?? "Clerk User";
                           
                var newUser = new AppUser
                {
                    Id = Guid.NewGuid(),
                    ClerkId = userId,
                    Name = name,
                    Email = email,
                    Country = "Global",
                    PasswordHash = "clerk_managed_identity",
                    CreatedAtUtc = DateTimeOffset.UtcNow
                };
                
                await userRepository.AddAsync(newUser, default);
                
                // Ensure wallet exists for the user
                var walletRepository = httpContext.RequestServices.GetRequiredService<Payi.Api.Features.Payments.Services.IWalletRepository>();
                await walletRepository.GetOrCreateAsync(email, default);
                
                var logger = httpContext.RequestServices.GetRequiredService<ILogger<AuthGuard>>();
                logger.LogInformation("Synced new Clerk user {Email} with ClerkId {ClerkId} and created default wallet.", email, userId);
            }
            
            // Mark as synced
            cache.Set(syncKey, true, TimeSpan.FromHours(1));
        }

        return await next(context);
    }
}
