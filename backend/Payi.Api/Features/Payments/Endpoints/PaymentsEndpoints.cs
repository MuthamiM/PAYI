using System.Net.Mail;
using System.Globalization;
using Payi.Api.Features.Auth.Domain;
using Payi.Api.Features.Auth.Services;
using Payi.Api.Features.Payments.Contracts;
using Payi.Api.Features.Payments.Domain;
using Payi.Api.Features.Payments.Services;
using QRCoder;

namespace Payi.Api.Features.Payments.Endpoints;

public static class PaymentsEndpoints
{
    public static void Map(IEndpointRouteBuilder app)
    {
        var group = app.MapGroup("/api/payments").WithTags("Payments");

        group.MapGet("/transactions", GetTransactionsAsync)
            .WithName("GetTransactions")
            .WithSummary("Get transaction history by user email")
            .WithDescription("Returns all transaction records for a signed-in user, sorted newest first.")
            .Produces<IReadOnlyCollection<TransactionRecordResponse>>(StatusCodes.Status200OK)
            .ProducesValidationProblem();

        group.MapPost("/send", SendAsync)
            .WithName("SendPayment")
            .WithSummary("Send a payment")
            .WithDescription("Creates a send transaction and routes it through method selection or country defaults.")
            .Produces<PaymentActionResponse>(StatusCodes.Status201Created)
            .ProducesValidationProblem();

        group.MapPost("/requests", CreateRequestAsync)
            .WithName("CreatePaymentRequest")
            .WithSummary("Create a payment request")
            .WithDescription("Creates a pending payment request that can be approved by the recipient.")
            .Produces<PaymentRequestResponse>(StatusCodes.Status201Created)
            .ProducesValidationProblem();

        group.MapGet("/notifications", GetNotificationsAsync)
            .WithName("GetNotifications")
            .WithSummary("Get notifications for a user")
            .WithDescription("Returns pending payment requests and recent received money events for a user.")
            .Produces<NotificationsResponse>(StatusCodes.Status200OK)
            .ProducesValidationProblem();

        group.MapPost("/requests/{id:guid}/approve", ApproveRequestAsync)
            .WithName("ApprovePaymentRequest")
            .WithSummary("Approve a payment request")
            .WithDescription("Debits recipient wallet, credits requester wallet, and settles the pending request.")
            .Produces<PaymentActionResponse>(StatusCodes.Status200OK)
            .ProducesValidationProblem()
            .ProducesProblem(StatusCodes.Status404NotFound)
            .ProducesProblem(StatusCodes.Status409Conflict);

        group.MapPost("/receive", ReceiveAsync)
            .WithName("ReceivePayment")
            .WithSummary("Record a receive payment")
            .WithDescription("Creates a receive transaction entry for reconciliation and dashboard history.")
            .Produces<PaymentActionResponse>(StatusCodes.Status201Created)
            .ProducesValidationProblem();

        group.MapGet("/methods", GetMethods)
            .WithName("GetPaymentMethods")
            .WithSummary("Get payment methods by country")
            .WithDescription("Returns QR, bank card, transfer, wallet, and card scheme support by country.")
            .Produces<PaymentMethodResponse>(StatusCodes.Status200OK)
            .CacheOutput(policy => policy.Expire(TimeSpan.FromMinutes(10)).SetVaryByQuery("country"));

        group.MapPost("/qr/create", CreateQrAsync)
            .WithName("CreateQrPayment")
            .WithSummary("Create a QR payment request")
            .WithDescription("Generates a QR payment payload and records a pending QR transaction.")
            .Produces<QrPaymentResponse>(StatusCodes.Status201Created)
            .ProducesValidationProblem();

        group.MapGet("/qr/image", GetQrImage)
            .WithName("GetQrImage")
            .WithSummary("Generate QR image for payload")
            .WithDescription("Returns a PNG QR image for a PAYI QR payload.")
            .Produces(StatusCodes.Status200OK, contentType: "image/png")
            .ProducesValidationProblem();

        group.MapPost("/qr/pay", PayQrAsync)
            .WithName("PayQrPayment")
            .WithSummary("Pay using QR payload")
            .WithDescription("Parses PAYI QR payload, debits wallet, and records payment transaction.")
            .Produces<PaymentActionResponse>(StatusCodes.Status201Created)
            .ProducesValidationProblem();

        group.MapGet("/wallet", GetWalletAsync)
            .WithName("GetWallet")
            .WithSummary("Get wallet balances")
            .WithDescription("Returns all balances for a user's wallet.")
            .Produces<WalletBalanceResponse>(StatusCodes.Status200OK)
            .ProducesValidationProblem();

        group.MapPost("/wallet/topup", TopUpWalletAsync)
            .WithName("TopUpWallet")
            .WithSummary("Top up wallet balance")
            .WithDescription("Credits wallet balance for testing or controlled admin operations.")
            .Produces<WalletBalanceResponse>(StatusCodes.Status200OK)
            .ProducesValidationProblem();
    }

    private static async Task<IResult> GetTransactionsAsync(
        string userEmail,
        ITransactionRepository repository,
        CancellationToken cancellationToken)
    {
        if (!IsValidEmail(userEmail))
        {
            return Results.ValidationProblem(new Dictionary<string, string[]>
            {
                ["userEmail"] = ["A valid user email is required."]
            });
        }

        var records = await repository.GetByUserEmailAsync(userEmail, cancellationToken);
        var response = records.Select(ToResponse).ToArray();
        return Results.Ok(response);
    }

    private static async Task<IResult> SendAsync(
        SendPaymentRequest request,
        ITransactionRepository repository,
        IWalletRepository walletRepository,
        IUserRepository userRepository,
        CancellationToken cancellationToken)
    {
        var errors = ValidateSend(request);
        if (errors.Count > 0)
        {
            return Results.ValidationProblem(errors);
        }

        var senderEmail = request.UserEmail.Trim().ToLowerInvariant();
        var recipientAccount = request.RecipientAccount.Trim();
        var recipientUser = await ResolveRecipientAsync(
            recipientAccount,
            request.RecipientName.Trim(),
            userRepository,
            cancellationToken);

        var currency = request.Currency.Trim().ToUpperInvariant();
        var debit = await walletRepository.DebitAsync(
            senderEmail,
            currency,
            request.Amount,
            cancellationToken);

        if (!debit.Success)
        {
            return Results.ValidationProblem(new Dictionary<string, string[]>
            {
                ["wallet"] = [debit.Message]
            });
        }

        var method = PaymentMethodCatalog.ResolveDefaultRail(request.DestinationCountry, request.Method);
        var tx = new PaymentTransaction
        {
            Reference = BuildReference("SND"),
            UserEmail = senderEmail,
            Direction = "Send",
            CounterpartyName = request.RecipientName.Trim(),
            Country = request.DestinationCountry.Trim(),
            Method = method,
            Amount = request.Amount,
            Currency = currency,
            Status = recipientUser is null ? "Processing" : "Completed",
            CreatedAtUtc = DateTimeOffset.UtcNow
        };

        await repository.AddAsync(tx, cancellationToken);

        var responseMessage = $"Payment initiated via {method}.";
        if (recipientUser is not null &&
            !string.Equals(recipientUser.Email, tx.UserEmail, StringComparison.OrdinalIgnoreCase))
        {
            await walletRepository.CreditAsync(recipientUser.Email, currency, request.Amount, cancellationToken);

            var recipientTx = new PaymentTransaction
            {
                Reference = BuildReference("RCV"),
                UserEmail = recipientUser.Email,
                Direction = "Receive",
                CounterpartyName = tx.UserEmail,
                Country = request.DestinationCountry.Trim(),
                Method = method,
                Amount = request.Amount,
                Currency = currency,
                Status = "Completed",
                CreatedAtUtc = DateTimeOffset.UtcNow
            };

            await repository.AddAsync(recipientTx, cancellationToken);
            responseMessage = $"Payment completed via {method}. Recipient wallet credited.";
        }

        var response = new PaymentActionResponse(
            true,
            responseMessage,
            tx.Reference,
            ToResponse(tx),
            debit.Currency,
            debit.Balance);

        return Results.Created($"/api/payments/transactions/{tx.Reference}", response);
    }

    private static async Task<AppUser?> ResolveRecipientAsync(
        string recipientAccount,
        string recipientName,
        IUserRepository userRepository,
        CancellationToken cancellationToken)
    {
        if (IsValidEmail(recipientAccount))
        {
            return await userRepository.GetByEmailAsync(recipientAccount, cancellationToken);
        }

        var normalizedAccount = recipientAccount.Trim().ToLowerInvariant();
        if (string.IsNullOrWhiteSpace(normalizedAccount))
        {
            return null;
        }

        var allUsers = await userRepository.GetAllAsync(cancellationToken);

        var byAlias = allUsers.FirstOrDefault(user =>
        {
            var emailAlias = user.Email.Split('@', StringSplitOptions.RemoveEmptyEntries).FirstOrDefault();
            return string.Equals(emailAlias, normalizedAccount, StringComparison.OrdinalIgnoreCase);
        });

        if (byAlias is not null)
        {
            return byAlias;
        }

        var byName = allUsers.FirstOrDefault(user =>
            string.Equals(user.Name.Trim(), recipientName, StringComparison.OrdinalIgnoreCase) ||
            string.Equals(user.Name.Replace(" ", string.Empty), normalizedAccount, StringComparison.OrdinalIgnoreCase) ||
            string.Equals(user.Name.Trim(), recipientAccount, StringComparison.OrdinalIgnoreCase));

        return byName;
    }

    private static async Task<IResult> ReceiveAsync(
        ReceivePaymentRequest request,
        ITransactionRepository repository,
        IWalletRepository walletRepository,
        CancellationToken cancellationToken)
    {
        var errors = ValidateReceive(request);
        if (errors.Count > 0)
        {
            return Results.ValidationProblem(errors);
        }

        var currency = request.Currency.Trim().ToUpperInvariant();
        var credit = await walletRepository.CreditAsync(
            request.UserEmail.Trim().ToLowerInvariant(),
            currency,
            request.Amount,
            cancellationToken);

        var tx = new PaymentTransaction
        {
            Reference = BuildReference("RCV"),
            UserEmail = request.UserEmail.Trim().ToLowerInvariant(),
            Direction = "Receive",
            CounterpartyName = request.SenderName.Trim(),
            Country = request.SourceCountry.Trim(),
            Method = string.IsNullOrWhiteSpace(request.Method) ? "Bank Transfer" : request.Method.Trim(),
            Amount = request.Amount,
            Currency = currency,
            Status = "Completed",
            CreatedAtUtc = DateTimeOffset.UtcNow
        };

        await repository.AddAsync(tx, cancellationToken);

        var response = new PaymentActionResponse(
            true,
            "Incoming payment recorded successfully.",
            tx.Reference,
            ToResponse(tx),
            credit.Currency,
            credit.Balance);

        return Results.Created($"/api/payments/transactions/{tx.Reference}", response);
    }

    private static async Task<IResult> CreateRequestAsync(
        CreatePaymentRequestRequest request,
        IPaymentRequestRepository requestRepository,
        IUserRepository userRepository,
        CancellationToken cancellationToken)
    {
        var errors = ValidateCreateRequest(request);
        if (errors.Count > 0)
        {
            return Results.ValidationProblem(errors);
        }

        var requesterEmail = request.RequesterEmail.Trim().ToLowerInvariant();
        var recipientEmail = request.RecipientEmail.Trim().ToLowerInvariant();

        var requester = await userRepository.GetByEmailAsync(requesterEmail, cancellationToken);
        if (requester is null)
        {
            return Results.ValidationProblem(new Dictionary<string, string[]>
            {
                ["requesterEmail"] = ["Requester account was not found."]
            });
        }

        var recipient = await userRepository.GetByEmailAsync(recipientEmail, cancellationToken);
        if (recipient is null)
        {
            return Results.ValidationProblem(new Dictionary<string, string[]>
            {
                ["recipientEmail"] = ["Recipient account was not found."]
            });
        }

        var paymentRequest = new PaymentRequest
        {
            Id = Guid.NewGuid(),
            Reference = BuildReference("REQ"),
            RequesterEmail = requesterEmail,
            RequesterName = string.IsNullOrWhiteSpace(request.RequesterName) ? requester.Name : request.RequesterName.Trim(),
            RecipientEmail = recipientEmail,
            RecipientName = string.IsNullOrWhiteSpace(request.RecipientName) ? recipient.Name : request.RecipientName.Trim(),
            Amount = decimal.Round(request.Amount, 2),
            Currency = request.Currency.Trim().ToUpperInvariant(),
            Country = request.Country.Trim(),
            Note = string.IsNullOrWhiteSpace(request.Note) ? null : request.Note.Trim(),
            Status = "Pending",
            CreatedAtUtc = DateTimeOffset.UtcNow,
            UpdatedAtUtc = null
        };

        var created = await requestRepository.AddAsync(paymentRequest, cancellationToken);
        return Results.Created($"/api/payments/requests/{created.Id}", ToRequestResponse(created));
    }

    private static async Task<IResult> GetNotificationsAsync(
        string userEmail,
        IPaymentRequestRepository requestRepository,
        ITransactionRepository transactionRepository,
        CancellationToken cancellationToken)
    {
        if (!IsValidEmail(userEmail))
        {
            return Results.ValidationProblem(new Dictionary<string, string[]>
            {
                ["userEmail"] = ["A valid user email is required."]
            });
        }

        var normalizedEmail = userEmail.Trim().ToLowerInvariant();
        var requests = await requestRepository.GetByRecipientEmailAsync(normalizedEmail, cancellationToken);
        var incomingRequests = requests
            .Where(item => string.Equals(item.Status, "Pending", StringComparison.OrdinalIgnoreCase))
            .OrderByDescending(item => item.CreatedAtUtc)
            .Select(ToRequestResponse)
            .ToArray();

        var transactions = await transactionRepository.GetByUserEmailAsync(normalizedEmail, cancellationToken);
        var receivedMoney = transactions
            .Where(item => string.Equals(item.Direction, "Receive", StringComparison.OrdinalIgnoreCase))
            .OrderByDescending(item => item.CreatedAtUtc)
            .Take(10)
            .Select(ToResponse)
            .ToArray();

        var response = new NotificationsResponse(incomingRequests, receivedMoney);
        return Results.Ok(response);
    }

    private static async Task<IResult> ApproveRequestAsync(
        Guid id,
        ApprovePaymentRequestRequest request,
        IPaymentRequestRepository requestRepository,
        ITransactionRepository transactionRepository,
        IWalletRepository walletRepository,
        IUserRepository userRepository,
        CancellationToken cancellationToken)
    {
        var errors = ValidateApproveRequest(request);
        if (errors.Count > 0)
        {
            return Results.ValidationProblem(errors);
        }

        var paymentRequest = await requestRepository.GetByIdAsync(id, cancellationToken);
        if (paymentRequest is null)
        {
            return Results.Problem(
                statusCode: StatusCodes.Status404NotFound,
                title: "Request not found",
                detail: "Payment request could not be found.");
        }

        if (!string.Equals(paymentRequest.Status, "Pending", StringComparison.OrdinalIgnoreCase))
        {
            return Results.Problem(
                statusCode: StatusCodes.Status409Conflict,
                title: "Request already processed",
                detail: $"This request is already {paymentRequest.Status.ToLowerInvariant()}.");
        }

        var approverEmail = request.UserEmail.Trim().ToLowerInvariant();
        if (!string.Equals(paymentRequest.RecipientEmail, approverEmail, StringComparison.OrdinalIgnoreCase))
        {
            return Results.ValidationProblem(new Dictionary<string, string[]>
            {
                ["userEmail"] = ["Only the request recipient can approve this payment request."]
            });
        }

        var requester = await userRepository.GetByEmailAsync(paymentRequest.RequesterEmail, cancellationToken);
        if (requester is null)
        {
            return Results.Problem(
                statusCode: StatusCodes.Status404NotFound,
                title: "Requester not found",
                detail: "Requester account no longer exists.");
        }

        var method = PaymentMethodCatalog.ResolveDefaultRail(paymentRequest.Country, request.Method);
        var debit = await walletRepository.DebitAsync(
            approverEmail,
            paymentRequest.Currency,
            paymentRequest.Amount,
            cancellationToken);

        if (!debit.Success)
        {
            return Results.ValidationProblem(new Dictionary<string, string[]>
            {
                ["wallet"] = [debit.Message]
            });
        }

        await walletRepository.CreditAsync(
            paymentRequest.RequesterEmail,
            paymentRequest.Currency,
            paymentRequest.Amount,
            cancellationToken);

        var payerTx = new PaymentTransaction
        {
            Reference = BuildReference("SND"),
            UserEmail = approverEmail,
            Direction = "Send",
            CounterpartyName = requester.Name,
            Country = paymentRequest.Country,
            Method = method,
            Amount = paymentRequest.Amount,
            Currency = paymentRequest.Currency,
            Status = "Completed",
            CreatedAtUtc = DateTimeOffset.UtcNow
        };

        await transactionRepository.AddAsync(payerTx, cancellationToken);

        var requesterTx = new PaymentTransaction
        {
            Reference = BuildReference("RCV"),
            UserEmail = paymentRequest.RequesterEmail,
            Direction = "Receive",
            CounterpartyName = paymentRequest.RecipientName,
            Country = paymentRequest.Country,
            Method = method,
            Amount = paymentRequest.Amount,
            Currency = paymentRequest.Currency,
            Status = "Completed",
            CreatedAtUtc = DateTimeOffset.UtcNow
        };

        await transactionRepository.AddAsync(requesterTx, cancellationToken);

        paymentRequest.Status = "Approved";
        paymentRequest.UpdatedAtUtc = DateTimeOffset.UtcNow;
        paymentRequest.SettlementReference = payerTx.Reference;
        await requestRepository.UpdateAsync(paymentRequest, cancellationToken);

        var response = new PaymentActionResponse(
            true,
            "Payment request approved and settled.",
            payerTx.Reference,
            ToResponse(payerTx),
            debit.Currency,
            debit.Balance);

        return Results.Ok(response);
    }

    private static IResult GetMethods(string? country)
    {
        var response = PaymentMethodCatalog.Resolve(country);
        return Results.Ok(response);
    }

    private static async Task<IResult> CreateQrAsync(
        QrPaymentRequest request,
        ITransactionRepository repository,
        CancellationToken cancellationToken)
    {
        var errors = ValidateQr(request);
        if (errors.Count > 0)
        {
            return Results.ValidationProblem(errors);
        }

        var reference = BuildReference("QR");
        var tx = new PaymentTransaction
        {
            Reference = reference,
            UserEmail = request.UserEmail.Trim().ToLowerInvariant(),
            Direction = "Receive",
            CounterpartyName = request.Purpose.Trim(),
            Country = request.Country.Trim(),
            Method = "QR Code",
            Amount = request.Amount,
            Currency = request.Currency.Trim().ToUpperInvariant(),
            Status = "Pending Scan",
            CreatedAtUtc = DateTimeOffset.UtcNow
        };

        await repository.AddAsync(tx, cancellationToken);

        var expiresAt = DateTimeOffset.UtcNow.AddMinutes(15);
        var qrPayload =
            $"payi://pay?ref={reference}&amount={request.Amount:0.00}&currency={request.Currency.Trim().ToUpperInvariant()}&country={Uri.EscapeDataString(request.Country.Trim())}";
        var qrImageDataUrl = BuildQrImageDataUrl(qrPayload);

        var response = new QrPaymentResponse(
            true,
            "QR payment request generated.",
            reference,
            qrPayload,
            expiresAt,
            qrImageDataUrl);

        return Results.Created($"/api/payments/transactions/{reference}", response);
    }

    private static IResult GetQrImage(string payload)
    {
        if (string.IsNullOrWhiteSpace(payload))
        {
            return Results.ValidationProblem(new Dictionary<string, string[]>
            {
                ["payload"] = ["QR payload is required."]
            });
        }

        var trimmed = payload.Trim();
        if (trimmed.Length > 2048)
        {
            return Results.ValidationProblem(new Dictionary<string, string[]>
            {
                ["payload"] = ["QR payload is too long."]
            });
        }

        var bytes = BuildQrPng(trimmed);

        return Results.File(bytes, "image/png");
    }

    private static async Task<IResult> PayQrAsync(
        QrPayRequest request,
        ITransactionRepository transactionRepository,
        IWalletRepository walletRepository,
        CancellationToken cancellationToken)
    {
        var errors = ValidateQrPay(request);
        if (errors.Count > 0)
        {
            return Results.ValidationProblem(errors);
        }

        if (!TryParseQrPayload(request.QrPayload, out var qrData, out var parseError))
        {
            return Results.ValidationProblem(new Dictionary<string, string[]>
            {
                ["qrPayload"] = [parseError]
            });
        }

        var debit = await walletRepository.DebitAsync(
            request.UserEmail.Trim().ToLowerInvariant(),
            qrData.Currency,
            qrData.Amount,
            cancellationToken);

        if (!debit.Success)
        {
            return Results.ValidationProblem(new Dictionary<string, string[]>
            {
                ["wallet"] = [debit.Message]
            });
        }

        var tx = new PaymentTransaction
        {
            Reference = BuildReference("QRPAY"),
            UserEmail = request.UserEmail.Trim().ToLowerInvariant(),
            Direction = "Send",
            CounterpartyName = $"QR {qrData.Reference}",
            Country = qrData.Country,
            Method = "QR Code",
            Amount = qrData.Amount,
            Currency = qrData.Currency,
            Status = "Completed",
            CreatedAtUtc = DateTimeOffset.UtcNow
        };

        await transactionRepository.AddAsync(tx, cancellationToken);

        var response = new PaymentActionResponse(
            true,
            $"QR payment completed for {qrData.Amount:0.00} {qrData.Currency}.",
            tx.Reference,
            ToResponse(tx),
            debit.Currency,
            debit.Balance);

        return Results.Created($"/api/payments/transactions/{tx.Reference}", response);
    }

    private static async Task<IResult> GetWalletAsync(
        string userEmail,
        IWalletRepository walletRepository,
        CancellationToken cancellationToken)
    {
        if (!IsValidEmail(userEmail))
        {
            return Results.ValidationProblem(new Dictionary<string, string[]>
            {
                ["userEmail"] = ["A valid user email is required."]
            });
        }

        var wallet = await walletRepository.GetOrCreateAsync(userEmail.Trim().ToLowerInvariant(), cancellationToken);
        var response = new WalletBalanceResponse(wallet.UserEmail, wallet.Balances, wallet.UpdatedAtUtc);
        return Results.Ok(response);
    }

    private static async Task<IResult> TopUpWalletAsync(
        WalletTopUpRequest request,
        IWalletRepository walletRepository,
        CancellationToken cancellationToken)
    {
        var errors = ValidateTopUp(request);
        if (errors.Count > 0)
        {
            return Results.ValidationProblem(errors);
        }

        await walletRepository.CreditAsync(
            request.UserEmail.Trim().ToLowerInvariant(),
            request.Currency.Trim().ToUpperInvariant(),
            request.Amount,
            cancellationToken);

        var wallet = await walletRepository.GetOrCreateAsync(request.UserEmail.Trim().ToLowerInvariant(), cancellationToken);
        var response = new WalletBalanceResponse(wallet.UserEmail, wallet.Balances, wallet.UpdatedAtUtc);
        return Results.Ok(response);
    }

    private static TransactionRecordResponse ToResponse(PaymentTransaction tx) =>
        new(tx.Reference, tx.Direction, tx.CounterpartyName, tx.Country, tx.Method, tx.Amount, tx.Currency, tx.Status, tx.CreatedAtUtc);

    private static PaymentRequestResponse ToRequestResponse(PaymentRequest request) =>
        new(
            request.Id,
            request.Reference,
            request.RequesterEmail,
            request.RequesterName,
            request.RecipientEmail,
            request.RecipientName,
            request.Amount,
            request.Currency,
            request.Country,
            request.Note,
            request.Status,
            request.CreatedAtUtc,
            request.UpdatedAtUtc,
            request.SettlementReference);

    private static string BuildReference(string prefix) =>
        $"{prefix}-{DateTimeOffset.UtcNow:yyyyMMddHHmmss}-{Random.Shared.Next(1000, 9999)}";

    private static Dictionary<string, string[]> ValidateSend(SendPaymentRequest request)
    {
        var errors = new Dictionary<string, string[]>(StringComparer.OrdinalIgnoreCase);

        if (!IsValidEmail(request.UserEmail))
        {
            errors["userEmail"] = ["A valid user email is required."];
        }

        if (string.IsNullOrWhiteSpace(request.DestinationCountry))
        {
            errors["destinationCountry"] = ["Destination country is required."];
        }

        if (string.IsNullOrWhiteSpace(request.RecipientName))
        {
            errors["recipientName"] = ["Recipient name is required."];
        }

        if (string.IsNullOrWhiteSpace(request.RecipientAccount))
        {
            errors["recipientAccount"] = ["Recipient account is required."];
        }

        if (request.Amount <= 0)
        {
            errors["amount"] = ["Amount must be greater than zero."];
        }

        if (string.IsNullOrWhiteSpace(request.Currency))
        {
            errors["currency"] = ["Currency is required."];
        }

        return errors;
    }

    private static Dictionary<string, string[]> ValidateReceive(ReceivePaymentRequest request)
    {
        var errors = new Dictionary<string, string[]>(StringComparer.OrdinalIgnoreCase);

        if (!IsValidEmail(request.UserEmail))
        {
            errors["userEmail"] = ["A valid user email is required."];
        }

        if (string.IsNullOrWhiteSpace(request.SourceCountry))
        {
            errors["sourceCountry"] = ["Source country is required."];
        }

        if (string.IsNullOrWhiteSpace(request.SenderName))
        {
            errors["senderName"] = ["Sender name is required."];
        }

        if (request.Amount <= 0)
        {
            errors["amount"] = ["Amount must be greater than zero."];
        }

        if (string.IsNullOrWhiteSpace(request.Currency))
        {
            errors["currency"] = ["Currency is required."];
        }

        return errors;
    }

    private static Dictionary<string, string[]> ValidateQr(QrPaymentRequest request)
    {
        var errors = new Dictionary<string, string[]>(StringComparer.OrdinalIgnoreCase);

        if (!IsValidEmail(request.UserEmail))
        {
            errors["userEmail"] = ["A valid user email is required."];
        }

        if (string.IsNullOrWhiteSpace(request.Country))
        {
            errors["country"] = ["Country is required."];
        }

        if (request.Amount <= 0)
        {
            errors["amount"] = ["Amount must be greater than zero."];
        }

        if (string.IsNullOrWhiteSpace(request.Currency))
        {
            errors["currency"] = ["Currency is required."];
        }

        if (string.IsNullOrWhiteSpace(request.Purpose))
        {
            errors["purpose"] = ["Purpose is required."];
        }

        return errors;
    }

    private static Dictionary<string, string[]> ValidateQrPay(QrPayRequest request)
    {
        var errors = new Dictionary<string, string[]>(StringComparer.OrdinalIgnoreCase);

        if (!IsValidEmail(request.UserEmail))
        {
            errors["userEmail"] = ["A valid user email is required."];
        }

        if (string.IsNullOrWhiteSpace(request.QrPayload))
        {
            errors["qrPayload"] = ["QR payload is required."];
        }

        return errors;
    }

    private static Dictionary<string, string[]> ValidateTopUp(WalletTopUpRequest request)
    {
        var errors = new Dictionary<string, string[]>(StringComparer.OrdinalIgnoreCase);

        if (!IsValidEmail(request.UserEmail))
        {
            errors["userEmail"] = ["A valid user email is required."];
        }

        if (string.IsNullOrWhiteSpace(request.Currency))
        {
            errors["currency"] = ["Currency is required."];
        }

        if (request.Amount <= 0)
        {
            errors["amount"] = ["Amount must be greater than zero."];
        }

        return errors;
    }

    private static Dictionary<string, string[]> ValidateCreateRequest(CreatePaymentRequestRequest request)
    {
        var errors = new Dictionary<string, string[]>(StringComparer.OrdinalIgnoreCase);

        if (!IsValidEmail(request.RequesterEmail))
        {
            errors["requesterEmail"] = ["A valid requester email is required."];
        }

        if (!IsValidEmail(request.RecipientEmail))
        {
            errors["recipientEmail"] = ["A valid recipient email is required."];
        }

        if (request.Amount <= 0)
        {
            errors["amount"] = ["Amount must be greater than zero."];
        }

        if (string.IsNullOrWhiteSpace(request.Currency))
        {
            errors["currency"] = ["Currency is required."];
        }

        if (string.IsNullOrWhiteSpace(request.Country))
        {
            errors["country"] = ["Country is required."];
        }

        if (string.Equals(request.RequesterEmail?.Trim(), request.RecipientEmail?.Trim(), StringComparison.OrdinalIgnoreCase))
        {
            errors["recipientEmail"] = ["Requester and recipient must be different accounts."];
        }

        return errors;
    }

    private static Dictionary<string, string[]> ValidateApproveRequest(ApprovePaymentRequestRequest request)
    {
        var errors = new Dictionary<string, string[]>(StringComparer.OrdinalIgnoreCase);

        if (!IsValidEmail(request.UserEmail))
        {
            errors["userEmail"] = ["A valid user email is required."];
        }

        return errors;
    }

    private static bool TryParseQrPayload(string payload, out QrPayloadData data, out string error)
    {
        data = new QrPayloadData("", 0, "KES", "Kenya");
        error = string.Empty;

        if (!Uri.TryCreate(payload.Trim(), UriKind.Absolute, out var uri))
        {
            error = "Invalid QR payload format.";
            return false;
        }

        var query = ParseQuery(uri.Query);

        if (!query.TryGetValue("ref", out var reference) || string.IsNullOrWhiteSpace(reference))
        {
            error = "QR payload is missing reference.";
            return false;
        }

        if (!query.TryGetValue("amount", out var amountRaw) ||
            !decimal.TryParse(amountRaw, NumberStyles.Number, CultureInfo.InvariantCulture, out var amount) ||
            amount <= 0)
        {
            error = "QR payload contains invalid amount.";
            return false;
        }

        var currency = query.TryGetValue("currency", out var parsedCurrency) && !string.IsNullOrWhiteSpace(parsedCurrency)
            ? parsedCurrency.Trim().ToUpperInvariant()
            : "KES";

        var country = query.TryGetValue("country", out var parsedCountry) && !string.IsNullOrWhiteSpace(parsedCountry)
            ? Uri.UnescapeDataString(parsedCountry).Trim()
            : "Kenya";

        data = new QrPayloadData(reference.Trim(), amount, currency, country);
        return true;
    }

    private static Dictionary<string, string> ParseQuery(string query)
    {
        var result = new Dictionary<string, string>(StringComparer.OrdinalIgnoreCase);
        var trimmed = query.StartsWith('?') ? query[1..] : query;

        foreach (var pair in trimmed.Split('&', StringSplitOptions.RemoveEmptyEntries))
        {
            var separator = pair.IndexOf('=');
            if (separator < 0)
            {
                continue;
            }

            var key = Uri.UnescapeDataString(pair[..separator]);
            var value = Uri.UnescapeDataString(pair[(separator + 1)..]);
            result[key] = value;
        }

        return result;
    }

    private sealed record QrPayloadData(string Reference, decimal Amount, string Currency, string Country);

    private static byte[] BuildQrPng(string payload)
    {
        using var generator = new QRCodeGenerator();
        using var data = generator.CreateQrCode(payload, QRCodeGenerator.ECCLevel.Q);
        return new PngByteQRCode(data).GetGraphic(12);
    }

    private static string BuildQrImageDataUrl(string payload)
    {
        var png = BuildQrPng(payload);
        return $"data:image/png;base64,{Convert.ToBase64String(png)}";
    }

    private static bool IsValidEmail(string email)
    {
        if (string.IsNullOrWhiteSpace(email))
        {
            return false;
        }

        try
        {
            var _ = new MailAddress(email);
            return true;
        }
        catch (FormatException)
        {
            return false;
        }
    }
}
