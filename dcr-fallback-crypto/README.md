# Android HAAPI Fallback Crypto

These resources can be used to enable an end-to-end Android and Identity Server strong security solution for developers.\
The keys generated can be used for Mutual TLS or to create client assertions.

## Prerequisites

Android keystores for testing will use the Bouncy Castle format, with a BKS extension.\
First copy the latest JAR file from the [releases page](https://www.bouncycastle.org/latest_releases.html) into this folder.

## Deliverable Files

The following artifacts need to be produced in order for an end-to-end Android solution to work.\
Client keys produced can be used to present either client certificates or client assertions.

| Artifact | Usage |
| -------- | ----- |
| devicekeystore.bks | An Android keystore containing a client key + certificate |
| servertruststore.bks | The SSL root authority of the Identity Server, to be used as a trust store by the Android app |
| DeviceClientCert.pem | The public key of the client certificate, to be included in a JWKS as a public key JWK |
| DeviceAuthority.pem | The issuer of the client certificate, to be configured as a client trust store in the Identity Server |
| Device JWKS Endpoint | An HTTP endpoint that serves the client certificate from DeviceKeyStore.bks as a JSON Web Key |

This repository starts with portable certificate formats and translates to Android specific formats when needed.\
All passwords used to access certificate private keys will be `android`.

## Keystores

For development purposes, BKS files containing client keys will be embedded into the APK file at deployment time.\
A secure production system would instead use a third party system to deploy keystores.\
Keys would then be provisioned by a Mobile Device Management system or a Software Attestation framework.

## Instructions

### 1. Create Certificates in PKCS12 Format

First run the following script to create some development certificates:

```bash
./createOpenSslCerts.sh
```

This produces the following outputs:

| File | Usage |
| ---- | ----- |
| DeviceClientCert.p12 | The Android client certificate and key in a password protected P12 format |
| DeviceAuthority.pem | The trusted root authority that issues client certificates and keys |

### 2. Get the Identity Server Certificate

The Identity Server uses a self signed SSL certificate by default, so the Android app needs to trust it directly.\
Get the certificate in PEM format like this:

```bash
openssl s_client -connect localhost:8443 2>/dev/null </dev/null | sed -ne '/-BEGIN CERTIFICATE-/,/-END CERTIFICATE-/p' > IdentityServerCert.pem
```

### 3. Create Android Keystores

Translate the client certificate and key to a BKS keystore format suitable for use with Android:

```bash
rm devicekeystore.bks 2>/dev/null
keytool -importkeystore \
-srckeystore  DeviceClientCert.p12 -srcstoretype  pkcs12 -srcstorepass  'android' \
-destkeystore devicekeystore.bks   -deststoretype bks    -deststorepass 'android' \
-provider org.bouncycastle.jce.provider.BouncyCastleProvider -providerpath bcprov-jdk18on-171.jar -noprompt
```

Also translate the Identity Server certificate to a BKS file:

```bash
rm servertruststore.bks 2>/dev/null
keytool -importcert -v -trustcacerts -file IdentityServerCert.pem -alias IdentityServerTrustStore -keystore servertruststore.bks \
-provider org.bouncycastle.jce.provider.BouncyCastleProvider -providerpath bcprov-jdk18on-171.jar -storetype BKS -storepass "android" -noprompt
```

### 4. Deploy Android Keystores

For demo purposes, deploy the keystore and truststore to the `/app/src/main/res/raw` folder of the Android app.\
This is just meant to be a deployment option that is easy for developers to manage.

```bash
TARGET_FOLDER=../../android-haapi-demo-app/app/src/main/res/raw
rm -rf $TARGET_FOLDER
mkdir $TARGET_FOLDER
cp devicekeystore.bks $TARGET_FOLDER
cp servertruststore.bks $TARGET_FOLDER
```

### 5. Load Keystores in Android

For testing, Android code can load a keystore embedded into the APK file like this:

```kotlin
val deviceKeyStore = loadKeyStore(context, R.raw.devicekeystore, "android")
val serverTrustStore = loadKeyStore(context, R.raw.servertruststore, "android")

fun loadKeyStore(context: Context, resourceId: Int, password: String): KeyStore {

    val inputStream = context.resources.openRawResource(resourceId)
    inputStream.use {
        val keyStore = KeyStore.getInstance("BKS")
        keyStore.load(inputStream, password.toCharArray())
        return keyStore
    }
}
```

### 6. Use Mutual TLS in Android

The Android code can supply HAAPI client credentials like this when using client certificate DCR credentials:

```kotlin
val dcrClientCredentials =
    ClientAuthenticationMethodConfiguration.Mtls(
        clientKeyStore = deviceKeyStore,
        clientKeyStorePassword = "android".toCharArray(),
        serverTrustStore = serverTrustStore
    )
```

### 7. Configure Mutual TLS in the Curity Identity Server

Add `DeviceAuthority.pem` as a client trust store via the Facilities menu.\
Edit the haapi-android-client and set its authentication method to `mutual-tls`.\
Select the DeviceAuthority item from the `Trusted CA` dropdown.

### 8. Use Client Assertions in Android

The Android code can supply HAAPI client credentials like this when using client assertion DCR credentials:

```kotlin
val dcrClientCredentials =
    ClientAuthenticationMethodConfiguration.SignedJwt.Asymmetric(
      clientKeyStore = deviceKeyStore,
      clientKeyStorePassword = deviceKeyStorePassword,
      alias = "deviceclientcert",
      algorithmIdentifier = ClientAuthenticationMethodConfiguration.SignedJwt.Asymmetric.AlgorithmIdentifier.RS256
    )
```

### 9. Configure a JWKS URI in the Curity Identity Server

Edit the haapi-android-client and set its authentication method to `jwks-uri` and configure a URL.\
Deploy a minimal Docker API to serve a keyset at http://devicemanagement:8000/.well-known/jwks. \
The API will load DeviceClientCert.pem and return a JWKS that includes the public key from DeviceClientCert.pem.\
The end-to-end client assertion solution will then work.
