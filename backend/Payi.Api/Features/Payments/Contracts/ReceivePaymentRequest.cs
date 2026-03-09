namespace Payi.Api.Features.Payments.Contracts;

public sealed record ReceivePaymentRequest(
    string UserEmail,
    string SourceCountry,
    string SenderName,
    decimal Amount,
    string Currency,
    string Method
);
