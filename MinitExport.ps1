$ErrorActionPreference = [System.Management.Automation.ActionPreference]::Stop

. "$PSScriptRoot\Utils.ps1"

$OutDir = ((Resolve-Path $PSScriptRoot).Path -Eq (Resolve-Path .).Path) ? ".\Out" : "."
New-Item -ItemType Directory -Force $OutDir | Out-Null

Log-Output $Log
Log-Output $Log "### $($MyInvocation.MyCommand.Name -Replace '\.ps1$') ###".PadRight(75, '#')
Log-Output $Log

$Cfg = ReadConfig
Login

$Today = [System.DateOnly]::FromDateTime([DateTime]::Now)
$MonthStart = $Today.AddDays(1 - $Today.Day).AddMonths(1)

$ZerosCount = 0

While ($ZerosCount -LT 10)
{
    Log-Output $Log "Getting month $($MonthStart.ToString("yyyy-MM-dd"))..."

    $LogPrefix = "   "
    For ($III = 0; $III -NE -1;)
    {
        Try
        {
            $TimeChunks = GetTimeChunks @{
                from = [Long] (Get-Date -UFormat '%s' $MonthStart.ToDateTime([System.TimeOnly]::MinValue)) * 1000
                to = [Long] (Get-Date -UFormat '%s' $MonthStart.AddMonths(1).ToDateTime([System.TimeOnly]::MinValue)) * 1000 - 1
            }
            Break
        }
        Catch
        {
            $III += 1
            If ($III -GE 10)
            {
                $III = -1
                Log-Output $Log -Kind Error "Enough retries."
                Throw
            }
            Else
            {
                Log-Output $Log -Kind Warning "An error occurred. Retrying..."
                Start-Sleep -Seconds 1
            }
        }
    }

    If ($TimeChunks.Length -Eq 0)
    {
        $ZerosCount += 1
    }
    Else
    {
        $ZerosCount = 0
    }

    $TimeChunks | ConvertTo-Json -Depth 100 | Out-File "$OutDir\$($MonthStart.ToString("yyyy-MM-dd")).json"

    $MonthStart = $MonthStart.AddMonths(-1)
}
