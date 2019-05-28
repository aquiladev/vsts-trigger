[CmdletBinding(DefaultParameterSetName = 'None')]
param
(
	[String] [Parameter(Mandatory = $true)]
	$ConnectedServiceName,
	
	[String] [Parameter(Mandatory = $true)]
	$ReleaseDefinitionName
)

Function Find-ReleaseDefinition {
	param([Parameter(Mandatory = $true)] $TfsUri)
	
	$url = [string]::Format("{0}{1}/_apis/release/definitions?`$expand=artifacts&api-version=3.0-preview.1", $TfsUri, $env:SYSTEM_TEAMPROJECT)
	Write-Host "url= $url"

	$result = $null
	try {
		$result = Invoke-RestMethod -Uri $url -Method GET -ContentType "application/json" -Headers @{Authorization=("Basic {0}" -f $base64AuthInfo)}
	} catch {
		Write-Verbose $_.Exception.ToString()
		$response = $_.Exception.Response
		$responseStream =  $response.GetResponseStream()
		$streamReader = New-Object System.IO.StreamReader($responseStream)
		$streamReader.BaseStream.Position = 0
		$streamReader.DiscardBufferedData()
		$responseBody = $streamReader.ReadToEnd()
		$streamReader.Close()
		Write-Error $responseBody
	}
	
	return $result.value | where {$_.name -eq $ReleaseDefinitionName}
}

Function Get-ArtifactsVersions {
	param
	(
		[Parameter(Mandatory = $true)] $TfsUri,
		[Parameter(Mandatory = $true)] $Artifacts
	)
	
	Write-Host "Get artifacts versions"
	$url = [string]::Format("{0}{1}/_apis/release/artifacts/versions?api-version=3.0-preview.1", $TfsUri, $env:SYSTEM_TEAMPROJECT)
	Write-Host "url= $url"
	
	$body = $Artifacts | ConvertTo-Json -Depth 4
	Write-Host "body= $body"
	
	$result = $null
	try {
		$result = Invoke-RestMethod -Uri $url -Method POST -Body $body -ContentType "application/json" -Headers @{Authorization=("Basic {0}" -f $base64AuthInfo)}
	} catch {
		Write-Verbose $_.Exception.ToString()
		$response = $_.Exception.Response
		$responseStream =  $response.GetResponseStream()
		$streamReader = New-Object System.IO.StreamReader($responseStream)
		$streamReader.BaseStream.Position = 0
		$streamReader.DiscardBufferedData()
		$responseBody = $streamReader.ReadToEnd()
		$streamReader.Close()
		Write-Error $responseBody
	}
	
	return $result
}

Function Get-Artifacts {
	param
	(
		[Parameter(Mandatory = $true)] $TfsUri,
		[Parameter(Mandatory = $true)] $ReleaseDefinition,
		[Parameter(Mandatory = $true)] $BuildDefinitionId
	)
	
	$artifacts = @()
	$defArtifacts = $ReleaseDefinition.artifacts
	
	if($defArtifacts -eq $null) {
		Write-Error "Cannot find artifacts for the Release Definition."
	}
	
	$currentArtifact = $defArtifacts | where {$_.definitionReference.definition.id -eq $BuildDefinitionId}

	if($currentArtifact -ne $null) {
		$artifacts += @{
			alias = $env:BUILD_DEFINITIONNAME
			instanceReference = @{
				name = $env:BUILD_BUILDNUMBER
				id = $env:BUILD_BUILDID
				sourceBranch = $env:BUILD_SOURCEBRANCH
			}
		}
	}
	
	$unknownArtifacts = $defArtifacts | where {$_.definitionReference.definition.id -ne $BuildDefinitionId}
	
	if($unknownArtifacts -eq $null) {
		return $artifacts
	}
	
	$versions = Get-ArtifactsVersions -TfsUri $TfsUri -Artifacts $unknownArtifacts

	if($versions -eq $null) {
		Write-Error "Cannot find artifacts versions."
	}

	$versions = $versions.artifactVersions
	
	foreach ($artifact in $unknownArtifacts) {
		$artifactVersions = $versions | where {$_.artifactSourceId -eq $artifact.id}
		
		if($artifactVersions -eq $null -or $artifactVersions.versions -eq $null -or $artifactVersions.versions.length -eq 0) {
			Write-Error "Cannot find artifact versions."
		}
		
		$latestVersion = $artifactVersions.versions[0]
		Write-Host "latestVersion= $latestVersion"
		
		$artifacts += @{
			alias = $artifact.alias
			instanceReference = @{
				name = $latestVersion.name
				id = $latestVersion.id
				sourceBranch = $latestVersion.sourceBranch
			}
		}
	}

	return $artifacts
}

Function TriggerRelease {
	param
	(
		[Parameter(Mandatory = $true)] $TfsUri,
		[Parameter(Mandatory = $true)] $ReleaseDefinition,
		[Parameter(Mandatory = $true)] $Artifacts
	)
	
	Write-Host "Trigger release"
	$url = [string]::Format("{0}{1}/_apis/release/releases?api-version=3.0-preview.1", $TfsUri, $env:SYSTEM_TEAMPROJECT)
	Write-Host "url= $url"
	
	$body = @{
		definitionId = $ReleaseDefinition.id
		description = ""
		artifacts = $Artifacts
		isDraft = $false
		manualEnvironments = @()
	} | ConvertTo-Json -Depth 4
	Write-Host "body= $body"
	
	$result = $null
	try {
		$result = Invoke-RestMethod -Uri $url -Method POST -Body $body -ContentType "application/json" -Headers @{Authorization=("Basic {0}" -f $base64AuthInfo)}
	} catch {
		Write-Verbose $_.Exception.ToString()
		$response = $_.Exception.Response
		$responseStream =  $response.GetResponseStream()
		$streamReader = New-Object System.IO.StreamReader($responseStream)
		$streamReader.BaseStream.Position = 0
		$streamReader.DiscardBufferedData()
		$responseBody = $streamReader.ReadToEnd()
		$streamReader.Close()
		Write-Error $responseBody
	}
	
	return $result
}

$ErrorActionPreference = 'Stop'

Write-Verbose "Entering script ReleaseTrigger.ps1"

Write-Host "ReleaseDefinitionName= $ReleaseDefinitionName"
Write-Host "TeamProject= $env:SYSTEM_TEAMPROJECT"

if($env:SYSTEM_TEAMFOUNDATIONCOLLECTIONURI -match "^(http://|https://)?[^/]+\.visualstudio\.com/") {
	Write-Host "Using cloud services"
	$tfsColUri = $env:SYSTEM_TEAMFOUNDATIONCOLLECTIONURI | out-string
	$uriParts = $tfsColUri -split ".visualstudio.com/"
	$tfsUri = [string]::Format("{0}.vsrm.visualstudio.com/{1}", $uriParts[0], $uriParts[1]).Trim()
}
else {
	Write-Host "Using on-premises services"
	$tfsUri = $env:SYSTEM_TEAMFOUNDATIONCOLLECTIONURI
}
Write-Host "TfsUri= $tfsUri"

$buildDefinitionId= $env:BUILD_DEFINITIONID
if($buildDefinitionId -eq $null) {
	$buildDefinitionId= $env:SYSTEM_DEFINITIONID
}

Write-Host "BuildDefinitionId= $buildDefinitionId"
Write-Host "BuildDefinitionName= $env:BUILD_DEFINITIONNAME"
Write-Host "BuildId= $env:BUILD_BUILDID"

$serviceEndpoint = Get-ServiceEndpoint -Name "$ConnectedServiceName" -Context $distributedTaskContext

$username = $serviceEndpoint.Authorization.Parameters.UserName
$password = $serviceEndpoint.Authorization.Parameters.Password
$base64AuthInfo = [Convert]::ToBase64String([Text.Encoding]::ASCII.GetBytes(("{0}:{1}" -f $username, $password)))

$definition = Find-ReleaseDefinition -TfsUri $tfsUri
if($definition -eq $null -or $definition -is [array]) {
	Write-Error "Cannot find Release Definition or there are more than one Release Definition with the name."
}

$artifacts = @(Get-Artifacts -TfsUri $tfsUri -ReleaseDefinition $definition -BuildDefinitionId $buildDefinitionId)
$release = TriggerRelease -TfsUri $tfsUri -ReleaseDefinition $definition -Artifacts $artifacts

Write-Verbose "Leaving script ReleaseTrigger.ps1"