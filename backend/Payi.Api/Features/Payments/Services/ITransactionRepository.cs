using Payi.Api.Features.Payments.Domain;

namespace Payi.Api.Features.Payments.Services;

public interface ITransactionRepository
{
    Task<IReadOnlyCollection<PaymentTransaction>> GetByUserEmailAsync(string userEmail, CancellationToken cancellationToken);
    Task<PaymentTransaction> AddAsync(PaymentTransaction transaction, CancellationToken cancellationToken);
}
