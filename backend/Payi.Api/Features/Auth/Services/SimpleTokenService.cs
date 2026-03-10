using System.IdentityModel.Tokens.Jwt;
using System.Security.Claims;
using System.Text;
using Microsoft.IdentityModel.Tokens;
using Payi.Api.Features.Auth.Domain;

namespace Payi.Api.Features.Auth.Services;

public sealed class JwtTokenService : ITokenService
{
    private readonly SymmetricSecurityKey _signingKey;
    private readonly JwtSecurityTokenHandler _handler = new();
    private readonly TimeSpan _expiry = TimeSpan.FromHours(1);
    private readonly string _issuer = "payi-api";
    private readonly string _audience = "payi-client";

    public JwtTokenService(IConfiguration configuration)
    {
        var secret = configuration["Jwt:SigningKey"]
                     ?? throw new InvalidOperationException(
                         "JWT signing key is not configured. Set 'Jwt:SigningKey' in appsettings or environment.");

        if (Encoding.UTF8.GetByteCount(secret) < 32)
        {
            throw new InvalidOperationException("JWT signing key must be at least 32 bytes (256 bits).");
        }

        _signingKey = new SymmetricSecurityKey(Encoding.UTF8.GetBytes(secret));
    }

    public string IssueToken(AppUser user)
    {
        var claims = new[]
        {
            new Claim(JwtRegisteredClaimNames.Sub, user.Id.ToString("D")),
            new Claim(JwtRegisteredClaimNames.Email, user.Email),
            new Claim("name", user.Name),
            new Claim(JwtRegisteredClaimNames.Jti, Guid.NewGuid().ToString("N"))
        };

        var credentials = new SigningCredentials(_signingKey, SecurityAlgorithms.HmacSha256);
        var now = DateTime.UtcNow;

        var token = new JwtSecurityToken(
            issuer: _issuer,
            audience: _audience,
            claims: claims,
            notBefore: now,
            expires: now.Add(_expiry),
            signingCredentials: credentials);

        return _handler.WriteToken(token);
    }

    public ClaimsPrincipal? ValidateToken(string token)
    {
        var parameters = new TokenValidationParameters
        {
            ValidateIssuer = true,
            ValidIssuer = _issuer,
            ValidateAudience = true,
            ValidAudience = _audience,
            ValidateLifetime = true,
            ValidateIssuerSigningKey = true,
            IssuerSigningKey = _signingKey,
            ClockSkew = TimeSpan.FromSeconds(30)
        };

        try
        {
            return _handler.ValidateToken(token, parameters, out _);
        }
        catch (SecurityTokenException)
        {
            return null;
        }
    }
}
