using Payi.Api.Features.Auth.Domain;

namespace Payi.Api.Features.Auth.Services;

public interface IUserRepository
{
    Task<AppUser?> GetByEmailAsync(string email, CancellationToken cancellationToken);
    Task<AppUser?> GetByIdAsync(Guid id, CancellationToken cancellationToken);
    Task<IReadOnlyCollection<AppUser>> GetAllAsync(CancellationToken cancellationToken);
    Task<AppUser> AddAsync(AppUser user, CancellationToken cancellationToken);
}
