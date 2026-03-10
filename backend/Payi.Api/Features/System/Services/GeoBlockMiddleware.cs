using Microsoft.Extensions.Caching.Memory;
using System.Text.Json.Serialization;

namespace Payi.Api.Features.System.Services;

public class GeoBlockMiddleware(RequestDelegate next, IMemoryCache cache, IHttpClientFactory httpClientFactory, ILogger<GeoBlockMiddleware> logger)
{
    // Allowed ISO-3166-1 alpha-2 country codes based on supported corridors
    // Corridors: Africa, China, Middle East, Asia, Russia
    private static readonly HashSet<string> AllowedRegions = 
    [
        "CN", "RU", "NG", "ZA", "KE", "EG", "GH", "UG", "TZ", "RW", "MA", "DZ", // Africa, China, Russia
        "AE", "SA", "QA", "KW", "BH", "OM", "IL", "JO", "LB", // Middle East
        "IN", "SG", "JP", "MY", "TH", "VN", "ID", "PH", "KR", "PK", "BD" // Asia
    ];

    public async Task InvokeAsync(HttpContext context)
    {
        var ip = context.Connection.RemoteIpAddress?.ToString();
        
        // Allow localhost for development
        if (string.IsNullOrEmpty(ip) || ip == "127.0.0.1" || ip == "::1")
        {
            await next(context);
            return;
        }

        var key = $"IP_Block_{ip}";
        // Use memory cache to avoid hitting the free API limits (45 req/min)
        if (!cache.TryGetValue(key, out GeoBlockResult? blockResult))
        {
            blockResult = new GeoBlockResult { IsBlocked = false };
            try
            {
                var client = httpClientFactory.CreateClient("GeoIP");
                // Calling ip-api.com to verify proxy, hosting, and countryCode
                var response = await client.GetFromJsonAsync<IpApiResponse>($"http://ip-api.com/json/{ip}?fields=status,countryCode,proxy,hosting");
                
                if (response != null && response.Status == "success")
                {
                    bool isVpnOrProxy = response.Proxy || response.Hosting;
                    bool isAllowedCountry = AllowedRegions.Contains(response.CountryCode);
                    
                    blockResult.IsBlocked = isVpnOrProxy || !isAllowedCountry;
                    
                    if (blockResult.IsBlocked) 
                    {
                        blockResult.Reason = isVpnOrProxy 
                            ? "VPN/Datacenter IP detected." 
                            : $"Operating from unsupported region: {response.CountryCode}.";
                        logger.LogWarning("Blocked IP {IP}. Reason: {Reason}", ip, blockResult.Reason);
                    }
                }
            }
            catch (Exception ex)
            {
                logger.LogError(ex, "Failed to check IP {IP}", ip);
                // Fail open if the geo API is down
            }
            
            // Cache result for 1 hour
            cache.Set(key, blockResult, TimeSpan.FromHours(1));
        }

        if (blockResult?.IsBlocked == true)
        {
            context.Response.StatusCode = StatusCodes.Status403Forbidden;
            context.Response.ContentType = "text/html; charset=utf-8";
            
            var html = $@"
<!DOCTYPE html>
<html lang='en'>
<head>
    <meta charset='UTF-8'>
    <meta name='viewport' content='width=device-width, initial-scale=1.0'>
    <title>Access Denied - PAYI</title>
    <style>
        body {{
            margin: 0;
            padding: 0;
            background: #0f172a;
            color: #f8fafc;
            font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, Oxygen, Ubuntu, Cantarell, 'Open Sans', 'Helvetica Neue', sans-serif;
            display: flex;
            align-items: center;
            justify-content: center;
            min-height: 100vh;
        }}
        .container {{
            background: rgba(255, 255, 255, 0.05);
            backdrop-filter: blur(20px);
            -webkit-backdrop-filter: blur(20px);
            border: 1px solid rgba(255, 255, 255, 0.1);
            border-radius: 16px;
            padding: 40px;
            max-width: 500px;
            text-align: center;
            box-shadow: 0 25px 50px -12px rgba(0, 0, 0, 0.5);
        }}
        h1 {{
            color: #fb7185;
            margin-top: 0;
            font-size: 24px;
        }}
        p {{
            color: #94a3b8;
            line-height: 1.6;
            margin-bottom: 24px;
        }}
        .reason {{
            background: rgba(0, 0, 0, 0.3);
            border: 1px solid rgba(251, 113, 133, 0.2);
            padding: 12px;
            border-radius: 8px;
            font-family: monospace;
            color: #fda4af;
            font-size: 14px;
        }}
        .brand {{
            font-weight: 800;
            color: #14b8a6;
            letter-spacing: 1px;
            font-size: 18px;
            margin-bottom: 20px;
        }}
    </style>
</head>
<body>
    <div class='container'>
        <div class='brand'>PAYI</div>
        <h1>Security Policy Violation</h1>
        <p>Your access has been blocked. Connections through commercial VPNs, proxies, datacenter IPs, or from unsupported geographical regions are strictly prohibited on this financial platform.</p>
        <div class='reason'>{blockResult.Reason}</div>
    </div>
</body>
</html>";
            await context.Response.WriteAsync(html);
            return;
        }

        await next(context);
    }
}

public class GeoBlockResult
{
    public bool IsBlocked { get; set; }
    public string Reason { get; set; } = "";
}

public class IpApiResponse
{
    [JsonPropertyName("status")]
    public string Status { get; set; } = "";
    
    [JsonPropertyName("countryCode")]
    public string CountryCode { get; set; } = "";
    
    [JsonPropertyName("proxy")]
    public bool Proxy { get; set; }
    
    [JsonPropertyName("hosting")]
    public bool Hosting { get; set; }
}

public static class GeoBlockMiddlewareExtensions
{
    public static IApplicationBuilder UseGeoBlocking(this IApplicationBuilder builder)
    {
        return builder.UseMiddleware<GeoBlockMiddleware>();
    }
}
