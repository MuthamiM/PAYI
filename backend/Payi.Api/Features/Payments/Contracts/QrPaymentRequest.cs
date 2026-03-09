namespace Payi.Api.Features.Payments.Contracts;

public sealed record QrPaymentRequest(
    string UserEmail,
    string Country,
    decimal Amount,
    string Currency,
    string Purpose
);
