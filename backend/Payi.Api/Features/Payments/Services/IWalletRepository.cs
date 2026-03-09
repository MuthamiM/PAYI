using Payi.Api.Features.Payments.Domain;

namespace Payi.Api.Features.Payments.Services;

public interface IWalletRepository
{
    Task<WalletAccount> GetOrCreateAsync(string userEmail, CancellationToken cancellationToken);
    Task<WalletMutationResult> CreditAsync(string userEmail, string currency, decimal amount, CancellationToken cancellationToken);
    Task<WalletMutationResult> DebitAsync(string userEmail, string currency, decimal amount, CancellationToken cancellationToken);
    Task<WalletMutationResult> SetBalanceAsync(string userEmail, string currency, decimal amount, CancellationToken cancellationToken);
}
