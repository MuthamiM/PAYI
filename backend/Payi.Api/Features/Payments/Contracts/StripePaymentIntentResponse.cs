namespace Payi.Api.Features.Payments.Contracts;

public sealed record StripePaymentIntentResponse(
    string ClientSecret,
    string PaymentIntentId,
    string PublishableKey
);
