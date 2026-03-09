using Payi.Api.Features.Payments.Domain;

namespace Payi.Api.Features.Payments.Services;

public interface IPaymentRequestRepository
{
    Task<PaymentRequest> AddAsync(PaymentRequest request, CancellationToken cancellationToken);
    Task<PaymentRequest?> GetByIdAsync(Guid id, CancellationToken cancellationToken);
    Task<IReadOnlyCollection<PaymentRequest>> GetByRecipientEmailAsync(string recipientEmail, CancellationToken cancellationToken);
    Task<IReadOnlyCollection<PaymentRequest>> GetByRequesterEmailAsync(string requesterEmail, CancellationToken cancellationToken);
    Task<PaymentRequest> UpdateAsync(PaymentRequest request, CancellationToken cancellationToken);
}
