# Configuring Windows for Nessus Credentialed Scans

To successfully run a Nessus credentialed scan on a Windows system, you need to ensure that certain services are running and specific registry settings are configured. Below are the steps to set up your environment:

## Required Windows Services

1. **Windows Management Instrumentation (WMI)**
   - **Description**: Provides management information and control in an enterprise environment.
   - **Status**: Must be running.
   - **Startup Type**: Manual/Automatic.

2. **Remote Registry**
   - **Description**: Enables remote users to modify registry settings on this computer.
   - **Status**: Must be running.
   - **Startup Type**: Manual/Automatic.

3. **Server (LanmanServer)**
   - **Description**: Supports file, print, and named-pipe sharing over the network.
   - **Status**: Must be running.
   - **Startup Type**: Manual/Automatic.

4. **Netlogon**
   - **Description**: Maintains a secure channel between your computer and the domain controller for authenticating users and services.
   - **Status**: Must be running.
   - **Startup Type**: Manual/Automatic.

## Required Registry Settings

1. **Enable Remote UAC**
   - **Path**: `HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System`
   - **Key**: `LocalAccountTokenFilterPolicy`
   - **Type**: `DWORD`
   - **Value**: `1`

2. **Enable Administrative Shares**
   - **Path**: `HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Services\LanmanServer\Parameters`
   - **Key**: `AutoShareServer` (for servers) or `AutoShareWks` (for workstations)
   - **Type**: `DWORD`
   - **Value**: `1`

## Additional Configuration

- **File and Printer Sharing**: Ensure that File and Printer Sharing is enabled in the network configuration.
- **Firewall Settings**: Allow the following ports through the firewall:
  - **TCP 135**: RPC Endpoint Mapper
  - **TCP 139**: NetBIOS Session Service
  - **TCP 445**: SMB
  - **Dynamic Ports**: 49152-65535 for WMI
