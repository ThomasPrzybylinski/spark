#bash
export SPARK_PREPEND_CLASSES=1
./bin/pyspark --driver-java-options '-agentlib:jdwp=transport=dt_socket,server=y,suspend=n,address=6006' --executor-memory 2G --driver-memory 12G
#--packages io.delta:delta-core_2.12:2.3.0 --conf "spark.sql.extensions=io.delta.sql.DeltaSparkSessionExtension" --conf "spark.sql.catalog.spark_catalog=org.apache.spark.sql.delta.catalog.DeltaCatalog"

