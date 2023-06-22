<#
The following table outlines the network communication requirements for a MEMCM setup:

Source: MEMCM Site Server 
Target: SQL Server 
Ports: 1433, 4022 
Protocol: TCP 
Description: SQL Server and SQL Service Broker communication

Source: All MEMCM Systems 
Target: All MEMCM Systems 
Ports: 80, 443 
Protocol: TCP 
Description: HTTP/HTTPS communication for site system roles

Source: All MEMCM Systems 
Target: All MEMCM Systems 
Ports: 10123 
Protocol: TCP 
Description: Wake-Up proxy communication

Source: MEMCM Site Server 
Target: Distribution Point 
Ports: 445 
Protocol: TCP 
Description: SMB for package transfer

Source: Client 
Target: Distribution Point 
Ports: 445 
Protocol: TCP 
Description: SMB for package download

Source: MEMCM Site Server 
Target: Client 
Ports: 10123 
Protocol: TCP 
Description: Wake on LAN

Source: Client 
Target: SUP/Wsus Server 
Ports: 8530, 8531 
Protocol: TCP 
Description: WSUS/SUP communication

Source: Client 
Target: Management Point 
Ports: 80, 443 
Protocol: TCP 
Description: HTTP/HTTPS for client communication

Source: Client 
Target: Distribution Point 
Ports: 80, 443 
Protocol: TCP 
Description: HTTP/HTTPS for content download

Source: Client 
Target: PXE Server 
Ports: 67, 68 
Protocol: UDP 
Description: DHCP for PXE boot

Source: Client 
Target: PXE Server 
Ports: 69 
Protocol: UDP 
Description: TFTP for PXE boot

Source: Client 
Target: State Migration Point 
Ports: 445 
Protocol: TCP 
Description: SMB for User State Migration

Source: Client 
Target: State Migration Point 
Ports: 80, 443 
Protocol: TCP 
Description: HTTP/HTTPS for User State Migration

Source: Management Point 
Target: SQL Server 
Ports: 1433, 4022 
Protocol: TCP 
Description: SQL Server and SQL Service Broker communication
#>
