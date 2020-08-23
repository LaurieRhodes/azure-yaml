# Example - Convert Microsoft documentation to YAML

$json = @'
{
	"location": "westus",
	"properties": {
		"platformFaultDomainCount": 2,
		"platformUpdateDomainCount": 20
	}
}
'@

$object = convertfrom-json -InputObject $json


Out-File -FilePath "C:\Test\deploy.yaml" -InputObject (ConvertTo-Yaml -data $object) -Force 

