#!powershell

# Copyright: (c) 2024, Yuichi Mizutani (yumizu11) <iyumizu@hotmail.com>

#AnsibleRequires -CSharpUtil Ansible.Basic

function Invoke-Command {
    param([Parameter(Mandatory=$true)][string] $Command, [string] $Arg = "")
    $pinfo = New-Object System.Diagnostics.ProcessStartInfo
    $pinfo.FileName = $Command
    $pinfo.RedirectStandardError = $true
    $pinfo.RedirectStandardOutput = $true
    $pinfo.StandardOutputEncoding = [System.Text.Encoding]::Unicode
    $pinfo.StandardErrorEncoding = [System.Text.Encoding]::Unicode
    $pinfo.UseShellExecute = $false
    $pinfo.CreateNoWindow = $true
    $pinfo.Arguments = $Arg
    $p = New-Object System.Diagnostics.Process
    $p.StartInfo = $pinfo
    $p.Start() | Out-Null
    $p.WaitForExit()
    $stdout = $p.StandardOutput.ReadToEnd()
    $stderr = $p.StandardError.ReadToEnd()

    return @{"rc" = $($p.ExitCode); "stdout" = $($stdout); "stderr" = $($stderr)}
}

function Invoke-WSL {
    param([string] $Arg = "")
    return (Invoke-Command -Command "wsl.exe" -Arg $Arg)
}

$spec = @{
    options = @{
        state = @{ type = "str"; choices = "present", "absent", "shutdown", "updated"; default = "present" }
    }
    # supports_check_mode = $true
}

$module = [Ansible.Basic.AnsibleModule]::Create($args, $spec)

$state = $module.Params.state

$module.Result.changed = $false

$wsl_path = "$($env:ProgramFiles)\WSL\wsl.exe"

if (($state -eq "present" -or $state -eq "updated" ) -and ((Test-Path -Path $wsl_path) -eq $false)) {
    $result = Invoke-Command -Command "winget.exe" -Arg "install --id Microsoft.WSL"
    $module.Result.stdout = $result.stdout
    $module.Result.stderr = $result.stderr
    $module.Result.rc = $result.rc
    if ($result.rc -eq 0) {
        if (Test-Path -Path $wsl_path) {
            $result = Invoke-WSL -Arg "--version"
            if ($result.rc -eq 0) {
                $module.Result.currenver = (($result.stdout.Split("`r`n"))[0].Split(":"))[1].Trim()
                $module.Result.changed = $true
            } else {
                $module.Warn("WSL was installed succeeded, but version number is unknown.")
            }
        } else {
            $module.FailJson("winget command succeeded, but wsl.exe is not installed. Something is wrong.")
        }
    } elseif ($result.rc -ne -1978335189) {
        $module.FailJson("Failed to install Microsoft.WSL store app. Please check network connectivity.")
    }
} elseif ($state -eq "updated") {
    $result = Invoke-WSL -Arg "--version"
    $currentver = ""
    if ($result.rc -eq 0) {
        $currentver = (($result.stdout.Split("`r`n"))[0].Split(":"))[1].Trim()
        $module.Result.currenver = $currentver
    }

    $result = Invoke-Command -Command "winget.exe" -Arg "upgrade Microsoft.WSL"
    if ($result.rc -ne -1978335212) {
        $result = Invoke-WSL -Arg "--version"
        $newver = (($result.stdout.Split("`r`n"))[0].Split(":"))[1].Trim()
        if ($currentver -ne $newver) {
            $module.Result.changed = $true
            $module.Result.currenver = $newver
        }
    }
} elseif ($state -eq "absent" -and (Test-Path -Path $wsl_path)) {
    $result = Invoke-WSL -Arg "--uninstall"
    $module.Result.stdout = $result.stdout
    $module.Result.stderr = $result.stderr
    $module.Result.rc = $result.rc
    if ($result.rc -eq 0) {
        $module.Result.changed = $true
    } else {
        $module.FailJson("Failed to uninstall WSL.")
    }
} elseif ($state -eq "shutdown") {
    $wslc = $wsl_path
    if ((Test-Path -Path $wsl_path) -eq $false) {
        $wslc = "wsl.exe"
    }
    $result = Invoke-Command -Command $wslc -Arg "--shutdown"
    $module.Result.stdout = $result.stdout
    $module.Result.stderr = $result.stderr
    $module.Result.rc = $result.rc
    if($result.rc -eq 0) {
        $module.Result.changed = $true
    } else {
        $module.FailJson("Failed to shutdown WSL.")
    }
}

$module.ExitJson()
