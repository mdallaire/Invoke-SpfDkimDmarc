function Get-DKIMRecord {
    [CmdletBinding()]
    param(
        [Parameter(
            Mandatory = $True,
            ValueFromPipeline = $True,
            ValueFromPipelineByPropertyName = $True,
            HelpMessage = "Specifies the domain for resolving the SPF-record."
        )][Alias('Resolve-DKIMRecord')]
        [string]$Name,

        [Parameter(
            ValueFromPipeline = $True,
            ValueFromPipelineByPropertyName = $True,
            HelpMessage = "Show DKIM-record from multiple domains from a file."
        )][Alias('Path')]
        [System.IO.FileInfo]$File,

        [Parameter(Mandatory = $False,
            HelpMessage = "Specify a custom DKIM selector.")]
        [string]$DkimSelector,

        [Parameter(Mandatory = $false,
            HelpMessage = "DNS Server to use.")]
        [string]$Server
    )

    begin {
        
        if ($PSBoundParameters.ContainsKey('Server')) {
            $SplatParameters = @{
                'Server'      = $Server
                'ErrorAction' = 'SilentlyContinue'
            }
        }
        Else {
            $SplatParameters = @{
                'ErrorAction' = 'SilentlyContinue'
            }
        }
                
        # Custom list of DKIM-selectors
        # https://help.sendmarc.com/support/solutions/articles/44001891845-email-provider-commonly-used-dkim-selectors
        $DkimSelectors = @(
            'selector1' # Microsoft
            'google', # Google
            'everlytic', # Everlytic
            'k1', # Mailchimp / Mandrill
            'mxvault' # Global Micro
            'dkim' # Hetzner
        )

        $DKimObject = New-Object System.Collections.Generic.List[System.Object]
    }

    Process { 
    
        if ($DkimSelector) {
            $DKIM = Resolve-DnsName -Type TXT -Name "$($DkimSelector)._domainkey.$($Name)" @SplatParameters | Select-Object -ExpandProperty Strings -ErrorAction SilentlyContinue
            if ($DKIM -eq $null) {
                $DkimAdvisory = "No DKIM-record found for selector $($DkimSelector)._domainkey."
            }
            elseif ($DKIM -match "v=DKIM1" -or $DKIM -match "k=") {
                $DkimAdvisory = "DKIM-record found."
            }
        }
        else {
            foreach ($DkimSelector in $DkimSelectors) {
                $DKIM = Resolve-DnsName -Type TXT -Name  "$($DkimSelector)._domainkey.$($Name)" @SplatParameters | Select-Object -ExpandProperty strings -ErrorAction SilentlyContinue
                if ($DKIM -eq $null) {
                    $DkimAdvisory = "We couldn't find a DKIM record associated with your domain."
                }
                elseif ($DKIM -match "v=DKIM1" -or $DKIM -match "k=") {
                    $DkimAdvisory = "DKIM-record found."
                    break
                } 
            }
        }
    } end {
        $DkimReturnValues = New-Object psobject
        $DkimReturnValues | Add-Member NoteProperty "Name" $Name
        $DkimReturnValues | Add-Member NoteProperty "DkimRecord" $DKIM
        $DkimReturnValues | Add-Member NoteProperty "DkimSelector" $DkimSelector
        $DkimReturnValues | Add-Member NoteProperty "DKIMAdvisory" $DkimAdvisory
        $DkimObject.Add($DkimReturnValues)
        $DkimReturnValues
    }
}      