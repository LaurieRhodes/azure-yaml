﻿<#

Module Name:

    AZRest.psm1

Description:

    Provides Azure Rest API

Version History

    1.0    - 7 July 2020    Laurie Rhodes       Initial Release

#>





function Get-Header(){
<#
  Function:  Get-Header

  Purpose:  To Generically produce a header for use in calling Microsoft API endpoints

  Parameters:   -Username   = Username
                -Password   = password

                -AppId      = The AppId of the App used for authentication
                -Thumbprint = eg. B35E2C978F83B49C36116802DC08B7DF7B58AB08

                -Tenant     = disney.onmicrosoft.com

                -Scope      = "azure"    - Azure Resource Manager
                                           "https://management.azure.com/"
                                
                              "graph"    - Microsoft Office and Mobile Device Management
                                            "https://graph.microsoft.com/beta/groups/'

                              "keyvault" - data plane of Azure keyvaults
                                            "https://<keyvaultname>.vault.azure.net/certificates/"

                              "storage"  - data plane of Azure storage Accounts (table)
                                            "https://<storageaccount>.table.core.windows.net/"

                              "analytics"- data plane of log analytics
                                            "https://api.loganalytics.io/v1/workspaces"

                              "portal"   - api interface of the Azure portal (only supports username / password authentication)
                                            "https://main.iam.ad.ext.azure.com/api/"

                              "windows"  - api interface of legacy Azure AD  (only supports username / password authentication)
                                            "https://graph.windows.net/<tenant>/policies?api-version=1.6-internal"

                -Proxy      = "http://proxy:8080" (if operating from behind a proxy)

                -ProxyCredential = (Credential Object)

                -Interactive  = suitable for use with MFA enabled accounts

  Example:  
    
     Get-Header -scope "portal" -Tenant "disney.com" -Username "Donald@disney.com" -Password "Mickey01" 
     Get-Header -scope "graph" -Tenant "disney.com" -AppId "aa73b052-6cea-4f17-b54b-6a536be5c832" -Thumbprint "B35E2C978F83B49C36611802DC08B7DF7B58AB08" 
     Get-Header -scope "azure" -Tenant "disney.com" -AppId "aa73b052-6cea-4f17-b54b-6a536be5c715" -Secret 'xznhW@w/.Yz14[vC0XbNzDFwiRRxUtZ3'
     Get-Header -scope "azure" -Tenant "disney.com" -Interactive


#> 
    [CmdletBinding()]
    param(
        [Parameter(ParameterSetName="User")]
        [string]$Username,
        [Parameter(ParameterSetName="User")]
        [String]$Password,
        [Parameter(ParameterSetName="App")]
        [Parameter(ParameterSetName="App2")]
        [string]$AppId,
        [Parameter(ParameterSetName="App")]
        [string]$Thumbprint,
        [Parameter(mandatory=$true)]
        [string]$Tenant,
        [Parameter(mandatory=$true)]
        [ValidateSet(
            "azure",
            "graph",
            "keyvault",
            "storage",
            "analytics",
            "portal",
            "windows"
        )][string]$Scope,
        [Parameter(ParameterSetName="App2")]
        [string]$Secret,
        [Parameter(ParameterSetName="inter")]
        [Switch]$interactive=$false,
        [Parameter(mandatory=$false)]
        [string]$Proxy,
        [Parameter(mandatory=$false)]
        [PSCredential]$ProxyCredential
    )
 
 
    begin {
 
 
       $ClientId       = "1950a258-227b-4e31-a9cf-717495945fc2" 
 
 
       switch($Scope){
           'portal' {$TokenEndpoint = "https://login.microsoftonline.com/$($tenant)/oauth2/token"
                    $RequestScope = "https://graph.microsoft.com/.default"
                    $ResourceID  = "74658136-14ec-4630-ad9b-26e160ff0fc6"
                    }
           'azure' {$TokenEndpoint = "https://login.microsoftonline.com/$($tenant)/oauth2/v2.0/token"
                    $RequestScope = "https://management.azure.com/.default"
                    $ResourceID  = "https://management.azure.com/"
                    }
           'graph' {$TokenEndpoint = "https://login.microsoftonline.com/$($tenant)/oauth2/token"
                    $RequestScope = "https://graph.microsoft.com/.default"
                    $ResourceID  = "https://graph.microsoft.com"
                    }
           'keyvault'{$TokenEndpoint = "https://login.microsoftonline.com/$($tenant)/oauth2/v2.0/token"
                    $RequestScope = "https://vault.azure.net/.default"
                    $ResourceID  = "https://vault.azure.net"
                    }
           'storage'{$TokenEndpoint = "https://login.microsoftonline.com/$($tenant)/oauth2/v2.0/token"
                    $RequestScope = "https://storage.azure.com/.default"
                    $ResourceID  = "https://storage.azure.com/"
                    }       
           'analytics'{$TokenEndpoint = "https://login.microsoftonline.com/$($tenant)/oauth2/v2.0/token"
                    $RequestScope = "https://api.loganalytics.io/.default"
                    $ResourceID  = "https://api.loganalytics.io/"
                    } 
           'windows'{$TokenEndpoint = "https://login.microsoftonline.com/$($tenant)/oauth2/token"
                    $RequestScope = "openid"
                    $ResourceID  = "https://graph.windows.net/"
                    }                                                        
           default { throw "Scope $($Scope) undefined - use azure or graph'" }
        }
 
 #$RequestScope = "openid"
        #Set Accountname based on Username or AppId
        if (!([string]::IsNullOrEmpty($Username))){$Accountname = $Username }
        if (!([string]::IsNullOrEmpty($AppId))){$Accountname = $AppId }
 
        
 
    }
    
    process {
        
        # Authenticating with Certificate
        if (!([string]::IsNullOrEmpty($Thumbprint)) -And ($interactive -eq $false)){
            write-host "+++ Certificate Authentication"
 
            # Try Local Machine Certs
            $Certificate = ((Get-ChildItem -Path Cert:\LocalMachine  -force -Recurse )| Where-Object {$_.Thumbprint -match $Thumbprint});
            if ([string]::IsNullOrEmpty($Certificate)){
            # Try Current User Certs
            $Certificate = ((Get-ChildItem -Path Cert:\CurrentUser  -force -Recurse )| Where-Object {$_.Thumbprint -match $Thumbprint});
            }
            
            if ([string]::IsNullOrEmpty($Certificate)){throw "certificate not found"}
 
 
            # Create base64 hash of certificate
            $CertificateBase64Hash = [System.Convert]::ToBase64String($Certificate.GetCertHash())
          
            # Create JWT timestamp for expiration
            $StartDate = (Get-Date "1970-01-01T00:00:00Z" ).ToUniversalTime()
            $JWTExpirationTimeSpan = (New-TimeSpan -Start $StartDate -End (Get-Date).ToUniversalTime().AddMinutes(2)).TotalSeconds
            $JWTExpiration = [math]::Round($JWTExpirationTimeSpan,0)
 
            # Create JWT validity start timestamp
            $NotBeforeExpirationTimeSpan = (New-TimeSpan -Start $StartDate -End ((Get-Date).ToUniversalTime())).TotalSeconds
            $NotBefore = [math]::Round($NotBeforeExpirationTimeSpan,0)
 
            # Create JWT header
            $JWTHeader = @{
                alg = "RS256"
                typ = "JWT"
                x5t = $CertificateBase64Hash -replace '\+','-' -replace '/','_' -replace '='
            }
            
            # Create JWT payload
            $JWTPayLoad = @{
                aud = $TokenEndpoint
                exp = $JWTExpiration
                iss = $AppId
                jti = [guid]::NewGuid()
                nbf = $NotBefore
                sub = $AppId
            }
 
           
            # Convert header and payload to base64
            $JWTHeaderToByte = [System.Text.Encoding]::UTF8.GetBytes(($JWTHeader | ConvertTo-Json))
            $EncodedHeader = [System.Convert]::ToBase64String($JWTHeaderToByte)
 
            $JWTPayLoadToByte =  [System.Text.Encoding]::UTF8.GetBytes(($JWTPayload | ConvertTo-Json))
            $EncodedPayload = [System.Convert]::ToBase64String($JWTPayLoadToByte)
 
            # Join header and Payload with "." to create a valid (unsigned) JWT
            $JWT = $EncodedHeader + "." + $EncodedPayload
 
            # Get the private key object of your certificate
            $PrivateKey = $Certificate.PrivateKey
            if ([string]::IsNullOrEmpty($PrivateKey)){throw "Unable to access certificate Private Key"}
 
            # Define RSA signature and hashing algorithm
            $RSAPadding = [Security.Cryptography.RSASignaturePadding]::Pkcs1
            $HashAlgorithm = [Security.Cryptography.HashAlgorithmName]::SHA256
 
            # Create a signature of the JWT
 
            $Signature = [Convert]::ToBase64String( $PrivateKey.SignData([System.Text.Encoding]::UTF8.GetBytes($JWT),$HashAlgorithm,$RSAPadding) ) -replace '\+','-' -replace '/','_' -replace '='
            
            $JWTBytes = [System.Text.Encoding]::UTF8.GetBytes($JWT)
 
 
            # Join the signature to the JWT with "."
            $JWT = $JWT + "." + $Signature
 
 
       switch($Scope){
           'portal' {

                        throw "FATAL Error - portal requests only support username and password (non interactive) flows"

                    }
           'azure' {
                    $Body = @{
                        client_id = $AppId 
                        client_assertion = $JWT
                        client_assertion_type = "urn:ietf:params:oauth:client-assertion-type:jwt-bearer"
                        scope = $RequestScope
                        grant_type = "client_credentials"
                    }
                    }
           'graph' {
                    $Body = "grant_type=client_credentials" `
                     +"&username=" +$Accountname `
                     +"&client_id=" +$AppId `
                     +"&client_assertion=" +$JWT `
                     +"&client_assertion_type=" +"urn:ietf:params:oauth:client-assertion-type:jwt-bearer" `
                     +"&scope=" +$RequestScope
                    }
           'keyvault' {
                    $Body = @{
                        client_id = $AppId 
                        client_assertion = $JWT
                        client_assertion_type = "urn:ietf:params:oauth:client-assertion-type:jwt-bearer"
                        scope = $RequestScope
                        grant_type = "client_credentials"
                        }
                    }
           'analytics' {
                    $Body = @{
                        client_id = $AppId 
                        client_assertion = $JWT
                        client_assertion_type = "urn:ietf:params:oauth:client-assertion-type:jwt-bearer"
                        scope = $RequestScope
                        grant_type = "client_credentials"
                        }
                    }                   
           'storage' {
                    $Body = @{
                        client_id = $AppId 
                        client_assertion = $JWT
                        client_assertion_type = "urn:ietf:params:oauth:client-assertion-type:jwt-bearer"
                        scope = $RequestScope
                        grant_type = "client_credentials"
                        }                    
                    }
           'windows' {

                        throw "FATAL Error - legacty windows graph requests only support username and password (non interactive) flows"

                    }
        }# end switch
 
 
            $Url = "https://login.microsoftonline.com/$Tenant/oauth2/v2.0/token"
 
            # Use the self-generated JWT as Authorization
            $Header = @{
                Authorization = "Bearer $JWT"
            }
 
            # Splat the parameters for Invoke-Restmethod for cleaner code
            $PostSplat = @{
                ContentType = 'application/x-www-form-urlencoded'
                Method = 'POST'
                Body = $Body
                Uri = $Url
                Headers = $Header
            }
 
 
            #Get Bearer Token
            $Request = Invoke-RestMethod @PostSplat
            # Create header
            $Header = $null
            $Header = @{
                Authorization = "$($Request.token_type) $($Request.access_token)"
            }
 
 
        } # End Certificate Authentication
 
 
 
        # Authenticating with Password
        if (!([string]::IsNullOrEmpty($Password)) -And ($interactive -eq $false)){
 
       switch($Scope){
           'portal' {
                    $Body = @{
                        client_id = "1950a258-227b-4e31-a9cf-717495945fc2"
                        username = $Accountname
                        password = $Password
                        resource = "74658136-14ec-4630-ad9b-26e160ff0fc6"
                        grant_type = "password"
                      }
                    }
           'azure' {
                    $Body = @{
                        client_id = $clientId 
                        username = $Accountname
                        password = $Password
                        scope = $RequestScope
                        grant_type = "password"
                      }
                    }
           'graph' {
                    $Body = "grant_type=password"`
                     +"&username=" +$Accountname `
                     +"&client_id=" +$clientId `
                     +"&password=$($Password)" `
                     +"&resource=" +[system.uri]::EscapeDataString($ResourceID)
                        }
           'keyvault' {
                    $Body = @{
                        client_id = $clientId 
                        username = $Accountname
                        password = $Password
                        scope = $RequestScope
                        grant_type = "password"
                      }
                     }
           'analytics' {
                    $Body = @{
                        client_id = $clientId 
                        username = $Accountname
                        password = $Password
                        scope = $RequestScope
                        grant_type = "password"
                      }
                     }                     
           'storage' {
                    $Body = @{
                        client_id = $clientId 
                        username = $Accountname
                        password = $Password
                        scope = $RequestScope
                        grant_type = "password"
                      }
                     } 
           'windows' {
                    $Body = "grant_type=password"`
                     +"&username=" +$Accountname `
                     +"&client_id=" +$clientId `
                     +"&password=$($Password)" `
                     +"&resource=" +[system.uri]::EscapeDataString($ResourceID)
                        }           
 
        }# end switch
 
 
 
        } # end password block
 
        # Authenticating with Secret
        if (!([string]::IsNullOrEmpty($Secret)) -And ($interactive -eq $false)){
 
       switch($Scope){
            'portal' {

                        throw "FATAL Error - portal requests only support username and password (non interactive) flows"

                    }
           'azure' {
                    $Body = @{
                        client_id = $AppId  
                        client_secret = $Secret
                        scope = $RequestScope
                        grant_type = "client_credentials"
                      }
                    }
           'graph' {
                    $Body = "grant_type=client_credentials"`
                     +"&client_id=" +$AppId `
                     +"&client_secret=" +$Secret `
                     +"&resource=" +[system.uri]::EscapeDataString($ResourceID)
                      }
           'keyvault' {
                    $Body = @{
                        client_id = $AppId  
                        client_secret = $Secret
                        scope = $RequestScope
                        grant_type = "client_credentials"
                      }
                    }  
           'analytics' {
                    $Body = @{
                        client_id = $AppId  
                        client_secret = $Secret
                        scope = $RequestScope
                        grant_type = "client_credentials"
                      }
                    }                                             
           'storage' {
                    $Body = @{
                        client_id = $AppId  
                        client_secret = $Secret
                        scope = $RequestScope
                        grant_type = "client_credentials"
                      }
                    }                      
           'windows' {
                    $Body = @{
                        client_id = $AppId  
                        client_secret = $Secret
                        scope = $RequestScope
                        grant_type = "client_credentials"
                      }
                    }                        
        }# end switch
 
 
       } # end secret block
 
 

        # Interfactive Authentication
         if($interactive -eq $true){
             $response_type         = "code"
             $redirectUri           = [System.Web.HttpUtility]::UrlEncode("http://localhost:8400/")
             $redirectUri           = "http://localhost:8400/"
             $code_challenge_method = "S256"
             $state                 = "141f0ce8-352d-483a-866a-79672b952f8e668bc603-ea1a-43e7-a203-af3abe51e2ea"
             $resource = [System.Web.HttpUtility]::UrlEncode("https://graph.microsoft.com")
             $RandomNumberGenerator = New-Object System.Security.Cryptography.RNGCryptoServiceProvider
             $Bytes = New-Object Byte[] 32
             $RandomNumberGenerator.GetBytes($Bytes)
             $code_verifier = ([System.Web.HttpServerUtility]::UrlTokenEncode($Bytes)).Substring(0, 43)
             $code_challenge = ConvertFrom-CodeVerifier -Method s256 -codeVerifier $code_verifier


             $url = "https://login.microsoftonline.com/organizations/oauth2/v2.0/authorize?scope=$($RequestScope)&response_type=$($response_type)&client_id=$($clientid)&redirect_uri=$([System.Web.HttpUtility]::UrlEncode($redirectUri))&prompt=select_account&code_challenge=$($code_challenge)&code_challenge_method=$($code_challenge_method)" 
 
             # portal requests only support username and password (non interactive) flows  
            if ($Scope -eq "portal"){

                throw "FATAL Error - portal requests only support username and password (non interactive) flows"

            }
             # portal requests only support username and password (non interactive) flows  
            if ($Scope -eq "windows"){

                throw "FATAL Error - legacty windows graph requests only support username and password (non interactive) flows"

            }
 
               Add-Type -AssemblyName System.Windows.Forms

                $form = New-Object -TypeName System.Windows.Forms.Form -Property @{Width=440;Height=640}
                $web  = New-Object -TypeName System.Windows.Forms.WebBrowser -Property @{Width=420;Height=600;Url=($url -f ($RequestScope -join "%20")) }

                $DocComp  = {
                    $Global:uri = $web.Url.AbsoluteUri        
                    if ($Global:uri -match "error=[^&]*|code=[^&]*") {$form.Close() }
                }
                $web.ScriptErrorsSuppressed = $true
                $web.Add_DocumentCompleted($DocComp)
                $form.Controls.Add($web)
                $form.Add_Shown({$form.Activate()})
                $form.ShowDialog() | Out-Null

                $queryOutput = [System.Web.HttpUtility]::ParseQueryString($web.Url.Query)
                $output = @{}
                foreach($key in $queryOutput.Keys){
                    $output["$key"] = $queryOutput[$key]
                }



                $authCode=$output["code"]


    #get Access Token

         $Body = @{
              client_id = $clientId 
              code = $authCode
              code_verifier = $code_verifier
              redirect_uri = $redirectUri
              grant_type = "authorization_code"
          }


         
         } # end interactive block


            $RequestSplat = @{
                Uri = $TokenEndpoint
                Method = “POST”
                Body = $Body 
                UseBasicParsing = $true
            }


           #Construct parameters if they exist
           if($Proxy){ $RequestSplat.Add('Proxy', $Proxy) }
           if($ProxyCredential){ $RequestSplat.Add('ProxyCredential', $ProxyCredential) }
                       
           $Response = Invoke-WebRequest @RequestSplat  
           $ResponseJSON = $Response|ConvertFrom-Json
 
 
            #Add the token to headers for the request
            $Header = New-Object "System.Collections.Generic.Dictionary[[String],[String]]"
            $Header.Add("Authorization", "Bearer "+$ResponseJSON.access_token)
            $Header.Add("Content-Type", "application/json")

            # storage requests require two different keys in the header 
            if ($Scope -eq "storage"){
                $Header.Add("x-ms-version", "2019-12-12")
                $Header.Add("x-ms-date", [System.DateTime]::UtcNow.ToString("R"))
            }

            # portal requests require two different keys in the header 
            if ($Scope -eq "portal"){
                $Header.Add("x-ms-client-request-id", "$((New-Guid).Guid)")
                $Header.Add("x-ms-session-id", "12345678910111213141516")
            }
 
    }
    
    end {
 
       return $Header 
 
    }
 
}







<#
  Function:  ConvertFrom-CodeVerifier

  Purpose:  Determines code-challenge from code-verifier for Azure Authentication

  Example:  
    
           ConvertFrom-CodeVerifier -Method s256 -codeVerifier XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX

  Author  https://gist.github.com/watahani
#>
function ConvertFrom-CodeVerifier {

    [OutputType([String])]
    param(
        [Parameter(Mandatory = $True, ValueFromPipeline = $True)]
        [String]$codeVerifier,
        [ValidateSet(
            "plain",
            "s256"
        )]$Method = "s256"
    )
    process {
        switch($Method){
            "plain" {
                return $codeVerifier
            }
            "s256" {
                # https://docs.microsoft.com/en-us/powershell/module/microsoft.powershell.utility/get-filehash?view=powershell-7
                $stringAsStream = [System.IO.MemoryStream]::new()
                $writer = [System.IO.StreamWriter]::new($stringAsStream)
                $writer.write($codeVerifier)
                $writer.Flush()
                $stringAsStream.Position = 0
                $hash = Get-FileHash -InputStream $stringAsStream | Select-Object Hash
                $hex = $hash.Hash
        
                $bytes = [byte[]]::new($hex.Length / 2)
                    
                For($i=0; $i -lt $hex.Length; $i+=2){
                    $bytes[$i/2] = [convert]::ToByte($hex.Substring($i, 2), 16)
                }
                $b64enc = [Convert]::ToBase64String($bytes)
                $b64url = $b64enc.TrimEnd('=').Replace('+', '-').Replace('/', '_')
                return $b64url     
            }
            default {
                throw "not supported method: $Method"
            }
        }
    }
}
 


function Get-Token(){
<#
  Function:  Get-Token

  Purpose:  To Generically produce a token for use in calling Microsoft API endpoints

            This is an Interactive Flow for use with Refresh tokens.  For Legacy authentication that doesnt use a refresh token
            use the Get-Header function

  Parameters: 
                -Tenant     = disney.onmicrosoft.com
                -Scope      = graph / azure

                -Proxy      ="http://proxy:8080"
                -ProxyCredential = (Credential Object)

  Example:  
    
     Get-Token -scope "azure" -Tenant "disney.com" -Interactive

#> 
    [CmdletBinding()]
    param(
        [Parameter(ParameterSetName="App")]
        [string]$Thumbprint,
        [Parameter(mandatory=$false)]
        [string]$Tenant,
        [Parameter(mandatory=$true)]
        [ValidateSet(
            "azure",
            "graph",
            "keyvault",
            "storage",
            "analytics"
        )][string]$Scope,
        [Parameter(mandatory=$false)]
        [string]$Proxy,
        [Parameter(mandatory=$false)]
        [PSCredential]$ProxyCredential
    )
 

 
    begin {
 


 
       $ClientId       = "1950a258-227b-4e31-a9cf-717495945fc2" 
 
 
       switch($Scope){
           'azure' {$TokenEndpoint = "https://login.microsoftonline.com/$($tenant)/oauth2/v2.0/token"
                    $RequestScope = "https://management.azure.com/.default"
                    $ResourceID  = "https://management.azure.com/"
                    }
           'graph' {$TokenEndpoint = "https://login.microsoftonline.com/$($tenant)/oauth2/token"
                    $RequestScope = "https://graph.microsoft.com/.default"
                    $ResourceID  = "https://graph.microsoft.com"
                    }
           'keyvault'{$TokenEndpoint = "https://login.microsoftonline.com/$($tenant)/oauth2/v2.0/token"
                    $RequestScope = "https://vault.azure.net/.default"
                    $ResourceID  = "https://vault.azure.net"
                    }
           'storage'{$TokenEndpoint = "https://login.microsoftonline.com/$($tenant)/oauth2/v2.0/token"
                    $RequestScope = "https://storage.azure.com/.default"
                    $ResourceID  = "https://storage.azure.com/"
                    }       
           'analytics'{$TokenEndpoint = "https://login.microsoftonline.com/$($tenant)/oauth2/v2.0/token"
                    $RequestScope = "https://api.loganalytics.io/.default"
                    $ResourceID  = "https://api.loganalytics.io/"
                    }                                   
           default { throw "Scope $($Scope) undefined - use azure or graph'" }
        }
 
        #Set Accountname based on Username or AppId
        if (!([string]::IsNullOrEmpty($Username))){$Accountname = $Username }
        if (!([string]::IsNullOrEmpty($AppId))){$Accountname = $AppId }
 
   
         $TokenObject = [PSCustomObject]@{
            token_type     = 'Bearer'
            token_endpoint = $TokenEndpoint
            scope          = $RequestScope
            access_token   = ''
            refresh_token  = ''
            client_id      = $clientId 
            client_assertion = ''
            client_assertion_type = ''
            code           = ''
            code_verifier  = ''
            redirect_uri   = ''
            grant_type     = ''
            expires_in     = ''
        }
    }
    
    process {
        
        # Interfactive Authentication

            $TokenObject.grant_type = "authorization_code"

             $response_type         = "code"
             $redirectUri           = [System.Web.HttpUtility]::UrlEncode("http://localhost:8400/")
             $redirectUri           = "http://localhost:8400/"
             $code_challenge_method = "S256"
             $state                 = "141f0ce8-352d-483a-866a-79672b952f8e668bc603-ea1a-43e7-a203-af3abe51e2ea"
             #$resource = [System.Web.HttpUtility]::UrlEncode("https://graph.microsoft.com")
             $RandomNumberGenerator = New-Object System.Security.Cryptography.RNGCryptoServiceProvider
             $Bytes = New-Object Byte[] 32
             $RandomNumberGenerator.GetBytes($Bytes)
             $code_verifier = ([System.Web.HttpServerUtility]::UrlTokenEncode($Bytes)).Substring(0, 43)

             $code_challenge = ConvertFrom-CodeVerifier -Method s256 -codeVerifier $code_verifier

             $url = "https://login.microsoftonline.com/$($tenant)/oauth2/v2.0/authorize?scope=$($RequestScope)&response_type=$($response_type)&client_id=$($clientid)&redirect_uri=$([System.Web.HttpUtility]::UrlEncode($redirectUri))&prompt=select_account&code_challenge=$($code_challenge)&code_challenge_method=$($code_challenge_method)" 

               Add-Type -AssemblyName System.Windows.Forms

                $form = New-Object -TypeName System.Windows.Forms.Form -Property @{Width=440;Height=640}
                $web  = New-Object -TypeName System.Windows.Forms.WebBrowser -Property @{Width=420;Height=600;Url=($url -f ($RequestScope -join "%20")) }

                $DocComp  = {
                    $Global:uri = $web.Url.AbsoluteUri        
                    if ($Global:uri -match "error=[^&]*|code=[^&]*") {$form.Close() }
                }
                $web.ScriptErrorsSuppressed = $true
                $web.Add_DocumentCompleted($DocComp)
                $form.Controls.Add($web)
                $form.Add_Shown({$form.Activate()})
                $form.ShowDialog() | Out-Null

                $queryOutput = [System.Web.HttpUtility]::ParseQueryString($web.Url.Query)
                $output = @{}
                foreach($key in $queryOutput.Keys){
                    $output["$key"] = $queryOutput[$key]
                }



                $authCode=$output["code"]


    #get Access Token


         $Body = @{
              client_id = $clientId 
              code = $authCode
              code_verifier = $code_verifier
              redirect_uri = $redirectUri
              grant_type = "authorization_code"
          }


             $TokenObject.code          = $authCode
             $TokenObject.code_verifier = $code_verifier
             $TokenObject.redirect_uri  = $redirectUri


           # All Request types have create a Body for POST that will return a token

            $RequestSplat = @{
                Uri = $TokenEndpoint
                Method = “POST”
                Body = $Body 
                UseBasicParsing = $true
            }


           #Construct parameters if they exist
           if($Proxy){ $RequestSplat.Add('Proxy', $Proxy) }
           if($ProxyCredential){ $RequestSplat.Add('ProxyCredential', $ProxyCredential) }
                       
           $Response = Invoke-WebRequest @RequestSplat  
           
           $ResponseJSON = $Response | ConvertFrom-Json

           write-debug $Response

            #Expires in states how many seconds from not the token will be valid - this needs to be referenced as a proper date/time

           $ResponseJSON.expires_in  = (Get-Date).AddSeconds([int]($ResponseJSON.expires_in) ).ToUniversalTime()
 
           $TokenObject.expires_in    = $ResponseJSON.expires_in
           $TokenObject.access_token  = $ResponseJSON.access_token
           $TokenObject.refresh_token  = $ResponseJSON.refresh_token
    }
    
    end {
 
    return  $TokenObject

    }
 
}


function Refresh-Token {
<#
  Function:  Refresh-Token

  Purpose:  Refreshes a token that supports Refresh tokens

  Parameters: 
                -Token     = Token object

  Example:  
    
     Refresh-Token -token $AuthToken

#> 
    [CmdletBinding()]
    param(
        [Parameter(mandatory=$true)]
        [PSCustomObject]$Token
    )
 

    # We have a previous refresh token. 
    # use it to get a new token

   $redirectUri = $([System.Web.HttpUtility]::UrlEncode($Token.redirect_uri))   


    # Refresh the token
    #get Access Token
    #$body = "grant_type=refresh_token&refresh_token=$($Token.refresh_token)&redirect_uri=$($redirectUri)&client_id=$($Token.clientId)&client_secret=$($clientSecretEncoded)"

    $body = "grant_type=refresh_token&refresh_token=$($Token.refresh_token)&redirect_uri=$($redirectUri)&client_id=$($Token.clientId)"

    $Response = $null
    try{
    $Response = Invoke-RestMethod $Token.token_endpoint  `
        -Method Post -ContentType "application/x-www-form-urlencoded" `
        -Body $body 
    }
    catch{
    throw "token refresh failed"
    }

    if ($Response){

        $Token.expires_in  = (Get-Date).AddSeconds([int]($Response.expires_in) ).ToUniversalTime()
        $Token.access_token  = $Response.access_token
        $Token.refresh_token  = $Response.refresh_token    

    }
        #####
  write-debug "Refresh Response = $($Response | convertto-json)"

} 




function Create-Header(){
<#
  Function:  Create-Header

  Purpose:  To Generically produce a header for use in calling Microsoft API endpoints

  Parameters:   -Token = (Previously Created Token Object)

  Example:  
    
     Create-Header -token $TokenObject 

#> 
    [CmdletBinding()]
    param(
        [Parameter(mandatory=$true)]
        [PSCustomObject]$Token
    )


           #refresh tokens about to expire
           $expirytime = ([DateTime]$Token.Expires_in).ToUniversalTime() 
           write-debug "Expiry = $($expirytime)"
           write-debug "Current time  = $((Get-Date).AddSeconds(10).ToUniversalTime())"

            if (((Get-Date).AddSeconds(10).ToUniversalTime()) -gt ($expirytime.AddMinutes(-2)) ) {

                # Need to initiate Refresh
                Refresh-Token -Token $Token

            }

 
            #Add the token to headers for the request
            $Header = New-Object "System.Collections.Generic.Dictionary[[String],[String]]"
            $Header.Add("Authorization", "Bearer "+$Token.access_token)
            $Header.Add("Content-Type", "application/json")

            #storage requests require two different keys in the header 
            if ($Scope -eq "https://storage.azure.com/.default"){
                $Header.Add("x-ms-version", "2019-12-12")
                $Header.Add("x-ms-date", [System.DateTime]::UtcNow.ToString("R"))
            }

            write-debug "header = $($Header)"


return  $Header


 }







<#
  Function:  Get-Latest

  Purpose:  Finds the latest date from a series of dates with the PowerShell pipeline

  Example:  
    
           $Hashtable | Get-latest
#>
function Get-Latest {
    Begin { $latest = $null }
    Process {
            if ($_  -gt $latest) { $latest = $_  }
    }
    End { $latest }
}



<#
  Function:  Get-AzureAPIVersions

  Purpose:  Constructs a dictionary of current Azure namespaces

  Parameters:   -SubscriptionId      = The subscription ID of the environment to connect to.
                -Header              = A hashtable (header) with valid authentication for Azure Management

  Example:  
    
             Get-AzureAPIVersions = Get-AnalyticsWorkspaceKey `
                                      -Header $header `
                                      -SubscriptionId "ed4ef888-5466-401c-b77a-6f9cd7cc6815" 
#>
function Get-AzureAPIVersions(){
param(
    [parameter( Mandatory = $true)]
    [string]$header,
    [parameter( Mandatory = $true)]
    [string]$SubscriptionID
)

    $dict = @{}
    
    Try{
      $uri = "https://management.azure.com/subscriptions/$($SubscriptionID)/providers/?api-version=2015-01-01"
      $result = Invoke-RestMethod -Uri $uri -Method GET -Headers $authHeader 
      
    $namespaces = $result.value 

    foreach ($namespace in $namespaces){
       foreach ($resource in $namespace.resourceTypes){

       #Add Provider Plus Resource Type
        $dict.Add("$($namespace.namespace)/$($resource.resourceType)",$($resource.apiVersions | Get-latest) )
       }
     }

     #return dictionary
     $dict      
    } catch {
      # catch any authentication or api errors
      Throw "Get-AzureAPIVersions failed - $($_.ErrorDetails.Message)"
    }

}


<#
  Function:  Get-Yamlfile

  Purpose:  Transforms a saved Yaml file to a Powershell Hash table

  Parameters:   -Path      = The file path for the yaml file to import.

  Example:  
    
            $object = Get-Yamlfile `-Path "C:\templates\vmachine.yaml"
#>
function Get-Yamlfile(){
param(
    [parameter( Mandatory = $true)]
    [string]$Path
)

    $content = ''

    [string[]]$fileContent = Get-Content $path

    foreach ($line in $fileContent) { $content = $content + "`n" + $line }

    ConvertFrom-Yaml $content

}



<#
  Function:  Get-JSONfile

  Purpose:  Transforms a saved Yaml file to a Powershell Hash table

  Parameters:   -Path      = The file path for the json file to import.

  Example:  
    
            $object = Get-JSONfile `-Path "C:\templates\vmachine.json"
#>
function Get-Jsonfile(){
param(
    [parameter( Mandatory = $true)]
    [string]$Path
)

    [string]$content = $null

    [string]$content = Get-Content -Path $path -Raw 
    
    if ( Get-TypeData -TypeName "System.Array" ){
       Remove-TypeData System.Array # Remove the redundant ETS-supplied .Count property
    }
    # https://stackoverflow.com/questions/20848507/why-does-powershell-give-different-result-in-one-liner-than-two-liner-when-conve/38212718#38212718

    $jsonobj =  ($content  | ConvertFrom-Json )

    $AzObject = ConvertTo-HashTable -InputObject $jsonobj

    
    $AzObject
}



<#
  Function:  ConvertTo-Hashtable
  
  Author:  Adam Bertram
             https://4sysops.com/archives/convert-json-to-a-powershell-hash-table/

  Purpose:  Transforms a saved Yaml file to a Powershell Hash table

  Parameters:   -InputObject      = the json custom object file to import.

  Example:    $json | ConvertFrom-Json | ConvertTo-HashTable
#>
function ConvertTo-Hashtable {
    [CmdletBinding()]
    [OutputType('hashtable')]
    param (
        [Parameter(ValueFromPipeline)]
        $InputObject
    )

    process {
        ## Return null if the input is null. This can happen when calling the function
        ## recursively and a property is null
        if ($null -eq $InputObject) {
            return $null
        }

        ## Check if the input is an array or collection. If so, we also need to convert
        ## those types into hash tables as well. This function will convert all child
        ## objects into hash tables (if applicable)
        if ($InputObject -is [System.Collections.IEnumerable] -and $InputObject -isnot [string]) {
            $collection = @(
                foreach ($object in $InputObject) {
                    ConvertTo-Hashtable -InputObject $object
                }
            )

            ## Return the array but don't enumerate it because the object may be pretty complex
            Write-Output -NoEnumerate $collection
        } elseif ($InputObject -is [psobject]) { ## If the object has properties that need enumeration
            ## Convert it to its own hash table and return it
            $hash = @{}
            foreach ($property in $InputObject.PSObject.Properties) {
                $hash[$property.Name] = ConvertTo-Hashtable -InputObject $property.Value
            }
            $hash
        } else {
            ## If the object isn't an array, collection, or other object, it's already a hash table
            ## So just return it.
            $InputObject
        }
    }
}




<#
  Function:  Set-AzureObject

  Purpose:  Changes aspects of the Id Property of an Azure object.  This allows
            Properties to be modified from the default values stored in templates.
            Typically this might be changing subscription or resourcegroup values
            for testing.

  Parameters:   -object        = The PowerShell custom object / Azure object to be modified
                -subscription  = The new subscription gui to deploy to


  Example:  
    
          $object = Set-AzureObject -object $object -Subscription "2be53ae5-6e46-47df-beb9-6f3a795387b8"
#> 
function Set-AzureObject(){
param(
    [parameter( Mandatory = $false)]
    [string]$Subscription,
    [parameter( Mandatory = $true)]
    [hashtable]$AzObject
)



    if ($Subscription){  
      $IdString = Set-IdSubscription -IdString $AzObject.id -Subscription $Subscription 
      $AzObject.id = $IdString
    }

    #return the object
     $AzureObject

}



<#
  Function: Set-IdSubscription

  Purpose:  Changes the subscription of the Id Property with an Azure object.  

  Parameters:   -object        = The PowerShell custom object / Azure object to be modified
                -subscription  = The new subscription gui to deploy to


  Example:  
    
          $object = Set-IdSubscription -object $object -Subscription "2be53ae5-6e46-47df-beb9-6f3a795387b8"
#> 
function Set-IdSubscription(){
param(
    [OutputType([hashtable])]
    [parameter( Mandatory = $true)]
    [string]$Subscription,
    [parameter( Mandatory = $true)]
    [string]$IdString
)

   # write-host "Set-IdSubscription azobject type = $($AzObject.GetType())"
    
    
  #Get Id property and split by '/' subscription
    $IdArray = $IdString.split('/')
     
  If ($IdArray[1] -eq 'subscriptions'){
    # substitute the subscription id with the new version
    $IdArray[2] = $Subscription

    #reconstruct the Id
    $id = ""
        for ($i=1;$i -lt $IdArray.Count; $i++) {
        $id = "$($id)/$($IdArray[$i])" 
    }


   $IdString = $id


  }
     $IdString
 #    }
}




<#
  Function:  Get-AzureObject

  Purpose:  Gets and Azure API compliant hash table from Azure cloud objects

  Parameters:   -apiversions   = A hashtable representing current API versions
                -authHeader    = A hashtable (header) with valid authentication for Azure Management
                -id            = An Azure object reference (string).

  Example:  
    
             Get-Azureobject -AuthHeader $authHeader -Apiversions $AzAPIVersions -azobject $azobject
#> 
function Get-AzureObject(){
param(
    [parameter( Mandatory = $true, ValueFromPipeline = $true)]
    [string]$id,
    [parameter( Mandatory = $true)]
    $authHeader,
    [parameter( Mandatory = $true)]
    $apiversions
)


Process  {
    $IDArray = ($id).split("/")

  # Because object types can be overloaded from root namespaces a bit of testing is required
  # to validate what the object type is.
  # The last provider element in the string is always the root namespace so we have to find
  # the last 'provider' element
  
   for ($i=0; $i -lt $IDArray.length; $i++) {
	   if ($IDArray[$i] -eq 'providers'){$provIndex =  $i}
   }

  # $provIndex references where the last occurence of 'provider' is in the Id string
  # we construct the resource type from stacking elements from the ID string

  $elementcount=1
  $providertype = @()

  # Starting at the provider, until the end of the string, stack each potential overload if it exists
  for ($i=$provIndex; $i -lt $IDArray.length; $i++) {
    switch($elementcount){
     {'2','3','5','7','9' -contains $_} { $providertype += $IDArray[$i]}
     default {}
    }
    $elementcount = $elementcount + 1
  }

  # We now know the object type
  $objecttype  = $providertype -join "/"

 # There are some inconsistent objects that dont have a type property - default to deriving type from the ID
  if ($objecttype -eq $null){ $objecttype = $IDArray[$provIndex + 2]}
  #Resource Groups are also a special case without a provider
  if($IDArray.count -eq 5){ $objecttype = "Microsoft.Resources/resourceGroups"}
  # Subscriptions are special too
  if(($IDArray[1] -eq 'subscriptions') -and ($idarray.Count -eq 3)){ $objecttype = "Microsoft.Resources/subscriptions" }
        
  # We can now get the correct API version for the object we are dealing with 
  # which is required for the Azure management URI 
 
  $uri = "https://management.azure.com/$($id)?api-version=$($apiversions["$($objecttype)"])"
    Invoke-RestMethod -Uri $uri -Method GET -Headers $authHeader 

  }

}



<#
  Function:  Remove-AzureObject

  Purpose:  Deletes an azure object

  Parameters:   -id            = A string ID representing an azure object.
                -authHeader    = A hashtable (header) with valid authentication for Azure Management
                -id            = An Azure object reference (string).

  Example:  
    
             Remove-AzureObject -AuthHeader $authHeader -Apiversions $AzAPIVersions -azobject $azobject
#> 
function Remove-AzureObject(){
param(
    [parameter( Mandatory = $true, ValueFromPipeline = $true)]
    [string]$id,
    [parameter( Mandatory = $true)]
    $authHeader,
    [parameter( Mandatory = $true)]
    $apiversions
)


Process  {
     $IDArray = ($id).split("/")
     # $namespace = $IDArray[6]
     # $resourcetype = $IDArray[7]

     # Find the last 'provider' element
     for ($i=0; $i -lt $IDArray.length; $i++) {
      if ($IDArray[$i] -eq 'providers'){$provIndex =  $i}
     }

     $arraykey = "$($IDArray[$provIndex + 1])/$($IDArray[$provIndex + 2])"


   #type can be overloaded - include if present
   if($IDArray[$provIndex + 4]){ 
     if($apiversions["$($arraykey)/$($IDArray[$provIndex + 4])"]){ $arraykey = "$($arraykey)/$($IDArray[$provIndex + 4])" } 
   }
     
     #Resource Groups are a special case without a provider
     if($IDArray.count -eq 5){ $arraykey = "Microsoft.Resources/resourceGroups"}
     
     $uri = "https://management.azure.com/$($id)?api-version=$($apiversions["$($arraykey)"])"

    Invoke-RestMethod -Uri $uri -Method DELETE -Headers $authHeader 

  }

}



<#
  Function:  Push-Azureobject

  Purpose:  Pushes and Azure API compliant hash table to the cloud

  Parameters:   -azobject      = A hashtable representing an azure object.
                -authHeader    = A hashtable (header) with valid authentication for Azure Management
                -azobject      = A hashtable (dictionary) of Azure API versions.
                -unescape      = may be set to $false to prevent the defaul behaviour of unescaping JSON

  Example:  
    
             Push-Azureobject -AuthHeader $authHeader -Apiversions $AzAPIVersions -azobject $azobject
#> 
function Push-Azureobject(){
param(
    [parameter( Mandatory = $true, ValueFromPipeline = $true)]
    $azobject,
    [parameter( Mandatory = $true)]
    $authHeader,
    [parameter( Mandatory = $true)]
    $apiversions,
    [parameter( Mandatory = $false)]
    [bool]$unescape=$true
)


Process  {
    $IDArray = ($azobject.id).split("/")

  # Because object types can be overloaded from root namespaces a bit of testing is required
  # to validate what the object type is.
  # The last provider element in the string is always the root namespace so we have to find
  # the last 'provider' element
  
   for ($i=0; $i -lt $IDArray.length; $i++) {
	   if ($IDArray[$i] -eq 'providers'){$provIndex =  $i}
   }

  # $provIndex references where the last occurence of 'provider' is in the Id string
  # we construct the resource type from stacking elements from the ID string

  $elementcount=1
  $providertype = @()

  # Starting at the provider, until the end of the string, stack each potential overload if it exists
  for ($i=$provIndex; $i -lt $IDArray.length; $i++) {
    switch($elementcount){
     {'2','3','5','7','9' -contains $_} { $providertype += $IDArray[$i]}
     default {}
    }
    $elementcount = $elementcount + 1
  }

  # We now know the object type
  $objecttype  = $providertype -join "/"

 # There are some inconsistent objects that dont have a type property - default to deriving type from the ID
  if ($objecttype -eq $null){ $objecttype = $IDArray[$provIndex + 2]}
  #Resource Groups are also a special case without a provider
  if($IDArray.count -eq 5){ $objecttype = "Microsoft.Resources/resourceGroups"}
   
  # We can now get the correct API version for the object we are dealing with 
  # which is required for the Azure management URI 
  $uri = "https://management.azure.com$($azobject.id)?api-version=$($apiversions["$($objecttype)"])"
   
   # The actual payload of the API request is simply deployed in json
   $jsonbody =  ConvertTo-Json -Depth 50 -InputObject $azobject 
   
   if ($unescape -eq $true){
     # Invoke-RestMethod -Uri $uri -Method PUT -Headers $authHeader -Body $( $jsonbody  | % { [System.Text.RegularExpressions.Regex]::Unescape($_) })   
    Invoke-RestMethod -Uri $uri -Method PUT -Headers $authHeader -Body $jsonbody  
   }
   else  
   {
      Invoke-RestMethod -Uri $uri -Method PUT -Headers $authHeader -Body $jsonbody   
   }
   
  }

}






Export-ModuleMember -function Get-Header, Get-Latest, Get-AzureAPIVersions, Get-AzureObject, Set-AzureObject, Push-AzureObject, Remove-AzureObject, Get-Yamlfile, Get-Jsonfile
