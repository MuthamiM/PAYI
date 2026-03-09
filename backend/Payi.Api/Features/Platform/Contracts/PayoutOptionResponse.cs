namespace Payi.Api.Features.Platform.Contracts;

public sealed record PayoutOptionResponse(
    string Country,
    string CountryCode,
    string PreferredRail,
    string SettlementNote
);
