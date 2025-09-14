# Parâmetros
$KeyVaultName          = "kv-exporddb"
$SqlServerName         = "sqldbteste0001"
$DatabaseName          = "estudados"
$StorageAccountName    = "stohomolexpoert0001"
$StorageContainer      = "sqldbbackup"
$StorageResourceGroup  = "RG-HOMOL"
$UserSecretName        = "sql-admin-user"
$PassSecretName        = "sql-admin-password"
$BackupPrefix          = "$DatabaseName-backup"
$RetentionCount        = 15

# Log início
$startTime = Get-Date
Write-Output "$startTime - Iniciando processo de backup BACPAC..."

# Valida módulo Az.Sql
if (-not (Get-Module -ListAvailable -Name Az.Sql)) {
    Write-Output "Instalando módulo Az.Sql..."
    Install-Module -Name Az.Sql -Force -Scope CurrentUser
}

# Autenticação (Managed Identity)
$AzContext = (Connect-AzAccount -Identity).Context

# Segredos do KeyVault
$sqlAdminUser = (Get-AzKeyVaultSecret -VaultName $KeyVaultName -Name $UserSecretName -AsPlainText -DefaultProfile $AzContext).Trim()
$sqlAdminPassword = (Get-AzKeyVaultSecret -VaultName $KeyVaultName -Name $PassSecretName -AsPlainText -DefaultProfile $AzContext).Trim()

# Storage Key
$storageAccountKey = (Get-AzStorageAccountKey -ResourceGroupName $StorageResourceGroup -Name $StorageAccountName -DefaultProfile $AzContext)[0].Value
$storageContext = New-AzStorageContext -StorageAccountName $StorageAccountName -StorageAccountKey $storageAccountKey

# Backup .bacpac
$backupFileName = "$BackupPrefix-$(Get-Date -Format 'yyyyMMdd-HHmmss').bacpac"
$storageUri = "https://$StorageAccountName.blob.core.windows.net/$StorageContainer/$backupFileName"

# Exportação do SQL Database
Write-Output "Iniciando exportação para o blob: $storageUri"

$exportStatus = New-AzSqlDatabaseExport `
    -ResourceGroupName $StorageResourceGroup `
    -ServerName $SqlServerName `
    -DatabaseName $DatabaseName `
    -StorageKeyType "StorageAccessKey" `
    -StorageKey $storageAccountKey `
    -StorageUri $storageUri `
    -AdministratorLogin $sqlAdminUser `
    -AdministratorLoginPassword (ConvertTo-SecureString $sqlAdminPassword -AsPlainText -Force) `
    -DefaultProfile $AzContext

Write-Output "Status da Exportação: $($exportStatus.Status)"

# Limpeza backups antigos
$existingBackups = Get-AzStorageBlob -Container $StorageContainer -Context $storageContext | Where-Object { $_.Name -like "$BackupPrefix*" } | Sort-Object LastModified -Descending

if ($existingBackups.Count -gt $RetentionCount) {
    $blobsToDelete = $existingBackups | Select-Object -Skip $RetentionCount
    foreach ($blob in $blobsToDelete) {
        Remove-AzStorageBlob -Blob $blob.Name -Container $StorageContainer -Context $storageContext
        Write-Output "Backup removido: $($blob.Name)"
    }
} else {
    Write-Output "Nenhum backup antigo a remover. Total atual: $($existingBackups.Count)"
}

$endTime = Get-Date
Write-Output "$endTime - Backup exportado para: $storageUri"
