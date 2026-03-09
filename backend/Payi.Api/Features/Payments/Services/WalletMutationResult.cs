using Payi.Api.Features.Payments.Domain;

namespace Payi.Api.Features.Payments.Services;

public sealed record WalletMutationResult(
    bool Success,
    string Message,
    WalletAccount Wallet,
    string Currency,
    decimal Balance
);
