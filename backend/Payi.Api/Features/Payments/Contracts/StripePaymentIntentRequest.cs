namespace Payi.Api.Features.Payments.Contracts;

public sealed record StripePaymentIntentRequest(
    string UserEmail,
    decimal Amount,
    string Currency
);
