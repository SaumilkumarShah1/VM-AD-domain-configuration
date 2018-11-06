Configuration WebsiteTest {

   param 
   ( 
		[Parameter(Mandatory)][string] $DomainName,
	    [Parameter(Mandatory)][string] $MachineName,
		[Parameter(Mandatory)][System.Management.Automation.PSCredential] $AdminCredentials,
		[Parameter(Mandatory)][System.Management.Automation.PSCredential] $DomainCredentials,
		[Parameter(Mandatory)][System.Management.Automation.PSCredential] $SafeModeCredentials
    ) 


	Import-DscResource -ModuleName xPSDesiredStateConfiguration
	Import-DscResource -ModuleName xActiveDirectory
	Import-DscResource -ModuleName xStorage
	Import-DscResource -ModuleName xNetworking
    Import-DscResource -ModuleName xPendingReboot

    [System.Management.Automation.PSCredential]$AdminDomainCreds = New-Object System.Management.Automation.PSCredential ("${DomainNetBiosName}\$($AdminCredentials.UserName)", $AdminCredentials.Password)
	[System.Management.Automation.PSCredential]$DomainCreds = New-Object System.Management.Automation.PSCredential ("${DomainNetBiosName}\$($DomainCredentials.UserName)", $DomainCredentials.Password)
	[System.Management.Automation.PSCredential]$SafeModeDomainCreds = New-Object System.Management.Automation.PSCredential ("${DomainNetBiosName}\$($SafeModeCredentials.UserName)", $SafeModeCredentials.Password)

  Node $MachineName
  {
    #Install the IIS Role
    WindowsFeature IIS
    {
      Ensure = “Present”
      Name = “Web-Server”
    }

    # Install Windows Feature "Active Directory Domain Services".
    WindowsFeature ADDSInstall
    {
        Ensure = "Present"
        Name   = "AD-Domain-Services"
    }

   
  }

}
