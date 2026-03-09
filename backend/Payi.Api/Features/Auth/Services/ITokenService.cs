using Payi.Api.Features.Auth.Domain;

namespace Payi.Api.Features.Auth.Services;

public interface ITokenService
{
    string IssueToken(AppUser user);
}
