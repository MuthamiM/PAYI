namespace Payi.Api.Features.Payments.Contracts;

public sealed record QrPayRequest(
    string UserEmail,
    string QrPayload
);
