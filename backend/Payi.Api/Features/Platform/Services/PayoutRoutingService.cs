using Payi.Api.Features.Platform.Contracts;

namespace Payi.Api.Features.Platform.Services;

public static class PayoutRoutingService
{
    private static readonly Dictionary<string, PayoutOptionResponse> CountryRoutes =
        new(StringComparer.OrdinalIgnoreCase)
        {
            ["KE"] = new("Kenya", "KE", "M-Pesa", "Mobile money settlement supported for eligible KES payouts."),
            ["CN"] = new("China", "CN", "Alipay", "Wallet settlement routed through Alipay partner rails."),
            ["NG"] = new("Nigeria", "NG", "Bank Transfer", "Settlement routed through approved Nigerian bank transfer partners."),
            ["AE"] = new("United Arab Emirates", "AE", "Bank Transfer", "Settlement routed through approved local bank partners."),
            ["SA"] = new("Saudi Arabia", "SA", "Bank Transfer", "Settlement routed through approved local bank partners.")
        };

    public static PayoutOptionResponse Resolve(string country)
    {
        if (string.IsNullOrWhiteSpace(country))
        {
            return new("Unknown", "N/A", "Bank Transfer", "Country not provided. Defaulting to standard bank payout rail.");
        }

        var normalized = country.Trim();
        var code = normalized.Length == 2 ? normalized.ToUpperInvariant() : MapNameToCode(normalized);

        return code is not null && CountryRoutes.TryGetValue(code, out var route)
            ? route
            : new(normalized, code ?? "N/A", "Bank Transfer", "No dedicated mobile wallet route configured for this country yet.");
    }

    private static string? MapNameToCode(string countryName)
    {
        return countryName.ToLowerInvariant() switch
        {
            "kenya" => "KE",
            "china" => "CN",
            "nigeria" => "NG",
            "united arab emirates" => "AE",
            "uae" => "AE",
            "saudi arabia" => "SA",
            _ => null
        };
    }
}
