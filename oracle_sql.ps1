docker cp ./sql OracleContainer:/opt
docker cp ./wallet OracleContainer:/opt
docker cp ./run_sql_add_sys.sh OracleContainer:/opt
docker cp ./run_sql_others.sh OracleContainer:/opt

docker exec -it OracleContainer bash /opt/run_sql_add_sys.sh
docker exec -it OracleContainer bash /opt/run_sql_others.sh