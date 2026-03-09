namespace Payi.Api.Features.Platform.Contracts;

public sealed record PlatformOverviewResponse(
    string Name,
    string Headline,
    string Description,
    IReadOnlyCollection<string> CoverageRegions
);
