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

	# Configure LCM to allow Windows to automatically reboot if needed. Note: NOT recommended for production!
    LocalConfigurationManager
    {
        # Set this to $true to automatically reboot the node after a configuration that requires reboot is applied. Otherwise, you will have to manually reboot the node for any configuration that requires it. The default (recommended for PRODUCTION servers) value is $false.
        RebootNodeIfNeeded = $true
        # The thumbprint of a certificate used to secure credentials passed in a configuration.
        CertificateId = $node.Thumbprint
    }

    # Install Windows Feature "Active Directory Domain Services".
    WindowsFeature ADDSInstall
    {
        Ensure = "Present"
        Name   = "AD-Domain-Services"
    }

	
 # Create AD Domain specified in HADCServerConfigData.
    xADDomain FirstDC
    {
        # Name of the remote domain. If no parent name is specified, this is the fully qualified domain name for the first domain in the forest.
        DomainName                    = $DomainName
        # Credentials used to query for domain existence.
        DomainAdministratorCredential = $DomainCreds
        # Password for the administrator account when the computer is started in Safe Mode.
        SafemodeAdministratorPassword = $SafeModeDomainCreds
        # Specifies the fully qualified, non-Universal Naming Convention (UNC) path to a directory on a fixed disk of the local computer that contains the domain database (optional).
        DatabasePath                  = "C:\NTDS"
        # Specifies the fully qualified, non-UNC path to a directory on a fixed disk of the local computer where the log file for this operation will be written (optional).
        LogPath                       = "C:\NTDS"
        # Specifies the fully qualified, non-UNC path to a directory on a fixed disk of the local computer where the Sysvol file will be written. (optional)
        SysvolPath                    = "C:\SYSVOL"
        # DependsOn specifies which resources depend on other resources, and the LCM ensures that they are applied in the correct order, regardless of the order in which resource instances are defined.
        DependsOn                     = "[WindowsFeature]ADDSInstall"
    }

    # Wait until AD Domain is created.
    xWaitForADDomain DomainWait
    {
        DomainName           = $DomainName
        DomainUserCredential = $DomainCreds
        # Maximum number of retries to check for the domain's existence.
        RetryCount           = 30
        # Interval to check for the domain's existence.
        RetryIntervalSec     = 20
        DependsOn            = "[xADDomain]FirstDC"
    }

    # Enable Recycle Bin.
    xADRecycleBin RecycleBin
    {
        # Credential with Enterprise Administrator rights to the forest.
        EnterpriseAdministratorCredential = $DomainCreds
        # Fully qualified domain name of forest to enable Active Directory Recycle Bin.
        ForestFQDN                        = $DomainName
        DependsOn                         = "[xWaitForADDomain]DomainWait"
    }

    # Create AD User "Test.User".
    xADUser ADUser
    {
        DomainName                    = $DomainName
        DomainAdministratorCredential = $DomainCreds
        UserName                      = "Test.User"
        Password                      = $SafeModeCredentials
        Ensure                        = "Present"
        DependsOn                     = "[xWaitForADDomain]DomainWait"
    }
   
  }

}
