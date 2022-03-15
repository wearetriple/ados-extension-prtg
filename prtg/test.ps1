param(
    [string]$PRTGUsername,
    [string]$PRTGPasshash,
    [string]$PRTGEndpoint,
    [string]$PRTGSensorId,
    [string]$Action,
    [string]$MonitorPeriod = ''
)

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

        if ($sleep -gt 0)
        {
            Start-Sleep $sleep

            Write-Host "Checking status after $sleep s"
        }

        $Uri = "${PRTGEndpoint}/getobjectstatus.htm?id=${PRTGSensorId}&name=status&show=text&username=${PRTGUsername}&passhash=${PRTGPasshash}"

        [xml]$response = Invoke-RestMethod -Method Get -Uri $Uri

        if ($response.prtg.result -eq 'Up ') {

            Write-Host "Sensor is Up"

            exit;
        }

        $attempt++
    }
    while ($Start.Add($MaxPeriod) -gt (Get-Date));

    throw "Sensor did not get status Up within allowed timespan"
}