namespace Payi.Api.Features.Platform.Contracts;

public sealed record CorridorResponse(
    string CorridorCode,
    string SourceRegion,
    string DestinationRegion,
    string Status
);
