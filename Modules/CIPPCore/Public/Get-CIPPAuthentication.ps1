
function Get-CIPPAuthentication {
    [CmdletBinding()]
    param (
        $APIName = 'Get Keyvault Authentication'
    )
    $Variables = @('ApplicationId', 'ApplicationSecret', 'TenantId', 'RefreshToken')

    try {
        if ($env:AzureWebJobsStorage -eq 'UseDevelopmentStorage=true') {
            $Table = Get-CIPPTable -tablename 'DevSecrets'
            $Secret = Get-CIPPAzDataTableEntity @Table -Filter "PartitionKey eq 'Secret' and RowKey eq 'Secret'"
            if (!$Secret) {
                throw 'Development variables not set'
            }
            foreach ($Var in $Variables) {
                if ($Secret.$Var) {
                    Set-Item -Path ENV:$Var -Value $Secret.$Var -Force -ErrorAction Stop
                }
            }
        } else {
            Connect-AzAccount -Identity
            $SubscriptionId = ($ENV:WEBSITE_ONWER_NAME -split '\+')[0]
            $Vault = Get-AzKeyVault -ResourceGroupName $ENV:Website_Resource_Group -SubscriptionId $SubscriptionId
            $Variables | ForEach-Object {
                Set-Item -Path ENV:$_ -Value (Get-AzKeyVaultSecret -VaultName $Vault.VaultName -Name $_ -AsPlainText -ErrorAction Stop) -Force
            }
        }
        $ENV:SetFromProfile = $true
        Write-LogMessage -message 'Reloaded authentication data from KeyVault' -Sev 'debug' -API 'CIPP Authentication'

        return $true
    } catch {
        Write-LogMessage -message 'Could not retrieve keys from Keyvault' -Sev 'CRITICAL' -API 'CIPP Authentication' -LogData (Get-CippException -Exception $_)
        return $false
    }
}


