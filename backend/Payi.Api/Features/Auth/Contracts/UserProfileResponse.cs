namespace Payi.Api.Features.Auth.Contracts;

public sealed record UserProfileResponse(
    Guid Id,
    string Name,
    string Email,
    string Country,
    DateTimeOffset CreatedAtUtc
);
