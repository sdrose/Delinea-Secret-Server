#Ensure that you have the necessary permissions and access rights within the CyberArk environment to interact with the REST API.
#Open an elevated PowerShell session.
#Define the following variables at the beginning of your script or session:
$CyberArkURL = "https://your-cyberark-instance.com"  # Replace with your CyberArk instance URL
$Username = "" 
$Password = ""
#$SafeName = "CON_Windows_Clients"
$SafeName = "CAN_Windows_Servers"
$OutputFilePath = "C:\export.csv"
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
$SafesURI = "$CyberArkURL/PasswordVault/api/accounts?filter=safename eq"+" "+$SafeName
#$SafesURI = "$CyberArkURL/PasswordVault/api/accounts"
$SafeResponse = Invoke-RestMethod -Uri $SafesURI -Headers $Headers
$AccountID = $SafeResponse.value | Select-Object -Property id
$ID=($AccountID -split "'r?'n")
$ID=$ID.trim('@{id=}')
            
foreach ($i in $ID)
{
     $AccountValue = $SafeResponse.value | Where-Object id -EQ $i 
     $AccountValue2 = $AccountValue.value | Select-Object -Property id,name,adrress,userName,platformId,safeName,secretManagement,createdTime

     #Retrieve account password
     $AccountURI="$CyberArkURL/PasswordVault/api/accounts/"+$i+"/Password/Retrieve"
     $AccoutResponse= Invoke-RestMethod -Uri $AccountURI -Method POST -Headers $Headers
     $AccountPassword = $AccoutResponse

     # Export the values
     $object = New-Object PSObject
     Add-Member -InputObject $object NoteProperty ID $AccountValue.id
     Add-Member -InputObject $object NoteProperty Name $AccountValue.name
     Add-Member -InputObject $object NoteProperty adress $AccountValue.adress
     Add-Member -InputObject $object NoteProperty UserName $AccountValue.UserName
     Add-Member -InputObject $object NoteProperty PlatformID $AccountValue.platformId
     Add-Member -InputObject $object NoteProperty SafeName $AccountValue.safeName
     Add-Member -InputObject $object NoteProperty SecretManagement $AccountValue.secretManagement
     Add-Member -InputObject $object NoteProperty CreateTime $AccountValue.createdTime
     Add-Member -InputObject $object NoteProperty PWD $AccountPassword

     $output+= $object
}        

$output | Export-Csv -Path $OutputFilePath -NoTypeInformation
                            
            
              
            
