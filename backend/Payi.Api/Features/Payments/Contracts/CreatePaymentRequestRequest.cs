namespace Payi.Api.Features.Payments.Contracts;

public sealed record CreatePaymentRequestRequest(
    string RequesterEmail,
    string RequesterName,
    string RecipientEmail,
    string RecipientName,
    decimal Amount,
    string Currency,
    string Country,
    string? Note
);
