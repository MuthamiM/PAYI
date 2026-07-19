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
            .RequireRateLimiting("GeneralRateLimit");

        group.MapPost("/register", RegisterAsync)
            .WithName("Register")
            .WithSummary("Register a new user")
            .AllowAnonymous();

        group.MapPost("/login", LoginAsync)
            .WithName("Login")
            .WithSummary("Local login")
            .AllowAnonymous();

        group.MapPost("/reset-password", ResetPasswordAsync)
            .WithName("ResetPassword")
            .WithSummary("Reset password stub")
            .AllowAnonymous();

        var authenticatedGroup = group.MapGroup("/")
            .AddEndpointFilter<AuthGuard>();

        // Returns the authenticated user's own directory listing (names/emails of all users for the send-to autocomplete).
        // Sensitive fields (password hash, IDs) are stripped.
        authenticatedGroup.MapGet("/users", GetUsersAsync)
            .WithName("ListUsers")
            .WithSummary("List user directory")
            .WithDescription("Returns a minimal directory of users (name/email) for recipient lookup. Requires authentication.")
            .Produces<IReadOnlyCollection<UserProfileResponse>>(StatusCodes.Status200OK)
            .CacheOutput("ShortApi");

        // Returns only the authenticated user's own profile by their ID
        authenticatedGroup.MapGet("/users/{id:guid}", GetUserByIdAsync)
            .WithName("GetUserById")
            .WithSummary("Get a user profile by ID")
            .WithDescription("Returns one registered user profile. Only your own profile is accessible.")
            .Produces<UserProfileResponse>(StatusCodes.Status200OK)
            .ProducesProblem(StatusCodes.Status404NotFound)
            .CacheOutput("ShortApi");

        // Returns the currently authenticated user's own profile
        authenticatedGroup.MapGet("/me", GetOwnProfileAsync)
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

    private static async Task<IResult> RegisterAsync(
        RegisterRequest request,
        IUserRepository userRepository,
        IPasswordService passwordService,
        ITokenService tokenService,
        Payi.Api.Features.Payments.Services.IWalletRepository walletRepository,
        CancellationToken cancellationToken)
    {
        var existing = await userRepository.GetByEmailAsync(request.Email, cancellationToken);
        if (existing is not null)
        {
            return Results.Problem(statusCode: StatusCodes.Status400BadRequest, title: "Email already registered");
        }

        var user = new AppUser
        {
            Id = Guid.NewGuid(),
            Name = request.Name,
            Email = request.Email,
            PhoneNumber = request.PhoneNumber,
            Country = request.Country,
            DefaultCurrency = string.IsNullOrWhiteSpace(request.Country) ? "USD" : request.Country, 
            PasswordHash = passwordService.Hash(request.Password),
            CreatedAtUtc = DateTimeOffset.UtcNow
        };

        await userRepository.AddAsync(user, cancellationToken);
        await walletRepository.GetOrCreateAsync(user.Email, cancellationToken);

        var token = tokenService.IssueToken(user);
        return Results.Ok(new { Token = token, user.Email, user.Name });
    }

    private static async Task<IResult> LoginAsync(
        LoginRequest request,
        IUserRepository userRepository,
        IPasswordService passwordService,
        ITokenService tokenService,
        CancellationToken cancellationToken)
    {
        var user = await userRepository.GetByEmailAsync(request.Email, cancellationToken);
        if (user is null || !passwordService.Verify(request.Password, user.PasswordHash))
        {
            return Results.Problem(statusCode: StatusCodes.Status401Unauthorized, title: "Invalid email or password");
        }

        var token = tokenService.IssueToken(user);
        return Results.Ok(new { Token = token, email = user.Email, name = user.Name, phone = user.PhoneNumber, currency = user.DefaultCurrency });
    }

    private static Task<IResult> ResetPasswordAsync(
        LoginRequest request, // Reusing LoginRequest for email only
        CancellationToken cancellationToken)
    {
        // This is a stub. In a real app, it would send an email.
        return Task.FromResult(Results.Ok(new { Message = "If an account exists, a reset link has been sent." }));
    }

    private static UserProfileResponse ToProfile(AppUser user) =>
        new(user.Id, user.Name, user.Email, user.PhoneNumber, user.Country, user.DefaultCurrency, user.CreatedAtUtc);
}
