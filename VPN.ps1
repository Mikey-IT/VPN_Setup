#
# Configuration Parameters
$ProfileName = 'LGOC VPN'
$DnsSuffix = 'liftsafeinspections.com'
$ServerAddress = 'VPN.liftsafegroup.com'
$L2tpPsk = 'LgocVPN'

#
# Build client VPN profile
# https://docs.microsoft.com/en-us/windows/client-management/mdm/vpnv2-csp
#

# Define VPN Profile XML
$ProfileNameEscaped = $ProfileName -replace ' ', '%20'
$ProfileXML =
	'<VPNProfile>
		<RememberCredentials>false</RememberCredentials>
		<DnsSuffix>'+$dnsSuffix+'</DnsSuffix>
		<NativeProfile>
			<Servers>' + $ServerAddress + '</Servers>
			<RoutingPolicyType>SplitTunnel</RoutingPolicyType>
			<NativeProtocolType>l2tp</NativeProtocolType>
			<L2tpPsk>'+$L2tpPsk+'</L2tpPsk>
		</NativeProfile>
'

# Routes to include in the VPN
$ProfileXML += "  <Route><Address>192.168.0.0</Address><PrefixSize>24</PrefixSize><ExclusionRoute>false</ExclusionRoute></Route>`n"
$ProfileXML += "  <Route><Address>192.168.1.0</Address><PrefixSize>24</PrefixSize><ExclusionRoute>false</ExclusionRoute></Route>`n"

$ProfileXML += '</VPNProfile>'

# Convert ProfileXML to Escaped Format
$ProfileXML = $ProfileXML -replace '<', '&lt;'
$ProfileXML = $ProfileXML -replace '>', '&gt;'
$ProfileXML = $ProfileXML -replace '"', '&quot;'

# Define WMI-to-CSP Bridge Properties
$nodeCSPURI = './Vendor/MSFT/VPNv2'
$namespaceName = 'root\cimv2\mdm\dmmap'
$className = 'MDM_VPNv2_01'

# Define WMI Session
$session = New-CimSession

#
# Create VPN Profile
#

try
{
	$newInstance = New-Object Microsoft.Management.Infrastructure.CimInstance $className, $namespaceName
	$property = [Microsoft.Management.Infrastructure.CimProperty]::Create('ParentID', "$nodeCSPURI", 'String', 'Key')
	$newInstance.CimInstanceProperties.Add($property)
	$property = [Microsoft.Management.Infrastructure.CimProperty]::Create('InstanceID', "$ProfileNameEscaped", 'String', 'Key')
	$newInstance.CimInstanceProperties.Add($property)
	$property = [Microsoft.Management.Infrastructure.CimProperty]::Create('ProfileXML', "$ProfileXML", 'String', 'Property')
	$newInstance.CimInstanceProperties.Add($property)

	$session.CreateInstance($namespaceName, $newInstance, $options) | Out-Null
	Write-Host "Created '$ProfileName' profile."
}
catch [Exception]
{
	Write-Host "Unable to create $ProfileName profile: $_"
	exit
}

# Create a desktop shortcut
$WScriptShell = New-Object -ComObject WScript.Shell
$Shortcut = $WScriptShell.CreateShortcut("$env:Public\Desktop\VPN.lnk")
$Shortcut.TargetPath = "rasphone.exe"
$Shortcut.Save()
