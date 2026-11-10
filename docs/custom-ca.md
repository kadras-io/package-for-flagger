# Custom Certificate Authorities

If Flagger needs to reach services with certificates signed by a private certificate authority, like a metrics provider, a webhook, or an alert provider, add the PEM-encoded certificates of the authority to the package values.

```yaml
ca_cert_data: |
  -----BEGIN CERTIFICATE-----
  MIICvjCCAaYCCQDhcJuwMw6yZzANBgkqhkiG9w0BAQsFADAhMQswCQYDVQQGEwJE
  ...
  -----END CERTIFICATE-----
```

The certificates are stored in the `flagger-ca-certificates` Secret and mounted in Flagger, which trusts them in addition to the system certificate authorities.
