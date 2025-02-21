# Mobile Deployments

Automated deployments of the Curity Identity Server to provide initial infrastructure for mobile testing.\
This repository provides a consistent developer experience for anyone who wants to run mobile examples.

## Example Applications

The following example applications can use this repository:

- [Android Kotlin AppAuth Code Example](https://curity.io/resources/learn/kotlin-android-appauth/)
- [iOS Swift AppAuth Code Example](https://curity.io/resources/learn/swift-ios-appauth/)
- [Advanced AppAuth code example using Dynamic Client Registration](https://curity.io/resources/learn/authenticated-dcr-example/)
- [Android Kotlin HAAPI UI SDK Code Example](https://curity.io/resources/learn/kotlin-android-haapi/)
- [iOS Swift HAAPI UI SDK Code Example](https://curity.io/resources/learn/swift-ios-haapi/)
- [React Native HAAPI Code Example](https://curity.io/resources/learn/react-native-haapi/)
- [Android Kotlin HAAPI Model SDK Code Example](https://github.com/curityio/android-haapi-demo-app)
- [iOS Swaift HAAPI Model SDK Code Example](https://github.com/curityio/ios-haapi-demo-app)

## Deployment Interface

Each mobile example calls the following script with parameters to start and stop the Curity Identity Server:

```bash
./start.sh
./stop.sh
```

## Configuration

The files in the `resources` folder provide the base configuration.\
Each code example can apply additional configuration based on its requirements:

- Examples can use default configuration files stored in this project, e.g. in the `appauth` folder.
- Examples can override configuration by copying in their own configuration files, e.g to the `haapi` folder.

## Administration and Users

After deploying the Curity Identity Server, sign in to the Admin UI using the following details:

- URL: `https://localhost:6749/admin`
- User: `admin`
- Password: `Password1`

If you use ngrok and you have a suitable license file you can also sign into the DevOps Dashboard and create test user accounts:

- URL: `https://localhost:6749/admin/dashboard`
- User: `admin`

You may also need to trust the `localhost` certificate at `resources/ssl-cert.pem` for the dashboard to succesfully make fetch requests. For example, on macOS:

- Import the certificate into Keychain Access under `System / Certificates`.
- The configure `Always Trust` for the `curityserver` certificate.

## User Data

You can query user data like accounts and passkeys by connecting to the PostgreSQL database:

```bash
POSTGRES_CONTAINER=$(docker ps | grep postgres | awk '{print $1}')
docker exec -it $POSTGRES_CONTAINER bash
```

Then connect to the database:

```bash
export PGPASSWORD=Password1 && psql -p 5432 -d idsvr -U postgres
```

Then query data like user account details or registered passkey public keys:

```text
select * from accounts;
select * from devices;
```

## More Information

Please visit [curity.io](https://curity.io/) for more information about the Curity Identity Server.
