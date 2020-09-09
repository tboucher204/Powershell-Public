Import-Module 'C:\Program Files (x86)\BitTitan\BitTitan PowerShell\BitTitanPowerShell.dll'

# Get both bt and mw tickets
$cred = Get-Credential
$mwTicket = Get-MW_Ticket -Credentials $cred
$btTicket = Get-BT_Ticket -Credentials $cred -ServiceType BitTitan


# Get an existing project
# The simplest way is to filter by project name, but this requires that a unique project name is used. If there are multiple projects with the same name, a list of projects will be returned. 
$connector = Get-MW_MailboxConnector -ticket $mwticket -Name "Exchange Online Migration"

# Get migration items in the project, filtered by project(connector) id
$mailboxItem = Get-MW_Mailbox -ticket $mwticket -ConnectorId $connector.Id -ImportEmailAddress Charles.Cobaugh@trimaco.com



# Start all items found in the project
foreach($mailbox in $mailboxItem)
{
     $migration = Add-MW_MailboxMigration -Ticket $mwticket -ConnectorId $connector.Id -MailboxId $mailbox.Id -UserId $mwticket.UserId -Type Full -ItemTypes Contact 
}