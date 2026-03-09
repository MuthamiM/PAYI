namespace Payi.Api.Features.Payments.Domain;

public sealed class PaymentTransaction
{
    public string Reference { get; init; } = string.Empty;
    public string UserEmail { get; init; } = string.Empty;
    public string Direction { get; init; } = string.Empty;
    public string CounterpartyName { get; init; } = string.Empty;
    public string Country { get; init; } = string.Empty;
    public string Method { get; init; } = string.Empty;
    public decimal Amount { get; init; }
    public string Currency { get; init; } = "USD";
    public string Status { get; init; } = string.Empty;
    public DateTimeOffset CreatedAtUtc { get; init; }
}
