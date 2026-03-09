namespace Payi.Api.Features.Payments.Contracts;

public sealed record NotificationsResponse(
    IReadOnlyCollection<PaymentRequestResponse> IncomingRequests,
    IReadOnlyCollection<TransactionRecordResponse> ReceivedMoney
);
