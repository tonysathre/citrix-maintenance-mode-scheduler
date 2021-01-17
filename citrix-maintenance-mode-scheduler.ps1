#Requires -Version 3

function New-GroupBox {
    param (
        [Parameter(Mandatory)]
            $Name,
        [Parameter(Mandatory)]
            [string]$Header,
        [Parameter(Mandatory)]
            $Margin,
        [Parameter(Mandatory)]
            $ParentControl
    )

    $Temp = New-Object -TypeName System.Windows.Controls.GroupBox
    $Temp.Name = $Name.ToString()
    $Temp.Header = $Header
    $Temp.Margin = $Margin

    New-Variable -Name $Name -Value $Temp -Scope Script -PassThru

    $ParentControl.AddChild((Get-Variable -Name $Name -ValueOnly))
}

function New-StackPanel {
    param (
        [Parameter(Mandatory)]
            [string]$Name,
        [Parameter(Mandatory)]
            $ParentControl    
    )

    $Temp = New-Object -TypeName System.Windows.Controls.StackPanel
    $Temp.Name = $Name.ToString()

    New-Variable -Name $Name -Value $Temp -Scope Script -PassThru

    $ParentControl.AddChild((Get-Variable -Name $Name -ValueOnly))
}

function New-Label {
    param (
        [Parameter(Mandatory)]
            [string]$Name,
        [Parameter(Mandatory)]
            [string]$Content,
        [Parameter(Mandatory)]
            [int]$Row,
        [Parameter(Mandatory)]
            [int]$Column,
        [Parameter(Mandatory)]
        [ValidateSet('Center', 'Left', 'Right', 'Stretch')]
            [string]$HorizontalAlignment = 'Center',
        [Parameter(Mandatory)]
            $ParentControl    
    )

    $Temp = New-Object -TypeName System.Windows.Controls.Label
    $Temp.Name = $Name.ToString()
    $Temp.Content = $Content
    $Temp.HorizontalAlignment = Set-HorizontalAlignment -HorizontalAlignment $HorizontalAlignment
    
    New-Variable -Name $Name -Value $Temp -Scope Script -PassThru

    $ParentControl.AddChild((Get-Variable -Name $Name -ValueOnly))
    [System.Windows.Controls.Grid]::SetColumn((Get-Variable -Name $Name -ValueOnly), $Column)
    [System.Windows.Controls.Grid]::SetRow((Get-Variable -Name $Name -ValueOnly), $Row)
}

function New-ComboBox {
    param (
        [Parameter(Mandatory)]
            [string]$Name,
        [Parameter(Mandatory)]
            [int]$Column,
        [Parameter(Mandatory)]
            [int]$Row,
        [Parameter(Mandatory)]
            $ItemsSource,
        [Parameter(Mandatory)]
        [ValidateSet('Center', 'Left', 'Right', 'Stretch')]
            [string]$HorizontalAlignment = 'Center',
        [Parameter(Mandatory)]
            $ParentControl,
        [Parameter(Mandatory=$false)]
            [int]$MinWidth,
        [Parameter(Mandatory=$false)]
            [int]$SelectedIndex,
        [Parameter(Mandatory=$false)]
            [string]$Margin = '0,0,0,0'
    )

    $Temp = New-Object -TypeName System.Windows.Controls.ComboBox
    $Temp.Name = $Name.ToString()
    $Temp.ItemsSource = $ItemsSource
    $Temp.HorizontalAlignment = Set-HorizontalAlignment -HorizontalAlignment $HorizontalAlignment
    $Temp.SelectedIndex = $SelectedIndex
    $Temp.Margin = $Margin
    if ($SelectedIndex -eq -1) {
        $Temp.Text = ''
    }

    New-Variable -Name $Name -Value $Temp -Scope Script -PassThru

    $ParentControl.AddChild((Get-Variable -Name $Name -ValueOnly))
    [System.Windows.Controls.Grid]::SetColumn((Get-Variable -Name $Name -ValueOnly), $Column)
    [System.Windows.Controls.Grid]::SetRow((Get-Variable -Name $Name -ValueOnly), $Row)
}
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
        [Parameter(Mandatory)]
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

$ConfigFile = Import-ConfigFile

try {
    Add-Type -Path (Join-Path $PSScriptRoot .\lib\Loya.Dameer.dll) | Out-Null
}
catch {
    New-DialogBox -Message $Error[0].Exception.Message -Title 'Unhandled Exception' -MessageBoxIcon Error -MessageBoxButtons OK
    Exit    
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

## Event Handlers ##


$Form.ShowDialog() | Out-Null