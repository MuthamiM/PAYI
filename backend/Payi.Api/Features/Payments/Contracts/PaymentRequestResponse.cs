namespace Payi.Api.Features.Payments.Contracts;

public sealed record PaymentRequestResponse(
    Guid Id,
    string Reference,
    string RequesterEmail,
    string RequesterName,
    string RecipientEmail,
    string RecipientName,
    decimal Amount,
    string Currency,
    string Country,
    string? Note,
    string Status,
    DateTimeOffset CreatedAtUtc,
    DateTimeOffset? UpdatedAtUtc,
    string? SettlementReference
);
