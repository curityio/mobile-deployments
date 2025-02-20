# Mobile Deployments

Automated deployments of the Curity Identity Server to provide fast working mobile setups.\
This repository provides a consistent developer experience for anyone who wants to run mobile examples.

## Example Applications

The following applications use this repository:

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

The files in the `resources` folder provide base behaviors related to data and user accounts.\
Different deployment scenarios can apply specific configuration files or override parameters.

For example, HAAPI deployments require a number of technical configuration settings.\
You can study the resources for a particular code example and apply them to your deployed deployments.

- [HAAPI configuration](haapi/example-config-template.xml)

## Administration and Users

Once the Curity Identity Server is deployed, sign in to the Admin UI using the following details:

- URL: `https://localhost:6749/admin`
- User: `admin`
- Password: `Password1`

Or sign into the DevOps Dashboard and create test user accounts:

- URL: `https://localhost:6749/admin/dashboard`
- User: `admin`

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
