namespace Payi.Api.Features.Payments.Contracts;

public sealed record PaymentActionResponse(
    bool Success,
    string Message,
    string Reference,
    TransactionRecordResponse Transaction,
    string BalanceCurrency,
    decimal AvailableBalance
);
