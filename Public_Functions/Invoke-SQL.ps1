#requires -Version 2
<#
	.SYNOPSIS
		Connects to MS SQL server and performs a sql statement on the proper table.
	
	.DESCRIPTION
		Connects to MS SQL server and performs a sql statement on the proper table.
	
	.PARAMETER server
		Name of the server hosting the database.  If you specify AlwaysOn, then the servername should be the name of the AlwaysOn Listener
	
	.PARAMETER database
		Name of the SQL Database
	
	.PARAMETER user
		User with appropriate permissions to the database. Ignored if the integratedsecurity is set to $TRUE
	
	.PARAMETER password
		Password for the user that has appropriate permissions to the database.  Ignored if the integratedsecurity is set to $TRUE
	
	.PARAMETER statement
		Query, update, exec, or insert statement to be performed against the database.
	
	.PARAMETER method
		Enter "query" if returning data (such as select statement), otherwise enter update, insert, or exec.
	
	.PARAMETER integratedsecurity
		$FALSE if using a username and password, otherwise $TRUE to use the account executing the script.
	
	.PARAMETER alwayson
		If connecting to a SQL AlwaysOn Availability Group, enter $TRUE, and specify the name of the listener as the server paramter.  Otherwise, leave blank or enter $false
	
	.EXAMPLE
		Invoke-SQL [-server] <Object> [-database] <Object> [-user] <Object> [-password] <Object> [-statement] <Object> [-method] <Object>  [<CommonParameters>]
	
	.NOTES
		Additional information about the function.
#>
function Invoke-SQL
{
	[CmdletBinding(PositionalBinding = $true,
				   SupportsPaging = $true,
				   SupportsShouldProcess = $true)]
	param
	(
		[Parameter(Mandatory = $true,
				   ValueFromPipeline = $true,
				   ValueFromPipelineByPropertyName = $true,
				   ValueFromRemainingArguments = $true)]
		[ValidateNotNullOrEmpty()]
		[Alias('sqlserver')]
		[string]$server,
		[Parameter(Mandatory = $true,
				   ValueFromPipeline = $true,
				   ValueFromPipelineByPropertyName = $true,
				   ValueFromRemainingArguments = $true)]
		[ValidateNotNullOrEmpty()]
		[Alias('sqldatabase')]
		[string]$database,
		[Parameter(Mandatory = $false,
				   ValueFromPipeline = $true,
				   ValueFromPipelineByPropertyName = $true,
				   ValueFromRemainingArguments = $true)]
		[Alias('username', 'sqluser', 'sqlusername')]
		[string]$user,
		[Parameter(Mandatory = $false,
				   ValueFromPipeline = $true,
				   ValueFromPipelineByPropertyName = $true,
				   ValueFromRemainingArguments = $true)]
		[Alias('pass', 'sqlpass', 'sqlpassword')]
		[string]$password,
		[Parameter(Mandatory = $true,
				   ValueFromPipeline = $true,
				   ValueFromPipelineByPropertyName = $true,
				   ValueFromRemainingArguments = $true)]
		[ValidateNotNullOrEmpty()]
		[Alias('sqlstatement')]
		[string]$statement,
		[Parameter(Mandatory = $true,
				   ValueFromPipeline = $true,
				   ValueFromPipelineByPropertyName = $true,
				   ValueFromRemainingArguments = $true)]
		[ValidateNotNullOrEmpty()]
		[string]$method,
		[Parameter(Mandatory = $true,
				   ValueFromPipeline = $true,
				   ValueFromPipelineByPropertyName = $true,
				   ValueFromRemainingArguments = $true)]
		[ValidateNotNullOrEmpty()]
		[Alias('sqlintegratedsecurity')]
		[bool]$integratedsecurity,
		[Parameter(ValueFromPipeline = $true,
				   ValueFromPipelineByPropertyName = $true,
				   ValueFromRemainingArguments = $true)]
		[Alias('multisubnetfailover')]
		[bool]$alwayson = $false
	)
	
	begin { }
	Process
	{
		Write-Verbose "Statement: $statement"
		try
		{
			$SqlConnection = New-Object -TypeName System.Data.SqlClient.SqlConnection
			if ($integratedsecurity -eq $false)
			{
				$SqlConnection.ConnectionString = "Server = $server; Initial Catalog = $database; Integrated Security = FALSE ;User ID = $user ;Password = $password;"
			}
			else
			{
				$SqlConnection.ConnectionString = "Server = $server; Initial Catalog = $database; Integrated Security = TRUE;"
			}
			if ($alwayson -eq $true)
			{
				$SqlConnection.ConnectionString = $SqlConnection.ConnectionString + 'multisubnetfailover = TRUE;'
			}
			Write-Verbose $SqlConnection.ConnectionString
			$SqlCmd = New-Object -TypeName System.Data.SqlClient.SqlCommand
			$SqlCmd.CommandText = $statement
			$SqlCmd.Connection = $SqlConnection
			$SqlCmd.CommandTimeout = 0
			$SqlAdapter = New-Object -TypeName System.Data.SqlClient.SqlDataAdapter
			$SqlAdapter.SelectCommand = $SqlCmd
			$SqlConnection.Open()
			if ($method -eq 'query')
			{
				$DataSet = New-Object -TypeName System.Data.DataSet
				$null = $SqlAdapter.Fill($DataSet)
				write-output $DataSet
			}
			else
			{
				$null = $SqlCmd.ExecuteNonQuery()
			}
			$SqlConnection.close()
		}
		catch
		{
			Write-output "Error:  $statement"
			Write-output  $_
		}
	}
	end { }
}


