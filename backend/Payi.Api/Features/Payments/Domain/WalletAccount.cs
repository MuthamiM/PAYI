namespace Payi.Api.Features.Payments.Domain;

public sealed class WalletAccount
{
    public string UserEmail { get; init; } = string.Empty;
    public Dictionary<string, decimal> Balances { get; set; } = new(StringComparer.OrdinalIgnoreCase);
    public DateTimeOffset UpdatedAtUtc { get; set; }
}
