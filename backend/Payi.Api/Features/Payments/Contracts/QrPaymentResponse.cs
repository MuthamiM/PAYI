namespace Payi.Api.Features.Payments.Contracts;

public sealed record QrPaymentResponse(
    bool Success,
    string Message,
    string Reference,
    string QrPayload,
    DateTimeOffset ExpiresAtUtc,
    string? QrImageDataUrl
);
