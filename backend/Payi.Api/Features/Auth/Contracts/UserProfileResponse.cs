namespace Payi.Api.Features.Auth.Contracts;

public sealed record UserProfileResponse(
    Guid Id,
    string Name,
    string Email,
    string PhoneNumber,
    string Country,
    string DefaultCurrency,
    DateTimeOffset CreatedAtUtc
);
