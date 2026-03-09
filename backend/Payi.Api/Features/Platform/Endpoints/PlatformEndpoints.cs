using System.Net.Mail;
using Payi.Api.Features.Platform.Contracts;
using Payi.Api.Features.Platform.Services;

namespace Payi.Api.Features.Platform.Endpoints;

public static class PlatformEndpoints
{
    public static void Map(IEndpointRouteBuilder app)
    {
        var group = app.MapGroup("/api/platform").WithTags("Platform");

        group.MapGet("/overview", GetOverview)
            .WithName("GetPlatformOverview")
            .WithSummary("Get platform overview")
            .WithDescription("Returns high-level product scope and region coverage details.")
            .Produces<PlatformOverviewResponse>(StatusCodes.Status200OK)
            .CacheOutput("MediumApi");

        group.MapGet("/how-it-works", GetWorkflowSteps)
            .WithName("GetWorkflowSteps")
            .WithSummary("Get payment workflow steps")
            .WithDescription("Returns ordered operational steps from onboarding through settlement.")
            .Produces<IReadOnlyCollection<WorkflowStepResponse>>(StatusCodes.Status200OK)
            .CacheOutput("MediumApi");

        group.MapGet("/transparency-measures", GetTransparencyMeasures)
            .WithName("GetTransparencyMeasures")
            .WithSummary("Get transparency and safety controls")
            .WithDescription("Returns controls used for fee visibility, risk management, and audit readiness.")
            .Produces<IReadOnlyCollection<TransparencyMeasureResponse>>(StatusCodes.Status200OK)
            .CacheOutput("MediumApi");

        group.MapGet("/corridors", GetCorridors)
            .WithName("GetCorridors")
            .WithSummary("Get active corridor list")
            .WithDescription("Returns supported cross-border corridors and operational status.")
            .Produces<IReadOnlyCollection<CorridorResponse>>(StatusCodes.Status200OK)
            .CacheOutput("MediumApi");

        group.MapGet("/payout-options", GetPayoutOption)
            .WithName("GetPayoutOption")
            .WithSummary("Resolve payout rail by country")
            .WithDescription("Maps destination country to preferred payout rail (for example: Kenya to M-Pesa, China to Alipay).")
            .Produces<PayoutOptionResponse>(StatusCodes.Status200OK)
            .CacheOutput(policy => policy.Expire(TimeSpan.FromMinutes(3)).SetVaryByQuery("country"));

        group.MapPost("/contact", SubmitContactAsync)
            .WithName("SubmitContact")
            .WithSummary("Submit business/contact request")
            .WithDescription("Stores a contact request for platform onboarding or partnership follow-up.")
            .Produces<ContactResponse>(StatusCodes.Status201Created)
            .ProducesValidationProblem();
    }

    private static IResult GetOverview()
    {
        var response = new PlatformOverviewResponse(
            Name: "PAYI",
            Headline: "Cross-border billing and payment platform",
            Description: "Unified payment experience for regulated corridors between Africa, Asia, and the Middle East.",
            CoverageRegions: ["Africa", "Asia", "Middle East"]);

        return Results.Ok(response);
    }

    private static IResult GetWorkflowSteps()
    {
        WorkflowStepResponse[] steps =
        [
            new(1, "Onboard and verify", "Complete KYC/KYB checks and activate eligible destination corridors."),
            new(2, "Quote and confirm", "Get transparent FX and fee quote before confirming the transfer."),
            new(3, "Route and settle", "Platform routes payment to the best available rail for destination payout."),
            new(4, "Track and reconcile", "Receive transaction events and reports for finance and audit operations.")
        ];

        return Results.Ok(steps);
    }

    private static IResult GetTransparencyMeasures()
    {
        TransparencyMeasureResponse[] controls =
        [
            new("Pre-transaction fee disclosure", "Users can see charges and FX spread before sending funds."),
            new("Risk and sanctions screening", "Transactions are screened before release based on corridor policy."),
            new("Real-time transaction tracking", "Events are captured from initiation through settlement."),
            new("Immutable audit logs", "All critical actions are recorded for compliance and review."),
            new("Dual-control approvals", "Sensitive actions require explicit second-person approval.")
        ];

        return Results.Ok(controls);
    }

    private static IResult GetCorridors()
    {
        CorridorResponse[] corridors =
        [
            new("AFR-CHN", "Africa", "China", "Active"),
            new("AFR-NGA", "Africa", "Nigeria", "Active"),
            new("AFR-MEA", "Africa", "Middle East", "Active"),
            new("AFR-ASIA", "Africa", "Asia", "Active"),
            new("AFR-RUS", "Africa", "Russia", "Review Required")
        ];

        return Results.Ok(corridors);
    }

    private static IResult GetPayoutOption(string country)
    {
        var response = PayoutRoutingService.Resolve(country);
        return Results.Ok(response);
    }

    private static async Task<IResult> SubmitContactAsync(
        ContactRequest request,
        IContactRepository contactRepository,
        CancellationToken cancellationToken)
    {
        var errors = ValidateContactRequest(request);
        if (errors.Count > 0)
        {
            return Results.ValidationProblem(errors);
        }

        var message = new ContactMessage
        {
            ReferenceId = $"CNT-{DateTimeOffset.UtcNow:yyyyMMddHHmmss}-{Random.Shared.Next(1000, 9999)}",
            Name = request.Name.Trim(),
            Email = request.Email.Trim().ToLowerInvariant(),
            Message = request.Message.Trim(),
            ReceivedAtUtc = DateTimeOffset.UtcNow
        };

        await contactRepository.AddAsync(message, cancellationToken);

        var response = new ContactResponse(
            ReferenceId: message.ReferenceId,
            ReceivedAtUtc: message.ReceivedAtUtc,
            Message: "Thanks, your request has been submitted.");

        return Results.Created($"/api/platform/contact/{message.ReferenceId}", response);
    }

    private static Dictionary<string, string[]> ValidateContactRequest(ContactRequest request)
    {
        var errors = new Dictionary<string, string[]>(StringComparer.OrdinalIgnoreCase);

        if (string.IsNullOrWhiteSpace(request.Name))
        {
            errors["name"] = ["Name is required."];
        }

        if (!IsValidEmail(request.Email))
        {
            errors["email"] = ["A valid email is required."];
        }

        if (string.IsNullOrWhiteSpace(request.Message))
        {
            errors["message"] = ["Message is required."];
        }

        return errors;
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
