# AutomationClusterCleanup

### Script to clean the database for the automation cluster and setup the SSO and generic helm chart. 
#### To run the script.py, you must need to pass the following inputs
#### We must pass configMap

```bash
DB_HOST: <postgresdb-host-service-name>
DB_PORT: "5432"
DB_USER_NAME: <postgres-db-user-name>
DB_NAME: <postgres-db-user-name>
LENS_DB: <lens-db-user-name>
GIT_SENSOR_DB: <git_sensor-db-user-name>
CASBIN_DB: <casbin-db-user-name>
ORCHESTRATOR_DB: <orchestrator-db-user-name>
DB_USER: <postgres-db-username>
DB_PASSWORD: <db-password>
PGPASSWORD: <pg-password>
url: <dashboard-url>
```
#### Need to pass the secret

```bash
ClientID: <google-api&service-clientID>
ClientSecret: <google-api&service-clientsecret>

```

