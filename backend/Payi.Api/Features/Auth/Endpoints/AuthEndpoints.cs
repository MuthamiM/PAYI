using Payi.Api.Features.Auth.Contracts;
using Payi.Api.Features.Auth.Domain;
using Payi.Api.Features.Auth.Services;

namespace Payi.Api.Features.Auth.Endpoints;

public static class AuthEndpoints
{
    public static void Map(IEndpointRouteBuilder app)
    {
        var group = app.MapGroup("/api/auth")
            .WithTags("Auth")
            .AddEndpointFilter<AuthGuard>()
            .RequireRateLimiting("GeneralRateLimit");

        // Returns the authenticated user's own directory listing (names/emails of all users for the send-to autocomplete).
        // Sensitive fields (password hash, IDs) are stripped.
        group.MapGet("/users", GetUsersAsync)
            .WithName("ListUsers")
            .WithSummary("List user directory")
            .WithDescription("Returns a minimal directory of users (name/email) for recipient lookup. Requires authentication.")
            .Produces<IReadOnlyCollection<UserProfileResponse>>(StatusCodes.Status200OK)
            .CacheOutput("ShortApi");

        // Returns only the authenticated user's own profile by their ID
        group.MapGet("/users/{id:guid}", GetUserByIdAsync)
            .WithName("GetUserById")
            .WithSummary("Get a user profile by ID")
            .WithDescription("Returns one registered user profile. Only your own profile is accessible.")
            .Produces<UserProfileResponse>(StatusCodes.Status200OK)
            .ProducesProblem(StatusCodes.Status404NotFound)
            .CacheOutput("ShortApi");

        // Returns the currently authenticated user's own profile
        group.MapGet("/me", GetOwnProfileAsync)
            .WithName("GetOwnProfile")
            .WithSummary("Get your own profile")
            .WithDescription("Returns the currently authenticated user's profile information.")
            .Produces<UserProfileResponse>(StatusCodes.Status200OK);
    }

    /// <summary>
    /// Returns the user directory for recipient lookup. 
    /// Only exposes name and email — no IDs, no password hashes.
    /// </summary>
    private static async Task<IResult> GetUsersAsync(
        HttpContext httpContext,
        IUserRepository userRepository,
        CancellationToken cancellationToken)
    {
        var users = await userRepository.GetAllAsync(cancellationToken);
        var profiles = users
            .Select(ToProfile)
            .OrderBy(user => user.CreatedAtUtc)
            .ToArray();

        return Results.Ok(profiles);
    }

    /// <summary>
    /// Returns a user profile only if the requested ID matches the authenticated user.
    /// Prevents IDOR — you cannot look up other users by cycling IDs.
    /// </summary>
    private static async Task<IResult> GetUserByIdAsync(
        HttpContext httpContext,
        Guid id,
        IUserRepository userRepository,
        CancellationToken cancellationToken)
    {
        var authEmail = httpContext.Items["AuthEmail"]?.ToString();
        var user = await userRepository.GetByIdAsync(id, cancellationToken);

        if (user is null)
        {
            return Results.Problem(statusCode: StatusCodes.Status404NotFound, title: "User not found");
        }

        // IDOR protection: only allow viewing your own profile
        if (!string.Equals(user.Email, authEmail, StringComparison.OrdinalIgnoreCase))
        {
            return Results.Problem(
                statusCode: StatusCodes.Status403Forbidden,
                title: "Forbidden",
                detail: "You can only view your own profile.");
        }

        return Results.Ok(ToProfile(user));
    }

    /// <summary>
    /// Returns the currently authenticated user's profile.
    /// </summary>
    private static async Task<IResult> GetOwnProfileAsync(
        HttpContext httpContext,
        IUserRepository userRepository,
        CancellationToken cancellationToken)
    {
        var authEmail = httpContext.Items["AuthEmail"]?.ToString();

        if (string.IsNullOrEmpty(authEmail))
        {
            return Results.Problem(
                statusCode: StatusCodes.Status401Unauthorized,
                title: "Authentication required");
        }

        var user = await userRepository.GetByEmailAsync(authEmail, cancellationToken);
        if (user is null)
        {
            return Results.Problem(
                statusCode: StatusCodes.Status404NotFound,
                title: "Profile not found",
                detail: "Your user profile was not found in the local database.");
        }

        return Results.Ok(ToProfile(user));
    }

    private static UserProfileResponse ToProfile(AppUser user) =>
        new(user.Id, user.Name, user.Email, user.Country, user.CreatedAtUtc);
}
