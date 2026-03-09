namespace Payi.Api.Features.Auth.Contracts;

public sealed record AuthResponse(
    bool Success,
    string Message,
    UserProfileResponse? User,
    string? AccessToken
);
