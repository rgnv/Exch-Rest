function Get-EXRWellKnownFolderItems{
    [CmdletBinding()]
    param( 
        [Parameter(Position=0, Mandatory=$false)] [string]$MailboxName,
        [Parameter(Position=1, Mandatory=$false)] [psobject]$AccessToken,
        [Parameter(Position=2, Mandatory=$false)] [string]$WellKnownFolder,
        [Parameter(Position=4, Mandatory=$false)] [switch]$ReturnSize,
        [Parameter(Position=5, Mandatory=$false)] [string]$SelectProperties,
        [Parameter(Position=6, Mandatory=$false)] [string]$Filter,
        [Parameter(Position=7, Mandatory=$false)] [string]$Top,
        [Parameter(Position=8, Mandatory=$false)] [string]$OrderBy,
        [Parameter(Position=9, Mandatory=$false)] [switch]$TopOnly,
        [Parameter(Position=10, Mandatory=$false)] [PSCustomObject]$PropList,
        [Parameter(Position=11, Mandatory=$false)] [psobject]$ClientFilter,
        [Parameter(Position=12, Mandatory=$false)] [string]$ClientFilterTop
    )
    Begin{
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
        if(![String]::IsNullorEmpty($Filter)){
            $Filter = "`&`$filter=" + [System.Web.HttpUtility]::UrlEncode($Filter)
        }
        if(![String]::IsNullorEmpty($Orderby)){
            $OrderBy = "`&`$OrderBy=" + $OrderBy
        }
        $TopValue = "1000"    
        if(![String]::IsNullorEmpty($Top)){
            $TopValue = $Top
        }      
        if(![String]::IsNullOrEmpty($ClientFilterTop)){
            $TopOnly = $false
        }
        if([String]::IsNullorEmpty($SelectProperties)){
            $SelectProperties = "`$select=ReceivedDateTime,Sender,Subject,IsRead,inferenceClassification"
        }
        else{
            $SelectProperties = "`$select=" + $SelectProperties
        }
        if($WellKnownFolder -ne $null)
        {
            $HttpClient =  Get-HTTPClient -MailboxName $MailboxName
            $EndPoint =  Get-EndPoint -AccessToken $AccessToken -Segment "users"
            $RequestURL =  $EndPoint + "('" + $MailboxName + "')/MailFolders/" + $WellKnownFolder + "/messages/?" +  $SelectProperties + "`&`$Top=" + $TopValue 
            $folderURI =  $EndPoint + "('" + $MailboxName + "')/MailFolders/" + $WellKnownFolder
             if($ReturnSize.IsPresent){
                if($PropList -eq $null){
                    $PropList = @()
                    $PidTagMessageSize = Get-EXRTaggedProperty -DataType "Integer" -Id "0x0E08"  
                    $PropList += $PidTagMessageSize
                }
            }
            if($PropList -ne $null){
               $Props = Get-EXRExtendedPropList -PropertyList $PropList -AccessToken $AccessToken
               $RequestURL += "`&`$expand=SingleValueExtendedProperties(`$filter=" + $Props + ")"
            }
            $RequestURL += $Filter + $OrderBy
            $clientReturnCount = 0;
            do{
                $JSONOutput = Invoke-RestGet -RequestURL $RequestURL -HttpClient $HttpClient -AccessToken $AccessToken -MailboxName $MailboxName
                foreach ($Message in $JSONOutput.Value) {
                    Add-Member -InputObject $Message -NotePropertyName ItemRESTURI -NotePropertyValue ($EndPoint + "('" + $MailboxName + "')/messages('" + $Message.Id + "')")
                    if($PropList -ne $null){
                        Expand-ExtendedProperties -Item $Message
                    }
                    if($ClientFilter -ne $null){
                        switch($ClientFilter.Operator){
                            "eq" {
                                if($Message.($ClientFilter.Property) -eq $ClientFilter.Value){
                                     Write-Output $Message
                                     $clientReturnCount++
                                }   
                            }
                            "ne" {
                                if($Message.($ClientFilter.Property) -ne $ClientFilter.Value){
                                     Write-Output $Message
                                     $clientReturnCount++
                                }
                            }
                        }
                        if(![String]::IsNullOrEmpty($ClientFilterTop)){
                            if([Int]::Parse($ClientFilterTop) -ge $clientReturnCount){
                                return 
                            }
                        }

                    }
                    else{
                        Write-Output $Message
                    }                    
                }           
                $RequestURL = $JSONOutput.'@odata.nextLink'
            }while(![String]::IsNullOrEmpty($RequestURL) -band (!$TopOnly))     
       } 
   

    }
}
