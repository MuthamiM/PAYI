using System.Security.Cryptography;
using Payi.Api.Features.Auth.Domain;

namespace Payi.Api.Features.Auth.Services;

public sealed class SimpleTokenService : ITokenService
{
    public string IssueToken(AppUser user)
    {
        var randomBytes = RandomNumberGenerator.GetBytes(24);
        var payload = $"{user.Id:N}.{Convert.ToBase64String(randomBytes)}";
        return Convert.ToBase64String(global::System.Text.Encoding.UTF8.GetBytes(payload));
    }
}
