!/bin/bash
echo "testing connection"
PGPASSWORD=$PGPASSWORD psql -h $DB_HOST -p $DB_PORT -U $DB_USER_NAME -d $DB_NAME -t -c "\l"

echo "LENS_DB-----"
echo $LENS_DB
echo "GIT_SENSOR_DB-----"
echo $GIT_SENSOR_DB
echo "CASBIN_DB-----"
echo $CASBIN_DB
echo "ORCHESTRATOR_DB-----"
echo $ORCHESTRATOR_DB

export PGPASSWORD=$DB_PASSWORD

echo "deleting and creating new DB"
SELECT pid, pg_terminate_backend(pid) FROM pg_stat_activity WHERE datname = 'orchestrator';

psql -h $DB_HOST -p $DB_PORT -U $DB_USER -d $DB_NAME -t -c "REVOKE CONNECT ON DATABASE $LENS_DB FROM public;"
psql -h $DB_HOST -p $DB_PORT -U $DB_USER -d $DB_NAME -t -c "ALTER DATABASE $LENS_DB ALLOW_CONNECTIONS = off;"
psql -h $DB_HOST -p $DB_PORT -U $DB_USER -d $DB_NAME -t -c "SELECT pg_terminate_backend(pid) FROM pg_stat_activity WHERE datname = '$LENS_DB' AND pid <> pg_backend_pid();"
psql -h $DB_HOST -p $DB_PORT -U $DB_USER -d $DB_NAME -t -c "DROP DATABASE $LENS_DB;"
psql -h $DB_HOST -p $DB_PORT -U $DB_USER -d $DB_NAME -t -c "CREATE DATABASE $LENS_DB;"

psql -h $DB_HOST -p $DB_PORT -U $DB_USER_NAME -d $DB_NAME -t -c "REVOKE CONNECT ON DATABASE $GIT_SENSOR_DB FROM public;"
psql -h $DB_HOST -p $DB_PORT -U $DB_USER_NAME -d $DB_NAME -t -c "ALTER DATABASE $GIT_SENSOR_DB ALLOW_CONNECTIONS = off;"
psql -h $DB_HOST -p $DB_PORT -U $DB_USER_NAME -d $DB_NAME -t -c "SELECT pg_terminate_backend(pid) FROM pg_stat_activity WHERE datname = '$GIT_SENSOR_DB';"
psql -h $DB_HOST -p $DB_PORT -U $DB_USER_NAME -d $DB_NAME -t -c "SELECT pg_terminate_backend(pg_stat_activity.pid) FROM pg_stat_activity WHERE pg_stat_activity.datname = '$GIT_SENSOR_DB' AND pid <> pg_backend_pid();"
psql -h $DB_HOST -p $DB_PORT -U $DB_USER_NAME -d $DB_NAME -t -c "DROP DATABASE $GIT_SENSOR_DB;"
psql -h $DB_HOST -p $DB_PORT -U $DB_USER_NAME -d $DB_NAME -t -c "CREATE DATABASE $GIT_SENSOR_DB;"

psql -h $DB_HOST -p $DB_PORT -U $DB_USER_NAME -d $DB_NAME -t -c "REVOKE CONNECT ON DATABASE $CASBIN_DB FROM public;"
psql -h $DB_HOST -p $DB_PORT -U $DB_USER_NAME -d $DB_NAME -t -c "ALTER DATABASE $CASBIN_DB ALLOW_CONNECTIONS = off;"
psql -h $DB_HOST -p $DB_PORT -U $DB_USER_NAME -d $DB_NAME -t -c "SELECT pg_terminate_backend(pid) FROM pg_stat_activity WHERE datname = '$CASBIN_DB';"
psql -h $DB_HOST -p $DB_PORT -U $DB_USER_NAME -d $DB_NAME -t -c "SELECT pg_terminate_backend(pg_stat_activity.pid) FROM pg_stat_activity WHERE pg_stat_activity.datname = '$CASBIN_DB' AND pid <> pg_backend_pid();"
psql -h $DB_HOST -p $DB_PORT -U $DB_USER_NAME -d $DB_NAME -t -c "DROP DATABASE $CASBIN_DB;"
psql -h $DB_HOST -p $DB_PORT -U $DB_USER_NAME -d $DB_NAME -t -c "CREATE DATABASE $CASBIN_DB;"

psql -h $DB_HOST -p $DB_PORT -U $DB_USER_NAME -d $DB_NAME -t -c "REVOKE CONNECT ON DATABASE $ORCHESTRATOR_DB FROM public;"
psql -h $DB_HOST -p $DB_PORT -U $DB_USER_NAME -d $DB_NAME -t -c "ALTER DATABASE $ORCHESTRATOR_DB ALLOW_CONNECTIONS = off;"
psql -h $DB_HOST -p $DB_PORT -U $DB_USER_NAME -d $DB_NAME -t -c "SELECT pg_terminate_backend(pg_stat_activity.pid) FROM pg_stat_activity WHERE pg_stat_activity.datname = '$ORCHESTRATOR_DB' AND pid <> pg_backend_pid();"
psql -h $DB_HOST -p $DB_PORT -U $DB_USER_NAME -d $DB_NAME -t -c "DROP DATABASE $ORCHESTRATOR_DB;"
psql -h $DB_HOST -p $DB_PORT -U $DB_USER_NAME -d $DB_NAME -t -c "CREATE DATABASE $ORCHESTRATOR_DB;"

PGPASSWORD=$PGPASSWORD psql -h $DB_HOST -p $DB_PORT -U $DB_USER_NAME -d $DB_NAME -t -c "\l"

echo "git cloning and doing migration"
: "${DEVTRON_BRANCH:=main}"
: "${GIT_SENSOR_BRANCH:=main}"
: "${LENS_BRANCH:=main}"

DB_CRED="$DB_USER:$DB_PASSWORD@"

git clone https://github.com/devtron-labs/git-sensor -b $GIT_SENSOR_BRANCH
git clone https://github.com/devtron-labs/devtron -b $DEVTRON_BRANCH
git clone https://github.com/devtron-labs/lens -b $LENS_BRANCH


migrate -path ./devtron/scripts/sql -database postgres://$DB_CRED$DB_HOST:$DB_PORT/$ORCHESTRATOR_DB?sslmode=disable up;

migrate -path ./devtron/scripts/casbin  -database postgres://$DB_CRED$DB_HOST:$DB_PORT/$CASBIN_DB?sslmode=disable up;


migrate -path ./git-sensor/scripts/sql  -database postgres://$DB_CRED$DB_HOST:$DB_PORT/$GIT_SENSOR_DB?sslmode=disable up;


migrate -path ./lens/scripts/sql  -database postgres://$DB_CRED$DB_HOST:$DB_PORT/$LENS_DB?sslmode=disable up;

echo "done migration"

echo "Starting SSO Setup"

echo "Cluster URL is"

echo $url
RedirectURI=${url}/api/dex/callback

PGPASSWORD=$PGPASSWORD psql -h $DB_HOST -p $DB_PORT -U $DB_USER_NAME -d $ORCHESTRATOR_DB -t -c "INSERT INTO sso_login_config (id, name, url, config, created_on, created_by, updated_on, updated_by, active) 
VALUES (1, 'google','$url' ,'{\"id\":\"google\",\"type\":\"oidc\",\"name\":\"Google\",\"config\":{\"clientID\":\"$ClientID\",\"clientSecret\":\"$ClientSecret\",\"hostedDomains\":[\"devtron.ai\"],\"issuer\":\"https://accounts.google.com\",\"redirectURI\": \"$RedirectURI\"}}', NOW(), 1, NOW(), 1, true) ;"

echo "Cleaning up Chart Repo"
PGPASSWORD=$PGPASSWORD psql -h $DB_HOST -p $DB_PORT -U $DB_USER_NAME -d $ORCHESTRATOR_DB -t -c "TRUNCATE TABLE chart_repo RESTART IDENTITY CASCADE;"

echo "Adding Devtron-Charts"
PGPASSWORD=$PGPASSWORD psql -h $DB_HOST -p $DB_PORT -U $DB_USER_NAME -d $ORCHESTRATOR_DB -t -c "INSERT INTO chart_repo (id, name, url ,is_default , active , created_on , created_by , updated_on , updated_by, external, deleted, allow_insecure_connection) 
VALUES ('1','Devtron-Charts','https://devtron-labs.github.io/helm-pilot/','f','t',NOW(),'1',NOW(),'1','t','f','f') ;"

echo "Cleanup done Successfully"
