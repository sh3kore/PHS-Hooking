function Invoke-ForceSync {
    param(
        [Parameter(Mandatory = $true, ParameterSetName = 'USERNAME')]
        [string]$Username,
        [Parameter(Mandatory = $true, ParameterSetName = 'USERNAME')]
        [string]$DomainController,
        [Parameter(Mandatory = $true, ParameterSetName = 'RDN')]
        [string]$RDN,
        [Parameter(Mandatory = $false)]
        [switch]$StartDeltaSync
    )
    if ($Username){
        Write-Output "[+] Query DC via LDAP to get RDN"
        $searcher = [adsisearcher][adsi]"LDAP://$DomainController"
        $searcher.Filter = "(samaccountname=$Username)"
        $result = $searcher.FindOne()
        $DN = "$($result.Properties.distinguishedname)"
        $RDN = $DN.Substring(0, $DN.IndexOf(","))
        Write-Output "[+] RDN Found: $RDN"
    }
    Write-Output "[+] Connecting to the SQL instance"
    $sql_connection = New-Object System.Data.SqlClient.SqlConnection
    $sql_connection.ConnectionString = "Data Source=(localdb)\.\ADSync2019;Trusted_Connection=true;"
    $sql_connection.Open()
    $sql_command = New-Object System.Data.SqlClient.SqlCommand
    $sql_command.CommandText = "select [is_password_hash_sync_retry] from ADSync.dbo.mms_connectorspace where [rdn]='$RDN'"
    $sql_command.Connection = $sql_connection
    $sql_reader = $sql_command.ExecuteReader()
    while ($sql_reader.Read()){
        $result = $sql_reader[0]
    }
    $sql_reader.Close()
    Write-Output "[+] Value of is_password_hash_sync_retry: $result"
    if (!$result){
        Write-Output "[+] Changing the value to True"
        $sql_command.CommandText = "UPDATE ADSync.dbo.mms_connectorspace SET [is_password_hash_sync_retry]=1 where [rdn]='$RDN'"
        $sql_reader = $sql_command.ExecuteReader()
        $sql_reader.Close()
        Write-Output "[+] Value of is_password_hash_sync_retry set to True"
    }
    $sql_connection.Close()
    if ($StartDeltaSync){
        $result = Start-ADSyncSyncCycle -PolicyType Delta -ErrorAction SilentlyContinue
        Write-Output "[+] Start AD sync cycle result: $($result.Result)"
    }
}
