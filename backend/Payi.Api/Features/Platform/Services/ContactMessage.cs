namespace Payi.Api.Features.Platform.Services;

public sealed class ContactMessage
{
    public string ReferenceId { get; init; } = string.Empty;
    public string Name { get; init; } = string.Empty;
    public string Email { get; init; } = string.Empty;
    public string Message { get; init; } = string.Empty;
    public DateTimeOffset ReceivedAtUtc { get; init; }
}
