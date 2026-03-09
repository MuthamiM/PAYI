using Payi.Api.Features.Payments.Contracts;

namespace Payi.Api.Features.Payments.Services;

public static class PaymentMethodCatalog
{
    private static readonly IReadOnlyCollection<string> GlobalCards =
    [
        "Visa",
        "Mastercard",
        "American Express",
        "Discover",
        "Diners Club",
        "JCB",
        "UnionPay"
    ];

    public static PaymentMethodResponse Resolve(string? country)
    {
        var normalized = (country ?? "Global").Trim();
        var code = normalized.ToUpperInvariant();

        return code switch
        {
            "KENYA" or "KE" => new(
                "Kenya",
                ["QR Code", "Bank Card", "Bank Transfer", "M-Pesa", "Card on File"],
                [.. GlobalCards, "Verve"],
                ["M-Pesa"],
                "M-Pesa is preferred for local mobile payouts; major global cards are enabled via partner acquirers."),
            "CHINA" or "CN" => new(
                "China",
                ["QR Code", "Bank Card", "Bank Transfer", "Alipay", "Card on File"],
                [.. GlobalCards, "UnionPay"],
                ["Alipay"],
                "Alipay and UnionPay are prioritized where partner corridor rails are available."),
            "RUSSIA" or "RU" => new(
                "Russia",
                ["QR Code", "Bank Card", "Bank Transfer"],
                [.. GlobalCards, "MIR"],
                [],
                "Availability depends on corridor compliance checks and partner bank enablement."),
            "TAIWAN" or "TW" => new(
                "Taiwan",
                ["QR Code", "Bank Card", "Bank Transfer"],
                [.. GlobalCards, "JCB"],
                [],
                "Card acceptance supports global schemes and partner domestic bank cards."),
            "MONGOLIA" or "MN" => new(
                "Mongolia",
                ["QR Code", "Bank Card", "Bank Transfer"],
                [.. GlobalCards],
                [],
                "Bank card and transfer rails enabled through partner financial institutions."),
            "SAUDI ARABIA" or "SA" => new(
                "Saudi Arabia",
                ["QR Code", "Bank Card", "Bank Transfer"],
                [.. GlobalCards, "mada"],
                [],
                "mada and global cards are supported based on acquirer and issuer participation."),
            "EGYPT" or "EG" => new(
                "Egypt",
                ["QR Code", "Bank Card", "Bank Transfer"],
                [.. GlobalCards, "Meeza"],
                [],
                "Meeza and international cards supported with corridor-level controls."),
            "NIGERIA" or "NG" => new(
                "Nigeria",
                ["QR Code", "Bank Card", "Bank Transfer"],
                [.. GlobalCards, "Verve"],
                [],
                "Verve and international card acceptance available in approved corridors."),
            _ => new(
                string.IsNullOrWhiteSpace(country) ? "Global" : normalized,
                ["QR Code", "Bank Card", "Bank Transfer", "Card on File"],
                [.. GlobalCards, "RuPay", "MIR", "Verve", "mada", "Meeza"],
                ["M-Pesa", "Alipay"],
                "Method availability depends on destination regulations, issuer/acquirer support, and corridor policy.")
        };
    }

    public static string ResolveDefaultRail(string country, string? requestedMethod)
    {
        if (!string.IsNullOrWhiteSpace(requestedMethod))
        {
            return requestedMethod.Trim();
        }

        return country.Trim().ToUpperInvariant() switch
        {
            "KENYA" or "KE" => "M-Pesa",
            "CHINA" or "CN" => "Alipay",
            "NIGERIA" or "NG" => "Bank Transfer",
            _ => "Bank Transfer"
        };
    }
}
