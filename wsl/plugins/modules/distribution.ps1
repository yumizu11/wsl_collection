#!powershell

# Copyright: (c) 2024, Yuichi Mizutani (yumizu11) <iyumizu@hotmail.com>

#AnsibleRequires -CSharpUtil Ansible.Basic
#Requires -Module Ansible.ModuleUtils.ArgvParser
#Requires -Module Ansible.ModuleUtils.CommandUtil

using namespace System.IO

Import-Module Appx

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
    return (Invoke-Command -Command "`"$wsl_path`"" -Arg $Arg)
}

function Get-InstalledDistro {
    $result = Invoke-WSL -Arg '--list -v'
    $default_distro = ""
    $installed_distro = @{}
    if ($result.rc -eq 0) {
        $lines = $result.stdout.Split("`r`n")
        (1..($lines.length - 1)) | ForEach-Object {
            if ($lines[$_].length -ge 2) {
                $lines[$_].SubString(2) -match '(\S+)\s+(\S+)\s+(\S+)'
                $distro_name = $Matches[1]
                $installed_distro.Add($distro_name, @{ "state" = $Matches[2]; "version" = $Matches[3] })
                if ($lines[$_][0] -eq '*') {
                    $default_distro = $distro_name
                }
            }
        }
    }

    return @{"rc" = $result.rc; "installed_distro" = $installed_distro; "default_distro" = $default_distro }
}

$spec = @{
    options = @{
        name = @{ type = "str"; required = $false }
        state = @{ type = "str"; choices = "absent", "present", "installed", "queried", "reset", "terminated", "unregistered", "exported", "imported"; default = "present" }
        is_default = @{ type = "bool"; default = $false}
        default_user = @{ type = "str"; required = $false }
        run_cmd = @{ type = "list"; required = $false }
        src = @{ type = "str"; required = $false }
        dest = @{ type = "str"; required = $false }
        install_path = @{ type = "str"; required = $false }
        vhd = @{ type = "bool"; default = $false}
    }
    # supports_check_mode = $true
}

$module = [Ansible.Basic.AnsibleModule]::Create($args, $spec)

$name = $module.Params.name
$state = $module.Params.state
$is_default = $module.Params.is_default
$default_user = $module.Params.default_user
$run_cmd = $module.Params.run_cmd
$src = $module.Params.src
$dest = $module.Params.dest
$install_path = $module.Params.install_path
$vhd = $module.Params.vhd

$module.Result.changed = $false

$wsl_path = Join-Path -Path ([environment]::getfolderpath("ProgramFiles")) -ChildPath "\WSL\wsl.exe"
$module.Result.wsl_path = $wsl_path

if ((Test-Path -Path $wsl_path) -eq $false) {
    $module.FailJson("The store version of WSL is not installed.")
}

$current_wsl_version = "N/A"
$result = Invoke-Command -Command "`"$($env:ProgramFiles)\WSL\wsl.exe`"" -Arg "--version"
if ($result.rc -eq 0) {
    $current_wsl_version = (($result.stdout.Split("`r`n"))[0].Split(":"))[1].Trim()
}
$module.Result.wsl_ver = $current_wsl_version

$current_distro = Get-InstalledDistro
if ($current_distro.rc -ne 0) {
    $module.Result.stdout = $current_distro.stdout
    $module.Result.stderr = $current_distro.stderr
    $module.Result.installed_distro = $current_distro.installed_distro
    $module.Warn("Failed to get installed distro list. rc = $($result.rc)")
}
$installed_distro = $current_distro.installed_distro
$default_distro = $current_distro.default_distro

if ($state -eq "terminated") {
    if ($name -in $installed_distro.Keys -and $installed_distro[$name].state -eq "Running") {
        $result = Invoke-WSL -Arg "--terminate $name"
        $module.Result.stdout = $result.stdout
        $module.Result.stderr = $result.stderr
        $module.Result.rc = $result.rc
        if($result.rc -eq 0) {
            $module.Result.changed = $true
        } else {
            $module.FailJson("Failed to terminate '$name'.")
        }
    }
    $current_distro = Get-InstalledDistro
    if ($current_distro.rc -eq 0) {
        $module.Result.installed_distro = $current_distro.installed_distro
        $module.Result.default_distro = $current_distro.default_distro
    }
}
if ($state -eq "unregistered" -or $state -eq "reset") {
    if ($name -in $installed_distro.Keys) {
        $result = Invoke-WSL -Arg "--unregister $name"
        $module.Result.stdout = $result.stdout
        $module.Result.stderr = $result.stderr
        $module.Result.rc = $result.rc
        if($result.rc -eq 0) {
            $module.Result.changed = $true
        } else {
            $module.FailJson("Failed to unregister '$name'.")
        }
    }
    $current_distro = Get-InstalledDistro
    if ($current_distro.rc -eq 0) {
        $module.Result.installed_distro = $current_distro.installed_distro
        $module.Result.default_distro = $current_distro.default_distro
    }
}
if ($state -eq "present" -or $state -eq "installed" -or $state -eq "reset") {
    if ($name -notin $installed_distro.Keys) {
        $result = Invoke-WSL -Arg "--install $name -n"
        $module.Result.stdout = $result.stdout
        $module.Result.stderr = $result.stderr
        $module.Result.rc = $result.rc
        if($result.rc -eq 0) {
           $module.Result.changed = $true
        } else {
            $module.FailJson("Failed to install '$name'.")
        }

        if (($state -eq "installed" -or $state -eq "reset") -and ($default_user -ne "" -or $run_cmd.length -ne 0)) {
            # Currently default user creation and initialize commands execution features are available only on Ubuntu distributions
            if ($name.StartsWith("Ubuntu")) {
                $userprofile_dir = [environment]::getfolderpath("UserProfile")
                $conf_folder = Join-Path -Path $userprofile_dir -ChildPath ".cloud-init"
                if ((Test-Path $conf_folder) -eq $false) {
                    New-Item -Path $conf_folder -ItemType Directory | Out-Null
                }
                $contents = @()
                $contents += "#cloud-config"
                if ($default_user -ne "") {
                    $contents += "users:"
                    $contents += "- name: $default_user"
                    $contents += "  groups: [adm,dialout,cdrom,floppy,sudo,audio,dip,video,plugdev,netdev]"
                    $contents += "  sudo: ALL=(ALL) NOPASSWD:ALL"
                    $contents += "  shell: /bin/bash"
                    $contents += "write_files:"
                    $contents += "- path: /etc/wsl.conf"
                    $contents += "  append: true"
                    $contents += "  content: |"
                    $contents += "    [user]"
                    $contents += "    default=$default_user"
                }
                if ($run_cmd.Count) {
                    $contents += "runcmd:"
                    $run_cmd | ForEach-Object {
                        $contents += "- $_"
                    }
                }
                $fs = New-Object StreamWriter((Join-Path -Path $conf_folder -ChildPath "$name.user-data"), $false)
                $contents | ForEach-Object {
                    $fs.WriteLine($_)
                }
                $fs.Close()
    
                $distro_exe = $name.Replace("-", "").Replace(".", "").Replace("_", "") + ".exe"
                $result = Invoke-Command -Command $distro_exe -Arg "install --root"
                if($result.rc -ne 0) {
                    $module.FailJson("Failed to run $distro_exe with Cloud-init conf file.")
                } else {
                    $retry_count = 10
                    do {
                        Start-Sleep -Seconds 3
                        $retry_count = $retry_count - 1
                        $result = Invoke-Command -Command $distro_exe -Arg "run cloud-init status --wait"
                        $module.Result.cloudinit_rc = $result.rc
                    } while (
                        $result.rc -ne 0 -and $retry_count -ne 0
                    )
                    Invoke-WSL -Arg "-terminate $name"
                }
            } else {
                $module.Warn("Because this distro does not support systemd, cloud-init cannot be applied.")
            }
        }
    }
    if (($state -eq "present" -or $state -eq "installed") -and $is_default -and $name -ne $default_distro) {
        $result = Invoke-WSL -Arg "--set-default $name"
        if($result.rc -eq 0) {
            $module.Result.changed = $true
        } else {
            $module.Warn("Failed to set '$name' default distro. This may be because the distro is installed but never launched yet.")
        }
    }
    $current_distro = Get-InstalledDistro
    if ($current_distro.rc -eq 0) {
        $module.Result.installed_distro = $current_distro.installed_distro
        $module.Result.default_distro = $current_distro.default_distro
    }
}
if ($state -eq "absent") {
    if ($name -in $installed_distro.Keys) {
        $reg = Get-ChildItem "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Lxss" | Get-ItemProperty | Where-Object { $_.DistributionName -eq $name }
        if ($reg) {
            $familyname = $reg.PackageFamilyName
            $packagename = $familyname.SubString(0, $familyname.LastIndexOf("_"))
            $package = Get-AppxPackage -name $packagename

            $result = Invoke-WSL -Arg "--unregister $name"
            $module.Result.stdout = $result.stdout
            $module.Result.stderr = $result.stderr
            $module.Result.rc = $result.rc
            if($result.rc -eq 0) {
                $module.Result.changed = $true
            } else {
                $module.FailJson("Failed to unregister '$name'.")
            }
    
            if ($package) {
                Remove-AppxPackage -Package $package
            } else {
                $module.Warn("Appx package could not be removed.")
            }
        } else {
            $module.Warn("Appx package could not be removed, because it was never launched.")
        }
    }
    $current_distro = Get-InstalledDistro
    if ($current_distro.rc -eq 0) {
        $module.Result.installed_distro = $current_distro.installed_distro
        $module.Result.default_distro = $current_distro.default_distro
    }
}
if ($state -eq "queried") {
    $module.Result.installed_distro = $installed_distro
    $module.Result.default_distro = $default_distro
}
if ($state -eq "exported") {
    if ((Test-Path $dest) -eq $false) {
        $warg = "--export $name $dest"
        if ($vhd) {
            $warg += " --vhd"
        }
        $result = Invoke-WSL -Arg $warg
        $module.Result.stdout = $result.stdout
        $module.Result.stderr = $result.stderr
        if($result.rc -eq 0) {
            $module.Result.changed = $true
        } else {
            $module.FailJson("Failed to export '$name' to $dest.")
        }
    }
    $module.Result.installed_distro = $installed_distro
    $module.Result.default_distro = $default_distro
}
if ($state -eq "imported") {
    if ($name -notin $installed_distro.Keys) {
        $warg = "--import $name $install_path $src"
        if ($vhd) {
            $warg += " --vhd"
        }
        $result = Invoke-WSL -Arg $warg
        $module.Result.stdout = $result.stdout
        $module.Result.stderr = $result.stderr
        if($result.rc -eq 0) {
            $module.Result.changed = $true
        } else {
            $module.FailJson("Failed to import '$name' to $install_path from $src.")
        }
        $current_distro = Get-InstalledDistro
        if ($current_distro.rc -eq 0) {
            $module.Result.installed_distro = $current_distro.installed_distro
            $module.Result.default_distro = $current_distro.default_distro
        }
    }
}

$module.ExitJson()
