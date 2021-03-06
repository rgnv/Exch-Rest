function Set-EXRContactPhoto {

	   [CmdletBinding()] 
    param( 
        [Parameter(Position = 1, Mandatory = $false)] [psobject]$AccessToken,
        [Parameter(Position = 2, Mandatory = $false)] [string]$MailboxName,
        [Parameter(Position = 4, Mandatory = $true)] [string]$id,
        [Parameter(Position = 6, Mandatory = $false)] [string]$FileName
    )  
    Begin {
        if ($AccessToken -eq $null) {
            $AccessToken = Get-ProfiledToken -MailboxName $MailboxName  
            if ($AccessToken -eq $null) {
                $AccessToken = Get-EXRAccessToken -MailboxName $MailboxName       
            }                 
        }
        if ([String]::IsNullOrEmpty($MailboxName)) {
            $MailboxName = $AccessToken.mailbox
        }  
        $HttpClient = Get-HTTPClient -MailboxName $MailboxName
        $EndPoint = Get-EndPoint -AccessToken $AccessToken -Segment "users" 
        $RequestURL = $EndPoint + "('" + $MailboxName + "')/Contacts('" + $id + "')/Photo/`$value"  
        $Photo = [System.IO.File]::ReadAllBytes($FileName)
        return Invoke-RestPut -RequestURL $RequestURL -HttpClient $HttpClient -AccessToken $AccessToken -MailboxName $MailboxName -Content $Photo -ContentHeader 'image/jpeg'

		

    } 
}

