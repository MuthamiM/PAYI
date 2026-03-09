namespace Payi.Api.Features.Platform.Contracts;

public sealed record ContactResponse(
    string ReferenceId,
    DateTimeOffset ReceivedAtUtc,
    string Message
);
