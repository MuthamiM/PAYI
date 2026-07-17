using Payi.Api.Features.Auth.Domain;
using Payi.Api.Features.Auth.Services;

namespace Payi.Api.Features.Kyc.Endpoints;

public static class KycEndpoints
{
    public static void Map(IEndpointRouteBuilder app)
    {
        var group = app.MapGroup("/api/kyc")
            .WithTags("KYC")
            .RequireRateLimiting("GeneralRateLimit")
            .AllowAnonymous();

        group.MapGet("/status", GetKycStatusAsync)
            .WithName("GetKycStatus")
            .WithSummary("Get the current KYC status for the user");

        group.MapPost("/submit", SubmitKycAsync)
            .WithName("SubmitKyc")
            .WithSummary("Submit KYC documents for verification")
            .DisableAntiforgery();
    }

    private static async Task<IResult> GetKycStatusAsync(
        HttpContext httpContext,
        IUserRepository userRepository,
        CancellationToken cancellationToken)
    {
        var userEmail = httpContext.Request.Headers["X-User-Email"].ToString();
        if (string.IsNullOrEmpty(userEmail))
        {
            return Results.BadRequest("User email is required.");
        }

        var user = await userRepository.GetByEmailAsync(userEmail, cancellationToken);
        if (user == null)
        {
            return Results.Ok(new { KycStatus = "Unverified" });
        }

        return Results.Ok(new { KycStatus = user.KycStatus });
    }

    private static async Task<IResult> SubmitKycAsync(
        HttpContext httpContext,
        IUserRepository userRepository,
        ILogger<object> logger,
        CancellationToken cancellationToken)
    {
        var userEmail = httpContext.Request.Headers["X-User-Email"].ToString();
        if (string.IsNullOrEmpty(userEmail))
        {
            return Results.BadRequest("User email is required.");
        }

        if (!httpContext.Request.HasFormContentType)
        {
            return Results.BadRequest("Request must be multipart/form-data.");
        }

        var form = await httpContext.Request.ReadFormAsync(cancellationToken);
        var faceDocument = form.Files.GetFile("faceDocument");
        var idDocument = form.Files.GetFile("idDocument");

        if (faceDocument == null || idDocument == null)
        {
            return Results.BadRequest("Both faceDocument and idDocument are required.");
        }

        var user = await userRepository.GetByEmailAsync(userEmail, cancellationToken);
        if (user == null)
        {
            return Results.NotFound("User not found.");
        }

        logger.LogInformation("Processing KYC for {Email}. Face: {FaceSize}B, ID: {IdSize}B",
            userEmail, faceDocument.Length, idDocument.Length);

        // Auto-approve integration for demo
        var updatedUser = new AppUser
        {
            Id = user.Id,
            ClerkId = user.ClerkId,
            Name = user.Name,
            Email = user.Email,
            PhoneNumber = user.PhoneNumber,
            Country = user.Country,
            DefaultCurrency = user.DefaultCurrency,
            PasswordHash = user.PasswordHash,
            CreatedAtUtc = user.CreatedAtUtc,
            KycStatus = "Verified"
        };

        await userRepository.UpdateAsync(updatedUser, cancellationToken);

        return Results.Ok(new { Message = "KYC submitted successfully and approved.", KycStatus = "Verified" });
    }
}
