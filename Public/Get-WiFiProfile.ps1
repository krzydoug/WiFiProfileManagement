<#
    .SYNOPSIS
        Lists the wireless profiles and their configuration settings.
    .PARAMETER ProfileName
        The name of the WiFi profile.
    .PARAMETER WiFiAdapterName
        Specifies the name of the wireless network adapter on the machine. This is used to obtain the Guid of the interface.
        The default value is 'Wi-Fi'
    .PARAMETER ClearKey
        Specifies if the password of the profile is to be returned.
    .EXAMPLE
        PS C:\>Get-WiFiProfile -ProfileName TestWiFi

        SSIDName       : TestWiFi
        ConnectionMode : auto
        Authentication : WPA2PSK
        Encryption     : AES
        Password       :

        Get the WiFi profile information on wireless profile TestWiFi

    .EXAMPLE 
        PS C:\>Get-WiFiProfile -ProfileName TestWiFi -CLearKey

        SSIDName       : TestWiFi
        ConnectionMode : auto
        Authentication : WPA2PSK
        Encryption     : AES
        Password       : password1

        This examples shows the use of the ClearKey switch to return the WiFi profile password.

    .EXAMPLE
        PS C:\>Get-WiFiProfile | where {$PSItem.ConnectionMode -eq 'auto' -and $PSItem.Authentication -eq 'open'}

        This example shows how to find WiFi profiles with insecure connection settings.
#>
function Get-WiFiProfile
{
    [CmdletBinding()]
    [OutputType([System.Management.Automation.PSCustomObject])]
    param
    (
        [Parameter(Position = 0)]
        [System.String[]]
        $ProfileName,

        [Parameter()]
        [System.String]
        $WiFiAdapterName,

        [Parameter()]
        [Switch]
        $ClearKey
    )

    try
    {
        $profileListPointer = 0

        if (!$WiFiAdapterName)
        {
            $interfaceGuids = (Get-WiFiInterface).Guid
        }
        else
        { 
            $interfaceGuids = Get-WiFiInterfaceGuid -WiFiAdapterName $WiFiAdapterName
        }

        $clientHandle = New-WiFiHandle

        if ($ClearKey)
        {
            $wlanProfileFlags = 13
        }
        else
        {
            $wlanProfileFlags = 0
        }

        if (!$ProfileName)
        {
            foreach ($interfaceGUID in $interfaceGuids)
            {
                [void] [WiFi.ProfileManagement]::WlanGetProfileList(
                    $clientHandle,
                    $interfaceGUID,
                    [IntPtr]::zero,
                    [ref] $profileListPointer
                )
                $wiFiProfileList = [WiFi.ProfileManagement+WLAN_PROFILE_INFO_LIST]::new($profileListPointer)
                $ProfileName = ($wiFiProfileList.ProfileInfo).strProfileName
            }
        }

        foreach ($wiFiProfile in $ProfileName)
        {
            foreach ($interfaceGUID in $interfaceGuids)
            {
                Get-WiFiProfileInfo -ProfileName $wiFiProfile -InterfaceGuid $interfaceGUID -ClientHandle $clientHandle -WlanProfileFlags $wlanProfileFlags
            }
        }
    }
    catch
    {
        Write-Error $PSItem
    }
    finally
    {
        if ($clientHandle)
        {
            Remove-WiFiHandle -ClientHandle $clientHandle
        }
    }
}
