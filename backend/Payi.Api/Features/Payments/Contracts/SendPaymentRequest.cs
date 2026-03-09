namespace Payi.Api.Features.Payments.Contracts;

public sealed record SendPaymentRequest(
    string UserEmail,
    string DestinationCountry,
    string RecipientName,
    string RecipientAccount,
    decimal Amount,
    string Currency,
    string? Method
);
