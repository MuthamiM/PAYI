namespace Payi.Api.Features.Platform.Services;

public interface IContactRepository
{
    Task<ContactMessage> AddAsync(ContactMessage message, CancellationToken cancellationToken);
}
