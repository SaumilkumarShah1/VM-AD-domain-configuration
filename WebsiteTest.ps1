Configuration WebsiteTest {

   param 
   ( 
		[Parameter(Mandatory)][string] $DomainName,
	    [Parameter(Mandatory)][string] $MachineName,
		[Parameter(Mandatory)][System.Management.Automation.PSCredential] $AdminCredentials
    ) 


	Import-DscResource -ModuleName xPSDesiredStateConfiguration
	Import-DscResource -ModuleName xActiveDirectory
	Import-DscResource -ModuleName xStorage
	Import-DscResource -ModuleName xNetworking
    Import-DscResource -ModuleName xPendingReboot

    [System.Management.Automation.PSCredential]$DomainCreds = New-Object System.Management.Automation.PSCredential ("${DomainNetBiosName}\$($AdminCredentials.UserName)", $AdminCredentials.Password)

  Node $MachineName
  {
    #Install the IIS Role
    WindowsFeature IIS
    {
      Ensure = �Present�
      Name = �Web-Server�
    }

    #Install ASP.NET 4.5
    WindowsFeature ASP
    {
      Ensure = �Present�
      Name = �Web-Asp-Net45�
    }

     WindowsFeature WebServerManagementConsole
    {
        Name = "Web-Mgmt-Console"
        Ensure = "Present"
    }

     LocalConfigurationManager 
        {
            RebootNodeIfNeeded = $true
        }

	    WindowsFeature DNS 
        { 
            Ensure = "Present" 
            Name = "DNS"		
        }

        Script EnableDNSDiags
	    {
      	    SetScript = { 
		        Set-DnsServerDiagnostics -All $true
                Write-Verbose -Verbose "Enabling DNS client diagnostics" 
            }
            GetScript =  { @{} }
            TestScript = { $false }
	        DependsOn = "[WindowsFeature]DNS"
        }

	    WindowsFeature DnsTools
	    {
	        Ensure = "Present"
            Name = "RSAT-DNS-Server"
            DependsOn = "[WindowsFeature]DNS"
	    }

        xDnsServerAddress DnsServerAddress 
        { 
            Address        = '127.0.0.1' 
            InterfaceAlias = $InterfaceAlias
            AddressFamily  = 'IPv4'
	        DependsOn = "[WindowsFeature]DNS"
        }

        WindowsFeature ADDSInstall 
        { 
            Ensure = "Present" 
            Name = "AD-Domain-Services"
	        DependsOn="[WindowsFeature]DNS" 
        } 

        WindowsFeature ADDSTools
        {
            Ensure = "Present"
            Name = "RSAT-ADDS-Tools"
            DependsOn = "[WindowsFeature]ADDSInstall"
        }

        WindowsFeature ADAdminCenter
        {
            Ensure = "Present"
            Name = "RSAT-AD-AdminCenter"
            DependsOn = "[WindowsFeature]ADDSInstall"
        }
  }

}
