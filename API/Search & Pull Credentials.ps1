 $api = "https://win-ss-01.secretserver.local/api/v1"
    $token = "AgLlTE3q7bJKiisEEPVQYKcD3lR1xYSrsBmODY65nfr8wrUL8Zu0FBGvkEA83T53CZKZb9r_UFTfUAYQA0-9M3LN_MIpLueQ_EevL3wNc60qnPyevXLTHMqO98xiJhSPxGFZOuLpnaGYZtDKdOpkamdOm0twkkVH58IfQH7uOc2nmQrKKHibbArba-ToXl3AgiaChnvDIavnBT-IdqqsTgI3jGNeevKo3p1CYlcpLeRdF_RWV-bGUbrfikmp12-hyaGQQ5RKnMV87rjOjIIan3oP-f5pbVTBEiSFh48EilFsiCltHJKzutaUy8JHvnwH3-XzvEWPdaju3udi6nxWVH0sBQgczvVnYRmtKn6Mm66iKwhSpZbpLBT3Oqnh-4WmTWTdBxTYaCvg6Kd3HArzAUieBtFxl24w5M1i81p2wbT7aPDbkZ-84C3Nvw3QfGO-2SpYOwSwmMdF3XJcGk-w9enEkK7LjO-BzQ_CGk10hH2igZkoPpoJbHQAjultHkSmbfo3fRqBBcNaE1-aUAruSvIoJDdNP_V8CINloHlT6eQYsVGJEYLOOGowZdgFcquWQUsfZo11wGetCpbdUNKUntjtHieL8Fh8-NIo7Qes3kQstxhNs0IkDMp8ikP_gfdr-0xdgGvu3ysnEr9KBzyI2p0y-EgQ3MB4j5fLesJkKp0MFvxMdGbyx4deYv3QQET2e3OgUrjSjbnvNi5ObUhDPfCwqIUE3LsNoilGCCoDOqz1J1QKkXnyNaGuwXuG1tVTj6s"
    $searchtext = "darth.vader"

    $headers = New-Object "System.Collections.Generic.Dictionary[[String],[String]]"
    $headers.Add("Authorization", "Bearer $token")

    $filters = "?filter.HeartbeatStatus=1&filter.includeRestricted=true&filter.searchtext=$searchtext"

    Write-Host "------------------------------"
    Write-Host "---- Secret Search Values-----"
    Write-Host "------------------------------"

    #?filter.searchfield=username&filter.searchfield=displayname&filter.searchfield=filter.searchText=mister&filter.includeinactive=true" -Headers $headers

    $result = Invoke-RestMethod "$api/secrets$filters" -Headers $headers

    Write-Host $result.filter.searchField
    Write-Host $result.total

    foreach($secret1 in $result.records)
    {
       Write-Host "id: " $secret1.id" | Name: "$secret1.name" | Folder ID: "$secret1.folderId" | Last HB: "$secret1.lastHeartBeatStatus
    }

    Write-Host "------------------------------"
    Write-Host "---- Lookup: Secret Values ---"
    Write-Host "------------------------------"

    #?filter.searchfield=username&filter.searchfield=displayname&filter.searchfield=filter.searchText=mister&filter.includeinactive=true" -Headers $headers

    $result = Invoke-RestMethod "$api/secrets/lookup$filters" -Headers $headers

    Write-Host $result.filter.searchField
    Write-Host $result.total


    foreach($secret in $result.records)
    {
       Write-Host $secret.id" -> "$secret.value
    }
    Write-Host "------------------------------"
}
catch [System.Net.WebException]
{
    Write-Host "----- Exception -----"
    Write-Host  $_.Exception
    Write-Host  $_.Exception.Response.StatusCode
    Write-Host  $_.Exception.Response.StatusDescription
    $result = $_.Exception.Response.GetResponseStream()
    $reader = New-Object System.IO.StreamReader($result)
    $reader.BaseStream.Position = 0
    $reader.DiscardBufferedData()
    $responseBody = $reader.ReadToEnd() | ConvertFrom-Json
    Write-Host  $responseBody.errorCode " - " $responseBody.message
    foreach($modelState in $responseBody.modelState)
    {
        $modelState
    }
}
