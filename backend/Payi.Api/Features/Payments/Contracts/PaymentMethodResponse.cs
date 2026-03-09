namespace Payi.Api.Features.Payments.Contracts;

public sealed record PaymentMethodResponse(
    string Country,
    IReadOnlyCollection<string> SupportedMethods,
    IReadOnlyCollection<string> CardSchemes,
    IReadOnlyCollection<string> Wallets,
    string Notes
);
