Set-StrictMode -Version Latest

function Get-AegisTransportCandidates {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [AllowEmptyCollection()]
        [object[]]$Providers
    )

    $results = [System.Collections.Generic.List[object]]::new()

    foreach ($provider in @($Providers)) {
        if ($null -eq $provider) {
            continue
        }

        $id = if ($provider.PSObject.Properties.Name -contains 'Id') {
            [string]$provider.Id
        } else {
            ''
        }

        $name = if ($provider.PSObject.Properties.Name -contains 'Name') {
            [string]$provider.Name
        } else {
            ''
        }

        if ([string]::IsNullOrWhiteSpace($id)) {
            $id = [guid]::NewGuid().ToString()
        }

        $results.Add(
            [pscustomobject][ordered]@{
                CandidateId    = $id
                Provider       = $name
                Available      = if ($provider.PSObject.Properties.Name -contains 'Available') {
                    [bool]$provider.Available
                } else {
                    $false
                }
                Active         = if ($provider.PSObject.Properties.Name -contains 'Active') {
                    [bool]$provider.Active
                } else {
                    $false
                }
                Verified       = if ($provider.PSObject.Properties.Name -contains 'Verified') {
                    [bool]$provider.Verified
                } else {
                    $false
                }
                ObservationOnly = $true
                MutationExecuted = $false
            }
        )
    }

    return @($results)
}
