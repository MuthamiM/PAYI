using System.Net.Mail;
using Microsoft.AspNetCore.Mvc;
using Payi.Api.Features.Auth.Contracts;
using Payi.Api.Features.Auth.Domain;
using Payi.Api.Features.Auth.Services;

namespace Payi.Api.Features.Auth.Endpoints;

public static class AuthEndpoints
{
    public static void Map(IEndpointRouteBuilder app)
    {
        var group = app.MapGroup("/api/auth").WithTags("Auth");

        group.MapPost("/register", RegisterAsync)
            .WithName("RegisterAccount")
            .WithSummary("Register a new platform account")
            .WithDescription("Creates a user account after validating input, checking uniqueness, and hashing password.")
            .Produces<AuthResponse>(StatusCodes.Status201Created)
            .ProducesValidationProblem()
            .ProducesProblem(StatusCodes.Status409Conflict);

        group.MapPost("/login", LoginAsync)
            .WithName("LoginAccount")
            .WithSummary("Authenticate a platform account")
            .WithDescription("Validates account credentials and returns an access token for client-side session handling.")
            .Produces<AuthResponse>(StatusCodes.Status200OK)
            .ProducesValidationProblem()
            .ProducesProblem(StatusCodes.Status401Unauthorized);

        group.MapGet("/users", GetUsersAsync)
            .WithName("ListUsers")
            .WithSummary("List registered users")
            .WithDescription("Returns all registered users without sensitive password fields.")
            .Produces<IReadOnlyCollection<UserProfileResponse>>(StatusCodes.Status200OK)
            .CacheOutput("ShortApi");

        group.MapGet("/users/{id:guid}", GetUserByIdAsync)
            .WithName("GetUserById")
            .WithSummary("Get a user profile by ID")
            .WithDescription("Returns one registered user profile.")
            .Produces<UserProfileResponse>(StatusCodes.Status200OK)
            .ProducesProblem(StatusCodes.Status404NotFound)
            .CacheOutput("ShortApi");
    }

    private static async Task<IResult> RegisterAsync(
        RegisterRequest request,
        IUserRepository userRepository,
        IPasswordService passwordService,
        ITokenService tokenService,
        CancellationToken cancellationToken)
    {
        var errors = ValidateRegisterRequest(request);
        if (errors.Count > 0)
        {
            return Results.ValidationProblem(errors);
        }

        var existing = await userRepository.GetByEmailAsync(request.Email, cancellationToken);
        if (existing is not null)
        {
            return Results.Conflict(new ProblemDetails
            {
                Title = "Duplicate account",
                Detail = "An account already exists with this email address.",
                Status = StatusCodes.Status409Conflict
            });
        }

        var user = new AppUser
        {
            Id = Guid.NewGuid(),
            Name = request.Name.Trim(),
            Email = request.Email.Trim().ToLowerInvariant(),
            Country = request.Country.Trim(),
            PasswordHash = passwordService.Hash(request.Password),
            CreatedAtUtc = DateTimeOffset.UtcNow
        };

        await userRepository.AddAsync(user, cancellationToken);

        var response = new AuthResponse(
            Success: true,
            Message: "Account created successfully.",
            User: ToProfile(user),
            AccessToken: tokenService.IssueToken(user)
        );

        return Results.Created($"/api/auth/users/{user.Id}", response);
    }

    private static async Task<IResult> LoginAsync(
        LoginRequest request,
        IUserRepository userRepository,
        IPasswordService passwordService,
        ITokenService tokenService,
        CancellationToken cancellationToken)
    {
        var errors = ValidateLoginRequest(request);
        if (errors.Count > 0)
        {
            return Results.ValidationProblem(errors);
        }

        var user = await userRepository.GetByEmailAsync(request.Email, cancellationToken);
        if (user is null || !passwordService.Verify(request.Password, user.PasswordHash))
        {
            return Results.Problem(
                statusCode: StatusCodes.Status401Unauthorized,
                title: "Authentication failed",
                detail: "Invalid email or password.");
        }

        var response = new AuthResponse(
            Success: true,
            Message: "Login successful.",
            User: ToProfile(user),
            AccessToken: tokenService.IssueToken(user)
        );

        return Results.Ok(response);
    }

    private static async Task<IResult> GetUsersAsync(IUserRepository userRepository, CancellationToken cancellationToken)
    {
        var users = await userRepository.GetAllAsync(cancellationToken);
        var profiles = users
            .Select(ToProfile)
            .OrderBy(user => user.CreatedAtUtc)
            .ToArray();

        return Results.Ok(profiles);
    }

    private static async Task<IResult> GetUserByIdAsync(Guid id, IUserRepository userRepository, CancellationToken cancellationToken)
    {
        var user = await userRepository.GetByIdAsync(id, cancellationToken);
        return user is null
            ? Results.Problem(statusCode: StatusCodes.Status404NotFound, title: "User not found")
            : Results.Ok(ToProfile(user));
    }

    private static Dictionary<string, string[]> ValidateRegisterRequest(RegisterRequest request)
    {
        var errors = new Dictionary<string, string[]>(StringComparer.OrdinalIgnoreCase);

        if (string.IsNullOrWhiteSpace(request.Name))
        {
            errors["name"] = ["Name is required."];
        }

        if (!IsValidEmail(request.Email))
        {
            errors["email"] = ["A valid email is required."];
        }

        if (string.IsNullOrWhiteSpace(request.Country))
        {
            errors["country"] = ["Country is required."];
        }

        if (string.IsNullOrWhiteSpace(request.Password) || request.Password.Length < 8)
        {
            errors["password"] = ["Password must be at least 8 characters."];
        }

        if (!string.Equals(request.Password, request.ConfirmPassword, StringComparison.Ordinal))
        {
            errors["confirmPassword"] = ["Password and confirm password must match."];
        }

        return errors;
    }

    private static Dictionary<string, string[]> ValidateLoginRequest(LoginRequest request)
    {
        var errors = new Dictionary<string, string[]>(StringComparer.OrdinalIgnoreCase);

        if (!IsValidEmail(request.Email))
        {
            errors["email"] = ["A valid email is required."];
        }

        if (string.IsNullOrWhiteSpace(request.Password))
        {
            errors["password"] = ["Password is required."];
        }

        return errors;
    }

    private static bool IsValidEmail(string email)
    {
        if (string.IsNullOrWhiteSpace(email))
        {
            return false;
        }

        try
        {
            var _ = new MailAddress(email);
            return true;
        }
        catch (FormatException)
        {
            return false;
        }
    }

    private static UserProfileResponse ToProfile(AppUser user) =>
        new(user.Id, user.Name, user.Email, user.Country, user.CreatedAtUtc);
}
