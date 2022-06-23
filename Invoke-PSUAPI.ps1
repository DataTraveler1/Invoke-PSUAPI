Function Invoke-PSUAPI {
    [CmdletBinding()]
    Param(
        [Parameter(Mandatory = $true)]
        [string]$server,
        [Parameter(Mandatory = $true)]
        [int32]$port,
        [Parameter(Mandatory = $true)]
        [string]$command,
        [Parameter(Mandatory = $true)]
        [ValidateSet('GET', 'POST', 'DELETE', 'PUT')]
        [string]$method,
        [Parameter(Mandatory = $true)]
        [string]$app_token,
        [Parameter(Mandatory = $false)]
        [hashtable]$body,
        [Parameter(Mandatory = $false)]
        [switch]$debug_mode
    )
    If ( $command -notlike '/*') {
        Write-Output "Error: The API command must begin with a forward slash (example: /version)"
        Return
    }
    If ( $port -lt 1 -or $port -gt 65535) {
        Write-Output "Error: The port must be at or between 1 and 65535"
        Return
    }
    If ( $server -like 'http*') {
        Write-Output "Error: Please do not include http in the server name. Just put the hostname of the server."
        Return
    }
    If ( $app_token -notmatch '^[0-9a-zA-Z.-]{1,}$') {
        Write-Output "Error: This does not appear to be a valid looking app token. Please confirm that this is a valid app token."
        Return
    }
    [string]$endpoint_url = ('http://' + $server + ':' + $port + '/api/v1' + $command)
    [hashtable]$headers = @{ Authorization = "Bearer $app_token" }
    $Error.Clear()
    [hashtable]$parameters = @{}
    $parameters.Add( 'Method', $method)
    $parameters.Add( 'Uri', $endpoint_url)
    $parameters.Add( 'ContentType', 'application/json')
    $parameters.Add( 'Headers', $headers)
    If( $null -ne $body)
    {
        $parameters.Add( 'Body', $body)
    }
    If( $debug_mode -eq $true)
    {
        [string]$parameters_display = $parameters | ConvertTo-Json -Depth 1
        Write-Output "Debug: Sending these parameters to the PSU API $parameters_display"
    }
    Try {
        [Microsoft.PowerShell.Commands.WebResponseObject]$response = Invoke-WebRequest @parameters
    }
    Catch {
        [array]$error_clone = $Error.Clone()
        [string]$error_message = $error_clone | Where-Object { $null -ne $_.Exception } | Select-Object -First 1 | Select-Object -ExpandProperty Exception
        Write-Output "Error: Invoke-WebRequest failed due to [$error_message]"
        Return
    }
    [int32]$response_code = $response.StatusCode
    If( $response_code -eq 200)
    {
        If($debug_mode -eq $true)
        {            
            Write-Output "Received status code [$response_code] on the request"
        }
    }
    Return $response.Content
}
