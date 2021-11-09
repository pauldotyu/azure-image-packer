$TempDir = 'c:\temp'
If (-Not(Test-Path $TempDir)) {
  New-Item  -ItemType Directory $TempDir | Out-Null
}

Try
{
  Write-Host 'Retrieving an access token for storage using user-assigned managed identity...'
  $audience = 'https://storage.azure.com'
  $token = Invoke-RestMethod -Uri "http://169.254.169.254/metadata/identity/oauth2/token?api-version=2018-02-01&resource=$audience" -Headers @{ 'Metadata' = 'true' }
  Write-Host $token.token_type 'token retrieved'

  Write-Host 'Retrieving installer from storage container...'
  $filePath = (Join-Path $TempDir $env:BLOBNAME)
  $blob = "https://$env:STORAGEACCOUNTNAME.blob.core.windows.net/$env:CONTAINERNAME/$env:BLOBNAME"
  Invoke-RestMethod -Method GET -Uri $blob -Headers @{
      'Authorization' = $token.token_type + " " + $token.access_token
      'x-ms-version'  = '2019-02-02'
  } -OutFile $filePath
  Write-Host $env:BLOBNAME 'retrieved'

  If (Test-Path $filePath) {
    Write-Host 'Installing' $env:BLOBNAME '...'
    # $filePath /?
    $proc = Start-Process -FilePath $filePath -Argument "/VERYSILENT /NORESTART /SP-" -Passthru
    Do {Start-Sleep -Milliseconds 500} Until ($proc.HasExited)
    Write-Host $env:BLOBNAME 'installed'
  } Else {
    Throw 'Oh snap! Installer not downloaded after all...'
  }

  If (Test-Path $TempDir) {
    Remove-Item $TempDir -Recurse
  }
}
Catch
{
   Write-Error 'This thing has crashed and burned, well done!' -ErrorAction Stop
   Exit 1  # packer will recognize failure at this point
}
