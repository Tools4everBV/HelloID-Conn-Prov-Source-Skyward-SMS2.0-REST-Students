# HelloID-Conn-Prov-Source-Skyward-SMS2.0-REST-Students

| :information_source: Information |
|:---------------------------|
| This repository contains the connector and configuration code only. The implementer is responsible to acquire the connection details such as username, password, certificate, etc. You might even need to sign a contract or agreement with the supplier before implementing this connector. Please contact the client's application manager to coordinate the connector requirements.       |
<br />
<p align="center"> 
  <img src="https://www.tools4ever.nl/connector-logos/skyward-logo-2.png">
</p>
<br />
 
This connector allows you to retrieve users from Skyward SMS 2.0 via the REST API.

The _PS7.ps1 scripts are PowerShell 7 and can be used in the cloud. The other scripts are PowerShell 5.1 compatible and can be used on the HelloID service machine.

## Known Issues

If you get the following error:

> The response content cannot be parsed because the Internet Explorer engine is not available, or Internet Explorer's first-launch configuration is not complete. Specify the UseBasicParsing parameter and try again.

Please start Internet Explorer on the HelloID service machine and complete the configuration settings pop up.

# HelloID Docs
The official HelloID documentation can be found at: https://docs.helloid.com/
