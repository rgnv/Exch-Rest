function Get-EndPoint
{
	[CmdletBinding()]
	param (
		[Parameter(Position = 0, Mandatory = $true)]
		[psObject]
		$AccessToken,
		
		[Parameter(Position = 1, Mandatory = $true)]
		[psObject]
		$Segment,
		
		[Parameter(Position = 2, Mandatory = $false)]
		[bool]
		$group,

		[Parameter(Position = 3, Mandatory = $false)]
		[switch]
		$beta
	)
	process
	{
		if ($group)
		{
			$Segment = "groups"
		}
		$EndPoint = "https://outlook.office.com/api/v2.0"
		switch ($AccessToken.resource)
		{
			"https://outlook.office.com" {
				if ($AccessToken.Beta)
				{
					$EndPoint = "https://outlook.office.com/api/beta/" + $Segment
				}
				else
				{
					$EndPoint = "https://outlook.office.com/api/v2.0/" + $Segment
				}
			}
			"https://graph.microsoft.us" {
				if ($AccessToken.Beta)
				{
					$EndPoint = "https://graph.microsoft.us/beta/" + $Segment
				}
				else
				{
					if($beta.IsPresent){
						$EndPoint = "https://graph.microsoft.us/beta/" + $Segment	
					}
					else{
						$EndPoint = "https://graph.microsoft.us/v1.0/" + $Segment				
					}					
				}
			}
		}
		return, $EndPoint
	}
}
