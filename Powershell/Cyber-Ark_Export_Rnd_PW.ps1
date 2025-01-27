# This script needs to run under PowerShell version 7; otherwise the -UnixTimeseconds option for get-date is not recongnized.
# Open an elevated PowerShell session.
# Ensure that you have the necessary permissions and access rights within the CyberArk environment to interact with the REST API.

# Define the following variables for use in the script session:
#----------
function GenRandomPwd 
{
    param (
        [Parameter(Mandatory)]
        [int] $length
    )

    $charSet = 'abcdefghijklmnopqrstuvwxyzABCDEFGHJKMNPQRSTUVWXYZ0123456789'.ToCharArray()

    $rng = New-Object System.Security.Cryptography.RNGCryptoServiceProvider
    $bytes = New-Object byte[]($length)

    $rng.GetBytes($bytes)

    $result = New-Object char[]($length)

    for ($i = 0 ; $i -lt $length ; $i++) {
        $result[$i] = $charSet[$bytes[$i]%$charSet.Length]
    }

    return "FakePw-" + -join($result)     
}

Function Write-Log {
    param(
        [Parameter(Mandatory = $true)][string] $message,
        [Parameter(Mandatory = $false)]
        [ValidateSet("INFO","WARN","ERROR")]
        [string] $level = "INFO"
    )

    # Create timestamp
    $timestamp = (Get-Date).toString("yyyy/MM/dd HH:mm:ss")

    # Append content to log file
    Add-Content -Path $OutputLogPath -Value "$timestamp [$level] - $message"
}

##  This variable directs the script if the export should go to a file or not
$ExportToFile = $true

##  This variable directs if the password field should be written to the output file along with all the other parameters being written to file
$ExportPwdField = $true

##  This variable directs, should the password file be written to the output file along with all the other parameters, 
##    should the ACTUAL password be replaced with a fake-generated password - for testing purposes.
$ExportFakePw = $true


$CyberArkURL = "https://cyberark.#####.com" 
$Username = "####" 
$Password = "####"
$SafeName = "CAN_Windows_Servers"
$OutputFilePath = "C:\Delinea\Results\export.csv"
$OutputLogPath = "C:\Delinea\Results\export.log"
Write-Log -level Info -message "Top of loop to pull data from CyberArk"

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
## $SafesURI = "$CyberArkURL/PasswordVault/api/accounts?filter=safename eq"+" "+$SafeName+" AND &limit=1000"
 ## $SafesURI = "$CyberArkURL/PasswordVault/api/accounts?limit=100"
$SafesURI = "$CyberArkURL/PasswordVault/api/accounts?offset=100&limit=100"
try {
    $SafeResponse = Invoke-RestMethod -Uri $SafesURI -Headers $Headers
} catch {
    # Dig into the exception to get the Response details.
    # Note that value__ is not a typo.
    Write-Log -level ERROR -message "StatusCode:" $_.Exception.Response.StatusCode.value__ 
    Write-Log -level ERROR -message "StatusDescription:" $_.Exception.Response.StatusDescription
}

$AccountID = $SafeResponse.value | Select-Object -Property id
 ##$ID=($AccountID -split "'r?'n")
 ##$ID=$ID.trim('@{id=}')

# Can I reduce the above 2 lines into the below single line?  If doesn't work, then swap in the above 2 lines and remove the below line ...
$ID=$AccountID.split("'r?'n").trim('@{id=}')
 ##$ID=($AccountID -split "'r?'n").trim('@{id=}')

foreach ($i in $ID)
{
    $AccountValue = ""
    $AccountValue = $SafeResponse.value | Where-Object id -EQ $i | Select-Object -Property id,name,address,userName,platformId,safeName,secretManagement,@{n='createdTime';e={Get-Date -UnixTimeseconds $_.createdTime -asUTC}}
     ## $AccountValue = $SafeResponse.value | Where-Object id -EQ $i | Select-Object -Property id,name,address,userName,platformId,safeName,secretManagement,createdTime
     ## $AccountValue2 = $AccountValue.value | Select-Object -Property id,name,address,userName,platformId,safeName,secretManagement,@{n='createdTime';e={Get-Date $_.lastlogondate -Format yyyy-MM-dd}}
    
     if ([string]::IsNullOrEmpty($variable)) {
        Write-Host "Variable is null or empty"
        Write-Log -level ERROR -message "Unable to pull value from CyberArk for ID: " $i
    }
    
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
    if ($ExportPwField)
    {
        if ($ExportFakePw)
        {
            Add-Member -InputObject $object NoteProperty PWD $GenRandomPwd 8
        }
        else 
        {
            Add-Member -InputObject $object NoteProperty PWD $AccountPassword  
        }
    }    
    Write-Log -level INFO -message "Secret Data Retrieved; ID: " +  $AccountValue.id + "Name: " +  $AccountValue.name

    $output+= $object
    ## $output  | Export-Csv -Path $OutputFilePath -NoTypeInformation ## I think this should be OUTSIDE the Foreach{} block
   
}

if ($ExportToFile) 
{
    $output  | Export-Csv -Path $OutputFilePath -NoTypeInformation 
    Write-Log -level INFO -message "Secrets written to CSV file: " + $ID.Count
}
