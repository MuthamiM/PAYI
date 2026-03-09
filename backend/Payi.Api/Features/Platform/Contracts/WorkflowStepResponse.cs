namespace Payi.Api.Features.Platform.Contracts;

public sealed record WorkflowStepResponse(
    int StepNumber,
    string Title,
    string Description
);
