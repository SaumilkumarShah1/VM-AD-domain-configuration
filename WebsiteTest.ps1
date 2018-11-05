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
      Ensure = “Present”
      Name = “Web-Server”
    }

  }

}
