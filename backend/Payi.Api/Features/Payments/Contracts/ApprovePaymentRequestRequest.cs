namespace Payi.Api.Features.Payments.Contracts;

public sealed record ApprovePaymentRequestRequest(
    string UserEmail,
    string? Method
);
