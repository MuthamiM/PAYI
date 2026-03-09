namespace Payi.Api.Features.Payments.Contracts;

public sealed record TransactionRecordResponse(
    string Reference,
    string Direction,
    string CounterpartyName,
    string Country,
    string Method,
    decimal Amount,
    string Currency,
    string Status,
    DateTimeOffset CreatedAtUtc
);
