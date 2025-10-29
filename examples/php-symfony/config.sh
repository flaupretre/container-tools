
cd config/init

ctools config add init db_ca_certs.sh pg_check_db.sh db_migrations.sh
ctools -r api config add init get_jwt_key.sh

cd ../start
for  i in api cron worker; do
  ctools -r $i config add start start_$i.sh
done

cd ../stop
ctools -r worker config add stop stop_worker.sh
