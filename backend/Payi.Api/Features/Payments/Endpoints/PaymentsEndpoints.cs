using System.Net.Mail;
using System.Globalization;
using System.Security.Cryptography;
using Payi.Api.Features.Auth.Domain;
using Payi.Api.Features.Auth.Services;
using Payi.Api.Features.Payments.Contracts;
using Payi.Api.Features.Payments.Domain;
using Payi.Api.Features.Payments.Services;
using Payi.Api.Features.System.Services;
using QRCoder;
using Stripe;

namespace Payi.Api.Features.Payments.Endpoints;

public static class PaymentsEndpoints
{
    private const decimal MaxTransferAmount = 1_000_000m;
    private const int MaxNameLength = 200;
    private const int MaxAccountLength = 254;
    private const int MaxCountryLength = 100;
    private const int MaxCurrencyLength = 3;
    private const int MaxNoteLength = 500;

    public static void Map(IEndpointRouteBuilder app)
    {
        var group = app.MapGroup("/api/payments")
            .WithTags("Payments")
            .AddEndpointFilter<AuthGuard>()
            .AddEndpointFilter<IdempotencyGuard>()
            .RequireRateLimiting("PaymentRateLimit");

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
            .ProducesValidationProblem()
            .AllowAnonymous();

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
            .WithDescription("Credits wallet balance. Requires authentication.")
            .Produces<WalletBalanceResponse>(StatusCodes.Status200OK)
            .ProducesValidationProblem();

        group.MapGet("/stripe/publishable-key", GetStripeKey)
            .WithName("GetStripeKey");

        group.MapPost("/stripe/create-intent", CreateStripeIntentAsync)
            .WithName("CreateStripeIntent");

        group.MapPost("/stripe/confirm", ConfirmStripeIntentAsync)
            .WithName("ConfirmStripeIntent");
    }

    /// <summary>
    /// Extracts the authenticated user's email from the AuthGuard-injected context.
    /// Returns null if HttpContext is missing (should not happen behind AuthGuard).
    /// </summary>
    private static string? GetAuthEmail(HttpContext context)
    {
        return context.Items.TryGetValue("AuthEmail", out var email) ? email as string : null;
    }

    private static async Task<IResult> GetTransactionsAsync(
        HttpContext httpContext,
        string userEmail,
        ITransactionRepository repository,
        CancellationToken cancellationToken)
    {
        var authEmail = GetAuthEmail(httpContext);
        var targetEmail = NormalizeEmail(userEmail);

        if (!string.Equals(authEmail, targetEmail, StringComparison.OrdinalIgnoreCase))
        {
            return Results.Problem(
                statusCode: StatusCodes.Status403Forbidden,
                title: "Forbidden",
                detail: "You can only view your own transactions.");
        }

        if (!IsValidEmail(userEmail))
        {
            return Results.ValidationProblem(new Dictionary<string, string[]>
            {
                ["userEmail"] = ["A valid user email is required."]
            });
        }

        var records = await repository.GetByUserEmailAsync(targetEmail, cancellationToken);
        var response = records.Select(ToResponse).ToArray();
        return Results.Ok(response);
    }

    private static async Task<IResult> SendAsync(
        HttpContext httpContext,
        SendPaymentRequest request,
        ITransactionRepository repository,
        IWalletRepository walletRepository,
        IUserRepository userRepository,
        IAuditLogger auditLogger,
        CancellationToken cancellationToken)
    {
        var authEmail = GetAuthEmail(httpContext);
        var senderEmail = NormalizeEmail(request.UserEmail);

        if (!string.Equals(authEmail, senderEmail, StringComparison.OrdinalIgnoreCase))
        {
            return Results.Problem(
                statusCode: StatusCodes.Status403Forbidden,
                title: "Forbidden",
                detail: "You can only send payments from your own account.");
        }

        var errors = ValidateSend(request);
        if (errors.Count > 0)
        {
            return Results.ValidationProblem(errors);
        }

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

        var clientIp = httpContext.Connection.RemoteIpAddress?.ToString();
        await auditLogger.LogAsync(new AuditEntry
        {
            Event = "Payment.Send",
            Actor = senderEmail,
            Target = tx.Reference,
            Detail = $"Sent {request.Amount:0.00} {currency} to {request.RecipientAccount.Trim()}.",
            IpAddress = clientIp
        }, cancellationToken);

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
        HttpContext httpContext,
        ReceivePaymentRequest request,
        ITransactionRepository repository,
        IWalletRepository walletRepository,
        CancellationToken cancellationToken)
    {
        var authEmail = GetAuthEmail(httpContext);
        var targetEmail = NormalizeEmail(request.UserEmail);

        if (!string.Equals(authEmail, targetEmail, StringComparison.OrdinalIgnoreCase))
        {
            return Results.Problem(
                statusCode: StatusCodes.Status403Forbidden,
                title: "Forbidden",
                detail: "You can only record receives for your own account.");
        }

        var errors = ValidateReceive(request);
        if (errors.Count > 0)
        {
            return Results.ValidationProblem(errors);
        }

        var currency = request.Currency.Trim().ToUpperInvariant();
        var credit = await walletRepository.CreditAsync(
            targetEmail,
            currency,
            request.Amount,
            cancellationToken);

        var tx = new PaymentTransaction
        {
            Reference = BuildReference("RCV"),
            UserEmail = targetEmail,
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
        HttpContext httpContext,
        CreatePaymentRequestRequest request,
        IPaymentRequestRepository requestRepository,
        IUserRepository userRepository,
        CancellationToken cancellationToken)
    {
        var authEmail = GetAuthEmail(httpContext);
        var requesterEmail = NormalizeEmail(request.RequesterEmail);

        if (!string.Equals(authEmail, requesterEmail, StringComparison.OrdinalIgnoreCase))
        {
            return Results.Problem(
                statusCode: StatusCodes.Status403Forbidden,
                title: "Forbidden",
                detail: "You can only create payment requests from your own account.");
        }

        var errors = ValidateCreateRequest(request);
        if (errors.Count > 0)
        {
            return Results.ValidationProblem(errors);
        }

        var recipientEmail = NormalizeEmail(request.RecipientEmail);

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
        HttpContext httpContext,
        string userEmail,
        IPaymentRequestRepository requestRepository,
        ITransactionRepository transactionRepository,
        CancellationToken cancellationToken)
    {
        var authEmail = GetAuthEmail(httpContext);
        var normalizedEmail = NormalizeEmail(userEmail);

        if (!string.Equals(authEmail, normalizedEmail, StringComparison.OrdinalIgnoreCase))
        {
            return Results.Problem(
                statusCode: StatusCodes.Status403Forbidden,
                title: "Forbidden",
                detail: "You can only view your own notifications.");
        }

        if (!IsValidEmail(userEmail))
        {
            return Results.ValidationProblem(new Dictionary<string, string[]>
            {
                ["userEmail"] = ["A valid user email is required."]
            });
        }

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
        HttpContext httpContext,
        Guid id,
        ApprovePaymentRequestRequest request,
        IPaymentRequestRepository requestRepository,
        ITransactionRepository transactionRepository,
        IWalletRepository walletRepository,
        IUserRepository userRepository,
        IAuditLogger auditLogger,
        CancellationToken cancellationToken)
    {
        var authEmail = GetAuthEmail(httpContext);
        var approverEmail = NormalizeEmail(request.UserEmail);

        if (!string.Equals(authEmail, approverEmail, StringComparison.OrdinalIgnoreCase))
        {
            return Results.Problem(
                statusCode: StatusCodes.Status403Forbidden,
                title: "Forbidden",
                detail: "You can only approve requests as your own account.");
        }

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

        var clientIp = httpContext.Connection.RemoteIpAddress?.ToString();
        await auditLogger.LogAsync(new AuditEntry
        {
            Event = "PaymentRequest.Approve",
            Actor = approverEmail,
            Target = paymentRequest.Id.ToString(),
            Detail = $"Approved request for {paymentRequest.Amount:0.00} {paymentRequest.Currency} from {paymentRequest.RequesterEmail}.",
            IpAddress = clientIp
        }, cancellationToken);

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
        HttpContext httpContext,
        QrPaymentRequest request,
        ITransactionRepository repository,
        CancellationToken cancellationToken)
    {
        var authEmail = GetAuthEmail(httpContext);
        var targetEmail = NormalizeEmail(request.UserEmail);

        if (!string.Equals(authEmail, targetEmail, StringComparison.OrdinalIgnoreCase))
        {
            return Results.Problem(
                statusCode: StatusCodes.Status403Forbidden,
                title: "Forbidden",
                detail: "You can only create QR requests for your own account.");
        }

        var errors = ValidateQr(request);
        if (errors.Count > 0)
        {
            return Results.ValidationProblem(errors);
        }

        var reference = BuildReference("QR");
        var tx = new PaymentTransaction
        {
            Reference = reference,
            UserEmail = targetEmail,
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
        HttpContext httpContext,
        QrPayRequest request,
        ITransactionRepository transactionRepository,
        IWalletRepository walletRepository,
        CancellationToken cancellationToken)
    {
        var authEmail = GetAuthEmail(httpContext);
        var targetEmail = NormalizeEmail(request.UserEmail);

        if (!string.Equals(authEmail, targetEmail, StringComparison.OrdinalIgnoreCase))
        {
            return Results.Problem(
                statusCode: StatusCodes.Status403Forbidden,
                title: "Forbidden",
                detail: "You can only pay from your own account.");
        }

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
            targetEmail,
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
            UserEmail = targetEmail,
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
        HttpContext httpContext,
        string userEmail,
        IWalletRepository walletRepository,
        CancellationToken cancellationToken)
    {
        var authEmail = GetAuthEmail(httpContext);
        var targetEmail = NormalizeEmail(userEmail);

        if (!string.Equals(authEmail, targetEmail, StringComparison.OrdinalIgnoreCase))
        {
            return Results.Problem(
                statusCode: StatusCodes.Status403Forbidden,
                title: "Forbidden",
                detail: "You can only view your own wallet.");
        }

        if (!IsValidEmail(userEmail))
        {
            return Results.ValidationProblem(new Dictionary<string, string[]>
            {
                ["userEmail"] = ["A valid user email is required."]
            });
        }

        var wallet = await walletRepository.GetOrCreateAsync(targetEmail, cancellationToken);
        var response = new WalletBalanceResponse(wallet.UserEmail, wallet.Balances, wallet.UpdatedAtUtc);
        return Results.Ok(response);
    }

    private static async Task<IResult> TopUpWalletAsync(
        HttpContext httpContext,
        WalletTopUpRequest request,
        IWalletRepository walletRepository,
        ITransactionRepository transactionRepository,
        IConfiguration config,
        CancellationToken cancellationToken)
    {
        var authEmail = GetAuthEmail(httpContext);
        var targetEmail = NormalizeEmail(request.UserEmail);

        if (!string.Equals(authEmail, targetEmail, StringComparison.OrdinalIgnoreCase))
        {
            return Results.Problem(
                statusCode: StatusCodes.Status403Forbidden,
                title: "Forbidden",
                detail: "You can only top up your own wallet.");
        }

        var maxTopUpPerTx = config.GetValue<decimal>("Security:MaxTopUpPerTransaction", 10000m);
        var errors = ValidateTopUp(request, maxTopUpPerTx);
        if (errors.Count > 0)
        {
            return Results.ValidationProblem(errors);
        }

        var maxTopUpPerDay = config.GetValue<decimal>("Security:MaxTopUpPerDay", 50000m);
        
        // Calculate daily top-up total
        var transactions = await transactionRepository.GetByUserEmailAsync(targetEmail, cancellationToken);
        var today = DateTimeOffset.UtcNow.Date;
        var dailyTopUpSum = transactions
            .Where(t => string.Equals(t.Method, "Top-Up", StringComparison.OrdinalIgnoreCase) && 
                        t.CreatedAtUtc.Date == today)
            .Sum(t => t.Amount);

        if (dailyTopUpSum + request.Amount > maxTopUpPerDay)
        {
            return Results.Problem(
                statusCode: StatusCodes.Status422UnprocessableEntity,
                title: "Daily Limit Exceeded",
                detail: $"This top-up exceeds your daily limit of {maxTopUpPerDay:N0} {request.Currency}. Remaining allowance: {Math.Max(0, maxTopUpPerDay - dailyTopUpSum):N0}.");
        }

        await walletRepository.CreditAsync(
            targetEmail,
            request.Currency.Trim().ToUpperInvariant(),
            request.Amount,
            cancellationToken);

        // Record the top-up as a transaction to track volume
        var tx = new PaymentTransaction
        {
            Reference = BuildReference("TOP"),
            UserEmail = targetEmail,
            Direction = "Receive",
            CounterpartyName = "External Funding",
            Country = "Global",
            Method = "Top-Up",
            Amount = request.Amount,
            Currency = request.Currency.Trim().ToUpperInvariant(),
            Status = "Completed",
            CreatedAtUtc = DateTimeOffset.UtcNow
        };
        await transactionRepository.AddAsync(tx, cancellationToken);

        var wallet = await walletRepository.GetOrCreateAsync(targetEmail, cancellationToken);
        var response = new WalletBalanceResponse(wallet.UserEmail, wallet.Balances, wallet.UpdatedAtUtc);
        return Results.Ok(response);
    }

    private static IResult GetStripeKey(IConfiguration config)
    {
        var key = config["Stripe:PublishableKey"];
        return Results.Ok(new { PublishableKey = key });
    }

    private static async Task<IResult> CreateStripeIntentAsync(
        HttpContext httpContext,
        StripePaymentIntentRequest request,
        IConfiguration config)
    {
        var authEmail = GetAuthEmail(httpContext);
        var targetEmail = NormalizeEmail(request.UserEmail);

        if (!string.Equals(authEmail, targetEmail, StringComparison.OrdinalIgnoreCase))
        {
            return Results.Problem(statusCode: 403, title: "Forbidden", detail: "Can only top up own wallet.");
        }

        var amountInCents = (long)(request.Amount * 100);

        var options = new PaymentIntentCreateOptions
        {
            Amount = amountInCents,
            Currency = request.Currency.Trim().ToLowerInvariant(),
            ReceiptEmail = targetEmail,
            Metadata = new Dictionary<string, string>
            {
                { "userEmail", targetEmail }
            }
        };

        var service = new PaymentIntentService();
        try
        {
            var intent = await service.CreateAsync(options);
            return Results.Ok(new StripePaymentIntentResponse(
                intent.ClientSecret,
                intent.Id,
                config["Stripe:PublishableKey"] ?? ""));
        }
        catch (StripeException e)
        {
            return Results.Problem(statusCode: 400, title: "Stripe Error", detail: e.StripeError.Message);
        }
    }

    private static async Task<IResult> ConfirmStripeIntentAsync(
        HttpContext httpContext,
        StripeConfirmRequest request,
        IWalletRepository walletRepository,
        ITransactionRepository transactionRepository,
        CancellationToken cancellationToken)
    {
        var authEmail = GetAuthEmail(httpContext);
        var targetEmail = NormalizeEmail(request.UserEmail);

        if (!string.Equals(authEmail, targetEmail, StringComparison.OrdinalIgnoreCase))
        {
            return Results.Problem(statusCode: 403, title: "Forbidden", detail: "Can only confirm own top up.");
        }

        var service = new PaymentIntentService();
        try
        {
            var intent = await service.GetAsync(request.PaymentIntentId, cancellationToken: cancellationToken);

            if (intent.Status == "succeeded")
            {
                if (!intent.Metadata.TryGetValue("userEmail", out var metaEmail) || 
                    !string.Equals(metaEmail, targetEmail, StringComparison.OrdinalIgnoreCase))
                {
                    return Results.Problem(statusCode: 400, title: "Invalid", detail: "Payment intent does not match user.");
                }

                var amount = intent.Amount / 100.0m;

                await walletRepository.CreditAsync(
                    targetEmail,
                    request.Currency.Trim().ToUpperInvariant(),
                    amount,
                    cancellationToken);

                var tx = new PaymentTransaction
                {
                    Reference = BuildReference("STRIPE"),
                    UserEmail = targetEmail,
                    Direction = "Receive",
                    CounterpartyName = "Card Deposit",
                    Country = "Global",
                    Method = "Stripe",
                    Amount = amount,
                    Currency = request.Currency.Trim().ToUpperInvariant(),
                    Status = "Completed",
                    CreatedAtUtc = DateTimeOffset.UtcNow
                };
                await transactionRepository.AddAsync(tx, cancellationToken);
                
                var wallet = await walletRepository.GetOrCreateAsync(targetEmail, cancellationToken);
                return Results.Ok(new WalletBalanceResponse(wallet.UserEmail, wallet.Balances, wallet.UpdatedAtUtc));
            }

            return Results.Problem(statusCode: 400, title: "Payment Not Succeeded", detail: $"Status is {intent.Status}");
        }
        catch (StripeException e)
        {
            return Results.Problem(statusCode: 400, title: "Stripe Error", detail: e.StripeError.Message);
        }
    }

    // --- Mapping ---

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

    /// <summary>
    /// Generates a cryptographically-strong transaction reference.
    /// Format: PREFIX-YYYYMMDDHHmmss-XXXXXXXX (8 hex chars from crypto-random).
    /// </summary>
    private static string BuildReference(string prefix)
    {
        var randomHex = Convert.ToHexString(RandomNumberGenerator.GetBytes(4));
        return $"{prefix}-{DateTimeOffset.UtcNow:yyyyMMddHHmmss}-{randomHex}";
    }

    private static string NormalizeEmail(string email) => email.Trim().ToLowerInvariant();

    // --- Validation ---

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
        else if (request.DestinationCountry.Length > MaxCountryLength)
        {
            errors["destinationCountry"] = [$"Destination country must be {MaxCountryLength} characters or fewer."];
        }

        if (string.IsNullOrWhiteSpace(request.RecipientName))
        {
            errors["recipientName"] = ["Recipient name is required."];
        }
        else if (request.RecipientName.Length > MaxNameLength)
        {
            errors["recipientName"] = [$"Recipient name must be {MaxNameLength} characters or fewer."];
        }

        if (string.IsNullOrWhiteSpace(request.RecipientAccount))
        {
            errors["recipientAccount"] = ["Recipient account is required."];
        }
        else if (request.RecipientAccount.Length > MaxAccountLength)
        {
            errors["recipientAccount"] = [$"Recipient account must be {MaxAccountLength} characters or fewer."];
        }

        if (request.Amount <= 0)
        {
            errors["amount"] = ["Amount must be greater than zero."];
        }
        else if (request.Amount > MaxTransferAmount)
        {
            errors["amount"] = [$"Amount must not exceed {MaxTransferAmount:N0}."];
        }

        if (string.IsNullOrWhiteSpace(request.Currency))
        {
            errors["currency"] = ["Currency is required."];
        }
        else if (request.Currency.Length > MaxCurrencyLength)
        {
            errors["currency"] = [$"Currency code must be {MaxCurrencyLength} characters or fewer."];
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
        else if (request.SourceCountry.Length > MaxCountryLength)
        {
            errors["sourceCountry"] = [$"Source country must be {MaxCountryLength} characters or fewer."];
        }

        if (string.IsNullOrWhiteSpace(request.SenderName))
        {
            errors["senderName"] = ["Sender name is required."];
        }
        else if (request.SenderName.Length > MaxNameLength)
        {
            errors["senderName"] = [$"Sender name must be {MaxNameLength} characters or fewer."];
        }

        if (request.Amount <= 0)
        {
            errors["amount"] = ["Amount must be greater than zero."];
        }
        else if (request.Amount > MaxTransferAmount)
        {
            errors["amount"] = [$"Amount must not exceed {MaxTransferAmount:N0}."];
        }

        if (string.IsNullOrWhiteSpace(request.Currency))
        {
            errors["currency"] = ["Currency is required."];
        }
        else if (request.Currency.Length > MaxCurrencyLength)
        {
            errors["currency"] = [$"Currency code must be {MaxCurrencyLength} characters or fewer."];
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
        else if (request.Country.Length > MaxCountryLength)
        {
            errors["country"] = [$"Country must be {MaxCountryLength} characters or fewer."];
        }

        if (request.Amount <= 0)
        {
            errors["amount"] = ["Amount must be greater than zero."];
        }
        else if (request.Amount > MaxTransferAmount)
        {
            errors["amount"] = [$"Amount must not exceed {MaxTransferAmount:N0}."];
        }

        if (string.IsNullOrWhiteSpace(request.Currency))
        {
            errors["currency"] = ["Currency is required."];
        }
        else if (request.Currency.Length > MaxCurrencyLength)
        {
            errors["currency"] = [$"Currency code must be {MaxCurrencyLength} characters or fewer."];
        }

        if (string.IsNullOrWhiteSpace(request.Purpose))
        {
            errors["purpose"] = ["Purpose is required."];
        }
        else if (request.Purpose.Length > MaxNoteLength)
        {
            errors["purpose"] = [$"Purpose must be {MaxNoteLength} characters or fewer."];
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

    private static Dictionary<string, string[]> ValidateTopUp(WalletTopUpRequest request, decimal maxAmount)
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
        else if (request.Currency.Length > MaxCurrencyLength)
        {
            errors["currency"] = [$"Currency code must be {MaxCurrencyLength} characters or fewer."];
        }

        if (request.Amount <= 0)
        {
            errors["amount"] = ["Amount must be greater than zero."];
        }
        else if (request.Amount > maxAmount)
        {
            errors["amount"] = [$"Amount must not exceed {maxAmount:N0} per transaction."];
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
        else if (request.Amount > MaxTransferAmount)
        {
            errors["amount"] = [$"Amount must not exceed {MaxTransferAmount:N0}."];
        }

        if (string.IsNullOrWhiteSpace(request.Currency))
        {
            errors["currency"] = ["Currency is required."];
        }
        else if (request.Currency.Length > MaxCurrencyLength)
        {
            errors["currency"] = [$"Currency code must be {MaxCurrencyLength} characters or fewer."];
        }

        if (string.IsNullOrWhiteSpace(request.Country))
        {
            errors["country"] = ["Country is required."];
        }
        else if (request.Country.Length > MaxCountryLength)
        {
            errors["country"] = [$"Country must be {MaxCountryLength} characters or fewer."];
        }

        if (request.Note is not null && request.Note.Length > MaxNoteLength)
        {
            errors["note"] = [$"Note must be {MaxNoteLength} characters or fewer."];
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
