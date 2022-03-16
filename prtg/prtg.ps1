Import-Module .\ps_modules\VstsTaskSdk\VstsTaskSdk.psm1

$PRTGUsername = Get-VstsInput -Name "PRTGUsername"
$PRTGPasshash = Get-VstsInput -Name "PRTGPasshash"
$PRTGEndpoint = Get-VstsInput -Name "PRTGEndpoint"
$PRTGSensorId = Get-VstsInput -Name "PRTGSensorId"
$Action = Get-VstsInput -Name "Action"
$MonitorPeriod = Get-VstsInput -Name "MonitorPeriod"

if ($Action -eq "pause") {

    $Uri = "${PRTGEndpoint}/pause.htm?id=${PRTGSensorId}&pausemsg=Paused_By_Automation&action=0&username=${PRTGUsername}&passhash=${PRTGPasshash}"

    Invoke-RestMethod -Method Get -Uri $Uri
}
elseif ($Action -eq "resume") {

    $Uri = "${PRTGEndpoint}/pause.htm?id=${PRTGSensorId}&action=1&username=${PRTGUsername}&passhash=${PRTGPasshash}"

    Invoke-RestMethod -Method Get -Uri $Uri

}
elseif ($Action -eq "monitor") {

    $MaxPeriod = [System.TimeSpan]::Parse($MonitorPeriod)

    $Start = Get-Date
    $attempt = 0;
    $delay = [math]::Ceiling($MaxPeriod.TotalSeconds / 120.0);

    do
    {
        $sleep = ($attempt * $delay)
        $now = Get-Date

        if ($sleep -gt 0)
        {
            Write-Host "${now}: Checking status in $sleep s"

            Start-Sleep $sleep
        }

        $Uri = "${PRTGEndpoint}/getobjectstatus.htm?id=${PRTGSensorId}&name=status&show=text&username=${PRTGUsername}&passhash=${PRTGPasshash}"

        [xml]$response = Invoke-RestMethod -Method Get -Uri $Uri

        if ($response.prtg.result -eq 'Up ') {

            Write-Host "Sensor is Up"

            exit;
        }
        else 
        {
            Write-Host "Sensor status is ${response.prtg.result}"
        }

        $attempt++
    }
    while ($Start.Add($MaxPeriod) -gt (Get-Date));

    throw "Sensor did not get status Up within allowed timespan"
}