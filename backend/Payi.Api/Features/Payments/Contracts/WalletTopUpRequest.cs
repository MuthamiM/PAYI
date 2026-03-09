namespace Payi.Api.Features.Payments.Contracts;

public sealed record WalletTopUpRequest(
    string UserEmail,
    string Currency,
    decimal Amount
);
