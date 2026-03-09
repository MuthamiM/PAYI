namespace Payi.Api.Features.Auth.Contracts;

public sealed record RegisterRequest(
    string Name,
    string Email,
    string Country,
    string Password,
    string ConfirmPassword
);
