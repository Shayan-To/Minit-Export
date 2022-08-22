Try
{
    [System.Net.WebClient2] | Out-Null
}
Catch
{
    Add-Type -TypeDefinition (Get-Content -Raw "$PSScriptRoot\WebClient2.cs") -Language CSharp
}

Function Log-Output([ValidateNotNullOrEmpty()] [String] $File, $Output, [ValidateSet("Normal", "Warning", "Error")] $Kind = "Normal")
{
    $Color = @{}
    If ($Kind -Eq 'Warning')
    {
        $Color.ForegroundColor = [System.ConsoleColor]::Yellow
    }
    If ($Kind -Eq 'Error')
    {
        $Color.ForegroundColor = [System.ConsoleColor]::Red
    }
    Write-Host @Color "$Output"
    "$(Get-Date -Format 'yyyy-MM-dd hh:mm:ss.fff tt') [$Kind]$([String]::New(" "[0], 7 - $Kind.Length)) :: $Output" | Out-File -Append $File
}

Function New-Aes($Password)
{
    $KeyByte = [System.Text.Encoding]::UTF8.GetBytes($Password)

    $Sha256 = [System.Security.Cryptography.SHA256]::Create()
    $Key = $Sha256.ComputeHash($KeyByte)
    $Sha256.Dispose()

    $MD5 = [System.Security.Cryptography.MD5]::Create()
    $IV = $MD5.ComputeHash($KeyByte)
    $MD5.Dispose()

    $Aes = [System.Security.Cryptography.Aes]::Create()
    $Aes.KeySize = 256
    $Aes.Key = $Key
    $Aes.IV = $IV
    $Aes.Mode = [System.Security.Cryptography.CipherMode]::CBC
    $Aes.Padding = [System.Security.Cryptography.PaddingMode]::PKCS7

    Return $Aes
}

Function Hardify($Str, $Password, [Switch] $Softify)
{
    $Aes = New-Aes $Password

    $Transformer = $Softify ? $Aes.CreateDecryptor() : $Aes.CreateEncryptor()

    $Data = $Softify ? [System.Convert]::FromBase64String($Str) : [System.Text.Encoding]::UTF8.GetBytes($Str)
    $Stream = [System.IO.MemoryStream]::New()
    $CrypStream = [System.Security.Cryptography.CryptoStream]::New($Stream, $Transformer, [System.Security.Cryptography.CryptoStreamMode]::Write)
    $CrypStream.Write($Data)
    $CrypStream.Dispose()
    $Transformer.Dispose()
    $Aes.Dispose()

    Return $Softify ? [System.Text.Encoding]::UTF8.GetString($Stream.ToArray()) : [System.Convert]::ToBase64String($Stream.ToArray())
}

Function Get-HeaderString
{
    [CmdletBinding(PositionalBinding = $False)]
    [OutputType([String])]
    Param
    (
        [Parameter(
            Mandatory = $True,
            ParameterSetName = 'Request Header')]
        [Alias("Req", 'Request')]
        [System.Net.HttpRequestHeader]
        $RequestHeader,
        [Parameter(
            Mandatory = $True,
            ParameterSetName = 'Response Header')]
        [Alias("Res", "Response")]
        [System.Net.HttpResponseHeader]
        $ResponseHeader
    )

    If ($PSCmdlet.ParameterSetName -Eq 'Request Header')
    {
        Return @(
            "Cache-Control",
            "Connection",
            "Date",
            "Keep-Alive",
            "Pragma",
            "Trailer",
            "Transfer-Encoding",
            "Upgrade",
            "Via",
            "Warning",
            "Allow",
            "Content-Length",
            "Content-Type",
            "Content-Encoding",
            "Content-Language",
            "Content-Location",
            "Content-MD5",
            "Content-Range",
            "Expires",
            "Last-Modified",
            "Accept",
            "Accept-Charset",
            "Accept-Encoding",
            "Accept-Language",
            "Authorization",
            "Cookie",
            "Expect",
            "From",
            "Host",
            "If-Match",
            "If-Modified-Since",
            "If-None-Match",
            "If-Range",
            "If-Unmodified-Since",
            "Max-Forwards",
            "Proxy-Authorization",
            "Referer",
            "Range",
            "Te",
            "Translate",
            "User-Agent"
        )[$RequestHeader]
    }
    Else
    {
        Return @(
            "Cache-Control",
            "Connection",
            "Date",
            "Keep-Alive",
            "Pragma",
            "Trailer",
            "Transfer-Encoding",
            "Upgrade",
            "Via",
            "Warning",
            "Allow",
            "Content-Length",
            "Content-Type",
            "Content-Encoding",
            "Content-Language",
            "Content-Location",
            "Content-MD5",
            "Content-Range",
            "Expires",
            "Last-Modified",
            "Accept-Ranges",
            "Age",
            "ETag",
            "Location",
            "Proxy-Authenticate",
            "Retry-After",
            "Server",
            "Set-Cookie",
            "Vary",
            "WWW-Authenticate"
        )[$ResponseHeader]
    }
}

Function Join-Dic($Dic, [String] $Separator)
{
    Return ($Dic.GetEnumerator() | ? { $Null -NE $_.Value } | % { $_.Key + '=' + $_.Value }) -Join $Separator
}
