#Requires -Version 3
function Set-HorizontalAlignment {
    param (
        [Parameter(Mandatory)]
        [ValidateSet('Center', 'Left', 'Right', 'Stretch')]
            [string]$HorizontalAlignment
    )

    switch ($HorizontalAlignment) {
        'Center' { return [System.Windows.HorizontalAlignment]::Center }
        'Left' { return [System.Windows.HorizontalAlignment]::Left }
        'Right' { return [System.Windows.HorizontalAlignment]::Right }
        'Stretch' { return [System.Windows.HorizontalAlignment]::Stretch }
    } 
}
function New-DateTimePicker {
    param (
        [Parameter(Mandatory)]
            [string]$Name,
        [Parameter(Mandatory)]
            [bool]$ShowCheckBox,
        [Parameter(Mandatory)]
        [ValidateSet('Long', 'Short', 'Time', 'Custom')]
            [string]$Format,
        [Parameter(Mandatory=$false)]
            [string]$CustomFormat = 'MM/dd/yyyy hh:mm tt',
        [Parameter(Mandatory)]
            [int]$Column,
        [Parameter(Mandatory)]
            [int]$Row,
        [Parameter(Mandatory=$false)]
        [ValidateSet('Center', 'Left', 'Right', 'Stretch')]
            [string]$HorizontalAlignment = 'Center',
        [Parameter(Mandatory)]
            $ParentControl
    )

    $Temp = New-Object Loya.Dameer.Dameer
    $Temp.Name = $Name.ToString()
    $Temp.ShowCheckBox = $ShowCheckBox
    $Temp.Format = $Format
    $Temp.CustomFormat = $CustomFormat
    $Temp.HorizontalAlignment = Set-HorizontalAlignment -HorizontalAlignment $HorizontalAlignment
    New-Variable -Name $Name -Value $Temp -Scope Script -PassThru

    $ParentControl.AddChild((Get-Variable -Name $Name -ValueOnly))
    [System.Windows.Controls.Grid]::SetColumn((Get-Variable -Name $Name -ValueOnly), $Column)
    [System.Windows.Controls.Grid]::SetRow((Get-Variable -Name $Name -ValueOnly), $Row)
}


function New-DialogBox {
    param (
        [Parameter(Mandatory)]
        [string]$Message,

        [Parameter(Mandatory)]
        [string]$Title,

        [Parameter(Mandatory)]
        [ValidateSet('Asterisk', 'Error', 'Exclamation', 'Hand', 'Information', 'None', 'Question', 'Stop', 'Warning')]
        [string]$MessageBoxIcon,

        [Parameter(Mandatory)]
        [ValidateSet('AbortRetryIgnore', 'OK', 'OKCancel', 'RetryCancel', 'YesNo', 'YesNoCancel')]
        [string]$MessageBoxButtons
    )

    $Icon = [System.Windows.Forms.MessageBoxIcon]::$MessageBoxIcon
    
    return [System.Windows.Forms.MessageBox]::Show($Message, $Title, $MessageBoxButtons, $Icon)
}

try {
    Add-Type -Path (Join-Path $PSScriptRoot .\lib\Loya.Dameer.dll) | Out-Null
}
catch {
    New-DialogBox -Message $Error[0].Exception.Message -Title 'Unhandled Exception' -MessageBoxIcon Error -MessageBoxButtons OK
    Exit    
}

function Get-Machines {
    try {
        $ListBox_Machine.ItemsSource = Invoke-Command -Session $PSSession -ScriptBlock {
            Add-PSSnapin Citrix.*
            (Get-BrokerMachine).HostedMachineName
        }
    }
    catch {
        New-DialogBox -Message $Error[0].Exception.Message -Title 'Unhandled Exception' -MessageBoxIcon Error -MessageBoxButtons OK
    }
}

function Get-DeliveryGroups {
    try {
        $Label_StatusBar.Content = 'Loading delivery groups'
        $DeliveryGroups = Invoke-Command -Session $PSSession -ScriptBlock {
                            Add-PSSnapin Citrix.*
                            $DeliveryGroups = Get-BrokerDesktopGroup

                            if ($DeliveryGroups.Length -eq 1) {
                                return $DeliveryGroups.ToString()
                            } else {
                                return $DeliveryGroups
                            }
        }

        $ComboBox_DeliveryGroup.ItemsSource = $DeliveryGroups
    }
    catch {
        New-DialogBox -Message $Error[0].Exception.Message -Title 'Unhandled Exception' -MessageBoxIcon Error -MessageBoxButtons OK
    }
    $Label_StatusBar.Content = 'Loaded delivery groups'
}

[xml]$XAML_Form = Get-Content -Raw (Join-Path $PSScriptRoot Main_Window.xaml)
Add-Type -AssemblyName PresentationCore
Add-Type -AssemblyName PresentationFramework
Add-Type -AssemblyName System.Drawing
Add-Type -AssemblyName System.Windows.Forms
[System.Windows.Forms.Application]::EnableVisualStyles() | Out-Null

try {
    $XML_Node_Reader = (New-Object System.Xml.XmlNodeReader $XAML_Form)
    $Form = [Windows.Markup.XamlReader]::Load($XML_Node_Reader)
}
catch {
    New-DialogBox -Title 'Unhandled Exception' -Message $Error[0].Exception.Message -MessageBoxIcon Error -MessageBoxButtons OK
    Exit
}

$XAML_Form.SelectNodes('//*[@Name]') | ForEach-Object {
    Set-Variable -Name ($_.Name) -Value $Form.FindName($_.Name) -Scope Script
}

## Build UI ##
New-DateTimePicker -Name DateTimePicker_Start -ShowCheckBox $false -Format Custom -CustomFormat 'MM/dd/yyyy hh:mm tt' -ParentControl $(Get-Variable -Name GroupBox_MaintenanceModeStart -ValueOnly) -Row 3 -Column 0 -HorizontalAlignment Center
New-DateTimePicker -Name DateTimePicker_End -ShowCheckBox $false -Format Custom -CustomFormat 'MM/dd/yyyy hh:mm tt' -ParentControl $(Get-Variable -Name GroupBox_MaintenanceModeEnd -ValueOnly) -Row 4 -Column 0 -HorizontalAlignment Center
$PowerActions = @('', 'TurnOn', 'TurnOff', 'Shutdown', 'Reset', 'Restart', 'Suspend', 'Resume')
$ComboBox_PowerAction.ItemsSource = $PowerActions
$ComboBox_ObjectType.ItemsSource = @('Machine', 'Delivery Group')
$ComboBox_ObjectType.SelectedItem = 'Machine'

## Event Handlers ##
$MenuItem_SetCredentials.Add_Click({
    $script:Credential = Get-Credential
})

$Form.Add_Closing({
    if ($PSSession) {
        $PSSession | Remove-PSSession
    }
})

$MenuItem_Exit.Add_Click({
    $Form.Close()
})

$ComboBox_ObjectType.Add_DropDownClosed({
    switch ($ComboBox_ObjectType.Text) {
        'Machine' {
            $GroupBox_DeliveryGroup.Visibility = 'Hidden'
            $GroupBox_Machine.Visibility = 'Visible'
        }
        'Delivery Group' {
            $GroupBox_Machine.Visibility = 'Hidden'
            $GroupBox_DeliveryGroup.Visibility = 'Visible'
        }
    }
})

$Button_Schedule.Add_Click({

})

$MenuItem_LoadData.Add_Click({
    if (-not( $PSSession)) {
        New-DialogBox -Message 'Not connected to a delivery controller.' -Title 'Error' -MessageBoxIcon Error -MessageBoxButtons OK
        return
    }

    try {
        Get-Machines
        Get-DeliveryGroups
    }
    catch {
        New-DialogBox -Message $Error[0].Exception.Message -Title 'Unhandled Exception' -MessageBoxIcon Error -MessageBoxButtons OK
    }
})

$Button_Connect.Add_Click({
    $Label_StatusBar.Content = "Connecting to $($TextBox_DeliveryController.Text)"
    try {
        $PSSessionParams = @{
            ComputerName = $TextBox_DeliveryController.Text
        }
        if ($Credential) {
            $PSSessionParams.Add('Credential', $Credential)
        }
        $script:PSSession = New-PSSession @PSSessionParams
    }
    catch [System.UnauthorizedAccessException] {
        New-DialogBox -Message $Error[0].Exception.Message -Title 'Access Denied' -MessageBoxIcon Error -MessageBoxButtons OK
    }
    catch {
        New-DialogBox -Message $Error[0].Exception.Message -Title 'Unhandled Exception' -MessageBoxIcon Error -MessageBoxButtons OK
    }
    
    if ($PSSession) {
        $Label_StatusBar.Content = "Connected to $($TextBox_DeliveryController.Text)"
    }
})

$Form.ShowDialog() | Out-Null