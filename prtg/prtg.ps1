Import-Module .\ps_modules\VstsTaskSdk\VstsTaskSdk.psm1

$PRTGUsername = Get-VstsInput -Name "PRTGUsername"
$PRTGPasshash = Get-VstsInput -Name "PRTGPasshash"
$PRTGEndpoint = Get-VstsInput -Name "PRTGEndpoint"
$PRTGSensorId = Get-VstsInput -Name "PRTGSensorId"
$Action = Get-VstsInput -Name "Action"
$MonitorPeriod = Get-VstsInput -Name "MonitorPeriod"

if ($Action -eq "pause") {

    Write-Host "Invoking '${PRTGEndpoint}/pause.htm?id=${PRTGSensorId}&pausemsg=Paused_By_Automation&action=0&username=x&passhash=x'"

    $Uri = "${PRTGEndpoint}/pause.htm?id=${PRTGSensorId}&pausemsg=Paused_By_Automation&action=0&username=${PRTGUsername}&passhash=${PRTGPasshash}"

    Invoke-RestMethod -Method Get -Uri $Uri
}
elseif ($Action -eq "resume") {

    Write-Host "Invoking '${PRTGEndpoint}/pause.htm?id=${PRTGSensorId}&action=1&username=x&passhash=x'"

    $Uri = "${PRTGEndpoint}/pause.htm?id=${PRTGSensorId}&action=1&username=${PRTGUsername}&passhash=${PRTGPasshash}"

    Invoke-RestMethod -Method Get -Uri $Uri

    Write-Host "Invoking '${PRTGEndpoint}/scannow.htm?id=${PRTGSensorId}&username=x&passhash=x'"

    $Uri = "${PRTGEndpoint}/scannow.htm?id=${PRTGSensorId}&username=${PRTGUsername}&passhash=${PRTGPasshash}"

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

        $now = Get-Date

        Write-Host "Invoking '${PRTGEndpoint}/getobjectstatus.htm?id=${PRTGSensorId}&name=status&show=text&username=x&passhash=x'"

        $Uri = "${PRTGEndpoint}/getobjectstatus.htm?id=${PRTGSensorId}&name=status&show=text&username=${PRTGUsername}&passhash=${PRTGPasshash}"

        [xml]$response = Invoke-RestMethod -Method Get -Uri $Uri

        $status = $response.prtg.result;

        if ($status -eq 'Up ') {

            Write-Host "${now}: Sensor is Up"

            exit;
        }
        else 
        {
            Write-Host "${now}: Sensor status is $status"
        }

        $attempt++
    }
    while ($Start.Add($MaxPeriod) -gt (Get-Date));

    throw "Sensor did not get status Up within allowed timespan"
}