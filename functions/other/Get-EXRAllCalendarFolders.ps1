function Get-EXRAllCalendarFolders
{
	[CmdletBinding()]
	param (
		[Parameter(Position = 0, Mandatory = $false)]
		[string]
		$MailboxName,
		
		[Parameter(Position = 1, Mandatory = $false)]
		[psobject]
		$AccessToken,
		
		[Parameter(Position = 2, Mandatory = $false)]
		[switch]
		$FolderClass
	)
	Process
	{
		if($AccessToken -eq $null)
		{
			$AccessToken = Get-ProfiledToken -MailboxName $MailboxName  
			if($AccessToken -eq $null){
				$AccessToken = Get-EXRAccessToken -MailboxName $MailboxName       
			}                 
		}
		if([String]::IsNullOrEmpty($MailboxName)){
			$MailboxName = $AccessToken.mailbox
		}  
		$HttpClient = Get-HTTPClient -MailboxName $MailboxName
		$EndPoint = Get-EndPoint -AccessToken $AccessToken -Segment "users"
		if ($FolderClass.IsPresent)
		{
			$RequestURL = $EndPoint + "('$MailboxName')/Calendars/?`$Top=1000`&`$expand=SingleValueExtendedProperties(`$filter=PropertyId%20eq%20'String%200x66B5')"
			if ($AccessToken.resource -eq "https://graph.microsoft.us")
			{
				$RequestURL = $EndPoint + "('$MailboxName')/Calendars/?`$Top=1000`&`$expand=SingleValueExtendedProperties(`$filter=Id%20eq%20'String%200x66B5')"
			}
			
		}
		else
		{
			$RequestURL = $EndPoint + "('$MailboxName')/Calendars/?`$Top=1000"
		}
		do
		{
			$JSONOutput = Invoke-RestGet -RequestURL $RequestURL -HttpClient $HttpClient -AccessToken $AccessToken -MailboxName $MailboxName
			foreach ($Folder in $JSONOutput.Value)
			{
				Write-Output $Folder
			}
			$RequestURL = $JSONOutput.'@odata.nextLink'
		}
		while (![String]::IsNullOrEmpty($RequestURL))
		
		
	}
}
