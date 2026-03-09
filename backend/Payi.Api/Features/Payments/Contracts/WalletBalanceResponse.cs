namespace Payi.Api.Features.Payments.Contracts;

public sealed record WalletBalanceResponse(
    string UserEmail,
    IReadOnlyDictionary<string, decimal> Balances,
    DateTimeOffset UpdatedAtUtc
);
