namespace Payi.Api.Features.Payments.Contracts;

public sealed record StripeConfirmRequest(
    string UserEmail,
    string PaymentIntentId,
    string Currency
);
