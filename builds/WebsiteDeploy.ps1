<#################################################################################################################################################################################

The powershell script will be called as post deployment step 
It looks for the services and deploys.

It extracts the website name to be deployed from the project file path given in the parameter. Multiple projects can be passed separated by comma(,), example give below.

ex: extracted website name: AccountsApiService      --- \src\accounts-service\Edmw.Accounts.Api\Edmw.Accounts.Api.csproj
ex: extracted website name: InstrumentsApiService   --- \src\instruments-service\Edmw.Instruments.Api\Edmw.Instruments.Api.csproj

Call this script file in the git lab yml file and pass the relative path of the project file to be deployed. Example below,

Single project 
ex: ./Builds/ServiceDeploy.ps1 \src\api\Edmw.Esg.Api\Edmw.Esg.Api.csproj Yes

Multiple project
ex: ./Builds/ServiceDeploy.ps1 \src\api\Edmw.Esg.Api\Edmw.Esg.Api.csproj,\src\loader-service\Edmw.Esg.Loader.ServiceHost\Edmw.Esg.Loader.ServiceHost.csproj Yes

Note: - Port number for any new website needs to be added in the enum EdwmApi. Port number availabe for few Api's. Add the extracted website name and port number
        in the enum provided.

Command line call example below,

ex: powershell .\Builds\EsgServiceDeploy.ps1 \src\api\Edmw.Esg.Api\Edmw.Esg.Api.csproj,\src\loader-service\Edmw.Esg.Loader.ServiceHost\Edmw.Esg.Loader.ServiceHost.csproj Yes

##################################################################################################################################################################################>

param (
    [Parameter(Mandatory=$true)]$deployprojectPaths,  
    <## 
       Pass project Api project file Path to be deployed
       ex: AccountsApiService    - \src\accounts-service\Edmw.Accounts.Api\Edmw.Accounts.Api.csproj
       ex: InstrumentsApiService - \src\instruments-service\Edmw.Instruments.Api\Edmw.Instruments.Api.csproj
    ##>
    [Parameter(Mandatory=$true)]$removeSite,
    <## 
      Pass Yes to remove the site or No to keep it while deployment
      ex: Yes
    #>
    [Parameter(Mandatory=$true)]$localCertificatePath,
    <## 
      Local certificate Path
      ex: "C:\Deployment\LocalCertificate\EDMWIdentitySvcCert.pfx"
    #>
    [Parameter(Mandatory=$true)]$localCertPassword
    <## 
      Local certificate password
      ex: 1234
    #>

     )


## port number start from 8211 onwards, since do not want to touch EDMW installed ports..
Enum EdwmApi
{

BusinessDatesService = 8184
PositionsApiService= 8251
InstrumentsApiService = 8252
AccountsApiService = 8253
EsgApiService= 8254
ReportingApiService = 8255
FXRateApiService = 8256
TransactionsApiService= 8257
InstrumentCharacteristicsApiService= 8258
LotsApiService= 8259
GatewayApiService = 8260
InstrumentClassificationApiService= 8261
IdentityApiService = 8262
DomainValueApiService = 8263

}

Enum EdwmApiPipelinePorts
{
AcgpService = 8182
AccountService = 8183
SystemService= 8184
DomainValueService = 8185
LoggerService = 8186
ContentManagementService = 8187
MenuBarService = 8188
IdentityService = 8189
ChartService = 8190
SummaryService = 8191
DashboardService = 8192
SchedulingChartService = 8193
InquiryContenService= 8194
Growthof10kService = 8195
FundLookThroughService = 8196
ReportDownloadService = 8197
DocumentTagService = 8198

PositionsApiService= 8251
InstrumentsApiService = 8252
AccountsApiService = 8253
EsgApiService= 8254
ReportingApiService = 8255
FXRateApiService = 8256
TransactionsApiService= 8257
InstrumentCharacteristicsApiService= 8258
LotsApiService= 8259
GatewayApiService = 8260
InstrumentClassificationApiService= 8261
IdentityApiService = 8262
DashboardConfigurationApiService = 8264
}


function Write-Log {
     [CmdletBinding()]
     param(
         [Parameter()]
         [ValidateNotNullOrEmpty()]
         [string]$Message,

         [Parameter()]
         [ValidateNotNullOrEmpty()]
         [ValidateSet('Information','Warning','Error')]
         [string]$Severity = 'Information',

         [Parameter()]
         [ValidateNotNullOrEmpty()]
         [ValidateSet('Yes','No')]
         [string]$writeLog = 'Yes'
     )

     $myObject = [PSCustomObject]@{
         Time = (Get-Date -f g)
         Message = $Message
         Severity = $Severity
         #WriteLog = $writeLog
     } 
     if($writeLog -eq 'Yes')
     {
       $myObject | Out-File -FilePath "$env:Temp\edmwapiinstall.log" -Append -Force
     }
}



function Test-SQLConnection
{    
    [OutputType([bool])]
    Param
    (
        [Parameter(Mandatory=$true,
                    ValueFromPipelineByPropertyName=$true,
                    Position=0)]
        $ConnectionString
    )
    try
    {
        $sqlConnection = New-Object System.Data.SqlClient.SqlConnection $ConnectionString;
        $sqlConnection.Open();
        $sqlConnection.Close();

        return $true;
    }
    catch
    {
        return $false;
    }
}

function SetPermissionForCertificate()
{
  param(
    [string]$userName,
    [string]$permission,
    [string]$certLocationPersonal,
    [string]$certThumbprint
    )

    #$userName = "EDMWWEB"
    #$permission = "Read"
    $certPath = "$certLocationPersonal\$certThumbprint"

    $CertObj= Get-ChildItem $certPath   #Cert:\LocalMachine\my\98cc8d1ddf1e850f1c32e0360bb49cf2f14f6408

    $rsaCert = [System.Security.Cryptography.X509Certificates.RSACertificateExtensions]::GetRSAPrivateKey($CertObj)
    
    if($rsaCert -ne $null)
    {
       $fileName = $rsaCert.key.UniqueName
       $path = "$env:ALLUSERSPROFILE\Microsoft\Crypto\Keys\$fileName"
       $permissions = Get-Acl -Path $path

       $rule = new-object security.accesscontrol.filesystemaccessrule $userName, $permission, allow

       $permissions.AddAccessRule($rule)
       Set-Acl -Path $path -AclObject $permissions 
    }
    else
    {
       Write-Host "Read permission not set for the certificate"
    }
    

}

Function Get-WebPoolDetails([ref]$apppoolName, [ref]$apppoolUserName, [ref]$apppoolPwd)
{
  $webpools = Get-CimInstance -Namespace root/MicrosoftIISv2 -ClassName IIsApplicationPoolSetting -Property Name, WAMUserName, WAMUserPass |
              select Name, WAMUserName, WAMUserPass
  if($webpools)
  {
    # Check details of one pool, say AccountApiPool
    # Both user name should be same
    #W3SVC/APPPOOLS/AccountApiPool
    foreach($webpool in $webpools)
    {
       if("W3SVC/APPPOOLS/AccountApiPool" -eq $webpool.Name)
       {
             $apppoolName.Value = $webpool.Name
             $apppoolUserName.Value = $webpool.WAMUserName
             $apppoolPwd.Value = $webpool.WAMUserPass
             break
       }
    }

   }
}


function Check-Deployment([ref]$deployedWebSiteName, [ref]$deployedWebAppPool)
{
[Void][Reflection.Assembly]::LoadWithPartialName("Microsoft.Web.Administration")

$sm = New-Object Microsoft.Web.Administration.ServerManager

foreach($site in $sm.Sites)
{
    $root = $site.Applications | where { $_.Path -eq "/" }

    if(($site.Name -eq $deployedWebSiteName) -and ($root.ApplicationPoolName -eq $deployedWebAppPool))
    {
       $deployedWebSiteName.Value = $site.Name

       $deployedWebAppPool.Value = $root.ApplicationPoolName
    }
}

}

function Check-WebPoolExists([ref]$webPoolExists, [ref]$webPoolName, $webappPoolName)
{
  [Void][Reflection.Assembly]::LoadWithPartialName("Microsoft.Web.Administration")
  $sm = New-Object Microsoft.Web.Administration.ServerManager

    foreach($pool in $sm.ApplicationPools)
    {
       if($pool.Name -eq $webappPoolName)
       {
          Write-Host Pool exists
          $webPoolExists.Value = $true
          $webPoolName.Value = $pool.Name
          break
       }
   
    }
}

function StartIISServices()
{
  try
  {
    ############################
    # START IIS sites 
    #IISReset /START
    $agr = "/START"
    Start-Process -FilePath $env:windir\System32\IISRESET -ArgumentList $agr -WindowStyle Hidden -Wait
  }
  catch
  {
   Throw $_.Exception.Message

    Write-Log -Message $_.Exception.Message -Severity Error -writeLog Yes
    #Add-Type -AssemblyName Microsoft.VisualBasic
    #$result = [Microsoft.VisualBasic.Interaction]::MsgBox('Not able to restart IIS. Please restart IIS manually.','OKOnly,SystemModal,Information', 'Information') 
  }
}

function StopIISServices()
{
  try
  {
    ############################
    # START IIS sites 
    #IISReset /START
    $agr = "/STOP"
    Start-Process -FilePath $env:windir\System32\IISRESET -ArgumentList $agr -WindowStyle Hidden -Wait
  }
  catch
  {
    Write-Host $_.Exception.Message
    Write-Log -Message $_.Exception.Message -Severity Error -writeLog Yes
  }
}

function Remove-Services()
{  
   ############################
   # remove IIS sites 
   # Remove-IISSite -Name "abc"
   $arrayremoveIISSites = Get-Website | select name  | Where-Object {$_.Name -like '*service*'}
  try
  {
   ## remove site using appcmd.exe , %systemroot%\system32\inetsrv\
   ##$agr = "set site /site.name:MarkitEDMW /+bindings.[protocol='net.tcp',bindingInformation='808:*']"
   ##Start-Process -FilePath $env:windir\System32\inetsrv\appcmd.exe -ArgumentList $agr -PassThru -Wait
   if($arrayremoveIISSites)
   {
       $appcmd = $env:SystemRoot + "\system32\inetsrv\appcmd.exe"
   
       foreach($site in $arrayremoveIISSites)
       {
         $webSite = Get-Website -Name $site.Name
         if($webSite.Name -eq $site.Name)
         {
            #Write-Host $site exists
            $siteName = $site.Name
            Write-Log -Message " $siteName exists" -Severity Information -writeLog Yes

            #Stop-WebSite -Name $site.Name
            #Remove-WebSite -Name $site.Name -Confirm:$false #-ErrorAction SilentlyContinue
            
            #& $appcmd delete site "$site"
            $agr = "delete site " + "$site"
            Start-Process -FilePath $env:windir\System32\inetsrv\appcmd.exe -ArgumentList $agr -PassThru -Wait
            Write-Log -Message "Removed site: $siteName " -Severity Information -writeLog Yes
         }
       }
   }
  }
  catch
  {
    Write-Log -Message $_.Exception.Message -Severity Error -writeLog Yes
  }

    Start-Sleep -s 5
   ###########################
   # remove IIS App Pool
   # Remove-WebAppPool -Name "abc"
   $arrayremoveappPool = Get-IISAppPool | select name | Where-Object {$_.Name -like '*ApiPool*'} 
  try
  {
   if($arrayremoveappPool)
   {
       foreach($pool in $arrayremoveappPool)
       {
         $apppoolName = Get-IISAppPool -Name $pool.Name
         if($apppoolName.Name -eq $pool.Name)
         {
           #Write-Host $pool exists
           $poolName = $pool.Name
           Write-Log -Message "$poolName exists" -Severity Information -writeLog Yes
           Stop-WebAppPool -Name $poolName 
           Remove-WebAppPool -Name $poolName -ErrorAction SilentlyContinue
           Write-Log -Message "Removed pool: $poolName " -Severity Information -writeLog Yes
         }
       }
   }
  }
  catch
  {
    #Write-Host $_.Exception.Message
    Write-Log -Message $_.Exception.Message -Severity Error -writeLog Yes
  }

}

function Remove-Service($deployTagService = $null, $removeSiteBoolean = $false)
{
try
{
  if($deployTagService -and $removeSiteBoolean)
{
   
   ## remove only the tagged site and  pool
   $webSite = Get-Website -Name $deployTagService
  if($webSite)
  {
   if($webSite.Name -eq $deployTagService)
   {
      $siteName = $webSite.Name
      Write-Host "$siteName exists"
      Write-Log -Message " $siteName exists" -Severity Information -writeLog Yes

      #Stop-WebSite -Name $siteName
      #Remove-WebSite -Name $site.Name -Confirm:$false #-ErrorAction SilentlyContinue
            
      #& $appcmd delete site "$site"
     $agrwebsite = "delete site " + "$siteName"
     Start-Process -FilePath $env:windir\System32\inetsrv\appcmd.exe -ArgumentList $agrwebsite -Wait
     Write-Host "Removed site: $siteName "
     Write-Log -Message "Removed site: $siteName " -Severity Information -writeLog Yes
   }
  }
  else
  {
    Write-Host "Site : $deployTagService not presen to removal"
  }

    Start-Sleep -s 3
   ## remove web pool
   $poolName = $deployTagService + "Pool"
   #$apppoolName = Get-IISAppPool -Name $poolName ## not working correctly

    Check-WebPoolExists ([ref]$webPoolExists) ([ref]$webPoolName) $poolName

    Start-Sleep -s 2

   if($webPoolExists) ## $apppoolName.Name -eq $pool.Name
    {
      #$poolName = $pool.Name
      Write-Host "$poolName exists"
      Write-Log -Message "$poolName exists" -Severity Information -writeLog Yes
      #Stop-WebAppPool -Name $poolName 
      $agrappPool = "delete apppool " + "$poolName"
      Start-Process -FilePath $env:windir\System32\inetsrv\appcmd.exe -ArgumentList $agrappPool -PassThru -Wait

       Start-Sleep -s 5
     # Remove-WebAppPool -Name $poolName -ErrorAction SilentlyContinue
      Write-Host "Removed pool: $poolName"
      Write-Log -Message "Removed pool: $poolName " -Severity Information -writeLog Yes
     }
   else
   {
     Write-Host "WebPool: $poolName not present to remove"
   }
}
else
{
    Write-Host "$deployTagService not removed. Since removeSite flag value is set as: $removeSiteBoolean"
    Write-Log -Message "$deployTagService not removed " -Severity Information -writeLog Yes
}
}
catch
{
   Write-Host $_.Exception.Message
   Write-Log -Message $_.Exception.Message -Severity Error -writeLog Yes
}
}


function SetSSLThumbPrintValue($installedPath, $thumbPrintVal)
{

 $apisArray =("IdentityApiService")

  foreach($api in $apisArray)
  {
     [bool]$isSaveIdent = $false

     $pathToJson = $installedPath + "$api\appsettings.json"
     if(Test-Path -Path $pathToJson)
     {
        $a = Get-Content $pathToJson -raw | ConvertFrom-Json

        switch($api)
        {
           "IdentityApiService" 
           {
                if($a.certificate -and $thumbPrintVal -ne $null)
                {
                   $a.certificate.thumbPrint = $thumbPrintVal
                   $isSaveIdent = $true
                }
                if($isSaveIdent)
                {
                  $a |  ConvertTo-Json -Depth 2 | set-content $pathToJson
                }

                break
           }

        }
        
     }
  }

}

function Add-Certificate()
{
    param
    (
       [Parameter(Mandatory=$true)]$certificatePath,
       [Parameter(Mandatory=$true)]$certPassword,
       [Parameter(Mandatory=$true)]$certLocationRoot, ## Trusted Root Certificate Authorities
       [Parameter(Mandatory=$true)]$certLocationPersonal, ## Personal
       [Parameter(Mandatory=$true)]$virtualDir,
       [Parameter(Mandatory=$true)]$serviceName,
       [Parameter(Mandatory=$true)]$port
    )

try
{
   if(Test-Path -Path $certificatePath)
   {
      
      $certificateRoot = Import-PfxCertificate -FilePath $certificatePath -Password (ConvertTo-SecureString -String $certPassword -AsPlainText -Force) -CertStoreLocation $certLocationRoot -Exportable

      $certificateVal = Import-PfxCertificate -FilePath $certificatePath -Password (ConvertTo-SecureString -String $certPassword -AsPlainText -Force) -CertStoreLocation $certLocationPersonal

      $thumbPrintVal = $certificateVal.Thumbprint
      $subjectVal = $certificateVal.Subject

      if($thumbPrintVal -ne $null)
      {
        SetPermissionForCertificate 'IIS_IUSRS' Read $certLocationPersonal $thumbPrintVal 
        $certPath = "$certLocationPersonal\$thumbPrintVal"
        $providerPath = "IIS:\SslBindings\0.0.0.0!$port"

        if((Get-ChildItem -Path $certLocationPersonal | Where-Object {$_.Thumbprint -eq $thumbPrintVal}))
        {
           Remove-Item -path "IIS:\SslBindings\0.0.0.0!$port" -ErrorAction SilentlyContinue
           Get-item $certPath | New-Item $providerPath

           ## remove http binding 
           Get-WebBinding -Port 80 -Name $serviceName -Protocol http | Remove-WebBinding

           ## set identity server config the thumprint value generated
           #SetSSLThumbPrintValue $virtualDir $thumbPrintVal
        }
        else
        {
           Throw "Thumbprint for certificate not found at path: $certPath "
        }

      }
      else
      {
        Throw "No thumprint found"
      }
    }
    else
    {
      Throw "Certificate not found in path: $certificatePath"
    }
}
catch
{
    Throw $_.Exception.Message 
 }

}


function Get-AllServices([string]$path)
{
try {
      if(Test-Path -Path $path)
      {
         ## get all folders with name like service
         $folders = Get-ChildItem -Directory -Path $path | select Name | Where-Object {$_.Name -like '*service*'} 
         foreach( $item in $folders){
           $services.Add($item)
         }
                     
      }
      else{
        Write-Log -Message "Path: $path doesn't exists" -Severity Error -writeLog Yes
      }
    }
catch{
   Write-Log -Message $_.Exception.Message -Severity Error -writeLog Yes
}
}


function Set-Service([ref]$deployedWebSiteName, [ref]$deployedWebAppPool, [ref]$lastWriteTime, [ref]$deployedVirDirPath, [ref]$isDeploymentSuccess, $service, $port, $virtualDir, $artifact, $customPath = $null)
{
   $webPoolExists = $null
   $webPoolName = $null
   ## check if any artifacts in folder
   $directoryInfo = Get-ChildItem -Path $artifact -Force | Measure-Object

   if($directoryInfo.count -gt 0) 
   {

   if(Test-path -Path "$env:SystemDrive\inetpub\wwwroot\$service")
   {
      Write-Host "virtual directory exists for service: $service"

      $poolName = $service + "Pool"

      $serviceName = $service #+ "Service"

      ## check if Site and pool exists, just replace the latest binaries
      #$webPool = Get-WebPoolDetails -apppoolName $poolName
      $iswebsiteExists = Get-Website -Name $serviceName

      if(-not $iswebsiteExists)
      {
        Check-WebPoolExists ([ref]$webPoolExists) ([ref]$webPoolName) $poolName

        Write-Host "webPoolExists: $webPoolExists, webPoolName: $webPoolName"

        if(-not $webPoolExists)
        {
          New-WebAppPool -Name $poolName -Force

          Start-Sleep -s 2

          $deployedWebAppPool.Value = $poolName

          $agrapp = "set APPPOOL $poolName /autoStart:true /startMode:AlwaysRunning"

          Start-Process -FilePath $env:windir\System32\inetsrv\appcmd.exe -ArgumentList $agrapp -WindowStyle Normal -Wait
          
          Start-Sleep -s 2

          Write-Host "created pool: $poolName "

        } 
		
		Write-Host "Deleting & copying virtual directory"
		## delete older dir contents and copy new 
        Get-ChildItem -Path "$env:SystemDrive\inetpub\wwwroot\$service" -Include *.* -File -Force -Recurse | foreach { $_.Delete()}

        Copy-Item -Path $artifact\* -Destination "$env:SystemDrive\inetpub\wwwroot\$service" -Recurse -Force 
		
        New-WebSite -Name $serviceName -PhysicalPath "$env:SystemDrive\inetpub\wwwroot\$service" -ApplicationPool $poolName -Force

        New-WebBinding -Name $serviceName -IPAddress * -Port $port -Protocol $protocolVal
        ## import certificate and https deployment
        Add-Certificate $certificatePath $certPassword $certLocationRoot $certLocationPersonal "$env:SystemDrive\inetpub\wwwroot\$service" $serviceName $port

        $deployedWebSiteName.Value = $serviceName

        $deployedVirDirPath.Value = "$env:SystemDrive\inetpub\wwwroot\$service"

        $lastWriteTime.Value = [datetime](Get-ItemProperty -Path "$env:SystemDrive\inetpub\wwwroot\$service" -Name LastWriteTime).lastwritetime

        $agrpreload = "set app $serviceName/ /preloadEnabled:true"

        Start-Process -FilePath $env:windir\System32\inetsrv\appcmd.exe -ArgumentList $agrpreload -WindowStyle Normal -Wait

        Start-Sleep -s 2

        Write-Host "created site: $serviceName "

      }
      else
      {
         ## stop pool and site 
         #Stop-WebAppPool -Name $poolName
         #Stop-Website -Name $serviceName 
         $deployedWebAppPool.Value = $poolName

         $deployedWebSiteName.Value = $serviceName

         $deployedVirDirPath.Value = "$env:SystemDrive\inetpub\wwwroot\$service"

         StopIISServices

         ## delete older dir contents and copy new 
         Get-ChildItem -Path "$env:SystemDrive\inetpub\wwwroot\$service" -Include *.* -File -Force -Recurse | foreach { $_.Delete()}

         ## just replace the latest binaries
         Copy-Item -Path $artifact\* -Destination "$env:SystemDrive\inetpub\wwwroot\$service" -Recurse -Force

         $lastWriteTime.Value = [datetime](Get-ItemProperty -Path "$env:SystemDrive\inetpub\wwwroot\$service" -Name LastWriteTime).lastwritetime

         #$isDeploymentSuccess.Value = $true
         #Start-WebAppPool -Name $poolName
         #Start-Website -Name $serviceName
      }
   }
   else
    {
       Write-Host "Virtual directory doesn't exists. Creating virtualdir: $virtualDir"

       $virtualDir = "$env:SystemDrive\inetpub\wwwroot\" + $service #+ "API"

       New-Item -Path $virtualDir -ItemType "directory" -Force

       $deployedVirDirPath.Value = $virtualDir

       if(Test-path -Path $virtualDir)
        {
              Copy-Item -Path $artifact\* -Destination $virtualDir -Recurse -Force

              $poolName = $service + "Pool"

              $serviceName = $service #+ "Service"

              New-WebAppPool -Name $poolName -Force 

              $deployedWebAppPool.Value = $poolName

              $agrapp = "set APPPOOL $poolName /autoStart:true /startMode:AlwaysRunning"

              Start-Process -FilePath $env:windir\System32\inetsrv\appcmd.exe -ArgumentList $agrapp -WindowStyle Normal -Wait
          
              Start-Sleep -s 2

              Write-Host "created pool: $poolName "

              New-WebSite -Name $serviceName -PhysicalPath $virtualDir -ApplicationPool $poolName
              New-WebBinding -Name $serviceName -IPAddress * -Port $port -Protocol $protocolVal
              ## import certificate and https deployment
              Add-Certificate $certificatePath $certPassword $certLocationRoot $certLocationPersonal $virtualDir $serviceName $port

              $deployedWebSiteName.Value = $serviceName

              $agrpreload = "set app $serviceName/ /preloadEnabled:true"

              Start-Process -FilePath $env:windir\System32\inetsrv\appcmd.exe -ArgumentList $agrpreload -WindowStyle Normal -Wait

              Start-Sleep -s 2

              Write-Host "created site: $serviceName"

              $lastWriteTime.Value = [datetime](Get-ItemProperty -Path $virtualDir -Name LastWriteTime).lastwritetime

              #$isDeploymentSuccess.Value = $true

        }
        else
        {
          ## TO DO not required 
        }

    }   
   }
   else
   {
      Write-Host "No binaries present in $artifact. Website not created for $service"

      Write-Log -Message "No binaries present in $artifact. Website not created for $service" -Severity Information -writeLog Yes
   }
}

function Service-Params($services, $portNumber, $apisFolder, $virtualDirectoryPath, $deployTagService = $null)
{
   if($deployTagService)
   {
        $portNumber= [EdwmApi]::$deployTagService.value__  #$portNumber + 1
        
        $virtualDirectoryPath = $virtualDirectoryPath + $deployTagService

        $artifactFolder = $apisFolder ##$apisFolder+$deployTagService

        $directoryInfo = Get-ChildItem -Path $artifactFolder -Force | Measure-Object

       if($directoryInfo.count -gt 0) 
       {
          Set-Service ([ref]$deployedWebSiteName) ([ref]$deployedWebAppPool) ([ref]$lastWriteTime) ([ref]$deployedVirDirPath) ([ref]$isDeploymentSuccess) $deployTagService $portNumber $virtualDirectoryPath $artifactFolder
          #Set-Service $deployTagService $portNumber $virtualDirectoryPath $artifactFolder ([ref]$deployedWebSiteName) ([ref]$deployedWebAppPool) ([ref]$lastWriteTime) ([ref]$deployedVirDirPath) ([ref]$isDeploymentSuccess)

       }
       else
       {
          Write-Host "No binaries present in $artifact. Website not created for $service"

          Write-Log -Message "No binaries present in $artifact. Website not created for $service" -Severity Information -writeLog Yes
       }
   }
   else
   { 

    if($services -ne $null)
    {
      foreach($service in $services)
      {
        $serviceName = $service.Name

        $portNumber = [EdwmApi]::$serviceName.value__  ##$portNumber + 1

        $virtualDirectoryPath = $virtualDirectoryPath + $service.Name

        $artifactFolder = $apisFolder+$service.Name

        $directoryInfo = Get-ChildItem -Path $artifactFolder -Force | Measure-Object

       if($directoryInfo.count -gt 0) 
       {

          Set-Service $service.Name $portNumber $virtualDirectoryPath $artifactFolder

       }
       else
       {
          
          Write-Log -Message "No binaries present in $artifact. Website not created for $service" -Severity Information -writeLog Yes
       }

      }
      
    }
  }
}

function Publish-Solution($projectPath, $outPath)
{

if(Test-Path -Path $projectPath)
{
  $projectfile = Get-ChildItem -Path $projectPath -Force 

  if($projectfile.Exists)
  {
    ## clean published directory
    if(Test-Path -Path $outPath)
    {
       $dirContents = Get-ChildItem -Path $outPath -Force | Measure-Object

       if($dirContents.Count -gt 0) {  Remove-Item -Path $outPath\* -Recurse -Force }

       dotnet publish $projectPath -o $outPath

      #$agr = "dotnet publish $projectPath -o $outPath"
      #Start-Process -ArgumentList $agr -WindowStyle Normal -Wait -WorkingDirectory $env:windir\System32\
    }
   }
}
else
{
   Write-Log -Message " $projectPath doesn't exists" -Severity Information -writeLog Yes
}

}

## https and certificate details

$protocolVal = "https"
$certLocationPersonal = "Cert:\LocalMachine\My"
$certLocationRoot = "Cert:\LocalMachine\Root"
$certificatePath = $localCertificatePath
$certPassword = $localCertPassword

#Write-Host $certificatePath 

$services = New-Object System.Collections.ArrayList

$dbProjectPath = $null

$apisFolder = $env:SystemDrive+ "\EDMWAPI\"

$virtualDirectoryPath = $env:SystemDrive + "\inetpub\wwwroot\"

$webPoolExists = $null

$webPoolName = $null

[bool]$removeSiteBoolean = $false

[bool]$cleanInstallBoolean = $false

$projectPaths = @()

$deployedWebSiteName = $null

$deployedWebAppPool = $null

$lastWriteTime = $null

$deployedVirDirPath = $null

$isDeploymentSuccess = $false

if($deployprojectPaths -ne $null)
{
   $projectPaths = $deployprojectPaths.Split(',')
}


if($removeSite -eq "Yes") { $removeSiteBoolean = $true}


$gitlocation = Get-Location

$gitBuildPath = $gitlocation.Path

Write-Host "Gitlab runner directory: $gitBuildPath"


try
{

if(Test-Path -Path $gitBuildPath)
{
    foreach($project in $projectPaths)
    {
       $serviceprojectPath = $gitBuildPath + $project
       
       Write-Host "Project directory: $serviceprojectPath"
       
       if(Test-Path -Path $serviceprojectPath)
       {
         $serviceProjectName = [System.IO.Path]::GetFileName($serviceprojectPath)
         ## split project name and create service name
         $deployServiceName = $serviceProjectName.Split('.')
         $deployTagService = $deployServiceName[1] + $deployServiceName[2] + "Service"
         $servicePublishPath = $env:SystemDrive + "\EDMWAPI\" + $deployTagService
         
          if(Test-Path -Path $servicePublishPath)
          {

           Write-Host "Publishing project: $serviceProjectName"

           Publish-Solution $serviceprojectPath $servicePublishPath

            #Write-Host "Publishing project: $serviceProjectName"

             #Publish-Solution $serviceprojectPath $servicePublishPath

             Write-Host "Removing service : $deployTagService if present"

             Remove-Service $deployTagService $removeSiteBoolean

            

             Write-Host "calling Service-Params method"

             #Service-Params $null $portNumber $apisFolder $virtualDirectoryPath $deployTagService

             Service-Params $null $portNumber $servicePublishPath $virtualDirectoryPath $deployTagService

             #Check-Deployment ([ref]$deployedWebSiteName) ([ref]$deployedWebAppPool) #([ref]$isDeploymentSuccess)

             if($deployedWebSiteName -and $deployedWebAppPool)
             {

               Write-Output ("Site: " + $deployedWebSiteName + " | Pool: " + $deployedWebAppPool + " deployed successfully " + " Virtualdir: " + $deployedVirDirPath + " last write time: " + $lastWriteTime.ToUniversalTime().ToString("R"))
               Start-Website -Name $deployedWebSiteName

             }
             else
             {
                Write-Host "Either site: $deployedWebSiteName or Apppool: $deployedWebAppPool not deployed correctly. Please check manually"
             }

             Write-Host "Restarting IIS server"

             StartIISServices
          }
          else
          {
             ## publish directory doesn't exists. create dir
             Write-Host "Publish path: $servicePublishPath doesn't exists. Creating publish directory"

             New-Item -Path $servicePublishPath -ItemType "directory" -Force

             Write-Host "Created publish directory: $servicePublishPath"

             Write-Host "Publishing project: $serviceProjectName"

             Publish-Solution $serviceprojectPath $servicePublishPath

             Write-Host "Removing service : $deployTagService if present"

             Remove-Service $deployTagService $removeSiteBoolean

             #Start-Sleep -s 15

             Write-Host "calling Service-Params method"

             #Service-Params $null $portNumber $apisFolder $virtualDirectoryPath $deployTagService
             Service-Params $null $portNumber $servicePublishPath $virtualDirectoryPath $deployTagService
              
             if($deployedWebSiteName -and $deployedWebAppPool)
             {

               Write-Output ("Site: " + $deployedWebSiteName + " | Pool: " + $deployedWebAppPool + " deployed successfully " + " Virtualdir: " + $deployedVirDirPath + " last write time: " + $lastWriteTime.ToUniversalTime().ToString("R"))
             }
             else
             {
                Write-Host "Either site: $deployedWebSiteName or Apppool: $deployedWebAppPool not deployed correctly. Please check manually"
             }

             StartIISServices
          }

       }
       else
       {
          Write-Host "Invalid projectpath: $serviceprojectPath. "
          return
       }
   
    }

}

}
catch
{
  Write-Host $_.Exception.Message
}






