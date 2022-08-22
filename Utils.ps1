. "$PSScriptRoot\Deps.ps1"

$ConfigFile = "$PSScriptRoot\Config.json"
$Log = "$PSScriptRoot\Log.log"

$CountAtATime = 50

$Password = '2F22B3F6A3BFCDE35C3D0DAB7048C39412613D22C535181EB8F8C826B66C39CA252E081CD2CBDFAC0C3DA6399562377C'

$BaseUrl = 'https://minitapp.ir'

$WC = [System.Net.WebClient2]::New()
# $WC = [FakeWebClient]::New()

$WC.Encoding = [System.Text.Encoding]::UTF8
#$WC.Proxy = [System.Net.WebProxy]::New('localhost', 8888)
$WC.Timeout = [TimeSpan]::FromSeconds(90)

$Cookies = @{}

Function Set-Headers
{
    $WC.Headers[[System.Net.HttpRequestHeader]::Cookie] = Join-Dic $Cookies '; '
}

Function ReadConfig
{
    Log-Output $Log 'Reading config file...'

    Return Get-Content -Raw $ConfigFile | ConvertFrom-Json -AsHashtable
}

Function Login
{
    Try
    {
        Log-Output $Log 'Logging in...'

        $Query = [System.Web.HttpUtility]::ParseQueryString('')
        $Query.Add('j_username', $Cfg.Email)
        $Query.Add('j_password', (Hardify -Softify $Cfg.Password $Password))
        $Query.Add('_spring_security_remember_me', 'on')

        $WC.Headers[(Get-HeaderString -Req ContentType)] = 'application/x-www-form-urlencoded'
        $WC.UploadString("$BaseUrl/j_spring_security_check", $Query.ToString())
        $ResponseHeaders = $WC.ResponseHeaders
    }
    Catch
    {
        [System.Net.WebException] $Ex = $_.Exception.InnerException
        If ($Ex.Response.StatusCode -NE [System.Net.HttpStatusCode]::Found)
        {
            Throw $Ex
        }
        $ResponseHeaders = $Ex.Response.Headers
    }

    $ResponseHeaders.GetValues((Get-HeaderString -Res SetCookie)) | % {
        $M = [Regex]::Match($_, '([^=]+)=([^;]+);')
        $Cookies[$M.Groups[1].Value] = $M.Groups[2].Value
    }
}

$LogPrefix = ""

Function GetTimeChunks($Filter)
{
    $Filter = $Filter | ConvertTo-Json
    $TotalCount = 1
    $Res = @()

    For ($I = 0; $I -LT $TotalCount; $I += $CountAtATime)
    {
        Log-Output $Log "${LogPrefix}Getting page... $($I + 1)-$($I + $CountAtATime) / $TotalCount"

        Set-Headers
        $WC.Headers['X-HTTP-Method-Override'] = 'GET'
        $WC.Headers[(Get-HeaderString -Req ContentType)] = 'application/json'
        $Chunks = $WC.UploadString("$BaseUrl/api/ws/$($Cfg.Workspace)/time_chunk/detail_items?extent=full&len=$CountAtATime&start=$I", $Filter)
                    | ConvertFrom-Json -AsHashtable

        $TotalCount = $Chunks.totalCount
        $Res += $Chunks.items
    }

    If ($Res.Length -NE $TotalCount)
    {
        Throw "Invalid number of time chunks."
    }

    Return $Res
}
