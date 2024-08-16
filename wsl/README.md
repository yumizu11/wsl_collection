# Ansible Collection: yumizu11.wsl

The ```yumizu11.wsl``` Ansible Collection includes a module to manage WSL distribution on Windows PC and Windows Server. It also includes a module to manage WSL itself.

## Ansible version compatibility

This collection has been tested against the following Ansible version: >= 2.9.10

## Installation and Usage

### Installing the Collection from Ansible Galaxy

```
ansible-galaxy collection install yumizu11.wsl
```

You can also include it in a ```requirements.yml``` file and install it via ```ansible-galaxy collection install -r requirements.yml``` using the format:

```yaml
collections:
  - name: yumizu11.wsl
```

## Modules

This collection provides the following modules you can use in your own roles and playbooks:

|Name|Description|
|---|---|
|distribution|Install, uninstall, terminate, unregister WSL distribution|
|wsl|Update, uninstall, or shutdown WSL|

### Examples

#### distribution module:

```
# Install Ubuntu-24.04
- name: Install Ubuntu-24.04
  yumizu11.wsl.distribution:
    name: Ubuntu-24.04

# Install Ubuntu-24.04 with creating default user
- name: Install Ubuntu-24.04 with creating user hohn
  yumizu11.wsl.distribution:
    name: Ubuntu-24.04
    default_user: john
    state: installed

# Install Ubuntu-24.04 with creating default user and install the latest version of Ansible
- name: Install Ubuntu-24.04 with creating user hohn
  yumizu11.wsl.distribution:
    name: Ubuntu-24.04
    default_user: john
    run_cmd:
        - add-apt-repository ppa:ansible/ansible -y
        - apt update
        - apt upgrade -y
        - apt install ansible -y
    state: installed

# Uninstall Ubuntu-24.04
- name: Uninstall Ubuntu-24.04
  yumizu11.wsl.distribution:
    name: Ubuntu-24.04
    state: absent

# Terminate Kali-linux
- name: Terminate Kali-linux
  yumizu11.wsl.distribution:
    name: kali-linux
    state: terminated

# Unregister Kali-linux
- name: Terminate Kali-linux
  yumizu11.wsl.distribution:
    name: kali-linux
    state: unregistered

# Export a distro to a tar file
- name: Export a distro (tar)
  yumizu11.wsl.distribution:
    name: Ubuntu-24.04
    dest: C:\\temp\\ubuntu2404.tar
    state: exported

# Export a distro to a vhdx file
- name: Export a distro to (vhdx)
  yumizu11.wsl.distribution:
    name: kali-linux
    dest: C:\\temp\\kali.vhdx
    vhd: true
    state: exported

# Import a distro from tar file
- name: Import distro (tar)
  yumizu11.wsl.distribution:
    name: Ubuntu-24.04-2
    src: C:\\temp\\ubuntu2404.tar
    install_path: C:\\wsl\\Ubuntu-24.04-Copy
    state: imported

# Import a distro from vhdx file
- name: Import distro (vhdx)
  yumizu11.wsl.distribution:
    name: kali-2
    src: C:\\temp\\kali.vhdx
    install_path: C:\\wsl\\kali-linux-2
    state: imported
    
# Query installed distro
- name: Query installed distro
  yumizu11.wsl.distribution:
    state: queried
    register: query_result

- name: Debug - show query_result
    ansible.builtin.debug:
    var: query_result
```

#### wsl module:

```
# Install store version of wsl if not installed
- name: Store version of wsl is installed
  yumizu11.wsl.wsl:

# Update WSL
- name: Update WSL
  yumizu11.wsl.wsl:
    state: updated

# Uninstall WSL
- name: WSL is uninstalled
  yumizu11.wsl.wsl:
    state: absent
    
# Shutdown WSL
- name: Shutdown WSL
  yumizu11.wsl.wsl:
    state: shutdown
```

## License

MIT License

See LICENSE.txt to see full text.
