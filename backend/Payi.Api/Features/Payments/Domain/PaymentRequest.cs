namespace Payi.Api.Features.Payments.Domain;

public sealed class PaymentRequest
{
    public Guid Id { get; init; }
    public string Reference { get; init; } = string.Empty;
    public string RequesterEmail { get; init; } = string.Empty;
    public string RequesterName { get; init; } = string.Empty;
    public string RecipientEmail { get; init; } = string.Empty;
    public string RecipientName { get; init; } = string.Empty;
    public decimal Amount { get; init; }
    public string Currency { get; init; } = "KES";
    public string Country { get; init; } = string.Empty;
    public string? Note { get; init; }
    public string Status { get; set; } = "Pending";
    public DateTimeOffset CreatedAtUtc { get; init; }
    public DateTimeOffset? UpdatedAtUtc { get; set; }
    public string? SettlementReference { get; set; }
}
