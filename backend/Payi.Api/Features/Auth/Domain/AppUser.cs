namespace Payi.Api.Features.Auth.Domain;

public sealed class AppUser
{
    public Guid Id { get; init; }
    public string ClerkId { get; init; } = string.Empty;
    public string Name { get; init; } = string.Empty;
    public string Email { get; init; } = string.Empty;
    public string Country { get; init; } = string.Empty;
    public string PasswordHash { get; init; } = string.Empty;
    public DateTimeOffset CreatedAtUtc { get; init; }
}
