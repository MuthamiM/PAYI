namespace Payi.Api.Features.Auth.Services;

public interface IPasswordService
{
    string Hash(string password);
    bool Verify(string password, string hashedPassword);
}
