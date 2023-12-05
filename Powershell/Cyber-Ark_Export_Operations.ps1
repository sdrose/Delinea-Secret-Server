# This script needs to run under PowerShell version 7; otherwise the -UnixTimeseconds option for get-date is not recongnized.
# Open an elevated PowerShell session.
# Ensure that you have the necessary permissions and access rights within the CyberArk environment to interact with the REST API.

# Define the following variables for use in the script session:
#----------
$CyberArkURL = "https://cyberark.#####.com" 
$Username = "####" 
$Password = "####"
$SafeName = "CAN_Windows_Servers"
$OutputFilePath = "C:\Delinea\Results\export.csv"
$output=@()
    $RequestBody = @{
        username = $Username
        password = $Password
    }
    
$AuthURI = "$CyberArkURL/PasswordVault/API/Auth/Cyberark/Logon"
$AuthResponse = Invoke-RestMethod -Uri $AuthURI -Method Post -Body ($RequestBody | ConvertTo-Json) -ContentType "application/json"
$Token = $AuthResponse
    
$Headers = @{
    "Authorization" = $Token
    "Content-Type" = "application/json"
}

# Retrieve Accounts ID
#----------
$SafesURI = "$CyberArkURL/PasswordVault/api/accounts?offset=100&limit=100"
  ## $SafesURI = "$CyberArkURL/PasswordVault/api/accounts?filter=safename eq"+" "+$SafeName+" AND &limit=1000"
  ## $SafesURI = "$CyberArkURL/PasswordVault/api/accounts?limit=100"
$SafeResponse = Invoke-RestMethod -Uri $SafesURI -Headers $Headers
$AccountID = $SafeResponse.value | Select-Object -Property id
 ##$ID=($AccountID -split "'r?'n")
 ##$ID=$ID.trim('@{id=}')

# Can I reduce the above 2 lines into the below single line?  If doesn't work, then swap in the above 2 lines and remove the below line ...
$ID=$AccountID.split("'r?'n").trim('@{id=}')
 ##$ID=($AccountID -split "'r?'n").trim('@{id=}')

foreach ($i in $ID)
{
    $AccountValue = $SafeResponse.value | Where-Object id -EQ $i | Select-Object -Property id,name,address,userName,platformId,safeName,secretManagement,@{n='createdTime';e={Get-Date -UnixTimeseconds $_.createdTime -asUTC}}
     ## $AccountValue = $SafeResponse.value | Where-Object id -EQ $i | Select-Object -Property id,name,address,userName,platformId,safeName,secretManagement,createdTime
     ## $AccountValue2 = $AccountValue.value | Select-Object -Property id,name,address,userName,platformId,safeName,secretManagement,@{n='createdTime';e={Get-Date $_.lastlogondate -Format yyyy-MM-dd}}
    
    #Retrieve account password
    #----------
    $AccountURI="$CyberArkURL/PasswordVault/api/accounts/"+$i+"/Password/Retrieve"
    $AccoutResponse= Invoke-RestMethod -Uri $AccountURI -Method POST -Headers $Headers
    $AccountPassword = $AccoutResponse
     
    # Export the values
    #----------
    $object = New-Object PSObject
    Add-Member -InputObject $object NoteProperty ID $AccountValue.id
    Add-Member -InputObject $object NoteProperty Name $AccountValue.name
    Add-Member -InputObject $object NoteProperty address $AccountValue.address
    Add-Member -InputObject $object NoteProperty UserName $AccountValue.UserName
    Add-Member -InputObject $object NoteProperty PlatformID $AccountValue.platformId
    Add-Member -InputObject $object NoteProperty SafeName $AccountValue.safeName
    Add-Member -InputObject $object NoteProperty SecretManagement $AccountValue.secretManagement
    Add-Member -InputObject $object NoteProperty CreateTime $AccountValue.createdTime
    Add-Member -InputObject $object NoteProperty PWD $AccountPassword

    $output+= $object
    ## $output  | Export-Csv -Path $OutputFilePath -NoTypeInformation ## I think this should be OUTSIDE the Foreach{} block
    $output  | Export-Csv -Path $OutputFilePath -NoTypeInformation 
}

