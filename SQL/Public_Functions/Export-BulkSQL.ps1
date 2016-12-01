<#
	.SYNOPSIS
		Exports a datatable into a SQL table
	
	.DESCRIPTION
		This function bulk copies a PowerShell datatable into a SQL table.  Bulk copies are tricky - the datatable (and the data) must be properly formatted exactly to match the destination SQL table.
	
	.PARAMETER sqlserver
		Name of the SQL server that contains the destination database and table.
	
	.PARAMETER sqldatabase
		Database that contains the SQL Table that will be the destination of the bulk export.
	
	.PARAMETER sqluser
		Optional SQL User that will be used to establish a connection the SQL database that houses the destination table.
	
	.PARAMETER sqlpass
		Password of the SQL user that will be used to establish a connection to the destination SQL table.
	
	.PARAMETER sqlintegratedsecurity
		If specified as true, the username and password parameters are not used.  Instead, the connection will use IntegratedSecurity to establish a connection to the destination SQL server.  If set to false, sqluser and sqlpass are needed.
	
	.PARAMETER datatable
		The PowerShell datatable that is used as the source of bulk export to the SQL table.
	
	.PARAMETER sqltable
		The name of the SQL table that is the target of the bulk export.
	
	.PARAMETER failover
		Specifies if the connection should use the 'MultiSubnetFailover' connection option, which is mandatory for connections to SQL AlwaysOn Availability Groups.  Requires .net 4.5 or greater.
	
	.EXAMPLE
		PS C:\> Export-BulkSQL -sqlserver $value1
	
	.NOTES
		Additional information about the function.
#>
function Export-BulkSQL
{
	[CmdletBinding(PositionalBinding = $true)]
	param
	(
		[Parameter(Mandatory = $true,
				   ValueFromPipeline = $true,
				   ValueFromPipelineByPropertyName = $true,
				   ValueFromRemainingArguments = $true,
				   Position = 1)]
		[ValidateNotNullOrEmpty()]
		[Alias('server', 'databaseserver')]
		[string]$sqlserver,
		[Parameter(Mandatory = $true,
				   ValueFromPipeline = $true,
				   ValueFromPipelineByPropertyName = $true,
				   ValueFromRemainingArguments = $true)]
		[ValidateNotNullOrEmpty()]
		[Alias('database')]
		[string]$sqldatabase,
		[Parameter(Mandatory = $false,
				   ValueFromPipeline = $true,
				   ValueFromPipelineByPropertyName = $true,
				   ValueFromRemainingArguments = $true)]
		[ValidateNotNullOrEmpty()]
		[Alias('user')]
		[string]$sqluser,
		[Parameter(Mandatory = $false,
				   ValueFromPipeline = $true,
				   ValueFromPipelineByPropertyName = $true,
				   ValueFromRemainingArguments = $true)]
		[ValidateNotNullOrEmpty()]
		[Alias('pass', 'password')]
		[string]$sqlpass,
		[Parameter(Mandatory = $true,
				   ValueFromPipeline = $true,
				   ValueFromPipelineByPropertyName = $true,
				   ValueFromRemainingArguments = $true)]
		[ValidateSet('true', 'false')]
		[Alias('integratedsecurity')]
		[string]$sqlintegratedsecurity,
		[Parameter(Mandatory = $true,
				   ValueFromPipeline = $true,
				   ValueFromPipelineByPropertyName = $true,
				   ValueFromRemainingArguments = $true)]
		[ValidateNotNullOrEmpty()]
		$datatable,
		[Parameter(Mandatory = $true,
				   ValueFromPipeline = $true,
				   ValueFromPipelineByPropertyName = $true,
				   ValueFromRemainingArguments = $true)]
		[ValidateNotNullOrEmpty()]
		[string]$sqltable,
		[Parameter(ValueFromPipeline = $true,
				   ValueFromPipelineByPropertyName = $true,
				   ValueFromRemainingArguments = $true)]
		[ValidateSet('true', 'false')]
		[string]$failover = 'false'
	)
	
	Begin
	{
		
	}
	Process
	{
		$SqlConnection = New-Object -TypeName System.Data.SqlClient.SqlConnection
		if ($sqlintegratedsecurity -eq $false)
		{
			$SqlConnection.ConnectionString = "Server = $sqlserver; Initial Catalog = $sqldatabase; Integrated Security = FALSE ;User ID = $sqluser ;Password = $sqlpass;"
		}
		else
		{
			$SqlConnection.ConnectionString = "Server = $sqlserver; Initial Catalog = $sqldatabase; Integrated Security = TRUE;"
		}
		if ($failover -eq $true)
		{
			$SqlConnection.ConnectionString = $SqlConnection.ConnectionString + "multisubnetfailover = TRUE;"
		}
		Write-Verbose $SqlConnection.ConnectionString
		try
		{
			$SqlConnection.Open()
		}
		catch
		{
			Write-Verbose "Open connection failed"
		}
		try
		{
			$BulkCopy = new-object ("System.Data.SqlClient.SqlBulkCopy") $SqlConnection
			$BulkCopy.DestinationTableName = "$sqltable"
			$BulkCopy.WriteToServer($datatable)
		}
		catch
		{
			Write-Verbose "Bulk Insert failed"
		}
		$SqlConnection.Close()
	}
	End
	{
		
	}
}
